extends Node3D

const VisualFactory = preload("res://scripts/game/visual_factory.gd")

var node_id: String = "infrastructure"
var display_name: String = "Infrastructure"
var requirements: Dictionary = {}
var completion_flag: String = ""
var objective_from: int = -1
var objective_to: int = -1
var technology: String = "mechanical"
var electrical_output_kw: float = 0.0
var electrical_load_kw: float = 0.0
var renewable: bool = false
var prerequisite_flag: String = ""
var rewards: Dictionary = {}
var _built: bool = false
var _active: bool = true
var _body: MeshInstance3D
var _status: Label3D

func configure(config: Dictionary) -> void:
	node_id = str(config.get("id", node_id))
	display_name = str(config.get("name", display_name))
	var requirement_value: Variant = config.get("requirements", {})
	requirements = (requirement_value as Dictionary).duplicate(true) if requirement_value is Dictionary else {}
	completion_flag = str(config.get("flag", "%s_online" % node_id))
	objective_from = int(config.get("objective_from", -1))
	objective_to = int(config.get("objective_to", -1))
	technology = str(config.get("technology", "mechanical"))
	electrical_output_kw = float(config.get("electrical_output_kw", 0.0))
	electrical_load_kw = float(config.get("electrical_load_kw", 0.0))
	renewable = bool(config.get("renewable", false))
	prerequisite_flag = str(config.get("prerequisite_flag", ""))
	var reward_value: Variant = config.get("rewards", {})
	rewards = (reward_value as Dictionary).duplicate(true) if reward_value is Dictionary else {}

func _ready() -> void:
	add_to_group("interactable")
	add_to_group("infrastructure")
	_built = bool(GameState.get_flag(completion_flag, false))
	_build_visual()
	_register_network()
	GameState.flag_changed.connect(_on_flag_changed)

func _build_visual() -> void:
	_body = VisualFactory.make_box_mesh(Vector3(2.8, 2.2, 2.8), "res://assets/pixel/rust_metal.png", _machine_color(), 0.58, 0.48)
	_body.position.y = 1.1
	add_child(_body)
	var cap := VisualFactory.make_box_mesh(Vector3(3.3, 0.28, 3.3), "res://assets/pixel/plate.png", Color(0.52, 0.57, 0.51), 0.7, 0.34)
	cap.position.y = 2.32
	add_child(cap)
	var shaft := VisualFactory.make_box_mesh(Vector3(0.36, 3.2, 0.36), "res://assets/pixel/gear.png", Color(0.68, 0.48, 0.22), 0.8, 0.3)
	shaft.position = Vector3(0.0, 2.8, 0.0)
	add_child(shaft)
	_status = VisualFactory.make_label("", Color(0.72, 0.88, 0.72))
	_status.position = Vector3(0.0, 4.9, 0.0)
	add_child(_status)
	_refresh_visual()

func _process(delta: float) -> void:
	if _built and _active:
		rotation.y += delta * (0.05 if technology == "rail" else 0.12)
	if node_id == "steam_engine" and _built and _active:
		InfrastructureNetwork.set_steam_pressure(move_toward(InfrastructureNetwork.steam_pressure_kpa, 640.0, delta * 22.0))

func get_prompt(_player: Node) -> String:
	if not _built:
		if not prerequisite_flag.is_empty() and not bool(GameState.get_flag(prerequisite_flag, false)):
			return "[%s] %s // prerequisite offline" % [SettingsManager.keybind_name("interact"), display_name]
		return "[%s] Rebuild %s — %s" % [SettingsManager.keybind_name("interact"), display_name, _requirements_text()]
	if electrical_output_kw > 0.0 or electrical_load_kw > 0.0:
		return "[%s] %s // %s // toggle" % [SettingsManager.keybind_name("interact"), display_name, "ONLINE" if _active else "ISOLATED"]
	return "[%s] Inspect %s" % [SettingsManager.keybind_name("interact"), display_name]

func interact(_player: Node) -> void:
	if not _built:
		if not prerequisite_flag.is_empty() and not bool(GameState.get_flag(prerequisite_flag, false)):
			GameState.notify("%s requires %s first." % [display_name, prerequisite_flag.replace("_", " ")], "error")
			return
		for item_value in requirements:
			if not GameState.has_item(str(item_value), int(requirements[item_value])):
				GameState.notify("%s requires %s." % [display_name, _requirements_text()], "error")
				return
		for item_value in requirements:
			GameState.remove_item(str(item_value), int(requirements[item_value]))
		GameState.set_flag(completion_flag, true)
		_built = true
		if GameState.objective_step == objective_from and objective_to >= 0:
			GameState.advance_objective(objective_to)
		for reward_value in rewards:
			GameState.add_item(str(reward_value), int(rewards[reward_value]))
		_register_network()
		_refresh_visual()
		GameState.add_journal(display_name, "Confirmation", "Regional infrastructure is operational. Its output now participates in the shared engineering network.")
		GameState.notify("%s brought online." % display_name, "success")
		return
	if electrical_output_kw > 0.0 or electrical_load_kw > 0.0:
		_active = not _active
		InfrastructureNetwork.set_switch(node_id, _active)
		_refresh_visual()
	GameState.notify(_diagnostic_text(), "info")

func _register_network() -> void:
	if not _built:
		return
	if electrical_output_kw > 0.0:
		InfrastructureNetwork.register_source(node_id, electrical_output_kw, renewable)
	if electrical_load_kw > 0.0:
		InfrastructureNetwork.register_consumer(node_id, electrical_load_kw, 2)

func _on_flag_changed(flag: String, value: Variant) -> void:
	if flag == completion_flag:
		_built = bool(value)
		_register_network()
		_refresh_visual()

func _requirements_text() -> String:
	var parts: Array[String] = []
	for item_value in requirements:
		parts.append("%d %s" % [int(requirements[item_value]), DataRegistry.display_name(str(item_value))])
	return ", ".join(parts) if not parts.is_empty() else "knowledge"

func _diagnostic_text() -> String:
	if node_id == "steam_engine":
		return "%s // %.0f kPa // %.1f kW" % [display_name, InfrastructureNetwork.steam_pressure_kpa, electrical_output_kw]
	if electrical_load_kw > 0.0:
		return "%s // load %.1f kW // %s" % [display_name, electrical_load_kw, "POWERED" if InfrastructureNetwork.is_powered(node_id) else "LOAD SHED"]
	return "%s // stable" % display_name

func _machine_color() -> Color:
	match technology:
		"steam":
			return Color(0.48, 0.34, 0.25)
		"electrical":
			return Color(0.30, 0.49, 0.48)
		"rail":
			return Color(0.40, 0.42, 0.39)
		"veil":
			return Color(0.34, 0.28, 0.48)
		_:
			return Color(0.43, 0.37, 0.29)

func _refresh_visual() -> void:
	if _status == null:
		return
	_status.text = "%s\n%s" % [display_name.to_upper(), "ONLINE" if _built and _active else ("ISOLATED" if _built else "OFFLINE")]
	_status.modulate = Color(0.62, 0.92, 0.70) if _built and _active else Color(0.92, 0.53, 0.31)
	if _body != null:
		_body.modulate = Color.WHITE if _built else Color(0.45, 0.43, 0.40)
