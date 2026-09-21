#+feature dynamic-literals
package input

import "core:testing"
import rl "vendor:raylib"

@(test)
test_action_down_uses_bindings :: proc(t: ^testing.T) {
	m := make_action_map()
	defer destroy_action_map(&m)
	state := Key_State {
		rl.KeyboardKey.W = true,
	}
	defer delete(state)
	testing.expect(t, action_down(&m, state, .Move_Forward))
	testing.expect(t, !action_down(&m, state, .Jump))
}
