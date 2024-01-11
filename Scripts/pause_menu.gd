extends Control

signal save_player_position

var main_menu = "res://Scenes/main_menu.tscn"

@onready var level = $".."
@onready var player = $"../Player"


func _on_resume_pressed():
	level.pauseMenu()


func _on_save_pressed():
	emit_signal("save_player_position", [player.position.x, player.position.y, player.position.z])


func _on_return_to_menu_pressed():
	get_tree().change_scene_to_file(main_menu)


func _on_quit_pressed():
	get_tree().quit()
