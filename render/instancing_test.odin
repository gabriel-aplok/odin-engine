package render

import "../scene"
import "../stress"
import obj "../object"
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
	batches := collect_boxes(ptrs[:])
	defer destroy_batches(&batches)
	total := 0
	for _, list in batches {
		total += len(list)
	}
	// Only the 30 boxes land in batches, spheres and glTF are skipped.
	testing.expect_value(t, total, 30)
	testing.expect(t, len(batches) > 0)
}

@(test)
test_collect_boxes_respects_visible_subset :: proc(t: ^testing.T) {
	s := scene.make_scene()
	defer scene.destroy_scene(&s)
	stress.generate(&s, 90, 1)
	// Simulate culling: pass only the first 10 objects.
	ptrs := make([dynamic]^obj.Game_Object, context.temp_allocator)
	for &o, i in s.objects {
		if i >= 10 {
			break
		}
		append(&ptrs, &o)
	}
	batches := collect_boxes(ptrs[:])
	defer destroy_batches(&batches)
	total := 0
	for _, list in batches {
		total += len(list)
	}
	// First 10 objects hold kinds 0,1,2 repeating, so 4 boxes.
	testing.expect_value(t, total, 4)
}
