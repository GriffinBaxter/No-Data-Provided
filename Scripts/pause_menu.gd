extends Control

signal save_player_position

const MAIN_MENU := "res://Scenes/main_menu.tscn"

@onready var level: Node3D = $".."
@onready var player: CharacterBody3D = $"../Player"


func _on_resume_pressed() -> void:
	level.pause_menu()


func _on_save_pressed() -> void:
	emit_signal("save_player_position", player.position)


func _on_return_to_menu_pressed() -> void:
	get_tree().change_scene_to_file(MAIN_MENU)


func _on_quit_pressed() -> void:
	get_tree().quit()
