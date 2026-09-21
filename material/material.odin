package material

import "../assets"
import rl "vendor:raylib"

Material :: struct {
	shader_path: string,
	tint:        rl.Color,
	shader:      rl.Shader,
	loaded:      bool,
}

load_lit_material :: proc(
	m: ^Material,
	store: ^assets.Asset_Store,
	vs_path, fs_path: string,
	tint: rl.Color,
) -> bool {
	vs, ok1 := assets.load_file(store, vs_path, .Shader_Source)
	fs, ok2 := assets.load_file(store, fs_path, .Shader_Source)
	if !ok1 || !ok2 {
		return false
	}
	vas, _ := assets.get(store, vs)
	fas, _ := assets.get(store, fs)
	_ = vas
	_ = fas
	m.shader = rl.LoadShader(cstring(raw_data(vs_path)), cstring(raw_data(fs_path)))
	m.shader_path = vs_path
	m.tint = tint
	m.loaded = true
	return true
}

unload_material :: proc(m: ^Material) {
	if m.loaded {
		rl.UnloadShader(m.shader)
		m.loaded = false
	}
}
