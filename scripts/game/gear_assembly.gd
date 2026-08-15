extends Node3D

const VisualFactory = preload("res://scripts/game/visual_factory.gd")

const GEAR_ID := "workshop_gearbox"
const BELT_ID := "workshop_belt"
var connected := false
var gear_visual: MeshInstance3D
var gear_definition: Dictionary = {}
var belt_definition: Dictionary = {}

func _ready() -> void:
	add_to_group("interactable")
	connected = bool(GameState.get_flag("gear_connected", false))
	gear_definition = DataRegistry.get_machine(GEAR_ID)
	belt_definition = DataRegistry.get_machine(BELT_ID)
	GameState.mechanical_network.add_transformer(
		GEAR_ID,
		float(gear_definition.get("ratio", 1.0)),
		float(gear_definition.get("efficiency", 1.0)),
		"gear"
	)
	GameState.mechanical_network.add_transformer(
		BELT_ID,
		float(belt_definition.get("ratio", 1.0)),
		float(belt_definition.get("efficiency", 1.0)),
		"belt"
	)
	if connected:
		_connect_network()
	_build_visual()
	TickManager.machine_tick.connect(_on_machine_tick)

func _connect_network() -> void:
	GameState.mechanical_network.connect_nodes("water_wheel", GEAR_ID)
	GameState.mechanical_network.connect_nodes(GEAR_ID, BELT_ID)

func _build_visual() -> void:
	gear_visual = MeshInstance3D.new()
	var mesh := CylinderMesh.new()
	mesh.top_radius = 0.9
	mesh.bottom_radius = 0.9
	mesh.height = 0.3
	mesh.radial_segments = 12
	gear_visual.mesh = mesh
	gear_visual.rotation_degrees.z = 90.0
	gear_visual.position.y = 1.0
	var mat: StandardMaterial3D = VisualFactory.make_material("res://assets/pixel/rust_metal.png", Color(0.80, 0.74, 0.63), 0.75, 0.48)
	gear_visual.material_override = mat
	add_child(gear_visual)

	var belt := MeshInstance3D.new()
	var belt_mesh := BoxMesh.new()
	belt_mesh.size = Vector3(3.0, 0.12, 0.24)
	belt.mesh = belt_mesh
	belt.position = Vector3(1.55, 1.0, 0.0)
	var belt_mat: StandardMaterial3D = VisualFactory.make_material("res://assets/pixel/wood_texture.png", Color(0.26, 0.18, 0.12), 0.0, 0.95)
	belt.material_override = belt_mat
	add_child(belt)

func get_prompt(_player: Node) -> String:
	if not connected:
		return "[%s] Install Crude Gear — craft with [%s] using Scrap x2" % [SettingsManager.keybind_name("interact"), SettingsManager.keybind_name("craft_gear")]
	return "Gearbox CONNECTED | %.0f RPM | %.0f Nm" % [
		GameState.mechanical_network.get_rpm(GEAR_ID),
		GameState.mechanical_network.get_torque(GEAR_ID)
	]

func interact(_player: Node) -> void:
	if connected:
		GameState.notify("Gear and belt alignment is holding.", "info")
		return
	if not GameState.has_item("crude_gear", 1):
		GameState.notify("No Crude Gear. Press [C] after gathering 2 Scrap.", "error")
		return
	if not bool(GameState.get_flag("water_wheel_repaired", false)):
		GameState.notify("Repair the water wheel before connecting the transmission.", "error")
		return
	GameState.remove_item("crude_gear", 1)
	connected = true
	GameState.set_flag("gear_connected", true)
	_connect_network()
	GameState.add_journal(
		"Workshop Transmission",
		"Confirmation",
		"A %.1f:1 step-up gear trades torque for speed. The belt carries the transformed rotation toward workshop machines." % float(gear_definition.get("ratio", 1.0))
	)
	GameState.advance_objective(4)
	GameState.notify("Transmission connected. The belt snaps into motion.", "success")
	AudioManager.play_ui("complete")

func _on_machine_tick(delta: float) -> void:
	var flag_connected: bool = bool(GameState.get_flag("gear_connected", connected))
	if flag_connected != connected:
		connected = flag_connected
		if connected:
			_connect_network()
		else:
			GameState.mechanical_network.disconnect_nodes("water_wheel", GEAR_ID)
			GameState.mechanical_network.disconnect_nodes(GEAR_ID, BELT_ID)
	if connected and gear_visual != null:
		var rpm: float = GameState.mechanical_network.get_rpm(GEAR_ID)
		gear_visual.rotate_x(deg_to_rad((rpm / 60.0) * 360.0 * delta))
