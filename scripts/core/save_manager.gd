extends Node

const SAVE_PATH := "user://ironveil_save.json"

func save_game(player: Node3D) -> bool:
	var data: Dictionary = GameState.snapshot()
	data["player_position"] = [player.global_position.x, player.global_position.y, player.global_position.z]
	var file: FileAccess = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
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
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(SAVE_PATH))
	if not (parsed is Dictionary):
		GameState.notify("Save file is invalid.", "error")
		return false
	var save_data: Dictionary = parsed
	GameState.restore(save_data)
	var position_value: Variant = save_data.get("player_position", [0.0, 1.0, 0.0])
	var p: Array = []
	if position_value is Array:
		p = position_value as Array
	if p.size() >= 3:
		player.global_position = Vector3(float(p[0]), float(p[1]), float(p[2]))
	GameState.notify("Game loaded.", "success")
	return true
