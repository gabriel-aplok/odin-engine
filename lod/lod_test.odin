package lod

import "core:testing"

@(test)
test_select_levels :: proc(t: ^testing.T) {
	testing.expect_value(t, select(10), Level.Full)
	testing.expect_value(t, select(FAR_DIST - 1), Level.Full)
	testing.expect_value(t, select(FAR_DIST), Level.Reduced)
	testing.expect_value(t, select(500), Level.Reduced)
}
