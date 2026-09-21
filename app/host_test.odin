package app

import "core:testing"

@(test)
test_step_accumulator_basic :: proc(t: ^testing.T) {
	steps, rest := step_accumulator(0, FIXED_DT)
	testing.expect_value(t, steps, 1)
	testing.expect(t, rest < 0.0001)
}

@(test)
test_step_accumulator_carries_remainder :: proc(t: ^testing.T) {
	steps, rest := step_accumulator(0, FIXED_DT * 2.5)
	testing.expect_value(t, steps, 2)
	testing.expect(t, rest > FIXED_DT * 0.4 && rest < FIXED_DT * 0.6)
}

@(test)
test_step_accumulator_clamps_spiral :: proc(t: ^testing.T) {
	steps, _ := step_accumulator(0, FIXED_DT * 100)
	testing.expect_value(t, steps, MAX_FIXED_STEPS)
}
