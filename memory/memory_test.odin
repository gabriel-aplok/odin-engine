package memory

import "core:testing"

@(test)
test_alloc_reset_and_budget :: proc(t: ^testing.T) {
	f := make_frame(64)
	defer destroy_frame(&f)
	a := alloc(&f, 16, 8)
	testing.expect(t, a != nil)
	testing.expect(t, used(&f) >= 16)
	// whole budget gone, next alloc fails loud.
	b := alloc(&f, 64, 8)
	testing.expect(t, b == nil)
	reset(&f)
	testing.expect_value(t, used(&f), 0)
	c := alloc(&f, 16, 8)
	testing.expect(t, c != nil)
}

@(test)
test_allocator_proc :: proc(t: ^testing.T) {
	f := make_frame(128)
	defer destroy_frame(&f)
	a := allocator(&f)
	buf, err := make([]u8, 32, a)
	testing.expect(t, err == nil)
	testing.expect_value(t, len(buf), 32)
	delete(buf, a)
	_, err = make([]u8, 256, a)
	testing.expect(t, err == .Out_Of_Memory)
}
