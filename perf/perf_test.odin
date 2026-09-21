package perf

import "core:os"
import "core:testing"

@(test)
test_avg_fps_and_worst :: proc(t: ^testing.T) {
	m := make_meter()
	defer destroy_meter(&m)
	push_frame(&m, 1.0 / 60)
	push_frame(&m, 1.0 / 60)
	testing.expect(t, avg_fps(&m) > 59 && avg_fps(&m) < 61)
	push_frame(&m, 0.1)
	testing.expect(t, m.worst == f32(0.1))
	reset_worst(&m)
	testing.expect_value(t, m.worst, f32(0))
}

@(test)
test_csv_roundtrip :: proc(t: ^testing.T) {
	m := make_meter()
	defer destroy_meter(&m)
	push_frame(&m, 1.0 / 60)
	record_row(&m, 0)
	path := "test_perf.csv"
	defer os.remove(path)
	testing.expect(t, write_csv(&m, path))
	data, err := os.read_entire_file(path, context.allocator)
	defer delete(data)
	testing.expect(t, err == nil)
	testing.expect(t, len(data) > 0)
}
