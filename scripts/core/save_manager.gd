extends Node

const SAVE_PATH := "user://ironveil_save.json"

func save_game(player: Node3D) -> bool:
	var data := GameState.snapshot()
	data["player_position"] = [player.global_position.x, player.global_position.y, player.global_position.z]
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		GameState.notify("Could not open save file.", "error")
		return false
	file.store_string(JSON.stringify(data, "\t"))
	file.close()
	GameState.notify("Game saved.", "success")
	return true

func load_game(player: Node3D) -> bool:
	if not FileAccess.file_exists(SAVE_PATH):
		GameState.notify("No save found.", "error")
		return false
	var parsed = JSON.parse_string(FileAccess.get_file_as_string(SAVE_PATH))
	if typeof(parsed) != TYPE_DICTIONARY:
		GameState.notify("Save file is invalid.", "error")
		return false
	GameState.restore(parsed)
	var p: Array = parsed.get("player_position", [0.0, 1.0, 0.0])
	if p.size() >= 3:
		player.global_position = Vector3(float(p[0]), float(p[1]), float(p[2]))
	GameState.notify("Game loaded.", "success")
	return true
