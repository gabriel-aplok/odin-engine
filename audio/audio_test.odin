package audio

import "core:testing"

@(test)
test_mix_gain_multiplies_master :: proc(t: ^testing.T) {
	b := make_bus()
	set_gain(&b, .Master, 0.5)
	set_gain(&b, .Sfx, 1.0)
	testing.expect_value(t, mix_gain(&b, .Sfx), f32(0.5))
	set_gain(&b, .Sfx, 2.0)
	testing.expect_value(t, b.gains[.Sfx], f32(1.0))
}
