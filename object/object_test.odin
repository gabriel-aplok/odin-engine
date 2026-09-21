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
test_damage_deactivates_at_zero :: proc(t: ^testing.T) {
	o := make_object(1, "box")
	set_health(&o, Health_Component{current = 10, max = 10})
	damage(&o, 4)
	h, _ := o.health.?
	testing.expect_value(t, h.current, i32(6))
	testing.expect_value(t, o.active, true)
	damage(&o, 6)
	h, _ = o.health.?
	testing.expect_value(t, h.current, i32(0))
	testing.expect_value(t, o.active, false)
}

@(test)
test_damage_without_health_is_noop :: proc(t: ^testing.T) {
	o := make_object(1, "box")
	damage(&o, 10)
	testing.expect_value(t, o.active, true)
}
