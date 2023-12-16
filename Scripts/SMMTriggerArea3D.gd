extends Area3D

@onready var player = $"../../Control/AspectRatioContainer/SubViewportContainer/SubViewport/Player"
@onready var sub_viewport_container = $"../../Control/AspectRatioContainer/SubViewportContainer"
@onready var smm_animation_player = $"../../SMMAnimationPlayer"

@onready var player_camera = $"../../Control/AspectRatioContainer/SubViewportContainer/SubViewport/Player/Head/Camera3D"
@onready var player_head = $"../../Control/AspectRatioContainer/SubViewportContainer/SubViewport/Player/Head"
@onready var smm_camera = $".."
@onready var table = $"../../Table"

var player_entered_area = false
var intro_cutscene_started = false
var cutscene_started = false

func _process(_delta):
	if (!intro_cutscene_started):
		intro_cutscene_started = true

		smm_animation_player.play("hallway_intro")

	if (!cutscene_started and player_entered_area and is_within_offset_degrees(-25, 10, player_camera.rotation_degrees.x) and is_within_offset_degrees(11.6, 10, player_head.rotation_degrees.y)):
		cutscene_started = true

		var tween = get_tree().create_tween().set_parallel()
		tween.tween_property(player_camera, "global_position", smm_camera.position, 0.5)
		tween.tween_property(player_camera, "global_rotation", smm_camera.rotation, 0.5)

		await get_tree().create_timer(0.5).timeout

		sub_viewport_container.visible = false
		smm_animation_player.play("hallway_outro")
		
		await get_tree().create_timer(5).timeout

		table.rotation_degrees = Vector3(0, 0, 0)

		await get_tree().create_timer(9.9).timeout

		var table_tween = get_tree().create_tween()
		table_tween.tween_property(table, "rotation_degrees", Vector3(0, 11.6, 0), 0.1)

func _on_body_entered(body):
	if (body == player):
		player_entered_area = true

func is_within_offset_degrees(original_degrees, offset_degrees, current_degrees):
	return original_degrees - offset_degrees <= current_degrees and current_degrees <= original_degrees + offset_degrees
