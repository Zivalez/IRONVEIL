extends Node3D

const SAW_ID := "mechanical_saw"
var process_accumulator := 0.0
var queue_logs := 0
var output_planks := 0
var blade_visual: MeshInstance3D
var definition: Dictionary = {}

func _ready() -> void:
	add_to_group("interactable")
	definition = DataRegistry.get_machine(SAW_ID)
	queue_logs = int(GameState.get_flag("saw_queue", 0))
	output_planks = int(GameState.get_flag("saw_output", 0))
	GameState.mechanical_network.add_consumer(
		SAW_ID,
		float(definition.get("min_rpm", 0.0)),
		float(definition.get("min_torque", 0.0)),
		float(definition.get("efficiency", 1.0))
	)
	if bool(GameState.get_flag("gear_connected", false)):
		GameState.mechanical_network.connect_nodes("workshop_belt", SAW_ID)
	_build_visual()
	TickManager.machine_tick.connect(_on_machine_tick)

func _build_visual() -> void:
	var table := MeshInstance3D.new()
	var table_mesh := BoxMesh.new()
	table_mesh.size = Vector3(2.2, 0.25, 1.2)
	table.mesh = table_mesh
	table.position.y = 0.75
	var table_mat := StandardMaterial3D.new()
	table_mat.albedo_color = Color(0.22, 0.18, 0.14)
	table_mat.roughness = 0.9
	table.material_override = table_mat
	add_child(table)

	blade_visual = MeshInstance3D.new()
	var blade_mesh := CylinderMesh.new()
	blade_mesh.top_radius = 0.62
	blade_mesh.bottom_radius = 0.62
	blade_mesh.height = 0.07
	blade_mesh.radial_segments = 24
	blade_visual.mesh = blade_mesh
	blade_visual.rotation_degrees.z = 90.0
	blade_visual.position = Vector3(0.0, 1.15, 0.0)
	var blade_mat := StandardMaterial3D.new()
	blade_mat.albedo_color = Color(0.62, 0.64, 0.61)
	blade_mat.metallic = 0.82
	blade_mat.roughness = 0.34
	blade_visual.material_override = blade_mat
	add_child(blade_visual)

func get_prompt(_player: Node) -> String:
	var powered: bool = GameState.mechanical_network.is_powered(SAW_ID)
	if output_planks > 0:
		return "[F] Collect Planks x%d | Saw %s" % [output_planks, "POWERED" if powered else "OFFLINE"]
	if GameState.has_item(str(definition.get("input_item", "log")), 1):
		return "[F] Load Logs into Saw | %s | queue %d" % ["POWERED" if powered else "NO POWER", queue_logs]
	return "Mechanical Saw | %s | queue %d | bring Logs" % ["POWERED" if powered else "OFFLINE", queue_logs]

func interact(_player: Node) -> void:
	if output_planks > 0:
		GameState.add_item(str(definition.get("output_item", "plank")), output_planks)
		GameState.notify("Collected %d Planks from the output tray." % output_planks, "success")
		output_planks = 0
		_store_state()
		return

	var input_item := str(definition.get("input_item", "log"))
	var available_logs := int(GameState.inventory.get(input_item, 0))
	if available_logs <= 0:
		GameState.notify("The saw needs Logs in its feed tray.", "error")
		return
	var to_load := mini(available_logs, 4 - queue_logs)
	if to_load <= 0:
		GameState.notify("Feed tray is already full.", "info")
		return
	GameState.remove_item(input_item, to_load)
	queue_logs += to_load
	_store_state()
	if GameState.objective_step == 4:
		GameState.advance_objective(5)
	GameState.notify("Loaded %d Logs. Processing is automatic while torque is available." % to_load, "success")

func _on_machine_tick(delta: float) -> void:
	var saved_queue := int(GameState.get_flag("saw_queue", queue_logs))
	var saved_output := int(GameState.get_flag("saw_output", output_planks))
	if saved_queue != queue_logs or saved_output != output_planks:
		queue_logs = saved_queue
		output_planks = saved_output
		process_accumulator = 0.0

	if bool(GameState.get_flag("gear_connected", false)):
		GameState.mechanical_network.connect_nodes("workshop_belt", SAW_ID)
	else:
		GameState.mechanical_network.disconnect_nodes("workshop_belt", SAW_ID)

	var powered: bool = GameState.mechanical_network.is_powered(SAW_ID)
	if powered and blade_visual != null:
		var rpm: float = GameState.mechanical_network.get_rpm(SAW_ID)
		blade_visual.rotate_x(deg_to_rad((rpm / 60.0) * 360.0 * delta))

	if not powered or queue_logs <= 0:
		process_accumulator = 0.0
		return

	process_accumulator += delta
	var cycle_seconds := float(definition.get("cycle_seconds", 2.5))
	if process_accumulator >= cycle_seconds:
		process_accumulator -= cycle_seconds
		queue_logs -= int(definition.get("input_count", 1))
		output_planks += int(definition.get("output_count", 3))
		_store_state()
		GameState.add_journal(
			"Mechanical Saw",
			"Confirmation",
			"The saw requires sufficient RPM and torque. Once supplied, loaded Logs are converted to Planks without repeated manual crafting."
		)
		if GameState.objective_step == 5:
			GameState.advance_objective(6)
			GameState.notify("The first Planks slide into the tray. The workshop lives again.", "success")
			AudioManager.play_ui("complete")

func _store_state() -> void:
	GameState.set_flag("saw_queue", queue_logs)
	GameState.set_flag("saw_output", output_planks)
