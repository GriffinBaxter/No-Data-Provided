extends Node3D

signal level_node_ready
signal movable
signal timeline_adjustable
signal autosave

enum State { BEFORE_INTRO_CUTSCENE, AFTER_INTRO_CUTSCENE, MATCH_ANIMATION, MATCH }
enum Motion { NONE, LAST_MEDIUM_PRESENTS, NO_DATA_PROVIDED, HALLWAY_INTRO }

const UTILS := preload("res://Scripts/utils.gd")
const STATES_MOVEABLE: Array[State] = [State.AFTER_INTRO_CUTSCENE, State.MATCH_ANIMATION]
const STATES_SAVABLE: Array[State] = [
	State.BEFORE_INTRO_CUTSCENE, State.AFTER_INTRO_CUTSCENE, State.MATCH
]
const MOTION_FINAL_AND_INITIAL_DELTA := {
	Motion.LAST_MEDIUM_PRESENTS: [Vector3(0, -1, 1), Vector3(70, 0, 0)],
	Motion.NO_DATA_PROVIDED: [Vector3(1.5, 2.75, -48.5), Vector3(0, 150, 0)],
	Motion.HALLWAY_INTRO: [Vector3(0, 1.75, 0), Vector3(0, -180, 0), Vector3(0, 0, -6)],
}
const LEVEL := 0

var paused := false
var state: State = State.BEFORE_INTRO_CUTSCENE
var current_motion: Motion = Motion.NONE
var player_entered_area := false
var interacted_with_identification := false
var timer: Timer
var bvh: Dictionary

var intro_cutscene_started := false
var end_cutscene_started := false

@onready var pause_menu_node: Control = $PauseMenu

@onready var player: CharacterBody3D = $Player
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var camera_shader: MeshInstance3D = $CameraShader
@onready var last_medium_presents: Label3D = $LastMediumPresentsLabel3D
@onready var no_data_provided: Label3D = $NoDataProvidedLabel3D
@onready var chapter_one: Label3D = $TableWithSlice/Table/ChapterLabel3D
@onready var recall: Label3D = $TableWithSlice/Table/ChapterTitleLabel3D
@onready var fade_in_out: Control = $FadeInOut
@onready var colour_rect: ColorRect = $FadeInOut/ColorRect

@onready var timeline: Node3D = $Viewport/SubViewportContainer/SubViewport/Camera3DNoShader/Timeline
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
		last_medium_presents.visible = true
		player_camera.fov = 50
		fade_in_out.visible = true
		colour_rect.color = Color(0, 0, 0, 1)
		var tween := get_tree().create_tween().set_ease(Tween.EASE_OUT)
		tween.tween_property(colour_rect, "color", Color(0, 0, 0, 0), 3)
		blink_text_with_caret(3, last_medium_presents)
		setup_motion_cutscene("Hallway/last_medium_presents.bvh", Motion.LAST_MEDIUM_PRESENTS, 10)
		await get_tree().create_timer(3).timeout

		fade_in_out.visible = false
		await letter_by_letter(last_medium_presents, "last medium presents")

		last_medium_presents.visible = false
		no_data_provided.visible = true
		setup_motion_cutscene("Hallway/no_data_provided.bvh", Motion.NO_DATA_PROVIDED, 6.6)
		await letter_by_letter(no_data_provided, "no data provided")

		no_data_provided.visible = false
		player_camera.fov = 80
		animation_player.play("hallway_intro")
		setup_motion_cutscene("Hallway/intro.bvh", Motion.HALLWAY_INTRO, 4.75, 0.1)
		await get_tree().create_timer(4.75).timeout

		wall_closing_dust_particles.emitting = true
		await get_tree().create_timer(0.25).timeout

		update_state(State.AFTER_INTRO_CUTSCENE)

	if current_motion != Motion.NONE:
		update_camera_with_motion(
			MOTION_FINAL_AND_INITIAL_DELTA[current_motion][0] as Vector3,
			MOTION_FINAL_AND_INITIAL_DELTA[current_motion][1] as Vector3,
			(
				MOTION_FINAL_AND_INITIAL_DELTA[current_motion][2] as Vector3
				if MOTION_FINAL_AND_INITIAL_DELTA[current_motion].size() >= 3
				else Vector3(0, 0, 0)
			),
			(
				MOTION_FINAL_AND_INITIAL_DELTA[current_motion][3] as Vector3
				if MOTION_FINAL_AND_INITIAL_DELTA[current_motion].size() >= 4
				else Vector3(0, 0, 0)
			),
		)

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

	if (
		!end_cutscene_started
		and interacted_with_identification
		and player.progress >= player.JUST_UNDER_ONE
	):
		end_cutscene()


func pause_menu() -> void:
	paused = !paused
	player_camera.attributes.dof_blur_far_enabled = !paused
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
	await blink_text_with_caret(2, label)
	var current_text := ""
	for letter in text:
		current_text += letter
		label.text = current_text + "|"
		await get_tree().create_timer(0.1).timeout
	await blink_text_with_caret(3, label, text)


func blink_text_with_caret(n: int, label: Label3D, text: String = "") -> void:
	for _n: int in n:
		label.text = text
		await get_tree().create_timer(0.5).timeout
		label.text = text + "|"
		await get_tree().create_timer(0.5).timeout
	label.text = text


func setup_motion_cutscene(
	path: String, motion: Motion, custom_time: float = 0, resolution: float = 1
) -> void:
	bvh = UTILS.get_bvh_dictionary(path, custom_time, resolution)
	setup_timer(bvh.time as float)
	current_motion = motion


func setup_timer(wait_time: float) -> void:
	timer = Timer.new()
	add_child(timer)
	timer.one_shot = true
	timer.autostart = true
	timer.wait_time = wait_time
	timer.start()


func update_camera_with_motion(
	final_position: Vector3,
	final_rotation: Vector3,
	initial_position_delta: Vector3,
	initial_rotation_delta: Vector3,
) -> void:
	if timer.time_left <= 0 and current_motion != Motion.NONE:
		current_motion = Motion.NONE
	else:
		var progress: float = (bvh.time - timer.time_left) / bvh.time
		player_camera.global_position = (
			UTILS.piecewise_linear_interpolation(bvh.position as PackedVector3Array, progress)
			- bvh.position[-1]
			+ final_position
			+ (1 - progress) * initial_position_delta
		)
		player_camera.global_rotation_degrees = (
			UTILS.piecewise_linear_interpolation(bvh.rotation as PackedVector3Array, progress)
			- bvh.rotation[-1]
			+ final_rotation
			+ (1 - progress) * initial_rotation_delta
		)


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
	var timeline_bvh := UTILS.get_bvh_dictionary("Hallway/timeline.bvh")
	var final_pos := (
		timeline_bvh.position[0] - timeline_bvh.position[-1] + Vector3(0, 1.75, -10) as Vector3
	)
	var final_rot := timeline_bvh.rotation[0] - timeline_bvh.rotation[-1] as Vector3
	var initial_pos := player_camera.global_position
	var initial_rot := player_camera.global_rotation_degrees
	for n: PackedFloat64Array in [
		[1. / 9., 2. / 9.],
		[3. / 9., 4. / 9.],
		[5. / 9., 6. / 9.],
		[7. / 9., 8. / 9.],
	]:
		await match_tweens(n[0], final_pos, initial_pos, final_rot, initial_rot)

		player_camera.fov -= 6
		player_camera.global_position = UTILS.interpolate_vector(n[1], final_pos, initial_pos)
		player_camera.global_rotation_degrees = UTILS.interpolate_vector(
			n[1], final_rot, initial_rot
		)

	await match_tweens(1, final_pos, initial_pos, final_rot, initial_rot)

	emit_signal("timeline_adjustable", true)
	timeline_out_in_animation(false)
	identification.visible = true


func match_tweens(
	n: float, final_pos: Vector3, initial_pos: Vector3, final_rot: Vector3, initial_rot: Vector3
) -> void:
	var tween := get_tree().create_tween().set_parallel()
	tween.tween_property(
		player_camera, "global_position", UTILS.interpolate_vector(n, final_pos, initial_pos), 0.5
	)
	tween.tween_property(
		player_camera,
		"global_rotation_degrees",
		UTILS.interpolate_vector(n, final_rot, initial_rot),
		0.5
	)
	await get_tree().create_timer(0.5).timeout

	tween.stop()


func timeline_out_in_animation(out: bool) -> void:
	const OUT_POS = Vector3(0, -0.25, -0.45)
	const IN_POS = Vector3(0, -0.15, -0.45)
	var timeline_tween := get_tree().create_tween()
	if out:
		timeline_tween.tween_property(timeline, "position", OUT_POS, 0.5)
		await get_tree().create_timer(0.5).timeout

		timeline.visible = false
	else:
		timeline.position = OUT_POS
		timeline.visible = true
		timeline_tween.tween_property(timeline, "position", IN_POS, 0.5)
		await get_tree().create_timer(0.5).timeout
	timeline_tween.stop()


func end_cutscene() -> void:
	end_cutscene_started = true
	emit_signal("timeline_adjustable", false)
	timeline_out_in_animation(true)
	fade_in_out.visible = true
	var tween_1 := get_tree().create_tween().set_parallel()
	tween_1.tween_property(player_camera, "global_position", Vector3(0, 7.5, -44.5), 13)
	tween_1.tween_property(player_camera, "global_rotation_degrees", Vector3(-90, 11.6, 0), 13)
	recall.visible = true
	await letter_by_letter(recall, "recall")

	await get_tree().create_timer(1).timeout

	chapter_one.visible = true
	letter_by_letter(chapter_one, "chapter one")
	await get_tree().create_timer(2).timeout

	var tween_2 := get_tree().create_tween().set_ease(Tween.EASE_IN)
	tween_2.tween_property(colour_rect, "color", Color(0, 0, 0, 1), 4.1)
