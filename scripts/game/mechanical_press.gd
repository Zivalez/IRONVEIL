extends Node3D

const PRESS_ID := "mechanical_press"
var queue_scrap := 0
var output_plate := 0
var process_accumulator := 0.0
var ram: MeshInstance3D
var definition: Dictionary = {}

func _ready() -> void:
	add_to_group("interactable")
	definition = DataRegistry.get_machine(PRESS_ID)
	queue_scrap = int(GameState.get_flag("press_queue", 0))
	output_plate = int(GameState.get_flag("press_output", 0))
	GameState.mechanical_network.add_consumer(
		PRESS_ID,
		float(definition.get("min_rpm", 0.0)),
		float(definition.get("min_torque", 0.0)),
		float(definition.get("efficiency", 1.0))
	)
	if bool(GameState.get_flag("gear_connected", false)):
		GameState.mechanical_network.connect_nodes("workshop_belt", PRESS_ID)
	_build_visual()
	TickManager.machine_tick.connect(_on_machine_tick)

func _build_visual() -> void:
	var frame := MeshInstance3D.new()
	var frame_mesh := BoxMesh.new()
	frame_mesh.size = Vector3(1.4, 2.1, 1.2)
	frame.mesh = frame_mesh
	frame.position.y = 1.05
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.20, 0.23, 0.22)
	mat.metallic = 0.7
	mat.roughness = 0.6
	frame.material_override = mat
	add_child(frame)

	ram = MeshInstance3D.new()
	var ram_mesh := BoxMesh.new()
	ram_mesh.size = Vector3(0.75, 0.45, 0.75)
	ram.mesh = ram_mesh
	ram.position.y = 1.4
	ram.material_override = mat
	add_child(ram)

func get_prompt(_player: Node) -> String:
	var powered: bool = GameState.mechanical_network.is_powered(PRESS_ID)
	if output_plate > 0:
		return "[F] Collect Pressed Plate x%d" % output_plate
	if GameState.has_item(str(definition.get("input_item", "scrap")), 1):
		return "[F] Load Scrap into Press | %s" % ("POWERED" if powered else "OFFLINE")
	return "Mechanical Press | %s | optional prototype machine" % ("POWERED" if powered else "OFFLINE")

func interact(_player: Node) -> void:
	if output_plate > 0:
		GameState.add_item(str(definition.get("output_item", "pressed_plate")), output_plate)
		output_plate = 0
		_store_state()
		GameState.notify("Collected pressed plates.", "success")
		return
	var input_item := str(definition.get("input_item", "scrap"))
	if GameState.has_item(input_item, int(definition.get("input_count", 1))):
		GameState.remove_item(input_item, int(definition.get("input_count", 1)))
		queue_scrap += 1
		_store_state()
		GameState.notify("Scrap loaded into the mechanical press.", "info")
	else:
		GameState.notify("No Scrap to load.", "error")

func _on_machine_tick(delta: float) -> void:
	var saved_queue := int(GameState.get_flag("press_queue", queue_scrap))
	var saved_output := int(GameState.get_flag("press_output", output_plate))
	if saved_queue != queue_scrap or saved_output != output_plate:
		queue_scrap = saved_queue
		output_plate = saved_output
		process_accumulator = 0.0

	if bool(GameState.get_flag("gear_connected", false)):
		GameState.mechanical_network.connect_nodes("workshop_belt", PRESS_ID)
	else:
		GameState.mechanical_network.disconnect_nodes("workshop_belt", PRESS_ID)
	if not GameState.mechanical_network.is_powered(PRESS_ID) or queue_scrap <= 0:
		process_accumulator = 0.0
		return
	process_accumulator += delta
	if ram != null:
		ram.position.y = 1.25 + sin(Time.get_ticks_msec() * 0.01) * 0.15
	var cycle_seconds := float(definition.get("cycle_seconds", 3.0))
	if process_accumulator >= cycle_seconds:
		process_accumulator -= cycle_seconds
		queue_scrap -= 1
		output_plate += int(definition.get("output_count", 1))
		_store_state()
		GameState.notify("Mechanical press completed a plate.", "success")

func _store_state() -> void:
	GameState.set_flag("press_queue", queue_scrap)
	GameState.set_flag("press_output", output_plate)
