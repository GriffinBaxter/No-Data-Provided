extends Area3D

@onready var player = $"../../Control/AspectRatioContainer/SubViewportContainer/SubViewport/Player"
@onready var sub_viewport_container = $"../../Control/AspectRatioContainer/SubViewportContainer"
@onready var smm_animation_player = $"../../SMMAnimationPlayer"

@onready var player_camera = $"../../Control/AspectRatioContainer/SubViewportContainer/SubViewport/Player/Head/Camera3D"
@onready var player_head = $"../../Control/AspectRatioContainer/SubViewportContainer/SubViewport/Player/Head"
@onready var smm_camera = $".."
@onready var table = $"../../TableWithSlice/Table"
@onready var valuable = $"../../TableWithSlice/Table/Valuable"
@onready var save_load = $"../../SaveLoad"

enum State {BEFORE_INTRO_CUTSCENE, AFTER_INTRO_CUTSCENE, MATCH}
var state = State.BEFORE_INTRO_CUTSCENE
const states_moveable = [State.AFTER_INTRO_CUTSCENE]
signal movable
signal autosave

const level = 0

var player_entered_area = false
var intro_cutscene_started = false

func load_game(save):
	update_state(save.state, false)
	player.position = Vector3(save.player_position[0], save.player_position[1], save.player_position[2])

func update_state(new_state, updated_from_autosave = true):
	state = new_state
	if state == State.MATCH and not updated_from_autosave:
		match_cutscene()
	if states_moveable.has(int(state)):
		emit_signal("movable", true)
	else:
		emit_signal("movable", false)
	if updated_from_autosave:
		emit_signal("autosave", level, state, [player.position.x, player.position.y, player.position.z])

func _ready():
	save_load.load.connect(load_game)

func _process(_delta):
	if (state == State.BEFORE_INTRO_CUTSCENE and !intro_cutscene_started):
		intro_cutscene_started = true

		smm_animation_player.play("hallway_intro")
		
		await get_tree().create_timer(5).timeout
		
		update_state(State.AFTER_INTRO_CUTSCENE)

	if (state < State.MATCH and player_entered_area and is_within_offset_degrees(-25, 10, player_camera.rotation_degrees.x) and is_within_offset_degrees(11.6, 10, player_head.rotation_degrees.y)):
		update_state(State.MATCH)

		var tween = get_tree().create_tween().set_parallel()
		tween.tween_property(player_camera, "global_position", smm_camera.position, 0.5)
		tween.tween_property(player_camera, "global_rotation", smm_camera.rotation, 0.5)

		await get_tree().create_timer(0.5).timeout

		match_cutscene()

func match_cutscene():
	sub_viewport_container.visible = false
	smm_animation_player.play("hallway_outro")
		
	await get_tree().create_timer(5).timeout

	table.rotation_degrees = Vector3(0, 0, 0)
	valuable.visible = false

	await get_tree().create_timer(9.9).timeout

	var table_tween = get_tree().create_tween()
	table_tween.tween_property(table, "rotation_degrees", Vector3(0, 11.6, 0), 0.1)

	await get_tree().create_timer(0.1).timeout

	valuable.visible = true

func _on_body_entered(body):
	if (body == player):
		player_entered_area = true

func _on_body_exited(body):
	if (body == player):
		player_entered_area = false

func is_within_offset_degrees(original_degrees, offset_degrees, current_degrees):
	return original_degrees - offset_degrees <= current_degrees and current_degrees <= original_degrees + offset_degrees
