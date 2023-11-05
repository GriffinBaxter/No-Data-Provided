extends Area3D

@onready var player = $"../Control/AspectRatioContainer/SubViewportContainer/SubViewport/Player"

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


func _on_body_entered(body):
	if (body == player):
		print("Player Reached Area")
