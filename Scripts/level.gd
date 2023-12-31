extends Node3D

@onready var pause_menu = $PauseMenu

@onready var player = $Player
@onready var animation_player = $AnimationPlayer
@onready var pickupArea3d = $TableWithInverseSlice/PickupArea3D

@onready var player_camera = $Player/Head/Camera3D
@onready var player_head = $Player/Head
@onready var table = $TableWithSlice/Table
@onready var valuable = $TableWithSlice/Table/Valuable
@onready var save_load = $SaveLoad

@onready var slicer = $TableWithSlice/Slicer
@onready var table_slice = $TableWithInverseSlice/TableSlice
@onready var inverse_slicer = $TableWithInverseSlice/Slicer

var paused = false

enum State {BEFORE_INTRO_CUTSCENE, AFTER_INTRO_CUTSCENE, MATCH}
var state = State.BEFORE_INTRO_CUTSCENE
const states_moveable = [State.AFTER_INTRO_CUTSCENE]
signal level_node_ready
signal movable
signal autosave

const level = 0

var player_entered_area = false
var intro_cutscene_started = false

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	Engine.time_scale = 1
	save_load.load.connect(load_game)
	emit_signal("level_node_ready")

func _process(_delta):
	if Input.is_action_just_pressed("pause"):
		pauseMenu()

	if (state == State.BEFORE_INTRO_CUTSCENE and !intro_cutscene_started):
		intro_cutscene_started = true

		animation_player.play("hallway_intro")
		
		await get_tree().create_timer(5).timeout
		
		update_state(State.AFTER_INTRO_CUTSCENE)

	if (state < State.MATCH and is_within_offset_position(table_slice.global_position, table.global_position, 0.5) and is_within_offset_degrees(table_slice.global_rotation_degrees.y, table.global_rotation_degrees.y, 10)):
		update_state(State.MATCH)

		var tween = get_tree().create_tween().set_parallel()
		tween.tween_property(inverse_slicer, "global_position", inverse_slicer.global_position + Vector3(0, 0.6, 0), 1)
		tween.tween_property(slicer, "global_position", slicer.global_position + Vector3(0, 0.6, 0), 1)

		await get_tree().create_timer(2).timeout
		tween.stop()

		match_cutscene()

func pauseMenu():
	paused = !paused
	if paused:
		pause_menu.show()
		Engine.time_scale = 0
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	else:
		pause_menu.hide()
		Engine.time_scale = 1
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

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

func match_cutscene():
	var tween1 = get_tree().create_tween().set_parallel()

	tween1.tween_property(player_camera, "global_position", Vector3(0.4, 1.65, -10), 5)
	tween1.tween_property(player_camera, "global_rotation_degrees", Vector3(-55, 11.6, 0), 5)

	await get_tree().create_timer(5).timeout
	tween1.stop()

	animation_player.play("hallway_outro")

	var tween2 = get_tree().create_tween().set_parallel()
	tween2.tween_property(player_camera, "global_position", Vector3(0, 1.65, -42.75), 10)
	tween2.tween_property(player_camera, "global_rotation_degrees", Vector3(-25, 11.6, 0), 10)

	table.rotation_degrees = Vector3(0, 0, 0)
	valuable.visible = false

	await get_tree().create_timer(9.9).timeout

	var table_tween = get_tree().create_tween()
	table_tween.tween_property(table, "rotation_degrees", Vector3(0, 11.6, 0), 0.1)

	await get_tree().create_timer(0.1).timeout

	valuable.visible = true

func is_within_offset_position(from, to, offset):
	return (to.x - offset <= from.x and from.x <= to.x + offset) and (to.y - offset <= from.y and from.y <= to.y + offset) and (to.z - offset <= from.z and from.z <= to.z + offset)

func is_within_offset_degrees(from, to, offset):
	from = snapped(from, 1) % 360
	to = snapped(to, 1) % 360
	return to - offset <= from and from <= to + offset
