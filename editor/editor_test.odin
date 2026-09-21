package editor

import "../scene"
import "core:testing"

@(test)
test_orbit_clamps_pitch :: proc(t: ^testing.T) {
	c := Editor_Camera {
		distance = 5,
	}
	orbit(&c, 0, 100000)
	testing.expect_value(t, c.pitch, MAX_PITCH)
	zoom(&c, -100)
	testing.expect_value(t, c.distance, MIN_DISTANCE)
}

@(test)
test_inspect_lists_objects :: proc(t: ^testing.T) {
	s := scene.make_scene()
	defer scene.destroy_scene(&s)
	_ = scene.spawn(&s, "box")
	text := inspect_scene(&s)
	defer delete(text)
	testing.expect(t, len(text) > 0)
}
