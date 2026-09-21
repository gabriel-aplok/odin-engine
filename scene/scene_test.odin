package scene

import "core:testing"

@(test)
test_spawn_find_remove :: proc(t: ^testing.T) {
	s := make_scene()
	defer destroy_scene(&s)

	a := spawn(&s, "box")
	b := spawn(&s, "ball")
	aid := a.id
	bid := b.id
	testing.expect(t, aid != bid)
	testing.expect_value(t, len(s.objects), 2)

	found, ok := find_by_id(&s, aid)
	testing.expect(t, ok)
	testing.expect_value(t, found.name, "box")

	testing.expect(t, remove_by_id(&s, aid))
	testing.expect_value(t, len(s.objects), 1)
	_, ok = find_by_id(&s, aid)
	testing.expect(t, !ok)
	testing.expect(t, !remove_by_id(&s, aid))
}

@(test)
test_active_count :: proc(t: ^testing.T) {
	s := make_scene()
	defer destroy_scene(&s)

	a := spawn(&s, "box")
	_ = spawn(&s, "ball")
	a.active = false
	testing.expect_value(t, active_count(&s), 1)
}
