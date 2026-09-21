package state

import "core:testing"

@(test)
test_set_and_is :: proc(t: ^testing.T) {
	m := make_machine()
	set(&m, "playing")
	testing.expect(t, is(&m, "playing"))
	testing.expect(t, !is(&m, "menu"))
	set(&m, "menu")
	testing.expect(t, is(&m, "menu"))
}
