package cull

import rl "vendor:raylib"
import "core:math/linalg"

Camera_Basis :: struct {
	position:  linalg.Vector3f32,
	forward:   linalg.Vector3f32,
	right:     linalg.Vector3f32,
	up:        linalg.Vector3f32,
	tan_half_v: f32,
	tan_half_h: f32,
	near:      f32,
	far:       f32,
}

NEAR :: f32(0.1)
FAR :: f32(1000.0)

from_camera :: proc(camera: rl.Camera3D, aspect: f32) -> Camera_Basis {
	fwd := linalg.normalize(camera.target - camera.position)
	right := linalg.normalize(linalg.cross(fwd, camera.up))
	up := linalg.cross(right, fwd)
	tan_v := linalg.tan(camera.fovy * linalg.RAD_PER_DEG / 2)
	return Camera_Basis{
		position   = camera.position,
		forward    = fwd,
		right      = right,
		up         = up,
		tan_half_v = tan_v,
		tan_half_h = tan_v * aspect,
		near       = NEAR,
		far        = FAR,
	}
}

sphere_visible :: proc(b: Camera_Basis, center: linalg.Vector3f32, radius: f32) -> bool {
	to := center - b.position
	depth := linalg.dot(to, b.forward)
	if depth + radius < b.near || depth - radius > b.far {
		return false
	}
	lateral_x := abs(linalg.dot(to, b.right))
	lateral_y := abs(linalg.dot(to, b.up))
	limit_x := b.tan_half_h * max(depth, 0) + radius
	limit_y := b.tan_half_v * max(depth, 0) + radius
	return lateral_x <= limit_x && lateral_y <= limit_y
}
