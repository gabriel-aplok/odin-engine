package app

import rl "vendor:raylib"

WINDOW_WIDTH :: 800
WINDOW_HEIGHT :: 450
TARGET_FPS :: 60
FIXED_DT :: f32(1.0 / 60.0)
MAX_FIXED_STEPS :: 5

Frame_Callback :: proc(dt: f32)
Draw_Callback :: proc(alpha: f32)

Frame_Stats :: struct {
	fps:        i32,
	frame_dt:   f32,
	steps:      int,
	accumulator: f32,
}

Host_Config :: struct {
	title:  string,
	width:  i32,
	height: i32,
	fps:    i32,
	update: Frame_Callback,
	draw:   Draw_Callback,
	stats:  ^Frame_Stats,
}

step_accumulator :: proc(acc: f32, frame_dt: f32) -> (steps: int, remainder: f32) {
	a := acc + frame_dt
	n := int(a / FIXED_DT)
	if n > MAX_FIXED_STEPS {
		n = MAX_FIXED_STEPS
	}
	return n, a - f32(n) * FIXED_DT
}

run :: proc(config: Host_Config) {
	rl.InitWindow(config.width, config.height, cstring(raw_data(config.title)))
	defer rl.CloseWindow()
	rl.SetTargetFPS(config.fps)

	acc := f32(0)
	for !rl.WindowShouldClose() {
		frame_dt := rl.GetFrameTime()
		steps, rest := step_accumulator(acc, frame_dt)
		acc = rest
		for _ in 0 ..< steps {
			if config.update != nil {
				config.update(FIXED_DT)
			}
		}
		alpha := acc / FIXED_DT
		rl.BeginDrawing()
		if config.draw != nil {
			config.draw(alpha)
		}
		rl.EndDrawing()
		if config.stats != nil {
			config.stats^ = Frame_Stats{
				fps      = rl.GetFPS(),
				frame_dt = frame_dt,
				steps    = steps,
			}
		}
	}
}
