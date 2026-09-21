package ui

import rl "vendor:raylib"
import "core:fmt"

TITLE_Y :: 150
BODY_Y :: 220
PROMPT_Y :: 260
TITLE_SIZE :: 40
BODY_SIZE :: 20

stats_text :: proc(
	fps, worst_ms, update_ms, draw_ms: f64,
	shown, total, calls, culled: int,
	allocator := context.allocator,
) -> string {
	return fmt.aprintf(
		"fps %.0f worst %.1fms upd %.2fms draw %.2fms shown %d/%d calls %d culled %d",
		fps,
		worst_ms,
		update_ms,
		draw_ms,
		shown,
		total,
		calls,
		culled,
		allocator = allocator,
	)
}

title_screen :: proc(title: string, lines: []string) {
	rl.DrawText(fmt.ctprintf("%s", title), 300, TITLE_Y, TITLE_SIZE, rl.DARKGRAY)
	y := i32(BODY_Y)
	for line in lines {
		rl.DrawText(fmt.ctprintf("%s", line), 220, y, BODY_SIZE, rl.GRAY)
		y += 40
	}
}

pause_overlay :: proc(hint: string) {
	rl.DrawText(fmt.ctprintf("PAUSED - %s", hint), 250, 200, BODY_SIZE, rl.MAROON)
}
