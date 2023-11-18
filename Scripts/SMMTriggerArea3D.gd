extends Area3D

@onready var player = $"../../Control/AspectRatioContainer/SubViewportContainer/SubViewport/Player"
@onready var sub_viewport_container = $"../../Control/AspectRatioContainer/SubViewportContainer"
@onready var smm_animation_player = $"../../SMMAnimationPlayer"

@onready var player_camera = $"../../Control/AspectRatioContainer/SubViewportContainer/SubViewport/Player/Head/Camera3D"
@onready var player_head = $"../../Control/AspectRatioContainer/SubViewportContainer/SubViewport/Player/Head"

var player_entered_area = false
var cutscene_started = false

func _process(_delta):
	if (!cutscene_started and player_entered_area and is_within_offset_degrees(-25, 10, player_camera.rotation_degrees.x) and is_within_offset_degrees(11.6, 10, player_head.rotation_degrees.y)):
		cutscene_started = true
		sub_viewport_container.visible = false
		smm_animation_player.play("cutscene_1")

func _on_body_entered(body):
	if (body == player):
		player_entered_area = true

func is_within_offset_degrees(original_degrees, offset_degrees, current_degrees):
	return original_degrees - offset_degrees <= current_degrees and current_degrees <= original_degrees + offset_degrees
