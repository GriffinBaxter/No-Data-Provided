extends Node


static func is_within_offset_position(from: Vector3, to: Vector3, offset: float) -> bool:
	return (
		(to.x - offset <= from.x and from.x <= to.x + offset)
		and (to.y - offset <= from.y and from.y <= to.y + offset)
		and (to.z - offset <= from.z and from.z <= to.z + offset)
	)


static func is_within_offset_degrees(from: float, to: float, offset: float) -> bool:
	from = snapped(from, 1) % 360
	to = snapped(to, 1) % 360
	return to - offset <= from and from <= to + offset


static func piecewise_linear_interpolation(vectors: PackedVector3Array, progress: float) -> Vector3:
	var n := vectors.size()
	var t := progress
	var ix: int
	var x0: Vector3
	var x1: Vector3
	t *= (n - 1)
	ix = floori(t)
	t -= ix
	x0 = vectors[ix]
	ix += 1
	if ix < n:
		x1 = vectors[ix]
		return x0 + (x1 - x0) * t
	return x0
