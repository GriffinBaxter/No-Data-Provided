extends Node3D

signal level_node_ready
signal movable
signal timeline_adjustable
signal autosave

enum State { BEFORE_INTRO_CUTSCENE, AFTER_INTRO_CUTSCENE, MATCH_ANIMATION, MATCH }

const UTILS := preload("res://Scripts/utils.gd")
const STATES_MOVEABLE: Array[State] = [State.AFTER_INTRO_CUTSCENE, State.MATCH_ANIMATION]
const STATES_SAVABLE: Array[State] = [
	State.BEFORE_INTRO_CUTSCENE, State.AFTER_INTRO_CUTSCENE, State.MATCH
]
const LEVEL := 0

var paused := false
var state: State = State.BEFORE_INTRO_CUTSCENE
var player_entered_area := false
var intro_cutscene_started := false
var interacted_with_identification := false

@onready var pause_menu_node: Control = $PauseMenu

@onready var player: CharacterBody3D = $Player
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var camera_shader: MeshInstance3D = $CameraShader
@onready var last_medium_presents: Label3D = $LastMediumPresentsLabel3D
@onready var no_data_provided: Label3D = $NoDataProvidedLabel3D

@onready var timeline: Node3D = $Player/Head/Camera3D/Timeline
@onready var player_camera: Camera3D = $Player/Head/Camera3D
@onready var player_head: Node3D = $Player/Head
@onready var save_load: Node = $SaveLoad
@onready var pickup_area_3d: Area3D = $TableWithInverseSlice/PickupArea3D

@onready var slicer: MeshInstance3D = $TableWithSlice/Slicer
@onready var table_slice: MeshInstance3D = $TableWithSlice/Table
@onready var inverse_slicer: MeshInstance3D = $TableWithInverseSlice/Slicer
@onready var inverse_table_slice: MeshInstance3D = $TableWithInverseSlice/TableSlice
@onready var identification: Node3D = $Identification
@onready var wall_closing_dust_particles: GPUParticles3D = $hallway/WallClosingDustParticles


func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	Engine.time_scale = 1
	save_load.load.connect(load_game)
	emit_signal("level_node_ready")


func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("pause"):
		pause_menu()

	if state == State.BEFORE_INTRO_CUTSCENE and !intro_cutscene_started:
		intro_cutscene_started = true
		player_camera.global_position = Vector3(0, -1, 1)
		player_camera.global_rotation_degrees = Vector3(70, 0, 0)
		last_medium_presents.visible = true
		player_camera.fov = 50
		await letter_by_letter(last_medium_presents, "last medium presents")

		player_camera.global_position = Vector3(1.75, 3, -48.5)
		player_camera.global_rotation_degrees = Vector3(0, 150, 0)
		last_medium_presents.visible = false
		no_data_provided.visible = true
		await letter_by_letter(no_data_provided, "no data provided")

		no_data_provided.visible = false
		player_camera.fov = 80
		animation_player.play("hallway_intro")
		await get_tree().create_timer(4.75).timeout

		wall_closing_dust_particles.emitting = true
		await get_tree().create_timer(0.25).timeout

		update_state(State.AFTER_INTRO_CUTSCENE)

	if (
		state < State.MATCH_ANIMATION
		and UTILS.is_within_offset_position(
			inverse_table_slice.global_position, table_slice.global_position, 0.5
		)
		and UTILS.is_within_offset_degrees(
			inverse_table_slice.global_rotation_degrees.y, table_slice.global_rotation_degrees.y, 10
		)
	):
		update_state(State.MATCH_ANIMATION)
		pickup_area_3d.picked_up = false
		var tween_1 := get_tree().create_tween().set_parallel()
		tween_1.tween_method(
			update_red_albedo, table_slice.material_override["shader_parameter/red_albedo"], 5, 1
		)
		tween_1.tween_method(
			update_green_albedo,
			table_slice.material_override["shader_parameter/green_albedo"],
			5,
			1
		)
		tween_1.tween_method(
			update_blue_albedo, table_slice.material_override["shader_parameter/blue_albedo"], 5, 1
		)
		tween_1.tween_property(
			inverse_table_slice, "global_position", table_slice.global_position, 1
		)
		tween_1.tween_property(inverse_slicer, "global_position", slicer.global_position, 1)
		tween_1.tween_property(inverse_table_slice, "rotation", table_slice.rotation, 1)
		tween_1.tween_property(inverse_slicer, "rotation", slicer.rotation, 1)
		await get_tree().create_timer(1).timeout

		inverse_table_slice.visible = false
		slicer.global_position += Vector3(0, 0.65, 0)
		var tween_2 := get_tree().create_tween().set_parallel()
		tween_2.tween_method(
			update_red_dither,
			camera_shader.get_surface_override_material(0).get_shader_parameter("red_dither"),
			1.6,
			1
		)
		tween_2.tween_method(
			update_green_dither,
			camera_shader.get_surface_override_material(0).get_shader_parameter("green_dither"),
			0.15,
			1
		)
		tween_2.tween_method(
			update_blue_dither,
			camera_shader.get_surface_override_material(0).get_shader_parameter("blue_dither"),
			0.1,
			1
		)
		tween_2.tween_method(
			update_red_albedo, table_slice.material_override["shader_parameter/red_albedo"], 0, 1
		)
		tween_2.tween_method(
			update_green_albedo,
			table_slice.material_override["shader_parameter/green_albedo"],
			0,
			1
		)
		tween_2.tween_method(
			update_blue_albedo, table_slice.material_override["shader_parameter/blue_albedo"], 0, 1
		)
		await get_tree().create_timer(1).timeout

		tween_1.stop()
		tween_2.stop()
		inverse_table_slice.visible = false
		update_state(State.MATCH)

	if interacted_with_identification and player.progress >= player.JUST_UNDER_ONE:
		end_cutscene()


func pause_menu() -> void:
	paused = !paused
	if paused:
		pause_menu_node.show()
		Engine.time_scale = 0
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	else:
		pause_menu_node.hide()
		Engine.time_scale = 1
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)


func load_game(save: Dictionary) -> void:
	update_state(save.state as State, false)
	player.position = save.player_position


func update_state(new_state: State, updated_from_autosave: bool = true) -> void:
	state = new_state
	if state == State.MATCH:
		match_cutscene()
	if STATES_MOVEABLE.has(int(state)):
		emit_signal("movable", true)
	else:
		emit_signal("movable", false)
	if updated_from_autosave and STATES_SAVABLE.has(int(state)):
		emit_signal("autosave", LEVEL, state, player.position)


func letter_by_letter(label: Label3D, text: String) -> void:
	await blink_text_with_caret(false, 2, label)
	var current_text := ""
	for letter in text:
		current_text += letter
		label.text = current_text + "|"
		await get_tree().create_timer(0.1).timeout
	await blink_text_with_caret(false, 3, label, text)


func blink_text_with_caret(caret_first: bool, n: int, label: Label3D, text: String = "") -> void:
	var caret_1 := "|" if caret_first else ""
	var caret_2 := "" if caret_first else "|"
	for _n: int in n:
		label.text = text + caret_1
		await get_tree().create_timer(0.5).timeout
		label.text = text + caret_2
		await get_tree().create_timer(0.5).timeout


func update_red_dither(value: float) -> void:
	camera_shader.get_surface_override_material(0).set_shader_parameter("red_dither", value)


func update_green_dither(value: float) -> void:
	camera_shader.get_surface_override_material(0).set_shader_parameter("green_dither", value)


func update_blue_dither(value: float) -> void:
	camera_shader.get_surface_override_material(0).set_shader_parameter("blue_dither", value)


func update_red_albedo(value: float) -> void:
	table_slice.material_override["shader_parameter/red_albedo"] = value
	inverse_table_slice.material_override["shader_parameter/red_albedo"] = value


func update_green_albedo(value: float) -> void:
	table_slice.material_override["shader_parameter/green_albedo"] = value
	inverse_table_slice.material_override["shader_parameter/green_albedo"] = value


func update_blue_albedo(value: float) -> void:
	table_slice.material_override["shader_parameter/blue_albedo"] = value
	inverse_table_slice.material_override["shader_parameter/blue_albedo"] = value


func match_cutscene() -> void:
	const FINAL_POS := Vector3(0.4, 0.5, -10)
	const FINAL_ROT := Vector3(55, 11.6, 0)
	var initial_pos := player_camera.global_position
	var initial_rot := player_camera.global_rotation_degrees
	for n: PackedFloat64Array in [
		[1. / 10., 2. / 10.],
		[3. / 10., 4. / 10.],
		[5. / 10., 6. / 10.],
		[7. / 10., 8. / 10.],
		[9. / 10., 1]
	]:
		var tween := get_tree().create_tween().set_parallel()
		tween.tween_property(
			player_camera,
			"global_position",
			UTILS.interpolate_vector(n[0], FINAL_POS, initial_pos),
			0.5
		)
		tween.tween_property(
			player_camera,
			"global_rotation_degrees",
			UTILS.interpolate_vector(n[0], FINAL_ROT, initial_rot),
			0.5
		)
		await get_tree().create_timer(0.5).timeout

		tween.stop()
		player_camera.fov -= 6
		player_camera.global_position = UTILS.interpolate_vector(n[1], FINAL_POS, initial_pos)
		player_camera.global_rotation_degrees = UTILS.interpolate_vector(
			n[1], FINAL_ROT, initial_rot
		)

	emit_signal("timeline_adjustable", true)
	timeline.visible = true
	identification.visible = true


func end_cutscene() -> void:
	emit_signal("timeline_adjustable", false)
	timeline.visible = false
	var tween := get_tree().create_tween().set_parallel()
	tween.tween_property(player_camera, "global_position", Vector3(0, 7.5, -44.5), 2.5)
	tween.tween_property(player_camera, "global_rotation_degrees", Vector3(-90, 11.6, 0), 2.5)
