package perf

import "core:time"

// zone timing. wrap a system, see what it costs.
// usage: tick := zone_begin() ... zone_end(&m, "sim", tick)
Zone :: struct {
	total_ms: f64,
	calls:    int,
}

zone_begin :: proc() -> time.Tick {
	return time.tick_now()
}

zone_end :: proc(m: ^Meter, name: string, tick: time.Tick) {
	z, ok := m.zones[name]
	if !ok {
		z = Zone{}
	}
	z.total_ms += time.duration_milliseconds(time.tick_since(tick))
	z.calls += 1
	m.zones[name] = z
}

zone_avg :: proc(m: ^Meter, name: string) -> f64 {
	z, ok := m.zones[name]
	if !ok || z.calls == 0 {
		return 0
	}
	return z.total_ms / f64(z.calls)
}

zone_reset :: proc(m: ^Meter) {
	for name in m.zones {
		m.zones[name] = Zone{}
	}
}

// priciest zone name this frame window. empty when nothing ran.
priciest_zone :: proc(m: ^Meter, allocator := context.allocator) -> string {
	best := ""
	best_ms := 0.0
	for name, z in m.zones {
		if z.total_ms > best_ms {
			best_ms = z.total_ms
			best = name
		}
	}
	if best == "" {
		return ""
	}
	out := make([]u8, len(best), allocator)
	copy(out, transmute([]u8)best)
	return transmute(string)out
}
