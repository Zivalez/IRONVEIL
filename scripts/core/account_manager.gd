extends Node

signal auth_changed(authenticated: bool, account: Dictionary)
signal worlds_updated(worlds: Array)
signal world_loaded(world: Dictionary, snapshot: Dictionary)
signal request_failed(message: String)
signal checkpoint_saved(world: Dictionary)

const SESSION_PATH := "user://ironveil_session.json"

var account: Dictionary = {}
var session_token: String = ""
var worlds: Array = []
var active_world_id: String = ""
var active_world: Dictionary = {}
var pending_snapshot: Dictionary = {}
var _request: HTTPRequest
var _operation: String = ""

func _ready() -> void:
	_request = HTTPRequest.new()
	add_child(_request)
	_request.request_completed.connect(_on_request_completed)
	_load_session()

func is_authenticated() -> bool:
	return not session_token.is_empty() and not account.is_empty()

func api_url(path: String) -> String:
	var base: String = str(SettingsManager.get_value("network", "lobby_url", "http://127.0.0.1:8081")).trim_suffix("/")
	return base + path

func register_account(email: String, password: String, display_name: String) -> void:
	_send("register", HTTPClient.METHOD_POST, "/auth/register", {"email": email, "password": password, "display_name": display_name}, false)

func login(email: String, password: String) -> void:
	_send("login", HTTPClient.METHOD_POST, "/auth/login", {"email": email, "password": password}, false)

func logout() -> void:
	if not session_token.is_empty():
		_send("logout", HTTPClient.METHOD_POST, "/auth/logout", {}, true)
	else:
		_clear_session()

func refresh_account() -> void:
	_send("me", HTTPClient.METHOD_GET, "/auth/me", {}, true)

func refresh_session() -> void:
	_send("refresh", HTTPClient.METHOD_POST, "/auth/refresh", {}, true)

func list_worlds() -> void:
	_send("list_worlds", HTTPClient.METHOD_GET, "/worlds", {}, true)

func create_world(world_name: String, kind: String, modifiers: Dictionary = {}) -> void:
	_send("create_world", HTTPClient.METHOD_POST, "/worlds", {"name": world_name, "kind": kind, "modifiers": modifiers}, true)

func join_world(invite_code: String) -> void:
	_send("join_world", HTTPClient.METHOD_POST, "/worlds/join", {"invite_code": invite_code}, true)

func load_world(world_id: String) -> void:
	active_world_id = world_id
	_send("load_world", HTTPClient.METHOD_GET, "/worlds/%s" % world_id, {}, true)

func create_invite() -> void:
	if active_world_id.is_empty():
		request_failed.emit("Select a shared world first.")
		return
	_send("invite", HTTPClient.METHOD_POST, "/worlds/%s/invite" % active_world_id, {}, true)

func save_checkpoint(snapshot: Dictionary, region: String, playtime_delta: int) -> void:
	if active_world_id.is_empty() or not is_authenticated():
		return
	_send("checkpoint", HTTPClient.METHOD_POST, "/worlds/%s/checkpoint" % active_world_id, {
		"snapshot": snapshot,
		"region": region,
		"playtime_delta": playtime_delta,
	}, true)

func consume_pending_snapshot() -> Dictionary:
	var result: Dictionary = pending_snapshot.duplicate(true)
	pending_snapshot.clear()
	return result

func _send(operation: String, method: HTTPClient.Method, path: String, payload: Dictionary, authenticated: bool) -> void:
	if _request.get_http_client_status() != HTTPClient.STATUS_DISCONNECTED:
		request_failed.emit("Another server request is still in progress.")
		return
	var headers := PackedStringArray(["Content-Type: application/json"])
	if authenticated:
		if session_token.is_empty():
			request_failed.emit("Sign in to use persistent worlds.")
			return
		headers.append("Authorization: Bearer %s" % session_token)
	_operation = operation
	var body: String = "" if method == HTTPClient.METHOD_GET else JSON.stringify(payload)
	var error: Error = _request.request(api_url(path), headers, method, body)
	if error != OK:
		_operation = ""
		request_failed.emit("Could not reach the IRONVEIL world service.")

func _on_request_completed(result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
	var operation: String = _operation
	_operation = ""
	var parsed: Variant = JSON.parse_string(body.get_string_from_utf8())
	var response: Dictionary = parsed as Dictionary if parsed is Dictionary else {}
	if result != HTTPRequest.RESULT_SUCCESS or response_code < 200 or response_code >= 300:
		if response_code == 401:
			_clear_session()
		request_failed.emit(str(response.get("message", "World service request failed (%d)." % response_code)))
		return
	match operation:
		"register", "login", "refresh":
			var account_value: Variant = response.get("account", {})
			account = (account_value as Dictionary).duplicate(true) if account_value is Dictionary else {}
			session_token = str(response.get("session_token", ""))
			_save_session()
			auth_changed.emit(true, account.duplicate(true))
			list_worlds()
		"logout":
			_clear_session()
		"me":
			var account_value: Variant = response.get("account", {})
			account = (account_value as Dictionary).duplicate(true) if account_value is Dictionary else {}
			_save_session()
			auth_changed.emit(true, account.duplicate(true))
		"list_worlds":
			var value: Variant = response.get("worlds", [])
			worlds = (value as Array).duplicate(true) if value is Array else []
			worlds_updated.emit(worlds.duplicate(true))
		"create_world", "join_world":
			list_worlds()
		"load_world":
			var world_value: Variant = response.get("world", {})
			var snapshot_value: Variant = response.get("snapshot", {})
			active_world = (world_value as Dictionary).duplicate(true) if world_value is Dictionary else {}
			pending_snapshot = (snapshot_value as Dictionary).duplicate(true) if snapshot_value is Dictionary else {}
			world_loaded.emit(active_world.duplicate(true), pending_snapshot.duplicate(true))
		"checkpoint":
			checkpoint_saved.emit(response.duplicate(true))
		"invite":
			GameState.notify("Shared-world invite: %s" % str(response.get("invite_code", "")), "success")

func _save_session() -> void:
	var file: FileAccess = FileAccess.open(SESSION_PATH, FileAccess.WRITE)
	if file != null:
		file.store_string(JSON.stringify({"session_token": session_token, "account": account}))
		file.close()

func _load_session() -> void:
	if not FileAccess.file_exists(SESSION_PATH):
		return
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(SESSION_PATH))
	if parsed is Dictionary:
		session_token = str((parsed as Dictionary).get("session_token", ""))
		var value: Variant = (parsed as Dictionary).get("account", {})
		account = (value as Dictionary).duplicate(true) if value is Dictionary else {}

func _clear_session() -> void:
	account.clear()
	session_token = ""
	worlds.clear()
	active_world_id = ""
	active_world.clear()
	pending_snapshot.clear()
	if FileAccess.file_exists(SESSION_PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(SESSION_PATH))
	auth_changed.emit(false, {})
	worlds_updated.emit([])
