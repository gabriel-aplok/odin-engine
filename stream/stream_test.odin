#+feature dynamic-literals
package stream

import "core:testing"

@(test)
test_budget_blocks_and_evicts :: proc(t: ^testing.T) {
	s := make_streamer(100)
	defer destroy_streamer(&s)
	request(&s, "a", 60, 1)
	request(&s, "b", 60, 1)
	testing.expect_value(t, pump(&s), 1)
	testing.expect_value(t, s.used_bytes, 60)
	// Same path twice queues once.
	request(&s, "b", 60, 2)
	testing.expect_value(t, len(s.queue), 1)
	visible := map[string]bool{"a" = false, "b" = true}
	defer delete(visible)
	testing.expect_value(t, evict_not_visible(&s, visible), 1)
	testing.expect_value(t, s.used_bytes, 0)
	testing.expect_value(t, pump(&s), 1)
	testing.expect_value(t, s.used_bytes, 60)
}
