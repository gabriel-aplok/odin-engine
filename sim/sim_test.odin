package sim

import "core:testing"

DT :: f32(1.0 / 60.0)

@(test)
test_dynamic_box_falls :: proc(t: ^testing.T) {
	w := make_world({0, -9.81, 0})
	defer destroy_world(&w)
	body := add_box(&w, 1, {0, 5, 0}, {0.5, 0.5, 0.5})
	for _ in 0 ..< 60 {
		step(&w, DT)
	}
	testing.expect(t, body_position(&w, body).y < 5)
}

@(test)
test_box_lands_on_static_ground :: proc(t: ^testing.T) {
	w := make_world({0, -9.81, 0})
	defer destroy_world(&w)
	_ = add_box(&w, 1, {0, -0.5, 0}, {50, 0.5, 50}, .staticBody)
	body := add_box(&w, 2, {0, 5, 0}, {0.5, 0.5, 0.5})
	for _ in 0 ..< 300 {
		step(&w, DT)
	}
	y := body_position(&w, body).y
	testing.expect(t, y > 0.4 && y < 0.6)
}

@(test)
test_contact_event_maps_to_object_ids :: proc(t: ^testing.T) {
	w := make_world({0, -9.81, 0})
	defer destroy_world(&w)
	_ = add_box(&w, 10, {0, -0.5, 0}, {50, 0.5, 50}, .staticBody)
	_ = add_box(&w, 20, {0, 2, 0}, {0.5, 0.5, 0.5})
	found := false
	for _ in 0 ..< 300 {
		step(&w, DT)
		contacts := drain_contacts(&w, context.temp_allocator)
		for c in contacts {
			if (c.a == 10 && c.b == 20) || (c.a == 20 && c.b == 10) {
				found = true
			}
		}
		if found {
			break
		}
	}
	testing.expect(t, found)
}

@(test)
test_remove_body_drops_mapping :: proc(t: ^testing.T) {
	w := make_world({0, -9.81, 0})
	defer destroy_world(&w)
	body := add_box(&w, 7, {0, 5, 0}, {0.5, 0.5, 0.5})
	_, ok := object_id(&w, body)
	testing.expect(t, ok)
	remove_body(&w, body)
	_, ok = object_id(&w, body)
	testing.expect(t, !ok)
}
