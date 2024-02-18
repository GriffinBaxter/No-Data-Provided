extends Area3D

const SLICER_OFFSET_POSITION: Vector3 = Vector3(0, 1.5, 0)
const SLICER_OFFSET_DEGREES: int = 20

var picked_up: bool = false
var object_rotation: float = 0
var can_rotate_object: bool = false

var timer: Timer
var continue_pick_up_animation_loop: bool = true

@onready var player: CharacterBody3D = $"../../Player"
@onready var pickup: Node3D = $"../../Player/Head/Camera3D/Pickup"
@onready var level: Node3D = $"../.."
@onready var camera_shader: MeshInstance3D = $"../../CameraShader"

@onready var table_with_inverse_slice: Node3D = $".."
@onready var table_slice: MeshInstance3D = $"../TableSlice"
@onready var slicer: MeshInstance3D = $"../Slicer"


func _on_body_entered(body: Node3D) -> void:
	if picked_up == false and body == player:
		timer = Timer.new()
		add_child(timer)
		timer.one_shot = true
		timer.autostart = true
		timer.wait_time = 0.2
		timer.timeout.connect(_timeout)
		timer.start()

		var tween: Tween = get_tree().create_tween().set_parallel()
		tween.tween_method(
			level.update_red_dither,
			camera_shader.get_surface_override_material(0).get_shader_parameter("red_dither"),
			0.6,
			1
		)
		tween.tween_method(
			level.update_green_dither,
			camera_shader.get_surface_override_material(0).get_shader_parameter("green_dither"),
			0.1,
			1
		)
		tween.tween_method(
			level.update_blue_dither,
			camera_shader.get_surface_override_material(0).get_shader_parameter("blue_dither"),
			0.4,
			1
		)
		await get_tree().create_timer(0.2).timeout

		picked_up = true


func _timeout() -> void:
	continue_pick_up_animation_loop = false


func _process(delta: float) -> void:
	if picked_up and level.state != level.State.MATCH:
		if can_rotate_object:
			if Input.is_action_pressed("rotate_left"):
				object_rotation += 2.5 * delta
			if Input.is_action_pressed("rotate_right"):
				object_rotation -= 2.5 * delta
		table_slice.position = pickup.global_position
		slicer.position = table_slice.position + SLICER_OFFSET_POSITION
		table_slice.rotation.y = pickup.global_rotation.y + object_rotation
		slicer.rotation_degrees.y = table_slice.rotation_degrees.y + SLICER_OFFSET_DEGREES

	if timer and continue_pick_up_animation_loop:
		var time_left: float = timer.time_left
		table_slice.position = Tween.interpolate_value(
			table_slice.position,
			pickup.global_position - table_slice.position,
			0.2 - time_left,
			0.2,
			Tween.TRANS_LINEAR,
			Tween.EASE_IN
		)
		slicer.position = table_slice.position + SLICER_OFFSET_POSITION
		table_slice.rotation.y = Tween.interpolate_value(
			table_slice.rotation.y,
			pickup.global_rotation.y - table_slice.rotation.y,
			0.2 - time_left,
			0.2,
			Tween.TRANS_LINEAR,
			Tween.EASE_IN
		)
		slicer.rotation_degrees.y = table_slice.rotation_degrees.y + SLICER_OFFSET_DEGREES
