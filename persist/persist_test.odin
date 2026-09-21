package persist

import "../scene"
import "core:os"
import "core:testing"

@(test)
test_save_load_roundtrip :: proc(t: ^testing.T) {
	s := scene.make_scene()
	defer scene.destroy_scene(&s)
	o := scene.spawn(&s, "box")
	o.transform.position = {1, 2, 3}
	path := "test_scene.json"
	defer os.remove(path)
	testing.expect(t, save_scene(&s, path))
	loaded := scene.make_scene()
	defer scene.destroy_scene(&loaded)
	testing.expect(t, load_scene(&loaded, path))
	testing.expect_value(t, len(loaded.objects), 1)
	testing.expect_value(t, loaded.objects[0].name, "box")
	testing.expect(t, loaded.objects[0].transform.position.x == 1)
	testing.expect(t, !load_scene(&loaded, "missing.json"))
}
