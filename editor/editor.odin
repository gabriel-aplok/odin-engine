package editor

import "../scene"
import "core:fmt"
import "core:math"
import "core:strings"
import rl "vendor:raylib"

Editor_Camera :: struct {
	yaw:      f32,
	pitch:    f32,
	distance: f32,
	target:   rl.Vector3,
}

ORBIT_SPEED :: 0.01
ZOOM_SPEED :: 1.0
MIN_DISTANCE :: 2.0
MAX_PITCH :: 1.4

orbit :: proc(c: ^Editor_Camera, dx, dy: f32) {
	c.yaw += dx * ORBIT_SPEED
	c.pitch = clamp(c.pitch + dy * ORBIT_SPEED, -MAX_PITCH, MAX_PITCH)
}

zoom :: proc(c: ^Editor_Camera, delta: f32) {
	c.distance = max(MIN_DISTANCE, c.distance + delta * ZOOM_SPEED)
}

camera_position :: proc(c: Editor_Camera) -> rl.Vector3 {
	cp := math.cos(c.pitch)
	return {
		c.target.x + c.distance * cp * math.cos(c.yaw),
		c.target.y + c.distance * math.sin(c.pitch),
		c.target.z + c.distance * cp * math.sin(c.yaw),
	}
}

inspect_scene :: proc(s: ^scene.Scene, allocator := context.allocator) -> string {
	b := strings.builder_make(allocator)
	for &o in s.objects {
		fmt.sbprintf(&b, "#%d %s active=%v pos=%v\n", o.id, o.name, o.active, o.transform.position)
	}
	return strings.to_string(b)
}
