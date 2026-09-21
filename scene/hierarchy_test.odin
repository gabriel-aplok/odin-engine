package scene

import "core:testing"

@(test)
test_world_matrix_parent_child :: proc(t: ^testing.T) {
	s := make_scene()
	defer destroy_scene(&s)
	parent := spawn(&s, "parent")
	pid := parent.id
	parent.transform.position = {1, 0, 0}
	child := spawn(&s, "child")
	child.transform.position = {0, 2, 0}
	child.transform.parent = pid
	w, ok := world_matrix(&s, child.id)
	testing.expect(t, ok)
	testing.expect(t, abs(w[3][0] - 1) < 0.001 && abs(w[3][1] - 2) < 0.001)
}
