extends Node3D

const SLICER_OFFSET_POSITION := Vector3(0, 1.5, 0)
const SLICER_OFFSET_DEGREES := 20

var picked_up := false
var object_rotation := 0.
var can_rotate_object := false

var timer: Timer
var continue_pick_up_animation_loop := true

@onready var player: CharacterBody3D = $"../Player"
@onready var pickup: Node3D = $"../Player/Head/Camera3D/Pickup"
@onready var level: Node3D = $".."
@onready var camera_shader: MeshInstance3D = $"../CameraShader"

@onready var table_with_inverse_slice: Node3D = $TableWithInverseSlice
@onready var table_slice: MeshInstance3D = $TableWithInverseSlice/TableSlice
@onready var slicer: MeshInstance3D = $TableWithInverseSlice/Slicer
@onready var pickup_area_3d: Area3D = $TableWithInverseSlice/PickupArea3D


func _ready() -> void:
	pickup_area_3d.body_entered.connect(_on_body_entered)


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
		var time_left := timer.time_left
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


func _on_body_entered(body: Node3D) -> void:
	if picked_up == false and body == player:
		timer = Timer.new()
		add_child(timer)
		timer.one_shot = true
		timer.autostart = true
		timer.wait_time = 0.2
		timer.timeout.connect(_timeout)
		timer.start()

		var tween := get_tree().create_tween().set_parallel()
		tween.tween_method(
			level.update_red_dither as Callable,
			camera_shader.get_surface_override_material(0).get_shader_parameter("red_dither"),
			0.6,
			1
		)
		tween.tween_method(
			level.update_green_dither as Callable,
			camera_shader.get_surface_override_material(0).get_shader_parameter("green_dither"),
			0.1,
			1
		)
		tween.tween_method(
			level.update_blue_dither as Callable,
			camera_shader.get_surface_override_material(0).get_shader_parameter("blue_dither"),
			0.4,
			1
		)
		await get_tree().create_timer(0.2).timeout

		picked_up = true


func _timeout() -> void:
	continue_pick_up_animation_loop = false
