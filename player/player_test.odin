package player

import "core:testing"

@(test)
test_move_and_ground_stick :: proc(t: ^testing.T) {
	p := make_player({0, HALF_HEIGHT, 0})
	jumped := step(&p, {1, 0}, false, 1.0 / 60)
	testing.expect(t, !jumped)
	testing.expect(t, p.position.x > 0)
	testing.expect(t, p.grounded)
	testing.expect_value(t, p.position.y, HALF_HEIGHT)
}

@(test)
test_jump_and_land :: proc(t: ^testing.T) {
	p := make_player({0, HALF_HEIGHT, 0})
	testing.expect(t, step(&p, {0, 0}, true, 1.0 / 60))
	testing.expect(t, !p.grounded)
	landed := false
	for _ in 0 ..< 300 {
		step(&p, {0, 0}, false, 1.0 / 60)
		if p.grounded {
			landed = true
			break
		}
	}
	testing.expect(t, landed)
	testing.expect_value(t, p.position.y, HALF_HEIGHT)
}

@(test)
test_no_double_jump :: proc(t: ^testing.T) {
	p := make_player({0, HALF_HEIGHT, 0})
	step(&p, {0, 0}, true, 1.0 / 60)
	vy := p.velocity.y
	step(&p, {0, 0}, true, 1.0 / 60)
	testing.expect(t, p.velocity.y < vy)
}
