package memory

import "core:mem"

// bump allocator over a fixed buffer. allocations die on reset.
// gives every frame a hard budget instead of open ended temp use.
Frame :: struct {
	buffer: []u8,
	offset: int,
}

make_frame :: proc(budget_bytes: int) -> Frame {
	return Frame{buffer = make([]u8, budget_bytes)}
}

destroy_frame :: proc(f: ^Frame) {
	delete(f.buffer)
	f.buffer = nil
	f.offset = 0
}

reset :: proc(f: ^Frame) {
	f.offset = 0
}

used :: proc(f: ^Frame) -> int {
	return f.offset
}

// nil when the budget runs out. loud on purpose, callers must check.
alloc :: proc(f: ^Frame, size, align: int) -> rawptr {
	addr := mem.align_forward(rawptr(&f.buffer[f.offset]), uintptr(align))
	off := int(uintptr(addr) - uintptr(rawptr(&f.buffer[0])))
	if off + size > len(f.buffer) {
		return nil
	}
	f.offset = off + size
	return addr
}

allocator :: proc(f: ^Frame) -> mem.Allocator {
	return mem.Allocator{procedure = allocator_proc, data = f}
}

allocator_proc :: proc(
	allocator_data: rawptr,
	mode: mem.Allocator_Mode,
	size, alignment: int,
	old_memory: rawptr,
	old_size: int,
	location := #caller_location,
) -> (
	[]byte,
	mem.Allocator_Error,
) {
	f := (^Frame)(allocator_data)
	#partial switch mode {
	case .Alloc, .Alloc_Non_Zeroed:
		ptr := alloc(f, size, alignment)
		if ptr == nil {
			return nil, .Out_Of_Memory
		}
		return mem.byte_slice(ptr, size), .None
	case .Free, .Free_All:
		return nil, .None
	case .Resize, .Resize_Non_Zeroed:
		return nil, .Out_Of_Memory
	}
	return nil, .Mode_Not_Implemented
}
