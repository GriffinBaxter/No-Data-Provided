extends Node

signal timeline_adjustable

const UTILS := preload("res://Scripts/utils.gd")

@onready var level: Node3D = $".."
@onready var player: CharacterBody3D = $"../Player"
@onready var camera_shader: MeshInstance3D = $"../CameraShader"
@onready var animation_player: AnimationPlayer = $"../AnimationPlayer"
@onready var last_medium_presents: Label3D = $"../Hallway/LastMediumPresentsLabel3D"
@onready var no_data_provided: Label3D = $"../Hallway/NoDataProvidedLabel3D"
@onready var chapter_one: Label3D = $"../Hallway/TableWithSlice/Table/ChapterLabel3D"
@onready var recall: Label3D = $"../Hallway/TableWithSlice/Table/ChapterTitleLabel3D"
@onready var fade_in_out: Control = $"../FadeInOut"
@onready var colour_rect: ColorRect = $"../FadeInOut/ColorRect"

@onready var player_camera: Camera3D = $"../Player/Head/Camera3D"
@onready var hallway: Node3D = $"../Hallway"
@onready var slicer: MeshInstance3D = $"../Hallway/TableWithSlice/Slicer"
@onready var inverse_slicer: MeshInstance3D = $"../Hallway/TableWithInverseSlice/Slicer"
@onready var table_slice: MeshInstance3D = $"../Hallway/TableWithSlice/Table"
@onready var inverse_table_slice: MeshInstance3D = $"../Hallway/TableWithInverseSlice/TableSlice"
@onready var identification: Node3D = $"../Hallway/Identification"
@onready
var wall_closing_dust_particles: GPUParticles3D = $"../Hallway/Walls/WallClosingDustParticles"
@onready var cutscenes: Node = $"../Cutscenes"


func _ready() -> void:
	timeline_adjustable.connect(player.update_can_use_timeline as Callable)


func intro_cutscene() -> void:
	last_medium_presents.visible = true
	player_camera.fov = 50
	fade_in_out.visible = true
	colour_rect.color = Color(0, 0, 0, 1)
	var tween := get_tree().create_tween().set_ease(Tween.EASE_OUT)
	tween.tween_property(colour_rect, "color", Color(0, 0, 0, 0), 3)
	level.blink_text_with_caret(3, last_medium_presents)
	cutscenes.setup_motion_cutscene(
		"Hallway/last_medium_presents.bvh", level.Motion.LAST_MEDIUM_PRESENTS, 10
	)
	await get_tree().create_timer(3).timeout

	fade_in_out.visible = false
	await level.letter_by_letter(last_medium_presents, "last medium presents")

	last_medium_presents.visible = false
	no_data_provided.visible = true
	cutscenes.setup_motion_cutscene(
		"Hallway/no_data_provided.bvh", level.Motion.NO_DATA_PROVIDED, 6.6
	)
	await level.letter_by_letter(no_data_provided, "no data provided")

	no_data_provided.visible = false
	player_camera.fov = 80
	level.update_red_dither(1.6)
	level.update_green_dither(0.15)
	level.update_blue_dither(0.1)
	animation_player.play("hallway_intro")
	cutscenes.setup_motion_cutscene("Hallway/intro.bvh", level.Motion.HALLWAY_INTRO, 4.75, 0.1)
	await get_tree().create_timer(4.75).timeout

	wall_closing_dust_particles.emitting = true
	await get_tree().create_timer(0.25).timeout


func match_animation() -> void:
	hallway.picked_up = false
	var tween_1 := get_tree().create_tween().set_parallel()
	tween_1.tween_method(
		level.update_red_albedo as Callable,
		table_slice.material_override["shader_parameter/red_albedo"],
		5,
		1
	)
	tween_1.tween_method(
		level.update_green_albedo as Callable,
		table_slice.material_override["shader_parameter/green_albedo"],
		5,
		1
	)
	tween_1.tween_method(
		level.update_blue_albedo as Callable,
		table_slice.material_override["shader_parameter/blue_albedo"],
		5,
		1
	)
	tween_1.tween_property(inverse_table_slice, "global_position", table_slice.global_position, 1)
	tween_1.tween_property(inverse_slicer, "global_position", slicer.global_position, 1)
	tween_1.tween_property(inverse_table_slice, "rotation", table_slice.rotation, 1)
	tween_1.tween_property(inverse_slicer, "rotation", slicer.rotation, 1)
	await get_tree().create_timer(1).timeout

	inverse_table_slice.visible = false
	slicer.global_position += Vector3(0, 0.65, 0)
	var tween_2 := get_tree().create_tween().set_parallel()
	(
		tween_2
		. tween_method(
			level.update_red_dither as Callable,
			camera_shader.get_surface_override_material(0).get_shader_parameter("red_dither"),
			2,
			1,
		)
	)
	(
		tween_2
		. tween_method(
			level.update_green_dither as Callable,
			camera_shader.get_surface_override_material(0).get_shader_parameter("green_dither"),
			2,
			1,
		)
	)
	(
		tween_2
		. tween_method(
			level.update_blue_dither as Callable,
			camera_shader.get_surface_override_material(0).get_shader_parameter("blue_dither"),
			2,
			1,
		)
	)
	(
		tween_2
		. tween_method(
			level.update_dither_amount as Callable,
			camera_shader.get_surface_override_material(0).get_shader_parameter("amount"),
			0.05,
			1,
		)
	)
	tween_2.tween_method(
		level.update_red_albedo as Callable,
		table_slice.material_override["shader_parameter/red_albedo"],
		0,
		1
	)
	tween_2.tween_method(
		level.update_green_albedo as Callable,
		table_slice.material_override["shader_parameter/green_albedo"],
		0,
		1
	)
	tween_2.tween_method(
		level.update_blue_albedo as Callable,
		table_slice.material_override["shader_parameter/blue_albedo"],
		0,
		1
	)
	await get_tree().create_timer(1).timeout

	tween_1.stop()
	tween_2.stop()
	inverse_table_slice.visible = false


func match_cutscene() -> void:
	var timeline_bvh := UTILS.get_bvh_dictionary("Hallway/timeline.bvh")
	var final_pos := (
		timeline_bvh.position[0] - timeline_bvh.position[-1] + Vector3(0, 1.75, -10) as Vector3
	)
	var final_rot := timeline_bvh.rotation[0] - timeline_bvh.rotation[-1] as Vector3
	var initial_pos: Vector3 = player_camera.global_position
	var initial_rot: Vector3 = player_camera.global_rotation_degrees
	for n: PackedFloat64Array in [
		[1. / 9., 2. / 9.],
		[3. / 9., 4. / 9.],
		[5. / 9., 6. / 9.],
		[7. / 9., 8. / 9.],
	]:
		await level.match_tweens(n[0], final_pos, initial_pos, final_rot, initial_rot)

		player_camera.fov -= 6
		player_camera.global_position = UTILS.interpolate_vector(n[1], final_pos, initial_pos)
		player_camera.global_rotation_degrees = UTILS.interpolate_vector(
			n[1], final_rot, initial_rot
		)

	await level.match_tweens(1, final_pos, initial_pos, final_rot, initial_rot)

	emit_signal("timeline_adjustable", true)
	level.timeline_out_in_animation(false)
	identification.visible = true


func end_cutscene() -> void:
	emit_signal("timeline_adjustable", false)
	level.timeline_out_in_animation(true)
	fade_in_out.visible = true
	var tween_1 := get_tree().create_tween().set_parallel()
	tween_1.tween_property(player_camera, "global_position", Vector3(0, 7.5, -44.5), 13)
	tween_1.tween_property(player_camera, "global_rotation_degrees", Vector3(-90, 11.6, 0), 13)
	recall.visible = true
	await level.letter_by_letter(recall, "recall")

	await get_tree().create_timer(1).timeout

	chapter_one.visible = true
	level.letter_by_letter(chapter_one, "chapter one")
	await get_tree().create_timer(2).timeout

	var tween_2 := get_tree().create_tween().set_ease(Tween.EASE_IN)
	tween_2.tween_property(colour_rect, "color", Color(0, 0, 0, 1), 4.1)
