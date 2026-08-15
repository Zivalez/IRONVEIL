extends Node

const DEFAULT_PORT := 9081
const CHECKPOINT_INTERVAL_SECONDS := 30.0
const CHECKPOINT_PATH := "user://room_server_checkpoint.json"

var _checkpoint_accumulator: float = 0.0

func _ready() -> void:
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

func _save_checkpoint() -> void:
	var file: FileAccess = FileAccess.open(CHECKPOINT_PATH, FileAccess.WRITE)
	if file == null:
		push_error("IRONVEIL_ROOM_CHECKPOINT_FAILED: cannot open checkpoint")
		return
	file.store_string(JSON.stringify(NetworkManager.room_server_snapshot()))
	file.close()
	print("IRONVEIL_ROOM_CHECKPOINT_OK")

func _load_checkpoint() -> void:
	if not FileAccess.file_exists(CHECKPOINT_PATH):
		return
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(CHECKPOINT_PATH))
	if parsed is Dictionary:
		NetworkManager.restore_room_server_snapshot(parsed as Dictionary)
		print("IRONVEIL_ROOM_CHECKPOINT_RESTORED")
