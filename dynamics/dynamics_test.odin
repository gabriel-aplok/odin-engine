package dynamics

import "../scene"
import obj "../object"
import "core:testing"

DT :: f32(1.0 / 60.0)

TEST_HITS: [dynamic][2]u64

record_hit :: proc(a, b: u64) {
	append(&TEST_HITS, [2]u64{a, b})
}

make_drop_scene :: proc() -> scene.Scene {
	s := scene.make_scene()
	ground := scene.spawn(&s, "ground")
	ground.transform.position = {0, -0.5, 0}
	ground.collider = obj.Collider{half_extents = {50, 0.5, 50}}
	box := scene.spawn(&s, "box")
	box.transform.position = {0, 5, 0}
	box.collider = obj.Collider{half_extents = {0.5, 0.5, 0.5}}
	box.body = obj.Rigid_Body{kind = .Dynamic, density = 1}
	obj.set_mesh(box, obj.Mesh_Component{color = {255, 0, 0, 255}, size = {1, 1, 1}})
	return s
}

@(test)
test_build_steps_and_syncs :: proc(t: ^testing.T) {
	s := make_drop_scene()
	defer scene.destroy_scene(&s)
	p := build(&s, DEFAULT_GRAVITY)
	defer destroy(&p)
	testing.expect_value(t, len(p.world.bodies), 2)
	box, _ := scene.find_by_id(&s, 2)
	start_y := box.transform.position.y
	contacts := step(&p, &s, DT)
	delete(contacts)
	// old spot stashed before the step ran.
	testing.expect_value(t, box.transform.prev_position.y, start_y)
	testing.expect(t, box.transform.position.y < start_y)
	for _ in 0 ..< 300 {
		contacts := step(&p, &s, DT)
		delete(contacts)
	}
	testing.expect(t, box.transform.position.y > 0.4 && box.transform.position.y < 0.6)
	ground, _ := scene.find_by_id(&s, 1)
	testing.expect_value(t, ground.transform.position.y, f32(-0.5))
}

@(test)
test_dispatch_routes_contacts :: proc(t: ^testing.T) {
	TEST_HITS = make([dynamic][2]u64, context.temp_allocator)
	s := make_drop_scene()
	defer scene.destroy_scene(&s)
	p := build(&s, DEFAULT_GRAVITY)
	defer destroy(&p)
	for _ in 0 ..< 300 {
		dispatch(&p, &s, DT, record_hit)
		if len(TEST_HITS) > 0 {
			break
		}
	}
	testing.expect(t, len(TEST_HITS) > 0)
	hit := TEST_HITS[0]
	testing.expect(
		t,
		(hit[0] == 1 && hit[1] == 2) || (hit[0] == 2 && hit[1] == 1),
	)
}

@(test)
test_same_seed_same_replay :: proc(t: ^testing.T) {
	run_hash :: proc(offset: f32) -> u64 {
		s := scene.make_scene()
		defer scene.destroy_scene(&s)
		ground := scene.spawn(&s, "ground")
		ground.transform.position = {0, -0.5, 0}
		ground.collider = obj.Collider{half_extents = {50, 0.5, 50}}
		for i in 0 ..< 50 {
			b := scene.spawn(&s, "box")
			b.transform.position = {offset + f32(i % 10), 5 + f32(i / 10), 0}
			b.collider = obj.Collider{half_extents = {0.5, 0.5, 0.5}}
			b.body = obj.Rigid_Body{kind = .Dynamic}
		}
		p := build(&s, DEFAULT_GRAVITY)
		defer destroy(&p)
		for _ in 0 ..< 120 {
			contacts := step(&p, &s, DT)
			delete(contacts)
		}
		return hash_scene(&s)
	}
	testing.expect_value(t, run_hash(0), run_hash(0))
	testing.expect(t, run_hash(0) != run_hash(100))
}
