package render

Backend :: enum {
	Raylib,
	Vulkan,
}

Renderer_Error :: enum {
	None,
	Vulkan_Not_Implemented,
}

Renderer :: struct {
	backend: Backend,
}

make_renderer :: proc(backend: Backend) -> (Renderer, Renderer_Error) {
	if backend == .Vulkan {
		return Renderer{backend = backend}, .Vulkan_Not_Implemented
	}
	return Renderer{backend = backend}, .None
}
