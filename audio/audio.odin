package audio

Bus :: enum {
	Master,
	Music,
	Sfx,
}

Audio_Bus :: struct {
	gains: [Bus]f32,
}

make_bus :: proc() -> Audio_Bus {
	return Audio_Bus{gains = {.Master = 1, .Music = 0.8, .Sfx = 0.9}}
}

set_gain :: proc(b: ^Audio_Bus, bus: Bus, gain: f32) {
	b.gains[bus] = clamp(gain, 0, 1)
}

mix_gain :: proc(b: ^Audio_Bus, bus: Bus) -> f32 {
	return b.gains[.Master] * b.gains[bus]
}
