package state

import "core:testing"

@(test)
test_transitions :: proc(t: ^testing.T) {
	m := make_machine()
	testing.expect_value(t, m.current, State.Menu)
	to_playing(&m)
	testing.expect_value(t, m.current, State.Playing)
	toggle_pause(&m)
	testing.expect_value(t, m.current, State.Paused)
	toggle_pause(&m)
	testing.expect_value(t, m.current, State.Playing)
	quit_to_menu(&m)
	testing.expect_value(t, m.current, State.Menu)
}

@(test)
test_pause_only_from_playing :: proc(t: ^testing.T) {
	m := make_machine()
	toggle_pause(&m)
	testing.expect_value(t, m.current, State.Menu)
}
