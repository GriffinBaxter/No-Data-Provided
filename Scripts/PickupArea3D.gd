extends Area3D

@onready var player = $"../../Player"
@onready var pickup = $"../../Player/Head/Camera3D/Pickup"
@onready var level = $"../.."
@onready var camera_shader = $"../../CameraShader"

@onready var table_with_inverse_slice = $".."
@onready var table_slice = $"../TableSlice"
@onready var slicer = $"../Slicer"

var picked_up = false
var object_rotation = 0

const slicer_offset_position = Vector3(0, 1.5, 0)
const slicer_offset_rotation_degrees = 20

func _on_body_entered(body):
	if (picked_up == false and body == player):
		picked_up = true

		var tween = get_tree().create_tween().set_parallel()
		tween.tween_method(level.update_red_dither, camera_shader.get_surface_override_material(0).get_shader_parameter("red_dither"), 0.6, 1)
		tween.tween_method(level.update_green_dither, camera_shader.get_surface_override_material(0).get_shader_parameter("green_dither"), 0.1, 1)
		tween.tween_method(level.update_blue_dither, camera_shader.get_surface_override_material(0).get_shader_parameter("blue_dither"), 0.4, 1)

func _process(delta):
	if picked_up and level.state != level.State.MATCH:
		if Input.is_action_pressed("rotate_left"):
			object_rotation += 2.5 * delta;
		if Input.is_action_pressed("rotate_right"):
			object_rotation -= 2.5 * delta;
		table_slice.position = pickup.global_position
		slicer.position = table_slice.position + slicer_offset_position
		table_slice.rotation.y = pickup.global_rotation.y + object_rotation
		slicer.rotation_degrees.y = table_slice.rotation_degrees.y + slicer_offset_rotation_degrees
