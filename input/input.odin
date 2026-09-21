#+feature dynamic-literals
package input

import rl "vendor:raylib"

Action :: enum {
	Move_Forward,
	Move_Back,
	Move_Left,
	Move_Right,
	Jump,
	Attack,
}

Key_State :: map[rl.KeyboardKey]bool

Action_Map :: struct {
	bindings: map[Action][dynamic]rl.KeyboardKey,
}

SCAN_MIN :: 32
SCAN_MAX :: 349

make_action_map :: proc() -> Action_Map {
	m := Action_Map {
		bindings = make(map[Action][dynamic]rl.KeyboardKey),
	}
	m.bindings[.Move_Forward] = {rl.KeyboardKey.W, rl.KeyboardKey.UP}
	m.bindings[.Move_Back] = {rl.KeyboardKey.S, rl.KeyboardKey.DOWN}
	m.bindings[.Move_Left] = {rl.KeyboardKey.A, rl.KeyboardKey.LEFT}
	m.bindings[.Move_Right] = {rl.KeyboardKey.D, rl.KeyboardKey.RIGHT}
	m.bindings[.Jump] = {rl.KeyboardKey.SPACE}
	m.bindings[.Attack] = {rl.KeyboardKey.J, rl.KeyboardKey.X}
	return m
}

destroy_action_map :: proc(m: ^Action_Map) {
	for _, keys in m.bindings {
		delete(keys)
	}
	delete(m.bindings)
}

poll_live_state :: proc() -> Key_State {
	state := make(Key_State)
	for i in SCAN_MIN ..= SCAN_MAX {
		key := rl.KeyboardKey(i)
		if rl.IsKeyDown(key) {
			state[key] = true
		}
	}
	return state
}

action_down :: proc(m: ^Action_Map, state: Key_State, action: Action) -> bool {
	keys, ok := m.bindings[action]
	if !ok {
		return false
	}
	for k in keys {
		if state[k] {
			return true
		}
	}
	return false
}
