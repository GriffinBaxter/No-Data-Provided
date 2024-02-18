extends Node

signal load

const SAVE_DIRECTORY: String = "user://01.save"
const DEV_SAVE_DIRECTORY: String = "user://dev.save"
const DEFAULT_SAVE: Dictionary = {
	"level": 0,
	"state": 0,
	"player_position": [0, 1, 0],
}

@onready var level_node: Node3D = $".."
@onready var pause_menu: Control = $"../PauseMenu"


func _ready() -> void:
	level_node.autosave.connect(save_game)
	pause_menu.save_player_position.connect(save_game_player_position)
	level_node.level_node_ready.connect(level_ready)


func level_ready() -> void:
	emit_signal("load", load_game())


func save_game(level: int, state: int, player_position: PackedFloat64Array) -> void:
	save_game_to_file(
		{
			"level": level,
			"state": state,
			"player_position": player_position,
		}
	)


func save_game_player_position(player_position: PackedFloat64Array) -> void:
	var save: Dictionary = load_game()
	save.player_position = player_position
	save_game_to_file(save)


func save_game_to_file(save: Dictionary) -> void:
	var current_save: FileAccess = FileAccess.open(SAVE_DIRECTORY, FileAccess.WRITE)
	var json_string: String = JSON.stringify(save)
	current_save.store_line(json_string)
	current_save.close()


func load_game() -> Dictionary:
	for dir: String in [DEV_SAVE_DIRECTORY, SAVE_DIRECTORY]:
		if FileAccess.file_exists(dir):
			var current_save: FileAccess = FileAccess.open(dir, FileAccess.READ)
			var json_string: String = current_save.get_line()
			var json: JSON = JSON.new()
			json.parse(json_string)
			var node_data: Dictionary = json.get_data()
			current_save.close()
			if node_data:
				return node_data
	return DEFAULT_SAVE
