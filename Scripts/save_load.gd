extends Node

signal load

const SAVE_DIRECTORY := "user://01.save"
const DEV_SAVE_DIRECTORY := "user://dev.save"
const DEFAULT_SAVE := {
	"level": 0,
	"state": 0,
	"player_position": Vector3(0, 1, 0),
}

@onready var level_node: Node3D = $".."
@onready var pause_menu: Control = $"../PauseMenu"


func _ready() -> void:
	level_node.autosave.connect(save_game)
	pause_menu.save_player_position.connect(save_game_player_position)
	level_node.level_node_ready.connect(level_ready)


func level_ready() -> void:
	emit_signal("load", load_game())


func save_game(level: int, state: int, player_position: Vector3) -> void:
	save_game_to_file(
		{
			"level": level,
			"state": state,
			"player_position": player_position,
		}
	)


func save_game_player_position(player_position: Vector3) -> void:
	var save := load_game()
	save.player_position = player_position
	save_game_to_file(save)


func save_game_to_file(save: Dictionary) -> void:
	var current_save := FileAccess.open(SAVE_DIRECTORY, FileAccess.WRITE)
	var save_string := var_to_str(save)
	current_save.store_line(save_string)
	current_save.close()


func load_game() -> Dictionary:
	for dir: String in [DEV_SAVE_DIRECTORY, SAVE_DIRECTORY]:
		if FileAccess.file_exists(dir):
			var current_save := FileAccess.open(dir, FileAccess.READ)
			var save_string := ""
			while not current_save.eof_reached():
				save_string += current_save.get_line()
			current_save.close()
			var save: Dictionary = str_to_var(save_string)
			if save:
				return save
	return DEFAULT_SAVE
