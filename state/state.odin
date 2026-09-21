package state

State :: enum {
	Menu,
	Playing,
	Paused,
}

Machine :: struct {
	current: State,
}

make_machine :: proc() -> Machine {
	return Machine{current = .Menu}
}

to_playing :: proc(m: ^Machine) {
	m.current = .Playing
}

toggle_pause :: proc(m: ^Machine) {
	if m.current == .Playing {
		m.current = .Paused
	} else if m.current == .Paused {
		m.current = .Playing
	}
}

quit_to_menu :: proc(m: ^Machine) {
	m.current = .Menu
}
