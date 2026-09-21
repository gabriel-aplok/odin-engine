package lod

Level :: enum {
	Full,
	Reduced,
}

NEAR_DIST :: f32(25)
FAR_DIST :: f32(60)

select :: proc(distance: f32) -> Level {
	if distance >= FAR_DIST {
		return .Reduced
	}
	return .Full
}
