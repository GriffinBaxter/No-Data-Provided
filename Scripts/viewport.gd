extends SubViewport

const ALPHA_VALUES := [0., 0.5]
var increase_highlight := true
var identification_tween_in_progress := false
var timeline_stopped_duration := 0.

@onready var viewport_camera: Camera3D = $Camera3DNoShader
@onready var viewport_identification: Node3D = $IdentificationNoShader

@onready var player_camera: Camera3D = $"../../../Player/Head/Camera3D"
@onready var identification: Node3D = $"../../../Identification"

@onready var viewport_identification_mesh: MeshInstance3D = $IdentificationNoShader/Cube

@onready var player: CharacterBody3D = $"../../../Player"


func _process(delta: float) -> void:
	match_movement_camera()
	for objects: Array[Variant] in [[viewport_identification, identification]]:
		var viewport: Variant = objects[0]
		var to_match: Variant = objects[1]
		match_movement(viewport, to_match)

	hightlight_identification_when_timeline_stopped(delta)


func match_movement(viewport: Variant, to_match: Variant) -> void:
	viewport.global_position = to_match.global_position
	viewport.global_rotation = to_match.global_rotation
	viewport.visible = to_match.visible


func match_movement_camera() -> void:
	match_movement(viewport_camera, player_camera)
	viewport_camera.fov = player_camera.fov


func hightlight_identification_when_timeline_stopped(delta: float) -> void:
	timeline_stopped_duration = timeline_stopped_duration + delta if player.timeline_stopped else 0.

	if (
		!identification_tween_in_progress
		and (timeline_stopped_duration >= 0.25 or !increase_highlight)
	):
		identification_tween_in_progress = true
		var tween := get_tree().create_tween()
		tween.tween_method(
			update_identification_alpha,
			ALPHA_VALUES[0] if increase_highlight else ALPHA_VALUES[1],
			ALPHA_VALUES[1] if increase_highlight else ALPHA_VALUES[0],
			1
		)
		await get_tree().create_timer(1).timeout

		tween.stop()
		increase_highlight = !increase_highlight
		identification_tween_in_progress = false


func update_identification_alpha(value: float) -> void:
	viewport_identification_mesh.material_override.albedo_color = Color(1, 1, 1, value)
