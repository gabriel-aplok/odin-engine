package config

import "core:encoding/json"
import "core:os"

// everything the game used to take from flags or constants lives here.
// flags still win over the file when both are set.
Config :: struct {
	stress_count:   int,
	seed:           u64,
	culling:        bool,
	instancing:     bool,
	width:          i32,
	height:         i32,
	fps:            i32,
	master_gain:    f32,
	music_gain:     f32,
	sfx_gain:       f32,
	frame_budget:   int,
	stream_budget:  int,
}

default_config :: proc() -> Config {
	return Config{
		stress_count = 0,
		seed         = 1234,
		culling      = true,
		instancing   = true,
		width        = 800,
		height       = 450,
		fps          = 60,
		master_gain  = 1,
		music_gain   = 0.8,
		sfx_gain     = 0.9,
		frame_budget = 256 * 1024,
		stream_budget = 64 * 1024 * 1024,
	}
}

load :: proc(path: string) -> (Config, bool) {
	cfg := default_config()
	bytes, err := os.read_entire_file(path, context.allocator)
	if err != nil {
		return cfg, false
	}
	defer delete(bytes)
	if json.unmarshal(bytes, &cfg) != nil {
		return default_config(), false
	}
	return cfg, true
}

save :: proc(cfg: ^Config, path: string) -> bool {
	bytes, err := json.marshal(cfg^)
	if err != nil {
		return false
	}
	defer delete(bytes)
	return os.write_entire_file(path, bytes) == nil
}
