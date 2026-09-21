package stream

Request :: struct {
	path:            string,
	size_bytes:      int,
	last_seen_frame: int,
}

Entry :: struct {
	size_bytes:      int,
	last_seen_frame: int,
}

Streamer :: struct {
	budget_bytes: int,
	used_bytes:   int,
	queue:        [dynamic]Request,
	loaded:       map[string]Entry,
}

make_streamer :: proc(budget_bytes: int) -> Streamer {
	return Streamer{
		budget_bytes = budget_bytes,
		queue        = make([dynamic]Request),
		loaded       = make(map[string]Entry),
	}
}

destroy_streamer :: proc(s: ^Streamer) {
	delete(s.queue)
	delete(s.loaded)
}

request :: proc(s: ^Streamer, path: string, size_bytes: int, frame: int) {
	if path in s.loaded {
		e := s.loaded[path]
		e.last_seen_frame = frame
		s.loaded[path] = e
		return
	}
	for &q in s.queue {
		if q.path == path {
			q.last_seen_frame = frame
			return
		}
	}
	append(&s.queue, Request{path = path, size_bytes = size_bytes, last_seen_frame = frame})
}

pump :: proc(s: ^Streamer) -> int {
	loaded_count := 0
	for len(s.queue) > 0 {
		next := s.queue[0]
		if s.used_bytes + next.size_bytes > s.budget_bytes {
			break
		}
		ordered_remove(&s.queue, 0)
		s.loaded[next.path] = Entry{size_bytes = next.size_bytes, last_seen_frame = next.last_seen_frame}
		s.used_bytes += next.size_bytes
		loaded_count += 1
	}
	return loaded_count
}

evict_not_visible :: proc(s: ^Streamer, visible: map[string]bool) -> int {
	evicted := 0
	for path, e in s.loaded {
		if !visible[path] {
			s.used_bytes -= e.size_bytes
			delete_key(&s.loaded, path)
			evicted += 1
		}
	}
	return evicted
}
