package render

import obj "../object"
import rl "vendor:raylib"

Batch_Key :: struct {
	color: rl.Color,
	size:  [3]f32,
}

collect_boxes :: proc(
	objects: []^obj.Game_Object,
	allocator := context.allocator,
) -> map[Batch_Key][dynamic]rl.Matrix {
	batches := make(map[Batch_Key][dynamic]rl.Matrix, allocator)
	for o in objects {
		if !o.active {
			continue
		}
		m, ok := o.mesh.?
		if !ok || m.shape != .Box {
			continue
		}
		key := Batch_Key {
			color = m.color,
			size  = m.size,
		}
		list, found := batches[key]
		if !found {
			list = make([dynamic]rl.Matrix, allocator)
		}
		// full local transform. linalg memory matches raylib memory
		// so the transmute is fine.
		append(&list, transmute(rl.Matrix)obj.local_matrix(o.transform))
		batches[key] = list
	}
	return batches
}

destroy_batches :: proc(batches: ^map[Batch_Key][dynamic]rl.Matrix) {
	for _, list in batches {
		delete(list)
	}
	delete(batches^)
}
