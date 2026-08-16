extends Node3D

const VisualFactory = preload("res://scripts/game/visual_factory.gd")

const NODE_ID := "water_wheel"
var repaired := false
var wheel_mesh: MeshInstance3D
var definition: Dictionary = {}

func _ready() -> void:
	add_to_group("interactable")
	definition = DataRegistry.get_machine(NODE_ID)
	repaired = bool(GameState.get_flag("water_wheel_repaired", false))
	GameState.mechanical_network.add_source(
		NODE_ID,
		float(definition.get("base_rpm", 0.0)),
		float(definition.get("base_torque", 0.0)),
		repaired
	)
	_build_visual()
	TickManager.machine_tick.connect(_on_machine_tick)

func _build_visual() -> void:
	var support := MeshInstance3D.new()
	var support_mesh := BoxMesh.new()
	support_mesh.size = Vector3(0.35, 2.8, 0.35)
	support.mesh = support_mesh
	support.position.y = 1.4
	support.position.x = -0.8
	var support_mat: StandardMaterial3D = VisualFactory.make_material("res://assets/pixel/wood_texture.png", Color(0.76, 0.66, 0.50), 0.0, 0.95)
	support.material_override = support_mat
	add_child(support)

	wheel_mesh = MeshInstance3D.new()
	var cylinder := CylinderMesh.new()
	cylinder.top_radius = 1.55
	cylinder.bottom_radius = 1.55
	cylinder.height = 0.38
	cylinder.radial_segments = 16
	wheel_mesh.mesh = cylinder
	wheel_mesh.rotation_degrees.z = 90.0
	wheel_mesh.position.y = 1.6
	var mat: StandardMaterial3D = VisualFactory.make_material("res://assets/pixel/wood_texture.png", Color(0.86, 0.72, 0.50), 0.0, 0.90)
	wheel_mesh.material_override = mat
	add_child(wheel_mesh)

func get_prompt(_player: Node) -> String:
	if not repaired:
		return "[%s] Repair Water Wheel // Scrap x2" % SettingsManager.keybind_name("interact")
	var rpm: float = GameState.mechanical_network.get_rpm(NODE_ID)
	var torque: float = GameState.mechanical_network.get_torque(NODE_ID)
	return "Water Wheel ONLINE | %.0f RPM | %.0f Nm" % [rpm, torque]

func interact(_player: Node) -> void:
	if repaired:
		GameState.notify("The wheel is already transferring torque.", "info")
		return
	if not GameState.has_item("scrap", 2):
		GameState.notify("Need 2 Scrap to rebuild the wheel bracket.", "error")
		return
	GameState.remove_item("scrap", 2)
	repaired = true
	GameState.set_flag("water_wheel_repaired", true)
	GameState.mechanical_network.set_source_enabled(NODE_ID, true)
	GameState.add_journal(
		"Water Wheel",
		"Confirmation",
		"Flow turns the repaired wheel at about %.0f RPM, producing %.0f Nm before transmission losses." % [
			float(definition.get("base_rpm", 0.0)),
			float(definition.get("base_torque", 0.0))
		]
	)
	GameState.advance_objective(3)
	GameState.notify("Water wheel repaired. The main shaft begins to turn.", "success")
	AudioManager.play_ui("complete")

func _on_machine_tick(delta: float) -> void:
	if bool(GameState.get_flag("water_wheel_repaired", repaired)) != repaired:
		repaired = bool(GameState.get_flag("water_wheel_repaired", false))
		GameState.mechanical_network.set_source_enabled(NODE_ID, repaired)
	if repaired and wheel_mesh != null:
		var rpm: float = GameState.mechanical_network.get_rpm(NODE_ID)
		wheel_mesh.rotate_x(deg_to_rad((rpm / 60.0) * 360.0 * delta))
