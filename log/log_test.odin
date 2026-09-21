package logger

import "core:os"
import "core:testing"

@(test)
test_level_filter :: proc(t: ^testing.T) {
	l := make_logger(.Warn)
	testing.expect(t, !should_write(&l, .Debug))
	testing.expect(t, !should_write(&l, .Info))
	testing.expect(t, should_write(&l, .Warn))
	testing.expect(t, should_write(&l, .Error))
}

@(test)
test_file_output :: proc(t: ^testing.T) {
	path := "test_log.txt"
	defer os.remove(path)
	l := make_logger()
	testing.expect(t, open_file(&l, path))
	info(&l, "test", "hello log")
	warn(&l, "test", "careful now")
	close_logger(&l)
	data, err := os.read_entire_file(path, context.allocator)
	defer delete(data)
	testing.expect(t, err == nil)
	text := string(data)
	testing.expect(t, len(text) > 0)
	testing.expect(t, find_substring(text, "hello log"))
	testing.expect(t, find_substring(text, "[Warn]"))
	testing.expect(t, !open_file(&l, "/no/such/dir/log.txt"))
}

find_substring :: proc(s, sub: string) -> bool {
	if len(sub) == 0 {
		return true
	}
	for i in 0 ..= len(s) - len(sub) {
		if s[i:i + len(sub)] == sub {
			return true
		}
	}
	return false
}
