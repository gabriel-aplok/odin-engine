package audio

SAMPLE_RATE :: 22050

// mono sine frames as f32s. just math, no sound card needed.
sine_frames :: proc(freq_hz, seconds: f32, allocator := context.allocator) -> []f32 {
	count := int(SAMPLE_RATE * seconds)
	frames := make([]f32, count, allocator)
	for i in 0 ..< count {
		phase := 2 * 3.14159265 * freq_hz * f32(i) / f32(SAMPLE_RATE)
		frames[i] = 0.4 * sin_approx(phase)
	}
	return frames
}

sin_approx :: proc(x: f32) -> f32 {
	y := x
	for y > 3.14159265 {
		y -= 2 * 3.14159265
	}
	for y < -3.14159265 {
		y += 2 * 3.14159265
	}
	y2 := y * y
	return y - y2 * y / 6 + y2 * y2 * y / 120
}
