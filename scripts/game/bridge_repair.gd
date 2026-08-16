extends Node3D

const VisualFactory = preload("res://scripts/game/visual_factory.gd")
const PLANK_COST := 6

var barrier: StaticBody3D
var planks_visual: Node3D

func _ready() -> void:
	add_to_group("interactable")
	_build_visual()
	_apply_state()
	GameState.flag_changed.connect(_on_flag_changed)

func _build_visual() -> void:
	planks_visual = Node3D.new()
	planks_visual.name = "BridgeDeck"
	add_child(planks_visual)
	for i in range(5):
		var plank: MeshInstance3D = VisualFactory.make_box_mesh(
			Vector3(1.1, 0.16, 4.8),
			"res://assets/pixel/wood_texture.png",
			Color(0.82, 0.72, 0.57),
			0.0,
			0.9
		)
		plank.position = Vector3(-2.4 + float(i) * 1.2, 0.15, 0.0)
		planks_visual.add_child(plank)

	barrier = StaticBody3D.new()
	barrier.name = "BrokenBridgeBarrier"
	barrier.position = Vector3(0.0, 0.8, 0.0)
	add_child(barrier)
	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(6.4, 1.6, 1.2)
	collision.shape = shape
	barrier.add_child(collision)

	var label: Label3D = VisualFactory.make_label("ASHWICK EAST BRIDGE", Color(0.91, 0.74, 0.38))
	label.position = Vector3(0.0, 1.4, 0.0)
	add_child(label)

func _apply_state() -> void:
	var repaired: bool = bool(GameState.get_flag("bridge_repaired", false))
	if planks_visual != null:
		planks_visual.visible = repaired
	if barrier != null:
		barrier.collision_layer = 0 if repaired else 1
		barrier.collision_mask = 0 if repaired else 1

func get_prompt(_player: Node) -> String:
	if bool(GameState.get_flag("bridge_repaired", false)):
		return "Ashwick East Bridge // repaired"
	return "[%s] Repair bridge // %d Planks required (%d carried)" % [SettingsManager.keybind_name("interact"), PLANK_COST, int(GameState.inventory.get("plank", 0))]

func interact(_player: Node) -> void:
	if bool(GameState.get_flag("bridge_repaired", false)):
		GameState.notify("The repaired bridge holds your weight.", "info")
		return
	if not GameState.has_item("plank", PLANK_COST):
		GameState.notify("The bridge needs %d Planks." % PLANK_COST, "error")
		return
	GameState.remove_item("plank", PLANK_COST)
	GameState.set_flag("bridge_repaired", true)
	_apply_state()
	GameState.add_journal(
		"Ashwick East Bridge",
		"Confirmation",
		"Six dimensioned Planks are enough to restore a safe crossing. Workshop automation now directly expands exploration range."
	)
	if GameState.objective_step == 6:
		GameState.advance_objective(7)
	GameState.notify("Bridge repaired. Ashwick is reachable.", "success")
	AudioManager.play_ui("complete")

func _on_flag_changed(flag: String, _value: Variant) -> void:
	if flag == "bridge_repaired":
		_apply_state()
