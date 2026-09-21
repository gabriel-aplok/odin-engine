package events

import "core:testing"

TEST_RAN: [dynamic]Event

record_event :: proc(e: Event, ctx: rawptr) {
	count := (^int)(ctx)
	count^ += 1
	append(&TEST_RAN, e)
}

@(test)
test_subscribe_emit_poll :: proc(t: ^testing.T) {
	TEST_RAN = make([dynamic]Event, context.temp_allocator)
	count := 0
	b := make_bus()
	defer destroy_bus(&b)
	subscribe(&b, "hit", record_event, &count)
	subscribe(&b, "hop", record_event, &count)
	emit(&b, "hit", 1, 2)
	emit(&b, "pause")
	testing.expect_value(t, poll(&b), 1)
	testing.expect_value(t, count, 1)
	testing.expect_value(t, len(TEST_RAN), 1)
	testing.expect_value(t, TEST_RAN[0], Event{topic = "hit", a = 1, b = 2})
	// queue drains, second poll runs nothing.
	testing.expect_value(t, poll(&b), 0)
}
