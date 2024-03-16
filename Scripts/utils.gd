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


static func interpolate_vector(n: float, final: Vector3, initial: Vector3) -> Vector3:
	return n * final + (1 - n) * initial


static func convert_point_bvh_file_to_object(bvh_strings: PackedStringArray) -> Dictionary:
	var bvh_object := {"position": [], "rotation": []}
	var motion_string_index := bvh_strings.find("MOTION")
	var frames := bvh_strings.slice(motion_string_index + 3, -1)
	for frame in frames:
		var channels := frame.split(", ")
		var float_channels: PackedFloat32Array = []
		for channel in channels:
			float_channels.append(float(channel))
		bvh_object.position.append(Vector3(float_channels[0], float_channels[1], float_channels[2]))
		bvh_object.rotation.append(Vector3(float_channels[3], float_channels[4], float_channels[5]))
	var num_frames := int(bvh_strings[motion_string_index + 1].substr(8))
	var frame_time := float(bvh_strings[motion_string_index + 2].substr(12))
	bvh_object.time = num_frames * frame_time
	return bvh_object


static func get_bvh_object(path: String) -> Dictionary:
	var motion_file := FileAccess.open("res://Motion/" + path, FileAccess.READ)
	var motion_strings: PackedStringArray = []
	while not motion_file.eof_reached():
		motion_strings.append(motion_file.get_line())
	motion_file.close()
	return convert_point_bvh_file_to_object(motion_strings)
