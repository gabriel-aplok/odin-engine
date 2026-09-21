package stress

import "../scene"
import "core:testing"

@(test)
test_generate_count_and_mixed_kinds :: proc(t: ^testing.T) {
	s := scene.make_scene()
	defer scene.destroy_scene(&s)
	generate(&s, 90, 42)
	testing.expect_value(t, len(s.objects), 90)
	boxes, spheres, gltfs := 0, 0, 0
	for &o in s.objects {
		m, ok := o.mesh.?
		testing.expect(t, ok)
		#partial switch m.shape {
		case .Box:
			boxes += 1
		case .Sphere:
			spheres += 1
		case .Gltf:
			gltfs += 1
		}
	}
	testing.expect_value(t, boxes, 30)
	testing.expect_value(t, spheres, 30)
	testing.expect_value(t, gltfs, 30)
}

@(test)
test_generate_is_deterministic :: proc(t: ^testing.T) {
	a := scene.make_scene()
	defer scene.destroy_scene(&a)
	b := scene.make_scene()
	defer scene.destroy_scene(&b)
	generate(&a, 10, 7)
	generate(&b, 10, 7)
	testing.expect(t, a.objects[0].transform.position == b.objects[0].transform.position)
}
