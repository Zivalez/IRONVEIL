extends Node

signal lobby_rooms_updated(rooms: Array)
signal lobby_request_failed(message: String)
signal connection_state_changed(state: String, message: String)
signal remote_player_state(peer_id: int, display_name: String, position: Vector3, yaw: float)
signal remote_player_left(peer_id: int)
signal shared_flag_received(flag: String, value: Variant)
signal room_roster_updated(players: Dictionary)
signal boss_authority_state(health: float, max_health: float, vulnerable: bool)

const MAX_PLAYERS_PER_ROOM := 4
const DEFAULT_ROOM_PORT := 9081
const MAX_REASONABLE_PLAYER_SPEED := 11.0
const TOKEN_CLOCK_SKEW_SECONDS := 15
const BOSS_MAX_HEALTH := 220.0
const BOSS_VULNERABILITY_SECONDS := 15
const BOSS_WORLD_POSITION := Vector3(73.0, 0.0, 0.0)
const BOSS_DAMAGE_DISTANCE := 4.5
const BOSS_DAMAGE_MIN_INTERVAL_MS := 350

var _peer: WebSocketMultiplayerPeer
var _join_token: String = ""
var _current_room_id: String = ""
var _local_display_name: String = "Survivor"
var _connection_state: String = "offline"
var _server_mode: bool = false
var _token_secret: String = "development-only-change-me"
var _max_active_rooms: int = 16

# Server-side state. A single Phase-2 process may host several logical rooms.
var _pending_auth: Dictionary = {}
var _peer_rooms: Dictionary = {}
var _room_players: Dictionary = {}
var _last_accepted_positions: Dictionary = {}
var _last_state_time_ms: Dictionary = {}
var _last_boss_damage_time_ms: Dictionary = {}
var _room_shared_flags: Dictionary = {}
var _room_boss_health: Dictionary = {}
var _room_boss_vulnerability_expires_unix: Dictionary = {}
var _client_boss_state: Dictionary = {}

var _list_request: HTTPRequest
var _create_request: HTTPRequest
var _join_request: HTTPRequest

func _ready() -> void:
	_list_request = HTTPRequest.new()
	_create_request = HTTPRequest.new()
	_join_request = HTTPRequest.new()
	add_child(_list_request)
	add_child(_create_request)
	add_child(_join_request)
	_list_request.request_completed.connect(_on_list_rooms_completed)
	_create_request.request_completed.connect(_on_create_room_completed)
	_join_request.request_completed.connect(_on_join_room_completed)

	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	multiplayer.connected_to_server.connect(_on_connected_to_server)
	multiplayer.connection_failed.connect(_on_connection_failed)
	multiplayer.server_disconnected.connect(_on_server_disconnected)

func _process(_delta: float) -> void:
	if not _server_mode or not multiplayer.is_server():
		return
	var now_unix: int = int(Time.get_unix_time_from_system())
	for room_id_variant in _room_boss_vulnerability_expires_unix.keys():
		var room_id: String = str(room_id_variant)
		var expires_at: int = int(_room_boss_vulnerability_expires_unix.get(room_id, 0))
		if expires_at > 0 and now_unix >= expires_at:
			_room_boss_vulnerability_expires_unix.erase(room_id)
			_set_room_shared_flag(room_id, "boss_vulnerable", false)
			_set_room_shared_flag(room_id, "thermal_valve_a", false)
			_set_room_shared_flag(room_id, "thermal_valve_b", false)
			_broadcast_boss_state(room_id)

func is_online() -> bool:
	return _connection_state == "online"

func is_server_mode() -> bool:
	return _server_mode

func current_room_id() -> String:
	return _current_room_id

func connection_state() -> String:
	return _connection_state

func _scene_multiplayer() -> SceneMultiplayer:
	return multiplayer as SceneMultiplayer

func start_room_server(port: int = DEFAULT_ROOM_PORT) -> Error:
	_server_mode = true
	_token_secret = OS.get_environment("ROOM_TOKEN_SECRET")
	if _token_secret.is_empty():
		_token_secret = "development-only-change-me"
	_max_active_rooms = maxi(1, int(OS.get_environment("MAX_ACTIVE_ROOMS"))) if not OS.get_environment("MAX_ACTIVE_ROOMS").is_empty() else 16

	_peer = WebSocketMultiplayerPeer.new()
	_peer.handshake_timeout = 5.0
	var error: Error = _peer.create_server(port, "0.0.0.0")
	if error != OK:
		push_error("IRONVEIL_ROOM_SERVER_START_FAILED: %s" % error_string(error))
		return error
	multiplayer.multiplayer_peer = _peer
	var scene_multiplayer: SceneMultiplayer = _scene_multiplayer()
	scene_multiplayer.server_relay = false
	scene_multiplayer.auth_timeout = 6.0
	scene_multiplayer.auth_callback = _server_auth_callback
	_log_event("room_server_started", {"port": port, "max_players_per_room": MAX_PLAYERS_PER_ROOM, "max_active_rooms": _max_active_rooms})
	return OK

func stop_network() -> void:
	multiplayer.multiplayer_peer = OfflineMultiplayerPeer.new()
	_peer = null
	_join_token = ""
	_current_room_id = ""
	_connection_state = "offline"
	_server_mode = false
	connection_state_changed.emit(_connection_state, "Offline")

func list_rooms() -> void:
	var url: String = _lobby_url("/rooms")
	var error: Error = _list_request.request(url)
	if error != OK:
		lobby_request_failed.emit("Could not start room-list request: %s" % error_string(error))

func create_room(room_name: String, password: String = "", is_public: bool = true) -> void:
	var body := {
		"name": room_name,
		"password": password,
		"public": is_public,
		"player_name": _display_name(),
	}
	var error: Error = _create_request.request(
		_lobby_url("/rooms"),
		PackedStringArray(["Content-Type: application/json"]),
		HTTPClient.METHOD_POST,
		JSON.stringify(body)
	)
	if error != OK:
		lobby_request_failed.emit("Could not start create-room request: %s" % error_string(error))

func join_room(room_id: String, password: String = "") -> void:
	var body := {
		"password": password,
		"player_name": _display_name(),
	}
	var error: Error = _join_request.request(
		_lobby_url("/rooms/%s/join" % room_id.uri_encode()),
		PackedStringArray(["Content-Type: application/json"]),
		HTTPClient.METHOD_POST,
		JSON.stringify(body)
	)
	if error != OK:
		lobby_request_failed.emit("Could not start join-room request: %s" % error_string(error))

func connect_with_ticket(websocket_url: String, room_id: String, token: String) -> Error:
	stop_network()
	_server_mode = false
	_join_token = token
	_current_room_id = room_id
	_local_display_name = _display_name()
	_connection_state = "connecting"
	connection_state_changed.emit(_connection_state, "Connecting to room...")

	_peer = WebSocketMultiplayerPeer.new()
	_peer.handshake_timeout = 6.0
	var error: Error = _peer.create_client(websocket_url)
	if error != OK:
		_connection_state = "offline"
		connection_state_changed.emit(_connection_state, "WebSocket error: %s" % error_string(error))
		return error
	multiplayer.multiplayer_peer = _peer
	var scene_multiplayer: SceneMultiplayer = _scene_multiplayer()
	scene_multiplayer.auth_timeout = 6.0
	scene_multiplayer.auth_callback = _client_auth_callback
	if not scene_multiplayer.peer_authenticating.is_connected(_on_client_peer_authenticating):
		scene_multiplayer.peer_authenticating.connect(_on_client_peer_authenticating)
	return OK

func submit_local_player_state(position: Vector3, yaw: float) -> void:
	if not is_online() or _server_mode:
		return
	_submit_player_state.rpc_id(1, position, yaw)

func submit_shared_flag(flag: String, value: Variant) -> void:
	if not is_online() or _server_mode:
		return
	_request_shared_flag.rpc_id(1, flag, value)

func submit_boss_damage(amount: float) -> void:
	if not is_online() or _server_mode:
		return
	_request_boss_damage.rpc_id(1, clampf(amount, 0.0, 40.0))

func cached_boss_state() -> Dictionary:
	return _client_boss_state.duplicate(true)

func _display_name() -> String:
	var value: String = str(SettingsManager.get_value("network", "display_name", "Survivor")).strip_edges()
	if value.is_empty():
		value = "Survivor"
	return value.substr(0, 24)

func _lobby_url(path: String) -> String:
	var base: String = str(SettingsManager.get_value("network", "lobby_url", "http://127.0.0.1:8081")).strip_edges().trim_suffix("/")
	return base + path

func _on_list_rooms_completed(result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
	if result != HTTPRequest.RESULT_SUCCESS or response_code < 200 or response_code >= 300:
		lobby_request_failed.emit("Room list failed (HTTP %d)." % response_code)
		return
	var parsed: Variant = JSON.parse_string(body.get_string_from_utf8())
	if not (parsed is Dictionary):
		lobby_request_failed.emit("Lobby returned invalid room-list JSON.")
		return
	var rooms_value: Variant = (parsed as Dictionary).get("rooms", [])
	lobby_rooms_updated.emit((rooms_value as Array).duplicate(true) if rooms_value is Array else [])

func _on_create_room_completed(result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
	_handle_join_ticket_response("Create room", result, response_code, body)

func _on_join_room_completed(result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
	_handle_join_ticket_response("Join room", result, response_code, body)

func _handle_join_ticket_response(label: String, result: int, response_code: int, body: PackedByteArray) -> void:
	if result != HTTPRequest.RESULT_SUCCESS or response_code < 200 or response_code >= 300:
		var message: String = "%s failed (HTTP %d)." % [label, response_code]
		var error_parsed: Variant = JSON.parse_string(body.get_string_from_utf8())
		if error_parsed is Dictionary:
			message = str((error_parsed as Dictionary).get("message", message))
		lobby_request_failed.emit(message)
		return
	var parsed: Variant = JSON.parse_string(body.get_string_from_utf8())
	if not (parsed is Dictionary):
		lobby_request_failed.emit("Lobby returned invalid join ticket.")
		return
	var payload: Dictionary = parsed as Dictionary
	var ws_url: String = str(payload.get("websocket_url", ""))
	var room_id: String = str(payload.get("room_id", ""))
	var token: String = str(payload.get("join_token", ""))
	if ws_url.is_empty() or room_id.is_empty() or token.is_empty():
		lobby_request_failed.emit("Lobby join ticket is incomplete.")
		return
	connect_with_ticket(ws_url, room_id, token)

func _on_client_peer_authenticating(peer_id: int) -> void:
	if _server_mode or peer_id != 1:
		return
	var auth_payload := {"token": _join_token}
	var scene_multiplayer: SceneMultiplayer = _scene_multiplayer()
	scene_multiplayer.send_auth(peer_id, JSON.stringify(auth_payload).to_utf8_buffer())
	scene_multiplayer.complete_auth(peer_id)

func _client_auth_callback(_peer_id: int, _payload: PackedByteArray) -> void:
	# Client does not accept credentials from the room server. Setting a callback
	# simply enables SceneMultiplayer's authentication lifecycle on both sides.
	pass

func _server_auth_callback(peer_id: int, payload: PackedByteArray) -> void:
	var parsed: Variant = JSON.parse_string(payload.get_string_from_utf8())
	if not (parsed is Dictionary):
		_reject_auth(peer_id, "malformed_auth")
		return
	var token: String = str((parsed as Dictionary).get("token", ""))
	var claims: Dictionary = _verify_join_token(token)
	if claims.is_empty():
		_reject_auth(peer_id, "invalid_token")
		return
	var room_id: String = str(claims.get("room_id", ""))
	var player_name: String = str(claims.get("player_name", "Survivor")).substr(0, 24)
	if room_id.is_empty():
		_reject_auth(peer_id, "missing_room")
		return
	var room: Dictionary = _room_players.get(room_id, {})
	if room.is_empty() and _room_players.size() >= _max_active_rooms:
		_reject_auth(peer_id, "server_capacity_reached")
		return
	if room.size() >= MAX_PLAYERS_PER_ROOM:
		_reject_auth(peer_id, "room_full")
		return
	_pending_auth[peer_id] = {"room_id": room_id, "player_name": player_name}
	_scene_multiplayer().complete_auth(peer_id)

func _reject_auth(peer_id: int, reason: String) -> void:
	_log_event("auth_rejected", {"peer_id": peer_id, "reason": reason})
	_scene_multiplayer().disconnect_peer(peer_id)

func _verify_join_token(token: String) -> Dictionary:
	var parts: PackedStringArray = token.split(".")
	if parts.size() != 2:
		return {}
	var payload_raw: PackedByteArray = _base64url_decode(parts[0])
	var signature_raw: PackedByteArray = _base64url_decode(parts[1])
	if payload_raw.is_empty() or signature_raw.is_empty():
		return {}
	var crypto := Crypto.new()
	var expected: PackedByteArray = crypto.hmac_digest(
		HashingContext.HASH_SHA256,
		_token_secret.to_utf8_buffer(),
		parts[0].to_utf8_buffer()
	)
	if not crypto.constant_time_compare(expected, signature_raw):
		return {}
	var parsed: Variant = JSON.parse_string(payload_raw.get_string_from_utf8())
	if not (parsed is Dictionary):
		return {}
	var claims: Dictionary = parsed as Dictionary
	var expires_at: int = int(claims.get("exp", 0))
	if expires_at + TOKEN_CLOCK_SKEW_SECONDS < int(Time.get_unix_time_from_system()):
		return {}
	return claims

func _base64url_decode(value: String) -> PackedByteArray:
	var normalized: String = value.replace("-", "+").replace("_", "/")
	while normalized.length() % 4 != 0:
		normalized += "="
	return Marshalls.base64_to_raw(normalized)

func _on_peer_connected(peer_id: int) -> void:
	if _server_mode:
		var auth_value: Variant = _pending_auth.get(peer_id, {})
		if not (auth_value is Dictionary):
			_scene_multiplayer().disconnect_peer(peer_id)
			return
		var auth: Dictionary = auth_value as Dictionary
		var room_id: String = str(auth.get("room_id", ""))
		var room: Dictionary = _room_players.get(room_id, {})
		room[peer_id] = {"name": str(auth.get("player_name", "Survivor")), "position": [0.0, 0.8, 0.0], "yaw": 0.0}
		_room_players[room_id] = room
		_peer_rooms[peer_id] = room_id
		_pending_auth.erase(peer_id)
		_log_event("player_joined", {"peer_id": peer_id, "room_id": room_id, "players": room.size()})
		_broadcast_roster(room_id)
		var shared: Dictionary = _room_shared_flags.get(room_id, {})
		for flag_variant in shared:
			_receive_shared_flag.rpc_id(peer_id, str(flag_variant), shared[flag_variant])
		_send_boss_state_to_peer(room_id, peer_id)
	else:
		# Client receives peer notifications from the server relay only when enabled.
		pass

func _on_peer_disconnected(peer_id: int) -> void:
	if _server_mode:
		var room_id: String = str(_peer_rooms.get(peer_id, ""))
		_peer_rooms.erase(peer_id)
		_last_accepted_positions.erase(peer_id)
		_last_state_time_ms.erase(peer_id)
		_last_boss_damage_time_ms.erase(peer_id)
		if not room_id.is_empty():
			var room: Dictionary = _room_players.get(room_id, {})
			room.erase(peer_id)
			if room.is_empty():
				_room_players.erase(room_id)
				_room_shared_flags.erase(room_id)
			else:
				_room_players[room_id] = room
				_broadcast_roster(room_id)
			_log_event("player_disconnected", {"peer_id": peer_id, "room_id": room_id})
	else:
		remote_player_left.emit(peer_id)

func _on_connected_to_server() -> void:
	_connection_state = "online"
	connection_state_changed.emit(_connection_state, "Connected to room %s" % _current_room_id)

func _on_connection_failed() -> void:
	_connection_state = "offline"
	connection_state_changed.emit(_connection_state, "Room connection failed")

func _on_server_disconnected() -> void:
	_connection_state = "offline"
	connection_state_changed.emit(_connection_state, "Room server disconnected")

@rpc("any_peer", "call_remote", "unreliable_ordered", 1)
func _submit_player_state(requested_position: Vector3, yaw: float) -> void:
	if not _server_mode or not multiplayer.is_server():
		return
	var sender_id: int = multiplayer.get_remote_sender_id()
	var room_id: String = str(_peer_rooms.get(sender_id, ""))
	if room_id.is_empty():
		return
	var now_ms: int = Time.get_ticks_msec()
	var accepted_position: Vector3 = requested_position
	var previous_value: Variant = _last_accepted_positions.get(sender_id, requested_position)
	if previous_value is Vector3:
		var previous: Vector3 = previous_value as Vector3
		var previous_time: int = int(_last_state_time_ms.get(sender_id, now_ms - 100))
		var elapsed: float = maxf(float(now_ms - previous_time) / 1000.0, 0.016)
		var maximum_step: float = MAX_REASONABLE_PLAYER_SPEED * elapsed + 0.65
		var offset: Vector3 = requested_position - previous
		if offset.length() > maximum_step:
			accepted_position = previous + offset.normalized() * maximum_step
	_last_accepted_positions[sender_id] = accepted_position
	_last_state_time_ms[sender_id] = now_ms

	var room: Dictionary = _room_players.get(room_id, {})
	var player: Dictionary = room.get(sender_id, {})
	player["position"] = [accepted_position.x, accepted_position.y, accepted_position.z]
	player["yaw"] = yaw
	room[sender_id] = player
	_room_players[room_id] = room
	for peer_id_variant in room.keys():
		var peer_id: int = int(peer_id_variant)
		_receive_player_state.rpc_id(peer_id, sender_id, str(player.get("name", "Survivor")), accepted_position, yaw)

@rpc("authority", "call_remote", "unreliable_ordered", 1)
func _receive_player_state(peer_id: int, display_name: String, position: Vector3, yaw: float) -> void:
	if _server_mode:
		return
	if peer_id == multiplayer.get_unique_id():
		return
	remote_player_state.emit(peer_id, display_name, position, yaw)

@rpc("any_peer", "call_remote", "reliable", 2)
func _request_shared_flag(flag: String, value: Variant) -> void:
	if not _server_mode or not multiplayer.is_server():
		return
	var sender_id: int = multiplayer.get_remote_sender_id()
	var room_id: String = str(_peer_rooms.get(sender_id, ""))
	if room_id.is_empty():
		return
	var allowed_client_flags: Array[String] = [
		"bridge_repaired", "mara_spoken", "foundry_gate_open",
		"thermal_valve_a", "thermal_valve_b",
		"ashlands_wind_online", "basin_irrigation_online", "phase3_mvp_complete"
	]
	if not allowed_client_flags.has(flag) or not bool(value):
		return
	var state: Dictionary = _room_shared_flags.get(room_id, {})
	# Validate that the player is physically near the world interaction they are
	# trying to commit. This is not a substitute for authoritative inventory,
	# but it prevents remote arbitrary progression RPCs.
	var required_position := {
		"bridge_repaired": Vector3(28.0, 0.0, 0.0),
		"mara_spoken": Vector3(40.0, 0.0, 3.0),
		"foundry_gate_open": Vector3(54.2, 0.0, 0.0),
		"thermal_valve_a": Vector3(63.0, 0.0, -7.0),
		"thermal_valve_b": Vector3(63.0, 0.0, 7.0),
		"ashlands_wind_online": Vector3(108.0, 0.0, -5.0),
		"basin_irrigation_online": Vector3(148.0, 0.0, -3.0),
		"phase3_mvp_complete": Vector3(164.0, 0.0, 7.0),
	}
	var interaction_position_value: Variant = required_position.get(flag, null)
	if interaction_position_value is Vector3 and not _peer_is_near(sender_id, interaction_position_value as Vector3, 5.5):
		return
	# Enforce the vertical-slice progression order on the authoritative room.
	if flag == "mara_spoken" and not bool(state.get("bridge_repaired", false)):
		return
	if flag == "foundry_gate_open" and not bool(state.get("mara_spoken", false)):
		return
	if flag.begins_with("thermal_valve_") and not bool(state.get("foundry_gate_open", false)):
		return
	if flag == "ashlands_wind_online" and not bool(state.get("furnace_saint_defeated", false)):
		return
	if flag == "basin_irrigation_online" and not bool(state.get("ashlands_wind_online", false)):
		return
	if flag == "phase3_mvp_complete" and not bool(state.get("basin_irrigation_online", false)):
		return
	_set_room_shared_flag(room_id, flag, true)
	state = _room_shared_flags.get(room_id, {})
	if bool(state.get("thermal_valve_a", false)) and bool(state.get("thermal_valve_b", false)) and not bool(state.get("boss_vulnerable", false)):
		_set_room_shared_flag(room_id, "boss_vulnerable", true)
		_room_boss_vulnerability_expires_unix[room_id] = int(Time.get_unix_time_from_system()) + BOSS_VULNERABILITY_SECONDS
		_broadcast_boss_state(room_id)

@rpc("authority", "call_remote", "reliable", 2)
func _receive_shared_flag(flag: String, value: Variant) -> void:
	if _server_mode:
		return
	shared_flag_received.emit(flag, value)

@rpc("any_peer", "call_remote", "reliable", 4)
func _request_boss_damage(amount: float) -> void:
	if not _server_mode or not multiplayer.is_server():
		return
	var sender_id: int = multiplayer.get_remote_sender_id()
	var room_id: String = str(_peer_rooms.get(sender_id, ""))
	if room_id.is_empty():
		return
	var state: Dictionary = _room_shared_flags.get(room_id, {})
	if not bool(state.get("boss_vulnerable", false)) or bool(state.get("furnace_saint_defeated", false)):
		return
	if not _peer_is_near(sender_id, BOSS_WORLD_POSITION, BOSS_DAMAGE_DISTANCE):
		return
	var now_ms: int = Time.get_ticks_msec()
	var last_damage_ms: int = int(_last_boss_damage_time_ms.get(sender_id, now_ms - BOSS_DAMAGE_MIN_INTERVAL_MS))
	if now_ms - last_damage_ms < BOSS_DAMAGE_MIN_INTERVAL_MS:
		return
	_last_boss_damage_time_ms[sender_id] = now_ms
	var health: float = float(_room_boss_health.get(room_id, BOSS_MAX_HEALTH))
	health = maxf(health - clampf(amount, 0.0, 40.0), 0.0)
	_room_boss_health[room_id] = health
	if health <= 0.0:
		_set_room_shared_flag(room_id, "furnace_saint_defeated", true)
		_set_room_shared_flag(room_id, "boss_vulnerable", false)
		_room_boss_vulnerability_expires_unix.erase(room_id)
	_broadcast_boss_state(room_id)

@rpc("authority", "call_remote", "reliable", 4)
func _receive_boss_state(health: float, max_health: float, vulnerable: bool) -> void:
	if _server_mode:
		return
	_client_boss_state = {"health": health, "max_health": max_health, "vulnerable": vulnerable}
	boss_authority_state.emit(health, max_health, vulnerable)

func _set_room_shared_flag(room_id: String, flag: String, value: Variant) -> void:
	var state: Dictionary = _room_shared_flags.get(room_id, {})
	state[flag] = value
	_room_shared_flags[room_id] = state
	var room: Dictionary = _room_players.get(room_id, {})
	for peer_id_variant in room.keys():
		_receive_shared_flag.rpc_id(int(peer_id_variant), flag, value)

func _broadcast_boss_state(room_id: String) -> void:
	var room: Dictionary = _room_players.get(room_id, {})
	for peer_id_variant in room.keys():
		_send_boss_state_to_peer(room_id, int(peer_id_variant))

func _send_boss_state_to_peer(room_id: String, peer_id: int) -> void:
	var state: Dictionary = _room_shared_flags.get(room_id, {})
	var health: float = float(_room_boss_health.get(room_id, BOSS_MAX_HEALTH))
	var vulnerable: bool = bool(state.get("boss_vulnerable", false))
	_receive_boss_state.rpc_id(peer_id, health, BOSS_MAX_HEALTH, vulnerable)

@rpc("authority", "call_remote", "reliable", 3)
func _receive_roster(players: Dictionary) -> void:
	if _server_mode:
		return
	room_roster_updated.emit(players.duplicate(true))

func _broadcast_roster(room_id: String) -> void:
	var room: Dictionary = _room_players.get(room_id, {})
	var clean: Dictionary = {}
	for peer_id_variant in room.keys():
		var peer_id: int = int(peer_id_variant)
		var info: Dictionary = room[peer_id]
		clean[peer_id] = {"name": str(info.get("name", "Survivor"))}
	for peer_id_variant in room.keys():
		_receive_roster.rpc_id(int(peer_id_variant), clean)

func _peer_is_near(peer_id: int, target: Vector3, max_distance: float) -> bool:
	var position_value: Variant = _last_accepted_positions.get(peer_id, null)
	if not (position_value is Vector3):
		return false
	var peer_position: Vector3 = position_value as Vector3
	var flat_peer := Vector3(peer_position.x, 0.0, peer_position.z)
	var flat_target := Vector3(target.x, 0.0, target.z)
	return flat_peer.distance_to(flat_target) <= max_distance

func room_server_snapshot() -> Dictionary:
	return {
		"rooms": _room_players.duplicate(true),
		"shared_flags": _room_shared_flags.duplicate(true),
		"boss_health": _room_boss_health.duplicate(true),
		"boss_vulnerability_expires_unix": _room_boss_vulnerability_expires_unix.duplicate(true),
	}

func restore_room_server_snapshot(snapshot: Dictionary) -> void:
	if not _server_mode:
		return
	var flags_value: Variant = snapshot.get("shared_flags", {})
	if flags_value is Dictionary:
		_room_shared_flags = (flags_value as Dictionary).duplicate(true)
	var boss_health_value: Variant = snapshot.get("boss_health", {})
	if boss_health_value is Dictionary:
		_room_boss_health = (boss_health_value as Dictionary).duplicate(true)
	var boss_expiry_value: Variant = snapshot.get("boss_vulnerability_expires_unix", {})
	if boss_expiry_value is Dictionary:
		_room_boss_vulnerability_expires_unix = (boss_expiry_value as Dictionary).duplicate(true)

func _log_event(event_name: String, data: Dictionary = {}) -> void:
	var record := {
		"event": event_name,
		"unix": int(Time.get_unix_time_from_system()),
		"data": data,
	}
	print("IRONVEIL_ROOM_EVENT ", JSON.stringify(record))
