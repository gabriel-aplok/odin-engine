package scene

import obj "../object"
import "core:math/linalg"
import "core:strings"

MAX_OBJECTS :: 1024

Scene :: struct {
	objects: [dynamic]obj.Game_Object,
	next_id: u64,
}

make_scene :: proc(allocator := context.allocator) -> Scene {
	return Scene{objects = make([dynamic]obj.Game_Object, allocator), next_id = 1}
}

destroy_scene :: proc(s: ^Scene) {
	for &o in s.objects {
		delete(o.name)
	}
	delete(s.objects)
	s.objects = nil
	s.next_id = 1
}

spawn :: proc(s: ^Scene, name: string) -> ^obj.Game_Object {
	append(&s.objects, obj.make_object(s.next_id, strings.clone(name)))
	s.next_id += 1
	return &s.objects[len(s.objects) - 1]
}

find_by_id :: proc(s: ^Scene, id: u64) -> (^obj.Game_Object, bool) {
	for &o in s.objects {
		if o.id == id {
			return &o, true
		}
	}
	return nil, false
}

remove_by_id :: proc(s: ^Scene, id: u64) -> bool {
	for o, i in s.objects {
		if o.id == id {
			delete(o.name)
			ordered_remove(&s.objects, i)
			return true
		}
	}
	return false
}

active_count :: proc(s: ^Scene) -> int {
	count := 0
	for &o in s.objects {
		if o.active {
			count += 1
		}
	}
	return count
}

world_matrix :: proc(s: ^Scene, id: u64) -> (linalg.Matrix4f32, bool) {
	o, ok := find_by_id(s, id)
	if !ok {
		return {}, false
	}
	local := obj.local_matrix(o.transform)
	p, has_parent := o.transform.parent.?
	if !has_parent {
		return local, true
	}
	parent_world, pok := world_matrix(s, p)
	if !pok {
		return local, true
	}
	return parent_world * local, true
}
