extends Node

const UTILS := preload("res://Scripts/utils.gd")

@export var node: Node3D
@export var camera: Camera3D

var timer: Timer
var bvh: Dictionary


func _ready() -> void:
	if camera == null:
		camera = $"../Player/Head/Camera3D"


func setup_motion_cutscene(
	path: String, motion: int, custom_time: float = 0, resolution: float = 1
) -> void:
	bvh = UTILS.get_bvh_dictionary(path, custom_time, resolution)
	setup_timer(bvh.time as float)
	node.current_motion = motion


func setup_timer(wait_time: float) -> void:
	timer = Timer.new()
	add_child(timer)
	timer.one_shot = true
	timer.autostart = true
	timer.wait_time = wait_time
	timer.start()


func update_camera_with_motion(camera_motion: Dictionary) -> void:
	if timer.time_left <= 0 and node.current_motion != node.Motion.NONE:
		node.current_motion = node.Motion.NONE
	else:
		var progress: float = (bvh.time - timer.time_left) / bvh.time
		camera.global_position = (
			UTILS.piecewise_linear_interpolation(bvh.position as PackedVector3Array, progress)
			- bvh.position[-1]
			+ camera_motion.final_pos
			+ (
				(1 - progress)
				* (
					camera_motion.initial_pos_delta
					if camera_motion.has("initial_pos_delta")
					else Vector3.ZERO
				)
			)
		)
		camera.global_rotation_degrees = (
			UTILS.piecewise_linear_interpolation(bvh.rotation as PackedVector3Array, progress)
			- bvh.rotation[-1]
			+ camera_motion.final_rot
			+ (
				(1 - progress)
				* (
					camera_motion.initial_rot_delta
					if camera_motion.has("initial_rot_delta")
					else Vector3.ZERO
				)
			)
		)
