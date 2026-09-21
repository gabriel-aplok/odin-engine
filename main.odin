package main

import "./app"
import "./game"
import "./perf"
import "./persist"
import "./scene"
import "./stress"
import "core:fmt"
import "core:os"
import "core:strconv"

WINDOW_TITLE :: "odin 3d engine"
DEFAULT_SEED :: 1234

_state: game.Game

update :: proc(dt: f32) {
	game.update(&_state, dt)
}

draw :: proc(alpha: f32) {
	game.draw(&_state, alpha)
}

parse_count :: proc(args: []string, flag: string, fallback: int) -> int {
	prefix := fmt.tprintf("--%s=", flag)
	for a in args {
		if len(a) > len(prefix) && a[:len(prefix)] == prefix {
			v, ok := strconv.parse_int(a[len(prefix):])
			if ok {
				return v
			}
		}
	}
	return fallback
}

has_flag :: proc(args: []string, flag: string) -> bool {
	for a in args {
		if a == flag {
			return true
		}
	}
	return false
}

main :: proc() {
	args := os.args
	ref_path := ""
	prefix := "--ref="
	for a in args {
		if len(a) > len(prefix) && a[:len(prefix)] == prefix {
			ref_path = a[len(prefix):]
		}
	}
	stress_count := parse_count(args, "stress", 0)
	seed := u64(parse_count(args, "seed", DEFAULT_SEED))

	if len(ref_path) > 0 {
		count := stress_count if stress_count > 0 else 10000
		s := scene.make_scene()
		defer scene.destroy_scene(&s)
		stress.generate(&s, count, seed)
		if !persist.save_scene(&s, ref_path) {
			fmt.eprintln("failed to write reference scene")
			os.exit(1)
		}
		fmt.printf("wrote %d objects to %s\n", count, ref_path)
		return
	}

	_state = game.make_game(
		stress_count,
		seed,
		!has_flag(args, "--no-cull"),
		!has_flag(args, "--no-instancing"),
	)
	defer game.destroy_game(&_state)
	app.run(
		app.Host_Config {
			title = WINDOW_TITLE,
			width = app.WINDOW_WIDTH,
			height = app.WINDOW_HEIGHT,
			fps = app.TARGET_FPS,
			update = update,
			draw = draw,
		},
	)
	perf.write_csv(&_state.meter, game.PERF_CSV)
}
