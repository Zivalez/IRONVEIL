extends Node3D

const VisualFactory = preload("res://scripts/game/visual_factory.gd")
var recipe_ids: Array[String] = ["filter_cartridge", "irrigation_pipe", "steel_bloom"]
var selected_index: int = 0

func _ready() -> void:
	add_to_group("interactable")
	var body := VisualFactory.make_box_mesh(Vector3(2.2, 0.9, 1.1), "res://assets/pixel/wood_texture.png", Color(0.66, 0.50, 0.34), 0.0, 0.9)
	body.position.y = 0.45
	add_child(body)

func get_prompt(_player: Node) -> String:
	var recipe_id: String = recipe_ids[selected_index]
	var recipe: Dictionary = DataRegistry.get_recipe(recipe_id)
	return "[%s] Workshop craft: %s | interact cycles/attempts" % [SettingsManager.keybind_name("interact"), str(recipe.get("name", recipe_id))]

func interact(_player: Node) -> void:
	var recipe_id: String = recipe_ids[selected_index]
	if GameState.can_craft(recipe_id, "workshop"):
		GameState.craft(recipe_id, "workshop")
		if recipe_id == "steel_bloom" and GameState.objective_step == 15:
			GameState.advance_objective(16)
	else:
		selected_index = (selected_index + 1) % recipe_ids.size()
		var next_recipe: Dictionary = DataRegistry.get_recipe(recipe_ids[selected_index])
		GameState.notify("Workbench selected: %s" % str(next_recipe.get("name", recipe_ids[selected_index])), "info")
