package object

import "core:testing"

@(test)
test_make_object_defaults :: proc(t: ^testing.T) {
	o := make_object(1, "box")
	testing.expect_value(t, o.id, u64(1))
	testing.expect_value(t, o.active, true)
	testing.expect_value(t, o.transform.scale.x, f32(1))
	_, has_mesh := o.mesh.?
	testing.expect(t, !has_mesh)
}

@(test)
test_set_mesh :: proc(t: ^testing.T) {
	o := make_object(1, "box")
	set_mesh(&o, Mesh_Component{color = {255, 0, 0, 255}, size = {1, 2, 3}})
	m, ok := o.mesh.?
	testing.expect(t, ok)
	testing.expect(t, m.size == [3]f32{1, 2, 3})
	testing.expect_value(t, m.shape, Shape_Kind.Box)
}

@(test)
test_interp_position :: proc(t: ^testing.T) {
	o := make_object(1, "box")
	o.transform.prev_position = {0, 0, 0}
	o.transform.position = {10, 0, 0}
	mid := interp_position(o.transform, 0.5)
	testing.expect(t, mid == [3]f32{5, 0, 0})
	testing.expect(t, interp_position(o.transform, 0) == [3]f32{0, 0, 0})
	testing.expect(t, interp_position(o.transform, 1) == [3]f32{10, 0, 0})
}
