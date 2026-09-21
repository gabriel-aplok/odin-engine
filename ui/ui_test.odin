package ui

import "core:testing"

@(test)
test_stats_text_format :: proc(t: ^testing.T) {
	s := stats_text(60, 20.5, 0.12, 1.34, 100, 200, 12, 80)
	defer delete(s)
	testing.expect_value(
		t,
		s,
		"fps 60 worst 20.5ms upd 0.12ms draw 1.34ms shown 100/200 calls 12 culled 80",
	)
}
