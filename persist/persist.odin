package persist

import "../scene"
import "core:encoding/json"
import "core:os"

Object_Data :: struct {
	name:     string,
	active:   bool,
	position: [3]f32,
	scale:    [3]f32,
}

Scene_Data :: struct {
	objects: []Object_Data,
}

save_scene :: proc(s: ^scene.Scene, path: string) -> bool {
	data := Scene_Data {
		objects = make([]Object_Data, len(s.objects)),
	}
	defer delete(data.objects)
	for o, i in s.objects {
		data.objects[i] = Object_Data {
			name     = o.name,
			active   = o.active,
			position = o.transform.position,
			scale    = o.transform.scale,
		}
	}
	bytes, err := json.marshal(data)
	if err != nil {
		return false
	}
	defer delete(bytes)
	return os.write_entire_file(path, bytes) == nil
}

load_scene :: proc(s: ^scene.Scene, path: string) -> bool {
	bytes, err := os.read_entire_file(path, context.allocator)
	if err != nil {
		return false
	}
	defer delete(bytes)
	data: Scene_Data
	if json.unmarshal(bytes, &data) != nil {
		return false
	}
	defer delete(data.objects)
	for od in data.objects {
		o := scene.spawn(s, od.name)
		o.active = od.active
		o.transform.position = od.position
		o.transform.scale = od.scale
		delete(od.name)
	}
	return true
}
