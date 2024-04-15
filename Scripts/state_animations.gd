extends Node

signal timeline_adjustable

const UTILS := preload("res://Scripts/utils.gd")

@onready var level: Node3D = $".."
@onready var player: CharacterBody3D = $"../Player"

func _ready() -> void:
	timeline_adjustable.connect(player.update_can_use_timeline as Callable)


func intro_cutscene() -> void:
	level.last_medium_presents.visible = true
	level.player_camera.fov = 50
	level.fade_in_out.visible = true
	level.colour_rect.color = Color(0, 0, 0, 1)
	var tween := get_tree().create_tween().set_ease(Tween.EASE_OUT)
	tween.tween_property(level.colour_rect as ColorRect, "color", Color(0, 0, 0, 0), 3)
	level.blink_text_with_caret(3, level.last_medium_presents)
	level.setup_motion_cutscene(
		"Hallway/last_medium_presents.bvh", level.Motion.LAST_MEDIUM_PRESENTS, 10
	)
	await get_tree().create_timer(3).timeout

	level.fade_in_out.visible = false
	await level.letter_by_letter(level.last_medium_presents, "last medium presents")

	level.last_medium_presents.visible = false
	level.no_data_provided.visible = true
	level.setup_motion_cutscene("Hallway/no_data_provided.bvh", level.Motion.NO_DATA_PROVIDED, 6.6)
	await level.letter_by_letter(level.no_data_provided, "no data provided")

	level.no_data_provided.visible = false
	level.player_camera.fov = 80
	level.update_red_dither(1.6)
	level.update_green_dither(0.15)
	level.update_blue_dither(0.1)
	level.animation_player.play("hallway_intro")
	level.setup_motion_cutscene("Hallway/intro.bvh", level.Motion.HALLWAY_INTRO, 4.75, 0.1)
	await get_tree().create_timer(4.75).timeout

	level.wall_closing_dust_particles.emitting = true
	await get_tree().create_timer(0.25).timeout


func match_animation() -> void:
	level.pickup_area_3d.picked_up = false
	var tween_1 := get_tree().create_tween().set_parallel()
	tween_1.tween_method(
		level.update_red_albedo as Callable,
		level.table_slice.material_override["shader_parameter/red_albedo"],
		5,
		1
	)
	tween_1.tween_method(
		level.update_green_albedo as Callable,
		level.table_slice.material_override["shader_parameter/green_albedo"],
		5,
		1
	)
	tween_1.tween_method(
		level.update_blue_albedo as Callable,
		level.table_slice.material_override["shader_parameter/blue_albedo"],
		5,
		1
	)
	tween_1.tween_property(
		level.inverse_table_slice as MeshInstance3D,
		"global_position",
		level.table_slice.global_position,
		1
	)
	tween_1.tween_property(
		level.inverse_slicer as MeshInstance3D, "global_position", level.slicer.global_position, 1
	)
	tween_1.tween_property(
		level.inverse_table_slice as MeshInstance3D, "rotation", level.table_slice.rotation, 1
	)
	tween_1.tween_property(
		level.inverse_slicer as MeshInstance3D, "rotation", level.slicer.rotation, 1
	)
	await get_tree().create_timer(1).timeout

	level.inverse_table_slice.visible = false
	level.slicer.global_position += Vector3(0, 0.65, 0)
	var tween_2 := get_tree().create_tween().set_parallel()
	(
		tween_2
		. tween_method(
			level.update_red_dither as Callable,
			level.camera_shader.get_surface_override_material(0).get_shader_parameter("red_dither"),
			2,
			1,
		)
	)
	(
		tween_2
		. tween_method(
			level.update_green_dither as Callable,
			level.camera_shader.get_surface_override_material(0).get_shader_parameter(
				"green_dither"
			),
			2,
			1,
		)
	)
	(
		tween_2
		. tween_method(
			level.update_blue_dither as Callable,
			level.camera_shader.get_surface_override_material(0).get_shader_parameter(
				"blue_dither"
			),
			2,
			1,
		)
	)
	(
		tween_2
		. tween_method(
			level.update_dither_amount as Callable,
			level.camera_shader.get_surface_override_material(0).get_shader_parameter("amount"),
			0.05,
			1,
		)
	)
	tween_2.tween_method(
		level.update_red_albedo as Callable,
		level.table_slice.material_override["shader_parameter/red_albedo"],
		0,
		1
	)
	tween_2.tween_method(
		level.update_green_albedo as Callable,
		level.table_slice.material_override["shader_parameter/green_albedo"],
		0,
		1
	)
	tween_2.tween_method(
		level.update_blue_albedo as Callable,
		level.table_slice.material_override["shader_parameter/blue_albedo"],
		0,
		1
	)
	await get_tree().create_timer(1).timeout

	tween_1.stop()
	tween_2.stop()
	level.inverse_table_slice.visible = false


func match_cutscene() -> void:
	var timeline_bvh := UTILS.get_bvh_dictionary("Hallway/timeline.bvh")
	var final_pos := (
		timeline_bvh.position[0] - timeline_bvh.position[-1] + Vector3(0, 1.75, -10) as Vector3
	)
	var final_rot := timeline_bvh.rotation[0] - timeline_bvh.rotation[-1] as Vector3
	var initial_pos: Vector3 = level.player_camera.global_position
	var initial_rot: Vector3 = level.player_camera.global_rotation_degrees
	for n: PackedFloat64Array in [
		[1. / 9., 2. / 9.],
		[3. / 9., 4. / 9.],
		[5. / 9., 6. / 9.],
		[7. / 9., 8. / 9.],
	]:
		await level.match_tweens(n[0], final_pos, initial_pos, final_rot, initial_rot)

		level.player_camera.fov -= 6
		level.player_camera.global_position = UTILS.interpolate_vector(n[1], final_pos, initial_pos)
		level.player_camera.global_rotation_degrees = UTILS.interpolate_vector(
			n[1], final_rot, initial_rot
		)

	await level.match_tweens(1, final_pos, initial_pos, final_rot, initial_rot)

	emit_signal("timeline_adjustable", true)
	level.timeline_out_in_animation(false)
	level.identification.visible = true


func end_cutscene() -> void:
	emit_signal("timeline_adjustable", false)
	level.timeline_out_in_animation(true)
	level.fade_in_out.visible = true
	var tween_1 := get_tree().create_tween().set_parallel()
	tween_1.tween_property(
		level.player_camera as Camera3D, "global_position", Vector3(0, 7.5, -44.5), 13
	)
	tween_1.tween_property(
		level.player_camera as Camera3D, "global_rotation_degrees", Vector3(-90, 11.6, 0), 13
	)
	level.recall.visible = true
	await level.letter_by_letter(level.recall, "recall")

	await get_tree().create_timer(1).timeout

	level.chapter_one.visible = true
	level.letter_by_letter(level.chapter_one, "chapter one")
	await get_tree().create_timer(2).timeout

	var tween_2 := get_tree().create_tween().set_ease(Tween.EASE_IN)
	tween_2.tween_property(level.colour_rect as ColorRect, "color", Color(0, 0, 0, 1), 4.1)
