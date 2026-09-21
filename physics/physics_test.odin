package physics

import "core:testing"

@(test)
test_integrate_moves_body :: proc(t: ^testing.T) {
	p := [3]f32{0, 0, 0}
	v := [3]f32{1, 0, 0}
	integrate(&p, &v, {0, 0, 0}, 1.0)
	testing.expect(t, abs(p.x - 1) < 0.001)
}

@(test)
test_aabb_overlap_and_resolve :: proc(t: ^testing.T) {
	a := AABB {
		center       = {0, 0, 0},
		half_extents = {1, 1, 1},
	}
	b := AABB {
		center       = {1.5, 0, 0},
		half_extents = {1, 1, 1},
	}
	testing.expect(t, overlaps(a, b))
	c := AABB {
		center       = {5, 0, 0},
		half_extents = {1, 1, 1},
	}
	testing.expect(t, !overlaps(a, c))
	m := AABB {
		center       = {1.2, 0, 0},
		half_extents = {0.5, 0.5, 0.5},
	}
	v := [3]f32{1, 0, 0}
	resolve_axis(&m, &v, a)
	testing.expect(t, !overlaps(m, a))
	testing.expect_value(t, v.x, f32(0))
}
