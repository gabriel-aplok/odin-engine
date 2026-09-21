package perf

import "core:testing"

@(test)
test_zones_accumulate_and_reset :: proc(t: ^testing.T) {
	m := make_meter()
	defer destroy_meter(&m)
	tick := zone_begin()
	zone_end(&m, "sim", tick)
	zone_end(&m, "sim", tick)
	testing.expect(t, zone_avg(&m, "sim") >= 0)
	testing.expect_value(t, zone_avg(&m, "nope"), f64(0))
	top := priciest_zone(&m, context.temp_allocator)
	testing.expect_value(t, top, "sim")
	zone_reset(&m)
	testing.expect_value(t, priciest_zone(&m, context.temp_allocator), "")
}
