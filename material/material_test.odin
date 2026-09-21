package material

import "../assets"
import "core:testing"
import rl "vendor:raylib"

@(test)
test_load_missing_shader_fails_clean :: proc(t: ^testing.T) {
	s := assets.make_store()
	defer assets.destroy_store(&s)
	m := Material{}
	testing.expect(t, !load_lit_material(&m, &s, "missing.vs", "missing.fs", rl.WHITE))
	testing.expect(t, !m.loaded)
}
