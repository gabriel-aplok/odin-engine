package physics

import "core:testing"

@(test)
test_sweep_finds_only_overlaps :: proc(t: ^testing.T) {
	bodies := []Body_Input{
		{min = {0, 0, 0}, max = {1, 1, 1}},
		{min = {0.5, 0, 0}, max = {1.5, 1, 1}},
		{min = {5, 5, 5}, max = {6, 6, 6}},
	}
	pairs := sweep_pairs(bodies)
	defer delete(pairs)
	testing.expect_value(t, len(pairs), 1)
	testing.expect_value(t, pairs[0], [2]int{0, 1})
}

@(test)
test_sweep_handles_thousand_bodies :: proc(t: ^testing.T) {
	bodies := make([]Body_Input, 1000, context.temp_allocator)
	for i in 0 ..< 1000 {
		x := f32(i) * 10
		bodies[i] = Body_Input{min = {x, 0, 0}, max = {x + 1, 1, 1}}
	}
	pairs := sweep_pairs(bodies, context.temp_allocator)
	testing.expect_value(t, len(pairs), 0)
}
