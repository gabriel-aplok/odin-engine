package events

Event :: struct {
	topic: string,
	a:     u64,
	b:     u64,
}

// ctx is caller owned. poll hands it back untouched.
// games pass their state pointer, tests pass a counter.
Handler :: proc(e: Event, ctx: rawptr)

Subscription :: struct {
	handler: Handler,
	ctx:     rawptr,
}

Bus :: struct {
	queue:       [dynamic]Event,
	subscribers: map[string][dynamic]Subscription,
}

make_bus :: proc() -> Bus {
	return Bus{
		queue       = make([dynamic]Event),
		subscribers = make(map[string][dynamic]Subscription),
	}
}

destroy_bus :: proc(b: ^Bus) {
	delete(b.queue)
	for _, list in b.subscribers {
		delete(list)
	}
	delete(b.subscribers)
}

subscribe :: proc(b: ^Bus, topic: string, handler: Handler, ctx: rawptr = nil) {
	list, ok := b.subscribers[topic]
	if !ok {
		list = make([dynamic]Subscription)
	}
	append(&list, Subscription{handler = handler, ctx = ctx})
	b.subscribers[topic] = list
}

emit :: proc(b: ^Bus, topic: string, a: u64 = 0, b_id: u64 = 0) {
	append(&b.queue, Event{topic = topic, a = a, b = b_id})
}

poll :: proc(b: ^Bus) -> int {
	ran := 0
	for e in b.queue {
		if list, ok := b.subscribers[e.topic]; ok {
			for s in list {
				s.handler(e, s.ctx)
				ran += 1
			}
		}
	}
	clear(&b.queue)
	return ran
}
