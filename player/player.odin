package player

import "core:math/linalg"

MOVE_SPEED :: f32(6)
JUMP_SPEED :: f32(7)
GRAVITY_Y :: f32(-22)
GROUND_Y :: f32(0)
HALF_HEIGHT :: f32(0.5)

Player :: struct {
	position: linalg.Vector3f32,
	velocity: linalg.Vector3f32,
	grounded: bool,
}

make_player :: proc(spawn: linalg.Vector3f32) -> Player {
	return Player{position = spawn, grounded = true}
}

// move is a normalized XZ direction. jump is true on the press frame.
step :: proc(p: ^Player, move: linalg.Vector2f32, jump: bool, dt: f32) -> bool {
	jumped := false
	p.velocity.x = move.x * MOVE_SPEED
	p.velocity.z = move.y * MOVE_SPEED
	if jump && p.grounded {
		p.velocity.y = JUMP_SPEED
		p.grounded = false
		jumped = true
	}
	p.velocity.y += GRAVITY_Y * dt
	p.position += p.velocity * dt
	if p.position.y <= GROUND_Y + HALF_HEIGHT {
		p.position.y = GROUND_Y + HALF_HEIGHT
		p.velocity.y = 0
		p.grounded = true
	}
	return jumped
}
