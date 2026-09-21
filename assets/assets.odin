package assets

import "core:os"

Asset_Kind :: enum {
	Bytes,
	Shader_Source,
}

Asset_Handle :: distinct u32

INVALID_HANDLE :: Asset_Handle(0)

Asset :: struct {
	kind: Asset_Kind,
	path: string,
	data: []u8,
}

Asset_Store :: struct {
	assets: [dynamic]Asset,
}

make_store :: proc() -> Asset_Store {
	return Asset_Store{assets = make([dynamic]Asset)}
}

destroy_store :: proc(s: ^Asset_Store) {
	for &a in s.assets {
		delete(a.data)
		delete(a.path)
	}
	delete(s.assets)
}

load_file :: proc(s: ^Asset_Store, path: string, kind: Asset_Kind) -> (Asset_Handle, bool) {
	data, err := os.read_entire_file(path, context.allocator)
	if err != nil {
		return INVALID_HANDLE, false
	}
	handle := Asset_Handle(len(s.assets) + 1)
	append(&s.assets, Asset{kind = kind, path = clone_string(path), data = data})
	return handle, true
}

get :: proc(s: ^Asset_Store, handle: Asset_Handle) -> (^Asset, bool) {
	i := int(handle) - 1
	if i < 0 || i >= len(s.assets) {
		return nil, false
	}
	return &s.assets[i], true
}

clone_string :: proc(s: string) -> string {
	b := make([]u8, len(s))
	copy(b, transmute([]u8)s)
	return transmute(string)b
}
