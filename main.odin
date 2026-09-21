package main

import "./app"
import "./game"
import "./config"
import logger "./log"
import "./scene"
import "./stress"
import "./persist"
import "./perf"
import "core:fmt"
import "core:os"
import "core:strconv"
import "core:strings"

WINDOW_TITLE :: "odin engine"
LOG_PATH :: "engine.log"

_state: game.Game

update :: proc(dt: f32) {
	game.update(&_state, dt)
}

draw :: proc(alpha: f32) {
	game.draw(&_state, alpha)
}

flag_value :: proc(args: []string, flag: string) -> (string, bool) {
	prefix := fmt.tprintf("--%s=", flag)
	for a in args {
		if strings.has_prefix(a, prefix) {
			return a[len(prefix):], true
		}
	}
	return "", false
}

parse_count :: proc(args: []string, flag: string, fallback: int) -> int {
	if v, ok := flag_value(args, flag); ok {
		if n, parsed := strconv.parse_int(v); parsed {
			return n
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

apply_cli :: proc(cfg: ^config.Config, args: []string) {
	cfg.stress_count = parse_count(args, "stress", cfg.stress_count)
	cfg.seed = u64(parse_count(args, "seed", int(cfg.seed)))
	if has_flag(args, "--no-cull") {
		cfg.culling = false
	}
	if has_flag(args, "--no-instancing") {
		cfg.instancing = false
	}
}

main :: proc() {
	logger.init()
	defer logger.shutdown()
	logger.open_log_file(LOG_PATH)
	args := os.args
	cfg := config.default_config()
	if path, ok := flag_value(args, "config"); ok {
		if loaded, found := config.load(path); found {
			cfg = loaded
			logger.info_msg("config", fmt.tprintf("loaded %s", path))
		} else {
			logger.warn_msg("config", fmt.tprintf("missing %s, using defaults", path))
		}
	}
	apply_cli(&cfg, args)

	if ref_path, ok := flag_value(args, "ref"); ok {
		count := cfg.stress_count if cfg.stress_count > 0 else 10000
		s := scene.make_scene()
		defer scene.destroy_scene(&s)
		stress.generate(&s, count, cfg.seed)
		if !persist.save_scene(&s, ref_path) {
			logger.error_msg("ref", fmt.tprintf("failed to write %s", ref_path))
			os.exit(1)
		}
		logger.info_msg("ref", fmt.tprintf("wrote %d objects to %s", count, ref_path))
		fmt.printf("wrote %d objects to %s\n", count, ref_path)
		return
	}

	_state = game.make_game(cfg)
	game.connect_events(&_state)
	defer game.destroy_game(&_state)
	logger.info_msg(
		"game",
		fmt.tprintf("start stress=%d seed=%d", cfg.stress_count, cfg.seed),
	)
	app.run(
		app.Host_Config{
			title = WINDOW_TITLE,
			width = cfg.width,
			height = cfg.height,
			fps = cfg.fps,
			update = update,
			draw = draw,
		},
	)
	perf.write_csv(&_state.meter, game.PERF_CSV)
}
