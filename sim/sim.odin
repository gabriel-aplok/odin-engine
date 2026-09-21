package sim

import "core:math/linalg"
import b3 "vendor:box3d"

SUB_STEPS :: 4

World :: struct {
	id:     b3.WorldId,
	bodies: map[b3.BodyId]u64,
}

Contact :: struct {
	a: u64,
	b: u64,
}

make_world :: proc(gravity: linalg.Vector3f32) -> World {
	def := b3.DefaultWorldDef()
	def.gravity = gravity
	return World{id = b3.CreateWorld(def), bodies = make(map[b3.BodyId]u64)}
}

destroy_world :: proc(w: ^World) {
	b3.DestroyWorld(w.id)
	delete(w.bodies)
}

// makes a box body tied to a game object id.
add_box :: proc(
	w: ^World,
	object_id: u64,
	position: linalg.Vector3f32,
	half_extents: linalg.Vector3f32,
	kind: b3.BodyType = .dynamicBody,
) -> b3.BodyId {
	body_def := b3.DefaultBodyDef()
	body_def.type = kind
	body_def.position = position
	body_def.rotation = 1
	body := b3.CreateBody(w.id, body_def)

	shape_def := b3.DefaultShapeDef()
	shape_def.density = 1
	shape_def.enableContactEvents = true
	hull := b3.MakeBoxHull(half_extents.x, half_extents.y, half_extents.z)
	_ = b3.CreateHullShape(body, shape_def, &hull.base)

	w.bodies[body] = object_id
	return body
}

add_ball :: proc(
	w: ^World,
	object_id: u64,
	position: linalg.Vector3f32,
	radius: f32,
	kind: b3.BodyType = .dynamicBody,
) -> b3.BodyId {
	body_def := b3.DefaultBodyDef()
	body_def.type = kind
	body_def.position = position
	body_def.rotation = 1
	body := b3.CreateBody(w.id, body_def)

	shape_def := b3.DefaultShapeDef()
	shape_def.density = 1
	shape_def.enableContactEvents = true
	sphere := b3.Sphere {
		center = {0, 0, 0},
		radius = radius,
	}
	_ = b3.CreateSphereShape(body, shape_def, &sphere)

	w.bodies[body] = object_id
	return body
}

remove_body :: proc(w: ^World, body: b3.BodyId) {
	b3.DestroyBody(body)
	delete_key(&w.bodies, body)
}

step :: proc(w: ^World, dt: f32) {
	b3.World_Step(w.id, dt, SUB_STEPS)
}

body_position :: proc(w: ^World, body: b3.BodyId) -> linalg.Vector3f32 {
	return b3.Body_GetPosition(body)
}

body_rotation :: proc(w: ^World, body: b3.BodyId) -> linalg.Quaternionf32 {
	return linalg.Quaternionf32(b3.Body_GetRotation(body))
}

object_id :: proc(w: ^World, body: b3.BodyId) -> (u64, bool) {
	id, ok := w.bodies[body]
	return id, ok
}

// grabs begin-touch pairs as game object ids. call it once per step.
drain_contacts :: proc(w: ^World, allocator := context.allocator) -> [dynamic]Contact {
	out := make([dynamic]Contact, allocator)
	events := b3.World_GetContactEvents(w.id)
	for e in events.beginEvents[:events.beginCount] {
		a_body := b3.Shape_GetBody(e.shapeIdA)
		b_body := b3.Shape_GetBody(e.shapeIdB)
		a_id, a_ok := w.bodies[a_body]
		b_id, b_ok := w.bodies[b_body]
		if a_ok && b_ok {
			append(&out, Contact{a = a_id, b = b_id})
		}
	}
	return out
}
