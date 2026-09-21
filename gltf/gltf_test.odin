package gltf

import "core:testing"

@(test)
test_inspect_triangle_model :: proc(t: ^testing.T) {
	info, ok := inspect("assets/models/triangle.gltf")
	testing.expect(t, ok)
	testing.expect_value(t, info.mesh_count, 1)
	testing.expect_value(t, info.node_count, 1)
	_, missing := inspect("missing.gltf")
	testing.expect(t, !missing)
}
