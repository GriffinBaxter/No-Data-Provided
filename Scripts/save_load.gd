extends Node

@onready var smm = $"../SMMCamera3D/SMMTriggerArea3D"
@onready var pause_menu = $"../PauseMenu"

func _ready():
	smm.autosave.connect(save_game)
	pause_menu.save_player_position.connect(save_game_player_position)

func save_game(level, state, player_position):
	save_game_to_file({
		"level": level,
		"state": state,
		"player_position": player_position,
	})

func save_game_player_position(player_position):
	var save = load_game()  # fails when save is empty file, should be fixed once loading is fully implemented
	save.player_position = player_position
	save_game_to_file(save)

func save_game_to_file(save):
	var save_game = FileAccess.open("user://01.save", FileAccess.WRITE)
	var json_string = JSON.stringify(save)
	save_game.store_line(json_string)
	save_game.close()

func load_game():
	if FileAccess.file_exists("user://01.save"):
		var save_game = FileAccess.open("user://01.save", FileAccess.READ)
		var json_string =  save_game.get_line()
		var json = JSON.new()
		var parse_result = json.parse(json_string)
		var node_data = json.get_data()
		save_game.close()
		return node_data
