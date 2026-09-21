package dynamics

import "../scene"
import b3 "vendor:box3d"
import "../sim"
import obj "../object"
import "core:math/linalg"

// did it like unity dots: components are just data, this package does the work.
// builds box3d bodies from the components, steps, writes transforms back.
Physics :: struct {
	world: sim.World,
}

Contact_Handler :: proc(a, b: u64)

DEFAULT_GRAVITY :: linalg.Vector3f32{0, -9.81, 0}

build :: proc(s: ^scene.Scene, gravity: linalg.Vector3f32) -> Physics {
	p := Physics{world = sim.make_world(gravity)}
	for &o in s.objects {
		c, ok := o.collider.?
		if !ok {
			continue
		}
		body, has_body := &o.body.?
		kind := obj.Body_Kind.Static
		if has_body {
			kind = body.kind
		}
		register(&p, &o, c, kind)
	}
	return p
}

register :: proc(p: ^Physics, o: ^obj.Game_Object, c: obj.Collider, kind: obj.Body_Kind) {
	body_kind := b3.BodyType.dynamicBody
	#partial switch kind {
	case .Static:
		body_kind = .staticBody
	case .Kinematic:
		body_kind = .kinematicBody
	}
	mesh, has_mesh := o.mesh.?
	shape := obj.Shape_Kind.Box
	if has_mesh {
		shape = mesh.shape
	}
	#partial switch shape {
	case .Sphere:
		radius := c.half_extents.x
		if has_mesh {
			radius = mesh.size.x / 2
		}
		sim.add_ball(&p.world, o.id, o.transform.position, radius, body_kind)
	case .Box, .Gltf:
		sim.add_box(&p.world, o.id, o.transform.position, c.half_extents, body_kind)
	}
}

// one step, then copies positions back to the objects.
// stashes the old spot first so draw can sit between frames.
// gives you the contacts, you delete the array.
step :: proc(p: ^Physics, s: ^scene.Scene, dt: f32) -> [dynamic]sim.Contact {
	for &o in s.objects {
		o.transform.prev_position = o.transform.position
	}
	sim.step(&p.world, dt)
	for body, id in p.world.bodies {
		o, ok := scene.find_by_id(s, id)
		if !ok {
			continue
		}
		o.transform.position = sim.body_position(&p.world, body)
		o.transform.rotation = sim.body_rotation(&p.world, body)
	}
	return sim.drain_contacts(&p.world)
}

dispatch :: proc(p: ^Physics, s: ^scene.Scene, dt: f32, handler: Contact_Handler) {
	contacts := step(p, s, dt)
	defer delete(contacts)
	for c in contacts {
		handler(c.a, c.b)
	}
}

destroy :: proc(p: ^Physics) {
	sim.destroy_world(&p.world)
}

// fnv hash over every object spot. same scene plus same steps
// gives the same number. replays compare against it.
hash_scene :: proc(s: ^scene.Scene) -> u64 {
	h := u64(14695981039346656037)
	mix := proc(h, v: u64) -> u64 {
		return (h ~ v) * 1099511628211
	}
	for &o in s.objects {
		h = mix(h, o.id)
		h = mix(h, u64(transmute(u32)o.transform.position.x))
		h = mix(h, u64(transmute(u32)o.transform.position.y))
		h = mix(h, u64(transmute(u32)o.transform.position.z))
		rot := transmute([4]u32)o.transform.rotation
		h = mix(h, u64(rot[0]))
		h = mix(h, u64(rot[1]))
		h = mix(h, u64(rot[2]))
		h = mix(h, u64(rot[3]))
	}
	return h
}
