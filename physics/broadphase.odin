package physics

import "core:math/linalg"

Body_Input :: struct {
	min: linalg.Vector3f32,
	max: linalg.Vector3f32,
}

// Sweep and prune on X axis. Returns index pairs whose AABBs overlap.
sweep_pairs :: proc(bodies: []Body_Input, allocator := context.allocator) -> [][2]int {
	order := make([]int, len(bodies), allocator)
	defer delete(order, allocator)
	for i in 0 ..< len(bodies) {
		order[i] = i
	}
	// Insertion sort by min.x. Bodies stay near their previous order
	// frame to frame, so this is near linear in practice.
	for i in 1 ..< len(order) {
		j := i
		for j > 0 && bodies[order[j]].min.x < bodies[order[j - 1]].min.x {
			order[j], order[j - 1] = order[j - 1], order[j]
			j -= 1
		}
	}

	pairs := make([dynamic][2]int, allocator)
	active := make([dynamic]int, allocator)
	defer delete(active)
	for idx in order {
		b := bodies[idx]
		j := 0
		for j < len(active) {
			if bodies[active[j]].max.x < b.min.x {
				ordered_remove(&active, j)
			} else {
				j += 1
			}
		}
		for other in active {
			o := bodies[other]
			if b.min.y <= o.max.y && o.min.y <= b.max.y &&
			   b.min.z <= o.max.z && o.min.z <= b.max.z {
				append(&pairs, [2]int{other, idx})
			}
		}
		append(&active, idx)
	}
	return pairs[:]
}
