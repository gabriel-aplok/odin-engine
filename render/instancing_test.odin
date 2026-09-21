package render

import obj "../object"
import "../scene"
import "../stress"
import "core:testing"

@(test)
test_collect_boxes_groups_and_skips :: proc(t: ^testing.T) {
	s := scene.make_scene()
	defer scene.destroy_scene(&s)
	stress.generate(&s, 90, 1)
	ptrs := make([dynamic]^obj.Game_Object, context.temp_allocator)
	for &o in s.objects {
		append(&ptrs, &o)
	}
	batches := collect_boxes(ptrs[:], 1.0)
	defer destroy_batches(&batches)
	total := 0
	for _, list in batches {
		total += len(list)
	}
	// only the 30 boxes end up in batches, spheres and gltf sit this one out.
	testing.expect_value(t, total, 30)
	testing.expect(t, len(batches) > 0)
}

@(test)
test_collect_boxes_respects_visible_subset :: proc(t: ^testing.T) {
	s := scene.make_scene()
	defer scene.destroy_scene(&s)
	stress.generate(&s, 90, 1)
	// fake culling: just hand over the first 10 objects.
	ptrs := make([dynamic]^obj.Game_Object, context.temp_allocator)
	for &o, i in s.objects {
		if i >= 10 {
			break
		}
		append(&ptrs, &o)
	}
	batches := collect_boxes(ptrs[:], 1.0)
	defer destroy_batches(&batches)
	total := 0
	for _, list in batches {
		total += len(list)
	}
	// first 10 objects cycle box/sphere/gltf, so 4 boxes.
	testing.expect_value(t, total, 4)
}

@(test)
test_instance_matrix_carries_position :: proc(t: ^testing.T) {
	s := scene.make_scene()
	defer scene.destroy_scene(&s)
	stress.generate(&s, 3, 1)
	ptrs := make([dynamic]^obj.Game_Object, context.temp_allocator)
	box_pos := [3]f32{}
	box_size := [3]f32{}
	for &o in s.objects {
		append(&ptrs, &o)
		if m, ok := o.mesh.?; ok && m.shape == .Box {
			box_pos = o.transform.position
			box_size = m.size
		}
	}
	batches := collect_boxes(ptrs[:], 1.0)
	defer destroy_batches(&batches)
	matched := false
	for key, list in batches {
		if key.size != box_size {
			continue
		}
		for mat in list {
			if mat[3].xyz == box_pos && mat[3].w == 1 {
				matched = true
			}
		}
	}
	testing.expect(t, matched)
}
