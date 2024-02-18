extends Control

const LEVEL: String = "res://Scenes/level.tscn"

var save_exists: bool = false

@onready var continue_button: Button = $MarginContainer/VBoxContainer/Continue


func _ready() -> void:
	update_save_exists()


func update_save_exists() -> void:
	save_exists = FileAccess.file_exists("user://01.save")
	continue_button.disabled = not save_exists


func _on_continue_pressed() -> void:
	update_save_exists()
	if save_exists:
		get_tree().change_scene_to_file(LEVEL)


func _on_new_pressed() -> void:
	DirAccess.remove_absolute("user://01.save")
	get_tree().change_scene_to_file(LEVEL)


func _on_quit_pressed() -> void:
	get_tree().quit()
