extends Area3D

@onready var player = $"../../Player"
@onready var pickup = $"../../Player/Head/Camera3D/Pickup"
@onready var level = $"../.."

@onready var table_with_inverse_slice = $".."
@onready var table_slice = $"../TableSlice"
@onready var slicer = $"../Slicer"

var picked_up = false
var object_rotation = 0

const slicer_offset_position = Vector3(0, 1.5, 0)
const slicer_offset_rotation_degrees = 20

func _on_body_entered(body):
	if (body == player):
		picked_up = true

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
