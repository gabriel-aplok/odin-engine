package perf

import "core:fmt"
import "core:os"
import "core:strings"

WINDOW_SAMPLES :: 120

Meter :: struct {
	samples:   [WINDOW_SAMPLES]f32,
	head:      int,
	count:     int,
	worst:     f32,
	update_ms: f64,
	draw_ms:   f64,
	rows:      [dynamic]string,
}

make_meter :: proc() -> Meter {
	return Meter{rows = make([dynamic]string)}
}

destroy_meter :: proc(m: ^Meter) {
	for r in m.rows {
		delete(r)
	}
	delete(m.rows)
}

push_frame :: proc(m: ^Meter, dt: f32) {
	m.samples[m.head] = dt
	m.head = (m.head + 1) % WINDOW_SAMPLES
	m.count = min(m.count + 1, WINDOW_SAMPLES)
	if dt > m.worst {
		m.worst = dt
	}
}

avg_fps :: proc(m: ^Meter) -> f32 {
	if m.count == 0 {
		return 0
	}
	sum := f32(0)
	for i in 0 ..< m.count {
		sum += m.samples[i]
	}
	avg := sum / f32(m.count)
	if avg <= 0 {
		return 0
	}
	return 1 / avg
}

reset_worst :: proc(m: ^Meter) {
	m.worst = 0
}

record_row :: proc(m: ^Meter, frame: int) {
	append(&m.rows, fmt.aprintf("%d,%.4f,%.4f,%.4f", frame, 1000 * avg_dt(m), 1000 * m.worst, m.update_ms + m.draw_ms))
}

avg_dt :: proc(m: ^Meter) -> f32 {
	if m.count == 0 {
		return 0
	}
	sum := f32(0)
	for i in 0 ..< m.count {
		sum += m.samples[i]
	}
	return sum / f32(m.count)
}

write_csv :: proc(m: ^Meter, path: string) -> bool {
	b := strings.builder_make()
	defer strings.builder_destroy(&b)
	strings.write_string(&b, "frame,avg_ms,worst_ms,update_draw_ms\n")
	for r in m.rows {
		strings.write_string(&b, r)
		strings.write_byte(&b, '\n')
	}
	return os.write_entire_file(path, transmute([]u8)strings.to_string(b)) == nil
}
