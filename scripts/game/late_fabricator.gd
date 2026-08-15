extends Node3D

const VisualFactory = preload("res://scripts/game/visual_factory.gd")
const RECIPES: Array[String] = ["pressure_vessel", "copper_coil", "industrial_relay", "rail_segment", "gateway_interface"]

func _ready() -> void:
	add_to_group("interactable")
	var base := VisualFactory.make_box_mesh(Vector3(3.2, 1.2, 1.8), "res://assets/pixel/rust_metal.png", Color(0.40, 0.55, 0.51), 0.72, 0.32)
	base.position.y = 0.6
	add_child(base)
	var label := VisualFactory.make_label("REGIONAL FABRICATOR", Color(0.59, 0.92, 0.78))
	label.position.y = 2.1
	add_child(label)

func get_prompt(_player: Node) -> String:
	var recipe_id: String = _next_recipe()
	if recipe_id.is_empty():
		return "[%s] Regional Fabricator // no complete material set" % SettingsManager.keybind_name("interact")
	return "[%s] Fabricate %s" % [SettingsManager.keybind_name("interact"), DataRegistry.get_recipe(recipe_id).get("name", recipe_id)]

func interact(_player: Node) -> void:
	var recipe_id: String = _next_recipe()
	if recipe_id.is_empty():
		GameState.notify("Fabricator has no complete material set. Inspect recipes in the field journal.", "info")
		return
	GameState.craft(recipe_id, "industrial")

func _next_recipe() -> String:
	for recipe_id in RECIPES:
		if GameState.can_craft(recipe_id, "industrial"):
			return recipe_id
	return ""
