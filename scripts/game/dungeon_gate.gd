extends Node3D

const VisualFactory = preload("res://scripts/game/visual_factory.gd")
const PLATE_COST := 2
const PLANK_COST := 4

var gate_body: StaticBody3D
var gate_mesh: MeshInstance3D

func _ready() -> void:
	add_to_group("interactable")
	_build_visual()
	_apply_state()
	GameState.flag_changed.connect(_on_flag_changed)

func _build_visual() -> void:
	gate_body = StaticBody3D.new()
	gate_body.name = "FoundryGateCollision"
	add_child(gate_body)
	gate_mesh = VisualFactory.make_box_mesh(
		Vector3(5.6, 4.2, 0.55),
		"res://assets/pixel/rust_metal.png",
		Color(0.76, 0.70, 0.62),
		0.65,
		0.62
	)
	gate_mesh.position.y = 2.1
	gate_body.add_child(gate_mesh)
	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(5.6, 4.2, 0.55)
	collision.shape = shape
	collision.position.y = 2.1
	gate_body.add_child(collision)
	var label: Label3D = VisualFactory.make_label("FOUNDRY VAULT // SEALED", Color(0.95, 0.59, 0.29))
	label.position = Vector3(0.0, 4.8, 0.0)
	add_child(label)

func _apply_state() -> void:
	var opened: bool = bool(GameState.get_flag("foundry_gate_open", false))
	if gate_mesh != null:
		gate_mesh.visible = not opened
	if gate_body != null:
		gate_body.collision_layer = 0 if opened else 1
		gate_body.collision_mask = 0 if opened else 1

func get_prompt(_player: Node) -> String:
	if bool(GameState.get_flag("foundry_gate_open", false)):
		return "Foundry Vault // gate unlocked"
	return "[%s] Repair gate drive // 2 Pressed Plates + 4 Planks" % SettingsManager.keybind_name("interact")

func interact(_player: Node) -> void:
	if bool(GameState.get_flag("foundry_gate_open", false)):
		GameState.notify("The Foundry gate remains locked in its open position.", "info")
		return
	if not bool(GameState.get_flag("mara_spoken", false)):
		GameState.notify("The gate mechanism is unfamiliar. Someone in Ashwick may recognize it.", "error")
		return
	if not GameState.has_item("pressed_plate", PLATE_COST) or not GameState.has_item("plank", PLANK_COST):
		GameState.notify("Gate repair requires 2 Pressed Plates and 4 Planks.", "error")
		return
	GameState.remove_item("pressed_plate", PLATE_COST)
	GameState.remove_item("plank", PLANK_COST)
	GameState.set_flag("foundry_gate_open", true)
	_apply_state()
	GameState.add_journal(
		"Foundry Gate",
		"Confirmation",
		"Pressed steel plates restore the gate's load-bearing linkage while Planks replace the rotten guide frame."
	)
	if GameState.objective_step == 9:
		GameState.advance_objective(10)
	GameState.notify("Foundry Vault opened. Pressure machinery is active below.", "success")
	AudioManager.play_ui("complete")

func _on_flag_changed(flag: String, _value: Variant) -> void:
	if flag == "foundry_gate_open":
		_apply_state()
