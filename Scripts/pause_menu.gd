extends Control

@onready var level = $".."
@onready var player = $"../Control/AspectRatioContainer/SubViewportContainer/SubViewport/Player"

var main_menu = "res://Scenes/main_menu.tscn"

signal save_player_position

func _on_resume_pressed():
	level.pauseMenu()

func _on_save_pressed():
	emit_signal("save_player_position", [player.position.x, player.position.y, player.position.z])

func _on_return_to_menu_pressed():
	get_tree().change_scene_to_file(main_menu)

func _on_quit_pressed():
	get_tree().quit()
