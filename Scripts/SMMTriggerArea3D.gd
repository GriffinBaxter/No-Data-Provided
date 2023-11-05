extends Area3D

@onready var player = $"../Control/AspectRatioContainer/SubViewportContainer/SubViewport/Player"
@onready var sub_viewport_container = $"../Control/AspectRatioContainer/SubViewportContainer"
@onready var smm_animation_player = $"../SMMAnimationPlayer"

func _on_body_entered(body):
	if (body == player):
		sub_viewport_container.visible = false
		smm_animation_player.play("cutscene_1")
