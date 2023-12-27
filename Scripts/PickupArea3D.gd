extends Area3D

@onready var player = $"../../Player"
@onready var table_with_inverse_slice = $".."

func _on_body_entered(body):
	if (body == player):
		table_with_inverse_slice.visible = false
