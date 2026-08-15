extends Node

const DEFAULT_PORT := 9081
const CHECKPOINT_INTERVAL_SECONDS := 30.0
const CHECKPOINT_PATH := "user://room_server_checkpoint.json"
const CHECKPOINT_TEMP_PATH := "user://room_server_checkpoint.tmp"
const CHECKPOINT_BACKUP_PATH := "user://room_server_checkpoint.backup.json"
const WORLD_SCHEMA_VERSION := 1

var _checkpoint_accumulator: float = 0.0

func _ready() -> void:
	var public_mode: bool = OS.get_environment("PUBLIC_MODE").to_lower() in ["1", "true", "yes", "on"]
	var token_secret: String = OS.get_environment("ROOM_TOKEN_SECRET")
	if public_mode and token_secret.length() < 32:
		push_error("IRONVEIL_ROOM_CONFIG_ERROR: ROOM_TOKEN_SECRET must be at least 32 characters in PUBLIC_MODE")
		get_tree().quit(2)
		return
	var port: int = DEFAULT_PORT
	var port_env: String = OS.get_environment("ROOM_PORT")
	if not port_env.is_empty():
		port = int(port_env)
	var error: Error = NetworkManager.start_room_server(port)
	if error != OK:
		get_tree().quit(1)
		return
	_load_checkpoint()
	TickManager.farming_tick.connect(_on_checkpoint_tick)
	print("IRONVEIL_ROOM_SERVER_READY port=%d max_players=%d" % [port, NetworkManager.MAX_PLAYERS_PER_ROOM])

func _on_checkpoint_tick(delta: float) -> void:
	_checkpoint_accumulator += delta
	if _checkpoint_accumulator < CHECKPOINT_INTERVAL_SECONDS:
		return
	_checkpoint_accumulator = 0.0
	_save_checkpoint()

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST or what == NOTIFICATION_PREDELETE:
		_save_checkpoint()

func _save_checkpoint() -> void:
	var snapshot: Dictionary = NetworkManager.room_server_snapshot()
	var payload: String = JSON.stringify(snapshot)
	var envelope := {"save_version":2,"game_version":"1.0.0","world_schema_version":WORLD_SCHEMA_VERSION,"checksum":_checksum(payload),"snapshot":snapshot}
	var file: FileAccess = FileAccess.open(CHECKPOINT_TEMP_PATH, FileAccess.WRITE)
	if file == null:
		push_error("IRONVEIL_ROOM_CHECKPOINT_FAILED: cannot open checkpoint")
		return
	file.store_string(JSON.stringify(envelope))
	file.close()
	var target: String=ProjectSettings.globalize_path(CHECKPOINT_PATH)
	var temporary: String=ProjectSettings.globalize_path(CHECKPOINT_TEMP_PATH)
	var backup: String=ProjectSettings.globalize_path(CHECKPOINT_BACKUP_PATH)
	if FileAccess.file_exists(CHECKPOINT_PATH):
		DirAccess.remove_absolute(backup)
		DirAccess.rename_absolute(target,backup)
	if DirAccess.rename_absolute(temporary,target) != OK:
		push_error("IRONVEIL_ROOM_CHECKPOINT_FAILED: atomic commit failed")
		return
	print("IRONVEIL_ROOM_CHECKPOINT_OK")

func _load_checkpoint() -> void:
	for path in [CHECKPOINT_PATH,CHECKPOINT_BACKUP_PATH]:
		if not FileAccess.file_exists(path):
			continue
		var parsed: Variant=JSON.parse_string(FileAccess.get_file_as_string(path))
		if not (parsed is Dictionary):
			continue
		var envelope: Dictionary=parsed as Dictionary
		var snapshot_value: Variant=envelope.get("snapshot",envelope)
		if not (snapshot_value is Dictionary):
			continue
		var snapshot: Dictionary=snapshot_value as Dictionary
		if envelope.has("checksum") and str(envelope.get("checksum","")) != _checksum(JSON.stringify(snapshot)):
			continue
		NetworkManager.restore_room_server_snapshot(snapshot)
		print("IRONVEIL_ROOM_CHECKPOINT_RESTORED")
		return

func _checksum(value: String) -> String:
	var context:=HashingContext.new()
	context.start(HashingContext.HASH_SHA256)
	context.update(value.to_utf8_buffer())
	return context.finish().hex_encode()
