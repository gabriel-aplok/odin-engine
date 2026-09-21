package audio

import "core:testing"

@(test)
test_sine_frame_count_and_range :: proc(t: ^testing.T) {
	frames := sine_frames(440, 0.1)
	defer delete(frames)
	testing.expect_value(t, len(frames), SAMPLE_RATE / 10)
	testing.expect_value(t, frames[0], f32(0))
	peak := f32(0)
	for f in frames {
		testing.expect(t, f >= -0.5 && f <= 0.5)
		if abs(f) > peak {
			peak = abs(f)
		}
	}
	testing.expect(t, peak > 0.3)
}
