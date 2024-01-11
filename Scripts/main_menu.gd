extends Control

var level = "res://Scenes/level.tscn"
var save_exists = false

@onready var continue_button = $MarginContainer/VBoxContainer/Continue


func _ready():
	update_save_exists()


func update_save_exists():
	save_exists = FileAccess.file_exists("user://01.save")
	continue_button.disabled = not save_exists


func _on_continue_pressed():
	update_save_exists()
	if save_exists:
		get_tree().change_scene_to_file(level)


func _on_new_pressed():
	DirAccess.remove_absolute("user://01.save")
	get_tree().change_scene_to_file(level)


func _on_quit_pressed():
	get_tree().quit()
