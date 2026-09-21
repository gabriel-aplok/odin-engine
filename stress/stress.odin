package stress

import "../scene"
import obj "../object"

AREA_HALF :: f32(50)
MIN_SIZE :: f32(0.3)
MAX_SIZE :: f32(2.0)

PALETTE := [4][4]u8{{38, 84, 124, 255}, {199, 125, 45, 255}, {110, 166, 130, 255}, {180, 70, 70, 255}}

// Seeded xorshift64 star. Deterministic across runs and platforms.
next_unit :: proc(state: ^u64) -> f32 {
	state^ = state^ ~ (state^ >> 12)
	state^ = state^ ~ (state^ << 25)
	state^ = state^ ~ (state^ >> 27)
	return f32((state^ * 0x2545F4914F6CDD1D >> 32) & 0xFFFFFF) / f32(0x1000000)
}

generate :: proc(s: ^scene.Scene, count: int, seed: u64) {
	state := seed | 1
	for i in 0 ..< count {
		o := scene.spawn(s, "prop")
		kind := obj.Shape_Kind(i % 3)
		size := MIN_SIZE + next_unit(&state) * (MAX_SIZE - MIN_SIZE)
		o.transform.position = {
			(next_unit(&state) * 2 - 1) * AREA_HALF,
			next_unit(&state) * 10,
			(next_unit(&state) * 2 - 1) * AREA_HALF,
		}
		c := PALETTE[i % len(PALETTE)]
		obj.set_mesh(
			o,
			obj.Mesh_Component{
				color = {c[0], c[1], c[2], c[3]},
				size = {size, size, size},
				shape = kind,
			},
		)
		o.body = obj.Rigid_Body{velocity = {0, 0, 0}, mass = 1}
		o.collider = obj.Collider{half_extents = {size / 2, size / 2, size / 2}}
	}
}
