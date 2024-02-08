extends Node

signal load

const SAVE_DIRECTORY = "user://01.save"
const DEV_SAVE_DIRECTORY = "user://dev.save"
const DEFAULT_SAVE = {
	"level": 0,
	"state": 0,
	"player_position": [0, 1, 0],
}

@onready var level_node = $".."
@onready var pause_menu = $"../PauseMenu"


func _ready():
	level_node.autosave.connect(save_game)
	pause_menu.save_player_position.connect(save_game_player_position)
	level_node.level_node_ready.connect(level_ready)


func level_ready():
	emit_signal("load", load_game())


func save_game(level, state, player_position):
	save_game_to_file(
		{
			"level": level,
			"state": state,
			"player_position": player_position,
		}
	)


func save_game_player_position(player_position):
	var save = load_game()
	save.player_position = player_position
	save_game_to_file(save)


func save_game_to_file(save):
	var current_save = FileAccess.open(SAVE_DIRECTORY, FileAccess.WRITE)
	var json_string = JSON.stringify(save)
	current_save.store_line(json_string)
	current_save.close()


func load_game():
	for dir in [DEV_SAVE_DIRECTORY, SAVE_DIRECTORY]:
		if FileAccess.file_exists(dir):
			var current_save = FileAccess.open(dir, FileAccess.READ)
			var json_string = current_save.get_line()
			var json = JSON.new()
			json.parse(json_string)
			var node_data = json.get_data()
			current_save.close()
			if node_data:
				return node_data
	return DEFAULT_SAVE
