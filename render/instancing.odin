package render

import rl "vendor:raylib"
import obj "../object"

Batch_Key :: struct {
	color: rl.Color,
	size:  [3]f32,
}

collect_boxes :: proc(objects: []^obj.Game_Object, allocator := context.allocator) -> map[Batch_Key][dynamic]rl.Matrix {
	batches := make(map[Batch_Key][dynamic]rl.Matrix, allocator)
	for o in objects {
		if !o.active {
			continue
		}
		m, ok := o.mesh.?
		if !ok || m.shape != .Box {
			continue
		}
		key := Batch_Key{color = m.color, size = m.size}
		list, found := batches[key]
		if !found {
			list = make([dynamic]rl.Matrix, allocator)
		}
		p := o.transform.position
		append(
			&list,
			rl.Matrix{
				m.size.x, 0, 0, 0,
				0, m.size.y, 0, 0,
				0, 0, m.size.z, 0,
				p.x, p.y, p.z, 1,
			},
		)
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
