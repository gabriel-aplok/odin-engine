package assets

import "core:os"
import "core:testing"

@(test)
test_load_and_get_file :: proc(t: ^testing.T) {
	path := "test_asset.bin"
	testing.expect(t, os.write_entire_file(path, []u8{1, 2, 3}) == nil)
	defer os.remove(path)
	s := make_store()
	defer destroy_store(&s)
	h, ok := load_file(&s, path, .Bytes)
	testing.expect(t, ok)
	a, found := get(&s, h)
	testing.expect(t, found)
	testing.expect_value(t, len(a.data), 3)
	_, missing := get(&s, INVALID_HANDLE)
	testing.expect(t, !missing)
	_, bad := load_file(&s, "does_not_exist.bin", .Bytes)
	testing.expect(t, !bad)
}
