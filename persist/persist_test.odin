package persist

import "../scene"
import obj "../object"
import "core:os"
import "core:testing"

@(test)
test_save_load_roundtrip :: proc(t: ^testing.T) {
	s := scene.make_scene()
	defer scene.destroy_scene(&s)
	o := scene.spawn(&s, "box")
	o.transform.position = {1, 2, 3}
	o.transform.scale = {2, 2, 2}
	obj.set_mesh(o, obj.Mesh_Component{color = {9, 9, 9, 255}, size = {1, 2, 3}})
	o.body = obj.Rigid_Body{kind = .Dynamic, density = 2, friction = 0.5}
	o.collider = obj.Collider{half_extents = {0.5, 1, 1.5}}
	path := "test_scene.json"
	defer os.remove(path)
	testing.expect(t, save_scene(&s, path))
	loaded := scene.make_scene()
	defer scene.destroy_scene(&loaded)
	testing.expect(t, load_scene(&loaded, path))
	testing.expect_value(t, len(loaded.objects), 1)
	back := loaded.objects[0]
	testing.expect_value(t, back.name, "box")
	testing.expect(t, back.transform.position == [3]f32{1, 2, 3})
	testing.expect(t, back.transform.scale == [3]f32{2, 2, 2})
	m, _ := back.mesh.?
	testing.expect(t, m.size == [3]f32{1, 2, 3})
	testing.expect_value(t, m.color.g, u8(9))
	b, has_body := back.body.?
	testing.expect(t, has_body)
	testing.expect_value(t, b.kind, obj.Body_Kind.Dynamic)
	testing.expect_value(t, b.density, f32(2))
	_, has_collider := back.collider.?
	testing.expect(t, has_collider)
	testing.expect(t, !load_scene(&loaded, "missing.json"))
}

@(test)
test_unknown_component_fails_loud :: proc(t: ^testing.T) {
	path := "test_unknown.json"
	defer os.remove(path)
	fake := `{"version": 2, "objects": [{"name": "box", "active": true, "components": [{"type": "nope", "data": "{}"}]}]}`
	testing.expect(t, os.write_entire_file(path, fake) == nil)
	loaded := scene.make_scene()
	defer scene.destroy_scene(&loaded)
	testing.expect(t, !load_scene(&loaded, path))
}
