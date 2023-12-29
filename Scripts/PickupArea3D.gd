extends Area3D

@onready var player = $"../../Player"
@onready var player_head = $"../../Player/Head"
@onready var pickup = $"../../Player/Head/Camera3D/Pickup"

@onready var table_with_inverse_slice = $".."
@onready var table_slice = $"../TableSlice"
@onready var slicer = $"../Slicer"

var picked_up = false

const slicer_offset_position = Vector3(0, 1.5, 0)
const slicer_offset_rotation_degrees = 20

func _on_body_entered(body):
	if (body == player):
		picked_up = true

func _process(_delta):
	if picked_up:
		table_slice.position = pickup.global_position
		slicer.position = table_slice.position + slicer_offset_position
		table_slice.rotation.y = player_head.rotation.y
		slicer.rotation_degrees.y = table_slice.rotation_degrees.y + slicer_offset_rotation_degrees
