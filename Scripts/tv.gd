extends Node3D

enum Motion { NONE, GRIFFIN_BAXTER_PRESENTS, NO_DATA_PROVIDED }

const CAMERA_MOTIONS := {
	Motion.GRIFFIN_BAXTER_PRESENTS:
	{"final_pos": Vector3(0, -1, 1), "final_rot": Vector3(70, 0, 0)},
	Motion.NO_DATA_PROVIDED:
	{"final_pos": Vector3(1.5, 2.75, -48.5), "final_rot": Vector3(0, 150, 0)},
}

var current_motion: Motion = Motion.NONE

@onready var cutscenes: Node = $Cutscenes
@onready
var griffin_baxter_presents: Label3D = $HallwaySubViewport/Hallway/GriffinBaxterPresentsLabel3D
@onready var hallway_camera: Camera3D = $HallwaySubViewport/Hallway/Camera3D
@onready var no_data_provided: Label3D = $HallwaySubViewport/Hallway/NoDataProvidedLabel3D
@onready var fade_in_out: Control = $FadeInOut
@onready var colour_rect: ColorRect = $FadeInOut/ColorRect


func _ready() -> void:
	await intro_security_cam_cutscene()


func _process(_delta: float) -> void:
	if current_motion != Motion.NONE:
		cutscenes.update_camera_with_motion(CAMERA_MOTIONS[current_motion] as Dictionary)
	if Input.is_physical_key_pressed(KEY_SPACE) or Input.is_physical_key_pressed(KEY_ESCAPE):
		go_to_main_menu()


func intro_security_cam_cutscene() -> void:
	griffin_baxter_presents.visible = true
	hallway_camera.fov = 50
	fade_in_out.visible = true
	colour_rect.color = Color(0, 0, 0, 1)
	var tween := get_tree().create_tween().set_ease(Tween.EASE_OUT)
	tween.tween_property(colour_rect, "color", Color(0, 0, 0, 0), 3)
	cutscenes.blink_text_with_caret(3, griffin_baxter_presents)
	cutscenes.setup_motion_cutscene(
		"Hallway/griffin_baxter_presents.bvh", Motion.GRIFFIN_BAXTER_PRESENTS, 10
	)
	await get_tree().create_timer(3).timeout

	fade_in_out.visible = false
	await cutscenes.letter_by_letter(griffin_baxter_presents, "griffin baxter presents")

	griffin_baxter_presents.visible = false
	no_data_provided.visible = true
	cutscenes.setup_motion_cutscene("Hallway/no_data_provided.bvh", Motion.NO_DATA_PROVIDED, 6.6)
	cutscenes.letter_by_letter(no_data_provided, "no data provided")
	await get_tree().create_timer(6.6).timeout

	go_to_main_menu()


func go_to_main_menu() -> void:
	get_tree().change_scene_to_file("res://Scenes/main_menu.tscn")
