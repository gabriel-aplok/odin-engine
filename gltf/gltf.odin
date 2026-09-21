package gltf

import cg "vendor:cgltf"
import "core:os"

Mesh_Info :: struct {
	mesh_count: int,
	node_count: int,
}

inspect :: proc(path: string) -> (Mesh_Info, bool) {
	data, err := os.read_entire_file(path, context.allocator)
	if err != nil {
		return {}, false
	}
	defer delete(data)

	options := cg.options{}
	cg_data, result := cg.parse(options, raw_data(data), len(data))
	if result != .success {
		return {}, false
	}
	defer cg.free(cg_data)
	info := Mesh_Info{
		mesh_count = len(cg_data.meshes),
		node_count = len(cg_data.nodes),
	}
	return info, true
}
