extends SubViewport

const ALPHA_VALUES := [0., 0.5]
var increase_highlight := true
var identification_tween_in_progress := false
var timeline_stopped_duration := 0.
var identification_selectable := false

@onready var viewport_camera: Camera3D = $Camera3DNoShader
@onready var viewport_identification: Node3D = $IdentificationNoShader

@onready var player_camera: Camera3D = $"../../../Player/Head/Camera3D"
@onready var identification: Node3D = $"../../../Hallway/Identification"

@onready var viewport_identification_mesh: MeshInstance3D = $IdentificationNoShader/Cube

@onready var player: CharacterBody3D = $"../../../Player"

@onready var timeline: Node3D = $Camera3DNoShader/Timeline
@onready var interact_label: Label3D = $Camera3DNoShader/InteractLabel3D


func _process(delta: float) -> void:
	handle_identification_selection(delta)

	match_movement_camera()
	for objects: Array[Variant] in [[viewport_identification, identification]]:
		var viewport: Variant = objects[0]
		var to_match: Variant = objects[1]
		match_movement(viewport, to_match)

	move_interact_label_with_identification()


func handle_identification_selection(delta: float) -> void:
	var progress: float = player.progress
	identification_selectable = can_select_identification(progress)
	hightlight(delta)


func can_select_identification(progress: float) -> bool:
	return (
		player.timeline_stopped and !player.has_interacted and 0.475 < progress and progress < 0.6
	)


func hightlight(delta: float) -> void:
	timeline_stopped_duration = (
		timeline_stopped_duration + delta if identification_selectable else 0.
	)
	if (
		!identification_tween_in_progress
		and (timeline_stopped_duration >= 0.25 or !increase_highlight)
	):
		identification_tween_in_progress = true
		var duration := 1. if increase_highlight else 0.5
		var tween := get_tree().create_tween().set_parallel()
		tween.tween_method(
			update_identification_alpha,
			ALPHA_VALUES[0] if increase_highlight else ALPHA_VALUES[1],
			ALPHA_VALUES[1] if increase_highlight else ALPHA_VALUES[0],
			duration
		)
		tween.tween_property(
			interact_label,
			"modulate",
			Color(1, 1, 1, 1) if increase_highlight else Color(1, 1, 1, 0),
			duration
		)
		await get_tree().create_timer(duration).timeout

		tween.stop()
		increase_highlight = !increase_highlight
		identification_tween_in_progress = false


func update_identification_alpha(value: float) -> void:
	viewport_identification_mesh.material_override.albedo_color = Color(1, 1, 1, value)


func move_interact_label_with_identification() -> void:
	interact_label.global_position = identification.global_position + Vector3(0, 0.2, 0)


func match_movement_camera() -> void:
	match_movement(viewport_camera, player_camera)
	viewport_camera.fov = player_camera.fov


func match_movement(viewport: Variant, to_match: Variant) -> void:
	viewport.global_position = to_match.global_position
	viewport.global_rotation = to_match.global_rotation
	viewport.visible = to_match.visible
