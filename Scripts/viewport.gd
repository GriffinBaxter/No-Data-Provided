extends SubViewport

@onready var viewport_camera: Camera3D = $Camera3DNoShader
@onready var viewport_identification: Node3D = $IdentificationNoShader

@onready var player_camera: Camera3D = $"../../../Player/Head/Camera3D"
@onready var identification: Node3D = $"../../../Identification"

@onready var viewport_identification_mesh: MeshInstance3D = $IdentificationNoShader/Cube


func _ready() -> void:
	const IDENTIFICATION_COLOURS := [Color(1, 1, 1, 0), Color(1, 1, 1, 0.5)]
	var alternate := false
	while true:
		var tween := get_tree().create_tween()
		tween.tween_method(
			update_identification_transparency,
			IDENTIFICATION_COLOURS[1] if alternate else IDENTIFICATION_COLOURS[0],
			IDENTIFICATION_COLOURS[0] if alternate else IDENTIFICATION_COLOURS[1],
			1
		)
		await get_tree().create_timer(1).timeout

		tween.stop()
		alternate = !alternate


func _process(_delta: float) -> void:
	match_movement_camera()
	for objects: Array[Variant] in [[viewport_identification, identification]]:
		var viewport: Variant = objects[0]
		var to_match: Variant = objects[1]
		match_movement(viewport, to_match)


func update_identification_transparency(value: Color) -> void:
	viewport_identification_mesh.material_override.albedo_color = value


func match_movement(viewport: Variant, to_match: Variant) -> void:
	viewport.global_position = to_match.global_position
	viewport.global_rotation = to_match.global_rotation
	viewport.visible = to_match.visible


func match_movement_camera() -> void:
	match_movement(viewport_camera, player_camera)
	viewport_camera.fov = player_camera.fov
