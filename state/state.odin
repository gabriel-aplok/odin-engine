package state

Machine :: struct {
	current: string,
}

make_machine :: proc() -> Machine {
	return Machine{}
}

set :: proc(m: ^Machine, s: string) {
	m.current = s
}

is :: proc(m: ^Machine, s: string) -> bool {
	return m.current == s
}
