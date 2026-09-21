package physics

import "core:math/linalg"

AABB :: struct {
	center:       linalg.Vector3f32,
	half_extents: linalg.Vector3f32,
}

GRAVITY :: linalg.Vector3f32{0, -9.81, 0}

CONTACT_EPSILON :: f32(0.001)

integrate :: proc(
	position, velocity: ^linalg.Vector3f32,
	acceleration: linalg.Vector3f32,
	dt: f32,
) {
	velocity^ += acceleration * dt
	position^ += velocity^ * dt
}

overlaps :: proc(a, b: AABB) -> bool {
	d := linalg.abs(a.center - b.center)
	e := a.half_extents + b.half_extents
	return d.x <= e.x && d.y <= e.y && d.z <= e.z
}

resolve_axis :: proc(mover: ^AABB, velocity: ^linalg.Vector3f32, solid: AABB) {
	if !overlaps(mover^, solid) {
		return
	}
	push :=
		(mover.half_extents + solid.half_extents) -
		linalg.abs(mover.center - solid.center) +
		CONTACT_EPSILON
	if push.x < push.y && push.x < push.z {
		s := sign(mover.center.x - solid.center.x)
		mover.center.x += push.x * s
		velocity.x = 0
	} else if push.y < push.z {
		s := sign(mover.center.y - solid.center.y)
		mover.center.y += push.y * s
		velocity.y = 0
	} else {
		s := sign(mover.center.z - solid.center.z)
		mover.center.z += push.z * s
		velocity.z = 0
	}
}

sign :: proc(v: f32) -> f32 {
	return v >= 0 ? 1 : -1
}
