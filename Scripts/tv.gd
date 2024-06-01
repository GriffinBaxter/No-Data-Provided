extends Node3D

enum Motion { NONE, LAST_MEDIUM_PRESENTS, NO_DATA_PROVIDED }

const CAMERA_MOTIONS := {
	Motion.LAST_MEDIUM_PRESENTS: {"final_pos": Vector3(0, -1, 1), "final_rot": Vector3(70, 0, 0)},
	Motion.NO_DATA_PROVIDED:
	{"final_pos": Vector3(1.5, 2.75, -48.5), "final_rot": Vector3(0, 150, 0)},
}

var current_motion: Motion = Motion.NONE

@onready var cutscenes: Node = $Cutscenes

@onready var last_medium_presents: Label3D = $HallwaySubViewport/Hallway/LastMediumPresentsLabel3D
@onready var hallway_camera: Camera3D = $HallwaySubViewport/Hallway/Camera3D
@onready var no_data_provided: Label3D = $HallwaySubViewport/Hallway/NoDataProvidedLabel3D
@onready var fade_in_out: Control = $FadeInOut
@onready var colour_rect: ColorRect = $FadeInOut/ColorRect


func _ready() -> void:
	await intro_security_cam_cutscene()


func _process(_delta: float) -> void:
	if current_motion != Motion.NONE:
		cutscenes.update_camera_with_motion(CAMERA_MOTIONS[current_motion] as Dictionary)


func intro_security_cam_cutscene() -> void:
	last_medium_presents.visible = true
	hallway_camera.fov = 50
	fade_in_out.visible = true
	colour_rect.color = Color(0, 0, 0, 1)
	var tween := get_tree().create_tween().set_ease(Tween.EASE_OUT)
	tween.tween_property(colour_rect, "color", Color(0, 0, 0, 0), 3)
	cutscenes.blink_text_with_caret(3, last_medium_presents)
	cutscenes.setup_motion_cutscene(
		"Hallway/last_medium_presents.bvh", Motion.LAST_MEDIUM_PRESENTS, 10
	)
	await get_tree().create_timer(3).timeout

	fade_in_out.visible = false
	await cutscenes.letter_by_letter(last_medium_presents, "last medium presents")

	last_medium_presents.visible = false
	no_data_provided.visible = true
	cutscenes.setup_motion_cutscene("Hallway/no_data_provided.bvh", Motion.NO_DATA_PROVIDED, 6.6)
	await cutscenes.letter_by_letter(no_data_provided, "no data provided")
