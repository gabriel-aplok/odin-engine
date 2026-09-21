package cull

import rl "vendor:raylib"
import "core:testing"

@(test)
test_basis_culling :: proc(t: ^testing.T) {
	camera := rl.Camera3D{
		position   = {0, 0, 0},
		target     = {0, 0, -1},
		up         = {0, 1, 0},
		fovy       = 60,
		projection = .PERSPECTIVE,
	}
	b := from_camera(camera, 16.0 / 9.0)
	testing.expect(t, sphere_visible(b, {0, 0, -5}, 0.5))
	testing.expect(t, !sphere_visible(b, {50, 0, -5}, 0.5))
	testing.expect(t, !sphere_visible(b, {0, 0, 5}, 0.5))
	testing.expect(t, !sphere_visible(b, {0, 0, -5000}, 0.5))
}
