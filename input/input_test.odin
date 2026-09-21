package input

import rl "vendor:raylib"
import "core:testing"

@(test)
test_action_down_uses_bindings :: proc(t: ^testing.T) {
	m := make_action_map()
	defer destroy_action_map(&m)
	bind_key(&m, "forward", rl.KeyboardKey.W)
	state := make_input_state()
	defer destroy_input_state(&state)
	state.keys[rl.KeyboardKey.W] = true
	testing.expect(t, action_down(&m, state, "forward"))
	testing.expect(t, !action_down(&m, state, "jump"))
}

@(test)
test_pad_buttons_trigger_actions :: proc(t: ^testing.T) {
	m := make_action_map()
	defer destroy_action_map(&m)
	bind_pad(&m, "jump", rl.GamepadButton.RIGHT_FACE_DOWN)
	state := make_input_state()
	defer destroy_input_state(&state)
	state.pads[rl.GamepadButton.RIGHT_FACE_DOWN] = true
	testing.expect(t, action_down(&m, state, "jump"))
}

@(test)
test_remap_at_runtime :: proc(t: ^testing.T) {
	m := make_action_map()
	defer destroy_action_map(&m)
	state := make_input_state()
	defer destroy_input_state(&state)
	bind_key(&m, "jump", rl.KeyboardKey.F)
	state.keys[rl.KeyboardKey.F] = true
	testing.expect(t, action_down(&m, state, "jump"))
	unbind_key(&m, "jump", rl.KeyboardKey.F)
	testing.expect(t, !action_down(&m, state, "jump"))
	bind_pad(&m, "attack", rl.GamepadButton.LEFT_FACE_UP)
	state.pads[rl.GamepadButton.LEFT_FACE_UP] = true
	testing.expect(t, action_down(&m, state, "attack"))
}
