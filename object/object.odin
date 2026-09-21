package object

import "core:math/linalg"
import rl "vendor:raylib"

// entity is the dots word for game object. same thing, pick the one you like.
Entity :: Game_Object

Transform :: struct {
	position:      linalg.Vector3f32,
	prev_position: linalg.Vector3f32,
	rotation:      linalg.Quaternionf32,
	scale:         linalg.Vector3f32,
	parent:        Maybe(u64),
}

Shape_Kind :: enum {
	Box,
	Sphere,
	Gltf,
}

Mesh_Component :: struct {
	color: rl.Color,
	size:  linalg.Vector3f32,
	shape: Shape_Kind,
}

Body_Kind :: enum {
	Dynamic,
	Static,
	Kinematic,
}

Rigid_Body :: struct {
	velocity:       linalg.Vector3f32,
	mass:           f32,
	kind:           Body_Kind,
	gravity_scale:  f32,
	density:        f32,
	friction:       f32,
	restitution:    f32,
}

Collider :: struct {
	half_extents: linalg.Vector3f32,
}

Game_Object :: struct {
	id:        u64,
	name:      string,
	active:    bool,
	transform: Transform,
	mesh:      Maybe(Mesh_Component),
	body:      Maybe(Rigid_Body),
	collider:  Maybe(Collider),
}

make_object :: proc(id: u64, name: string) -> Game_Object {
	return Game_Object {
		id = id,
		name = name,
		active = true,
		transform = Transform {
			position = {0, 0, 0},
			prev_position = {0, 0, 0},
			rotation = linalg.QUATERNIONF32_IDENTITY,
			scale = {1, 1, 1},
		},
	}
}

set_mesh :: proc(obj: ^Game_Object, mesh: Mesh_Component) {
	obj.mesh = mesh
}

local_matrix :: proc(t: Transform) -> linalg.Matrix4f32 {
	rot := linalg.matrix4_from_quaternion_f32(t.rotation)
	s := linalg.matrix4_scale_f32(t.scale)
	tr := linalg.matrix4_translate_f32(t.position)
	return tr * rot * s
}

// render spot between the last two physics spots. alpha 0 is old, 1 is new.
interp_position :: proc(t: Transform, alpha: f32) -> linalg.Vector3f32 {
	return t.prev_position + (t.position - t.prev_position) * alpha
}
