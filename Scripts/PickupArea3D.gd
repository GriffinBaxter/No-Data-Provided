extends Area3D

const SLICER_OFFSET_POSITION = Vector3(0, 1.5, 0)
const SLICER_OFFSET_DEGREES = 20

var picked_up = false
var object_rotation = 0
var can_rotate_object = false

var timer
var continue_pick_up_animation_loop = true

@onready var player = $"../../Player"
@onready var pickup = $"../../Player/Head/Camera3D/Pickup"
@onready var level = $"../.."
@onready var camera_shader = $"../../CameraShader"

@onready var table_with_inverse_slice = $".."
@onready var table_slice = $"../TableSlice"
@onready var slicer = $"../Slicer"


func _on_body_entered(body):
	if picked_up == false and body == player:
		timer = Timer.new()
		add_child(timer)
		timer.one_shot = true
		timer.autostart = true
		timer.wait_time = 0.2
		timer.timeout.connect(_timeout)
		timer.start()

		var tween = get_tree().create_tween().set_parallel()
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

		while continue_pick_up_animation_loop:
			var time_left = timer.time_left
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
			await get_tree().create_timer(0.001).timeout

		picked_up = true


func _timeout():
	continue_pick_up_animation_loop = false


func _process(delta):
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
