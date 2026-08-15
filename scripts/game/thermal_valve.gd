extends Node3D

const VisualFactory = preload("res://scripts/game/visual_factory.gd")

var valve_id: String = "a"
var wheel: MeshInstance3D
var status_light: OmniLight3D

func configure(id_value: String) -> void:
	valve_id = id_value
	name = "ThermalValve_%s" % valve_id.to_upper()

func _ready() -> void:
	add_to_group("interactable")
	add_to_group("thermal_valve")
	_build_visual()
	TickManager.machine_tick.connect(_on_machine_tick)

func _build_visual() -> void:
	var column := VisualFactory.make_box_mesh(
		Vector3(0.8, 1.6, 0.8),
		"res://assets/pixel/rust_metal.png",
		Color(0.80, 0.72, 0.62),
		0.65,
		0.55
	)
	column.position.y = 0.8
	add_child(column)
	wheel = MeshInstance3D.new()
	var wheel_mesh := TorusMesh.new()
	wheel_mesh.inner_radius = 0.22
	wheel_mesh.outer_radius = 0.50
	wheel.mesh = wheel_mesh
	wheel.rotation_degrees.x = 90.0
	wheel.position = Vector3(0.0, 1.05, -0.52)
	wheel.material_override = VisualFactory.make_material(
		"res://assets/pixel/rust_metal.png",
		Color(0.92, 0.65, 0.40),
		0.72,
		0.45
	)
	add_child(wheel)
	status_light = OmniLight3D.new()
	status_light.position = Vector3(0.0, 1.25, -0.8)
	status_light.omni_range = 3.5
	status_light.light_energy = 1.4
	status_light.shadow_enabled = true
	add_child(status_light)

func _flag_name() -> String:
	return "thermal_valve_%s" % valve_id

func _is_active() -> bool:
	return bool(GameState.get_flag(_flag_name(), false))

func get_prompt(_player: Node) -> String:
	if not bool(GameState.get_flag("foundry_gate_open", false)):
		return "Thermal relief valve // inaccessible pressure lock"
	if _is_active():
		return "Thermal Valve %s // OPEN" % valve_id.to_upper()
	return "[%s] Open Thermal Valve %s" % [SettingsManager.keybind_name("interact"), valve_id.to_upper()]

func interact(_player: Node) -> void:
	if not bool(GameState.get_flag("foundry_gate_open", false)):
		GameState.notify("The valve is isolated behind the Foundry pressure lock.", "error")
		return
	if _is_active():
		GameState.notify("Valve %s is already venting." % valve_id.to_upper(), "info")
		return
	GameState.set_flag(_flag_name(), true)
	GameState.notify("Thermal Valve %s opened. Pressure falls across the guardian loop." % valve_id.to_upper(), "success")
	if bool(GameState.get_flag("thermal_valve_a", false)) and bool(GameState.get_flag("thermal_valve_b", false)):
		if not NetworkManager.is_online():
			GameState.set_flag("boss_vulnerable", true)
			GameState.set_flag("boss_vulnerability_started_ms", Time.get_ticks_msec())
		GameState.add_journal(
			"Furnace Saint Armor",
			"Confirmation",
			"Opening both relief valves causes rapid thermal contraction. The guardian's armor joints are vulnerable only for a short window."
		)
		if GameState.objective_step == 10:
			GameState.advance_objective(11)
		GameState.notify("THERMAL SHOCK // pressure collapse initiated.", "success")
		AudioManager.play_ui("complete")

func _on_machine_tick(delta: float) -> void:
	if wheel != null and _is_active():
		wheel.rotate_z(delta * 2.2)
	if status_light != null:
		status_light.light_color = Color(0.33, 0.92, 0.93) if _is_active() else Color(0.92, 0.32, 0.17)
		status_light.light_energy = 1.7 if _is_active() else 0.8
