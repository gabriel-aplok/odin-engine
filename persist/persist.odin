package persist

import "../scene"
import obj "../object"
import "core:encoding/json"
import "core:os"
import "core:strings"

// one table entry per component. new components add one entry,
// the save and load loops below never change.
Saver :: proc(o: ^obj.Game_Object) -> (string, bool)

Loader :: proc(o: ^obj.Game_Object, data: string) -> bool

Codec :: struct {
	save: Saver,
	load: Loader,
}

// builtin components. new engine component adds one line here.
make_codecs :: proc(allocator := context.allocator) -> map[string]Codec {
	codecs := make(map[string]Codec, allocator)
	codecs["transform"] = Codec{save = save_transform, load = load_transform}
	codecs["mesh"] = Codec{
		save = proc(o: ^obj.Game_Object) -> (string, bool) {
			return save_component(o, o.mesh)
		},
		load = proc(o: ^obj.Game_Object, data: string) -> bool {
			m: obj.Mesh_Component
			if json.unmarshal(transmute([]u8)data, &m) != nil {
				return false
			}
			o.mesh = m
			return true
		},
	}
	codecs["body"] = Codec{
		save = proc(o: ^obj.Game_Object) -> (string, bool) {
			return save_component(o, o.body)
		},
		load = proc(o: ^obj.Game_Object, data: string) -> bool {
			b: obj.Rigid_Body
			if json.unmarshal(transmute([]u8)data, &b) != nil {
				return false
			}
			o.body = b
			return true
		},
	}
	codecs["collider"] = Codec{
		save = proc(o: ^obj.Game_Object) -> (string, bool) {
			return save_component(o, o.collider)
		},
		load = proc(o: ^obj.Game_Object, data: string) -> bool {
			c: obj.Collider
			if json.unmarshal(transmute([]u8)data, &c) != nil {
				return false
			}
			o.collider = c
			return true
		},
	}
	return codecs
}

Transform_Data :: struct {
	position:   [3]f32,
	rotation:   [4]f32,
	scale:      [3]f32,
	parent:     u64,
	has_parent: bool,
}

save_transform :: proc(o: ^obj.Game_Object) -> (string, bool) {
	d := Transform_Data{
		position   = o.transform.position,
		rotation   = transmute([4]f32)o.transform.rotation,
		scale      = o.transform.scale,
		has_parent = false,
	}
	if p, ok := o.transform.parent.?; ok {
		d.parent = p
		d.has_parent = true
	}
	bytes, err := json.marshal(d)
	if err != nil {
		return "", false
	}
	return string(bytes), true
}

load_transform :: proc(o: ^obj.Game_Object, data: string) -> bool {
	d: Transform_Data
	if json.unmarshal(transmute([]u8)data, &d) != nil {
		return false
	}
	o.transform.position = d.position
	o.transform.rotation = transmute(quaternion128)d.rotation
	o.transform.scale = d.scale
	if d.has_parent {
		o.transform.parent = d.parent
	}
	return true
}

save_component :: proc(o: ^obj.Game_Object, existing: Maybe($T)) -> (string, bool) {
	c, ok := existing.?
	if !ok {
		return "", false
	}
	bytes, err := json.marshal(c)
	if err != nil {
		return "", false
	}
	return string(bytes), true
}

Component_Entry :: struct {
	type: string,
	data: string,
}

Object_Record :: struct {
	name:       string,
	active:     bool,
	components: []Component_Entry,
}

Scene_File :: struct {
	version: int,
	objects: []Object_Record,
}

SCENE_VERSION :: 2

free_file :: proc(file: ^Scene_File) {
	for &rec in file.objects {
		for &entry in rec.components {
			delete(entry.type)
			delete(entry.data)
		}
		delete(rec.components)
		delete(rec.name)
	}
	delete(file.objects)
}

save_scene :: proc(s: ^scene.Scene, path: string) -> bool {
	codecs := make_codecs()
	defer delete(codecs)
	records := make([]Object_Record, len(s.objects))
	for o, i in s.objects {
		entries := make([dynamic]Component_Entry)
		for name, codec in codecs {
			data, ok := codec.save(&s.objects[i])
			if !ok {
				continue
			}
			append(&entries, Component_Entry{type = strings.clone(name), data = data})
		}
		records[i] = Object_Record{
			name       = strings.clone(o.name),
			active     = o.active,
			components = entries[:],
		}
	}
	file := Scene_File{version = SCENE_VERSION, objects = records}
	bytes, err := json.marshal(file)
	if err != nil {
		free_file(&file)
		return false
	}
	defer delete(bytes)
	ok := os.write_entire_file(path, bytes) == nil
	free_file(&file)
	return ok
}

load_scene :: proc(s: ^scene.Scene, path: string) -> bool {
	codecs := make_codecs()
	defer delete(codecs)
	bytes, err := os.read_entire_file(path, context.allocator)
	if err != nil {
		return false
	}
	defer delete(bytes)
	file: Scene_File
	if json.unmarshal(bytes, &file) != nil {
		return false
	}
	if file.version != SCENE_VERSION {
		free_file(&file)
		return false
	}
	for rec in file.objects {
		o := scene.spawn(s, rec.name)
		o.active = rec.active
		loaded := true
		for entry in rec.components {
			codec, known := codecs[entry.type]
			if !known || !codec.load(o, entry.data) {
				loaded = false
				break
			}
		}
		if !loaded {
			free_file(&file)
			return false
		}
	}
	free_file(&file)
	return true
}
