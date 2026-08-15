extends Node

const SAVE_PATH := "user://ironveil_save.json"
const SAVE_TEMP_PATH := "user://ironveil_save.tmp"
const BACKUP_PATH := "user://ironveil_save.backup.json"
const SAVE_VERSION := 2
const WORLD_SCHEMA_VERSION := 1
const GAME_VERSION := "1.0.0"

var _session_started_unix: int = 0

func _ready() -> void:
	_session_started_unix = int(Time.get_unix_time_from_system())

func build_snapshot(player: Node3D) -> Dictionary:
	var complete: Dictionary = GameState.snapshot()
	var player_state := {
		"inventory": complete.get("inventory", {}),
		"survival": complete.get("survival", {}),
		"injuries": complete.get("injuries", {}),
		"journal_entries": complete.get("journal_entries", []),
		"objective_step": complete.get("objective_step", 0),
		"position": [player.global_position.x, player.global_position.y, player.global_position.z],
	}
	var world_state := {
		"flags": complete.get("flags", {}),
		"world_objects": complete.get("world_objects", {}),
		"mechanical_network": complete.get("mechanical_network", {}),
		"current_region_id": complete.get("current_region_id", "green_hollow"),
		"ambient_temperature": complete.get("ambient_temperature", 18.0),
	}
	return {"world": world_state, "player": player_state}

func save_game(player: Node3D) -> bool:
	var snapshot: Dictionary = build_snapshot(player)
	var payload: String = JSON.stringify(snapshot)
	var envelope := {
		"save_version": SAVE_VERSION,
		"game_version": GAME_VERSION,
		"world_schema_version": WORLD_SCHEMA_VERSION,
		"created_at": int(Time.get_unix_time_from_system()),
		"checksum": _checksum(payload),
		"snapshot": snapshot,
	}
	var file: FileAccess = FileAccess.open(SAVE_TEMP_PATH, FileAccess.WRITE)
	if file == null:
		GameState.notify("Could not open the save checkpoint.", "error")
		return false
	file.store_string(JSON.stringify(envelope, "\t"))
	file.close()
	var absolute_save: String = ProjectSettings.globalize_path(SAVE_PATH)
	var absolute_temp: String = ProjectSettings.globalize_path(SAVE_TEMP_PATH)
	var absolute_backup: String = ProjectSettings.globalize_path(BACKUP_PATH)
	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.remove_absolute(absolute_backup)
		DirAccess.rename_absolute(absolute_save, absolute_backup)
	if DirAccess.rename_absolute(absolute_temp, absolute_save) != OK:
		GameState.notify("Atomic save commit failed; previous checkpoint remains available.", "error")
		return false
	if AccountManager.is_authenticated() and not AccountManager.active_world_id.is_empty():
		var elapsed: int = maxi(0, int(Time.get_unix_time_from_system()) - _session_started_unix)
		_session_started_unix = int(Time.get_unix_time_from_system())
		AccountManager.save_checkpoint(snapshot, GameState.current_region_id, elapsed)
		GameState.notify("Local and server checkpoints queued.", "success")
	else:
		GameState.notify("Local checkpoint saved.", "success")
	return true

func load_game(player: Node3D) -> bool:
	for path in [SAVE_PATH, BACKUP_PATH]:
		var snapshot: Dictionary = _read_checkpoint(path)
		if not snapshot.is_empty():
			apply_snapshot(snapshot, player)
			GameState.notify("Checkpoint restored.", "success")
			return true
	GameState.notify("No valid checkpoint found.", "error")
	return false

func apply_snapshot(snapshot: Dictionary, player: Node3D) -> void:
	var world_value: Variant = snapshot.get("world", {})
	var player_value: Variant = snapshot.get("player", {})
	if not (player_value is Dictionary) or (player_value as Dictionary).is_empty():
		var players_value: Variant = snapshot.get("players", {})
		if players_value is Dictionary and not AccountManager.account.is_empty():
			player_value = (players_value as Dictionary).get(str(AccountManager.account.get("id", "")), {})
	var merged: Dictionary = {}
	if world_value is Dictionary:
		merged.merge(world_value as Dictionary, true)
	if player_value is Dictionary:
		merged.merge(player_value as Dictionary, true)
	GameState.restore(merged)
	var position_value: Variant = merged.get("position", merged.get("player_position", [0.0, 1.0, 0.0]))
	if position_value is Array:
		var values: Array = position_value as Array
		if values.size() >= 3:
			player.global_position = Vector3(float(values[0]), float(values[1]), float(values[2]))

func _read_checkpoint(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	if not (parsed is Dictionary):
		return {}
	var envelope: Dictionary = parsed as Dictionary
	if not envelope.has("snapshot"):
		return {"world": envelope, "player": envelope}
	var snapshot_value: Variant = envelope.get("snapshot", {})
	if not (snapshot_value is Dictionary):
		return {}
	var snapshot: Dictionary = snapshot_value as Dictionary
	if str(envelope.get("checksum", "")) != _checksum(JSON.stringify(snapshot)):
		return {}
	return snapshot.duplicate(true)

func _checksum(value: String) -> String:
	var context := HashingContext.new()
	context.start(HashingContext.HASH_SHA256)
	context.update(value.to_utf8_buffer())
	return context.finish().hex_encode()
