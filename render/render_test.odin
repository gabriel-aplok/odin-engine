package render

import "core:testing"

@(test)
test_raylib_backend_ok_vulkan_explicit :: proc(t: ^testing.T) {
	_, err := make_renderer(.Raylib)
	testing.expect_value(t, err, Renderer_Error.None)
	_, verr := make_renderer(.Vulkan)
	testing.expect_value(t, verr, Renderer_Error.Vulkan_Not_Implemented)
}
