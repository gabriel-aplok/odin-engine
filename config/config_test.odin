package config

import "core:os"
import "core:testing"

@(test)
test_roundtrip_and_defaults :: proc(t: ^testing.T) {
	path := "test_config.json"
	defer os.remove(path)
	cfg := default_config()
	cfg.stress_count = 500
	cfg.seed = 99
	testing.expect(t, save(&cfg, path))
	back, ok := load(path)
	testing.expect(t, ok)
	testing.expect_value(t, back.stress_count, 500)
	testing.expect_value(t, back.seed, u64(99))
	testing.expect_value(t, back.width, cfg.width)
}

@(test)
test_missing_or_broken_falls_back :: proc(t: ^testing.T) {
	cfg, ok := load("missing_config.json")
	testing.expect(t, !ok)
	testing.expect_value(t, cfg.fps, 60)
	path := "test_broken.json"
	defer os.remove(path)
	testing.expect(t, os.write_entire_file(path, "{nope") == nil)
	_, ok = load(path)
	testing.expect(t, !ok)
}
