package input

import rl "vendor:raylib"

Action :: string

PAD :: 0

Input_State :: struct {
	keys: map[rl.KeyboardKey]bool,
	pads: map[rl.GamepadButton]bool,
}

Action_Map :: struct {
	keys: map[Action][dynamic]rl.KeyboardKey,
	pads: map[Action][dynamic]rl.GamepadButton,
}

SCAN_MIN :: 32
SCAN_MAX :: 349

FIRST_PAD_BUTTON :: rl.GamepadButton.UNKNOWN
LAST_PAD_BUTTON :: rl.GamepadButton.RIGHT_THUMB

make_action_map :: proc() -> Action_Map {
	return Action_Map{
		keys = make(map[Action][dynamic]rl.KeyboardKey),
		pads = make(map[Action][dynamic]rl.GamepadButton),
	}
}

destroy_action_map :: proc(m: ^Action_Map) {
	for _, keys in m.keys {
		delete(keys)
	}
	delete(m.keys)
	for _, btns in m.pads {
		delete(btns)
	}
	delete(m.pads)
}

bind_key :: proc(m: ^Action_Map, action: Action, key: rl.KeyboardKey) {
	list, ok := m.keys[action]
	if !ok {
		list = make([dynamic]rl.KeyboardKey)
	}
	for k in list {
		if k == key {
			m.keys[action] = list
			return
		}
	}
	append(&list, key)
	m.keys[action] = list
}

bind_pad :: proc(m: ^Action_Map, action: Action, btn: rl.GamepadButton) {
	list, ok := m.pads[action]
	if !ok {
		list = make([dynamic]rl.GamepadButton)
	}
	for b in list {
		if b == btn {
			m.pads[action] = list
			return
		}
	}
	append(&list, btn)
	m.pads[action] = list
}

unbind_key :: proc(m: ^Action_Map, action: Action, key: rl.KeyboardKey) {
	list, ok := m.keys[action]
	if !ok {
		return
	}
	for k, i in list {
		if k == key {
			ordered_remove(&list, i)
			break
		}
	}
	m.keys[action] = list
}

make_input_state :: proc() -> Input_State {
	return Input_State{
		keys = make(map[rl.KeyboardKey]bool),
		pads = make(map[rl.GamepadButton]bool),
	}
}

destroy_input_state :: proc(s: ^Input_State) {
	delete(s.keys)
	delete(s.pads)
}

poll_live_state :: proc() -> Input_State {
	state := make_input_state()
	for i in SCAN_MIN ..= SCAN_MAX {
		key := rl.KeyboardKey(i)
		if rl.IsKeyDown(key) {
			state.keys[key] = true
		}
	}
	if rl.IsGamepadAvailable(PAD) {
		for i in int(FIRST_PAD_BUTTON) ..= int(LAST_PAD_BUTTON) {
			btn := rl.GamepadButton(i)
			if rl.IsGamepadButtonDown(PAD, btn) {
				state.pads[btn] = true
			}
		}
	}
	return state
}

action_down :: proc(m: ^Action_Map, state: Input_State, action: Action) -> bool {
	if keys, ok := m.keys[action]; ok {
		for k in keys {
			if state.keys[k] {
				return true
			}
		}
	}
	if btns, ok := m.pads[action]; ok {
		for b in btns {
			if state.pads[b] {
				return true
			}
		}
	}
	return false
}
