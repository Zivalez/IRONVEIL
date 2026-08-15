extends Node

signal inventory_changed(inventory: Dictionary)
signal survival_changed(survival: Dictionary)
signal objective_changed(step: int, text: String)
signal journal_changed(entries: Array)
signal notification(message: String, kind: String)
signal boss_changed(name: String, health: float, max_health: float, vulnerable: bool)
signal boss_cleared()
signal flag_changed(flag: String, value: Variant)

const MechanicalNetworkClass = preload("res://scripts/core/mechanical_network.gd")

var inventory: Dictionary = {}
var survival: Dictionary = {}
var objective_step: int = 0
var journal_entries: Array[Dictionary] = []
var flags: Dictionary = {}
var mechanical_network: MechanicalNetwork = MechanicalNetworkClass.new()
var _applying_remote_flag: bool = false

const OBJECTIVES: Array[String] = [
	"Find something edible in the forest.",
	"Locate the abandoned workshop.",
	"Repair the workshop water wheel (needs 2 Scrap).",
	"Craft and connect a Crude Gear (2 Scrap).",
	"Load Logs into the mechanical saw.",
	"Keep the wheel powered and let the saw make Planks automatically.",
	"Repair Ashwick's east bridge (needs 6 Planks).",
	"Speak with Archivist Mara in Ashwick.",
	"Use the mechanical press to produce 2 Pressed Plates.",
	"Open the Foundry Vault gate (2 Plates + 4 Planks).",
	"Activate both thermal relief valves inside the Foundry.",
	"Defeat the Furnace Saint while its armor is thermally vulnerable.",
	"VERTICAL SLICE COMPLETE — Ashwick's Foundry is silent again.",
]

func _ready() -> void:
	TickManager.farming_tick.connect(_on_survival_tick)
	TickManager.machine_tick.connect(_on_machine_tick)
	NetworkManager.shared_flag_received.connect(_on_remote_shared_flag)
	new_game()

func new_game() -> void:
	inventory = {}
	survival = {
		"hunger": 72.0,
		"thirst": 76.0,
		"health": 100.0,
		"max_health": 100.0,
	}
	objective_step = 0
	journal_entries = []
	flags = {}
	mechanical_network.clear()
	clear_boss()
	_emit_all()

func _on_machine_tick(_delta: float) -> void:
	mechanical_network.solve()

func _on_survival_tick(delta: float) -> void:
	var harsh_multiplier: float = 1.45 if bool(SettingsManager.get_value("gameplay", "harsh_climate", false)) else 1.0
	survival["hunger"] = maxf(float(survival.get("hunger", 0.0)) - 0.35 * delta * harsh_multiplier, 0.0)
	survival["thirst"] = maxf(float(survival.get("thirst", 0.0)) - 0.55 * delta * harsh_multiplier, 0.0)
	if float(survival["hunger"]) <= 0.0 or float(survival["thirst"]) <= 0.0:
		survival["health"] = maxf(float(survival.get("health", 100.0)) - 2.0 * delta, 0.0)
	elif float(survival["hunger"]) > 65.0 and float(survival["thirst"]) > 65.0:
		survival["health"] = minf(float(survival.get("health", 100.0)) + 0.25 * delta, float(survival.get("max_health", 100.0)))
	survival_changed.emit(survival.duplicate(true))

func add_item(item_id: String, quantity: int = 1) -> void:
	if quantity <= 0:
		return
	inventory[item_id] = int(inventory.get(item_id, 0)) + quantity
	inventory_changed.emit(inventory.duplicate(true))
	if item_id == "pressed_plate" and objective_step == 8 and has_item("pressed_plate", 2):
		advance_objective(9)

func remove_item(item_id: String, quantity: int = 1) -> bool:
	if quantity <= 0:
		return true
	if int(inventory.get(item_id, 0)) < quantity:
		return false
	inventory[item_id] = int(inventory.get(item_id, 0)) - quantity
	if int(inventory[item_id]) <= 0:
		inventory.erase(item_id)
	inventory_changed.emit(inventory.duplicate(true))
	return true

func has_item(item_id: String, quantity: int = 1) -> bool:
	return int(inventory.get(item_id, 0)) >= quantity

func consume_food(item_id: String) -> bool:
	var item: Dictionary = DataRegistry.get_item(item_id)
	if item.is_empty() or not item.has("nutrition"):
		return false
	var nutrition_value: Variant = item.get("nutrition", {})
	if not (nutrition_value is Dictionary):
		return false
	if not remove_item(item_id, 1):
		return false
	var nutrition: Dictionary = nutrition_value as Dictionary
	survival["hunger"] = minf(100.0, float(survival["hunger"]) + float(nutrition.get("hunger", 0.0)))
	survival["thirst"] = minf(100.0, float(survival["thirst"]) + float(nutrition.get("thirst", 0.0)))
	survival_changed.emit(survival.duplicate(true))
	notify("Ate %s." % DataRegistry.display_name(item_id), "success")
	if objective_step == 0:
		advance_objective(1)
	return true

func can_craft(recipe_id: String) -> bool:
	var recipe: Dictionary = DataRegistry.get_recipe(recipe_id)
	if recipe.is_empty():
		return false
	var inputs_value: Variant = recipe.get("inputs", {})
	if not (inputs_value is Dictionary):
		return false
	var inputs: Dictionary = inputs_value as Dictionary
	for item_id_variant in inputs:
		var item_id: String = str(item_id_variant)
		if not has_item(item_id, int(inputs[item_id_variant])):
			return false
	return true

func craft(recipe_id: String) -> bool:
	var recipe: Dictionary = DataRegistry.get_recipe(recipe_id)
	if recipe.is_empty() or not can_craft(recipe_id):
		notify("Missing materials for %s." % str(recipe.get("name", recipe_id)), "error")
		return false
	var inputs_value: Variant = recipe.get("inputs", {})
	var outputs_value: Variant = recipe.get("outputs", {})
	if not (inputs_value is Dictionary) or not (outputs_value is Dictionary):
		notify("Recipe data is invalid: %s." % recipe_id, "error")
		return false
	var inputs: Dictionary = inputs_value as Dictionary
	var outputs: Dictionary = outputs_value as Dictionary
	for item_id_variant in inputs:
		remove_item(str(item_id_variant), int(inputs[item_id_variant]))
	for item_id_variant in outputs:
		add_item(str(item_id_variant), int(outputs[item_id_variant]))
	notify("Crafted %s." % str(recipe.get("name", recipe_id)), "success")
	add_journal("Crafting: %s" % str(recipe.get("name", recipe_id)), "Confirmation", "Field materials can be shaped into repeatable components when the right process is known.")
	return true

func advance_objective(new_step: int) -> void:
	var clamped: int = clampi(new_step, 0, OBJECTIVES.size() - 1)
	if clamped <= objective_step:
		return
	objective_step = clamped
	objective_changed.emit(objective_step, current_objective())

func current_objective() -> String:
	return OBJECTIVES[clampi(objective_step, 0, OBJECTIVES.size() - 1)]

func add_journal(title: String, stage: String, body: String) -> void:
	for entry in journal_entries:
		if str(entry.get("title", "")) == title and str(entry.get("stage", "")) == stage:
			return
	journal_entries.append({"title": title, "stage": stage, "body": body})
	journal_changed.emit(journal_entries.duplicate(true))

func set_flag(flag: String, value: Variant = true) -> void:
	flags[flag] = value
	flag_changed.emit(flag, value)
	var shared_flags: Array[String] = [
		"bridge_repaired", "mara_spoken", "foundry_gate_open",
		"thermal_valve_a", "thermal_valve_b"
	]
	if shared_flags.has(flag) and not _applying_remote_flag and NetworkManager.is_online() and not NetworkManager.is_server_mode():
		NetworkManager.submit_shared_flag(flag, value)

func _on_remote_shared_flag(flag: String, value: Variant) -> void:
	_applying_remote_flag = true
	flags[flag] = value
	flag_changed.emit(flag, value)
	_applying_remote_flag = false

func get_flag(flag: String, fallback: Variant = false) -> Variant:
	return flags.get(flag, fallback)

func notify(message: String, kind: String = "info") -> void:
	notification.emit(message, kind)

func update_boss(name: String, health: float, max_health: float, vulnerable: bool) -> void:
	boss_changed.emit(name, health, max_health, vulnerable)

func clear_boss() -> void:
	boss_cleared.emit()

func snapshot() -> Dictionary:
	return {
		"inventory": inventory.duplicate(true),
		"survival": survival.duplicate(true),
		"objective_step": objective_step,
		"journal_entries": journal_entries.duplicate(true),
		"flags": flags.duplicate(true),
		"mechanical_network": mechanical_network.to_dict(),
	}

func restore(data: Dictionary) -> void:
	var inventory_value: Variant = data.get("inventory", {})
	if inventory_value is Dictionary:
		inventory = (inventory_value as Dictionary).duplicate(true)
	var survival_value: Variant = data.get("survival", survival)
	if survival_value is Dictionary:
		survival = (survival_value as Dictionary).duplicate(true)
	objective_step = clampi(int(data.get("objective_step", 0)), 0, OBJECTIVES.size() - 1)
	journal_entries.clear()
	var journal_value: Variant = data.get("journal_entries", [])
	if journal_value is Array:
		for entry_value in journal_value:
			if entry_value is Dictionary:
				journal_entries.append((entry_value as Dictionary).duplicate(true))
	var flags_value: Variant = data.get("flags", {})
	if flags_value is Dictionary:
		flags = (flags_value as Dictionary).duplicate(true)
	var network_value: Variant = data.get("mechanical_network", {})
	if network_value is Dictionary:
		mechanical_network.from_dict(network_value as Dictionary)
	_emit_all()

func _emit_all() -> void:
	inventory_changed.emit(inventory.duplicate(true))
	survival_changed.emit(survival.duplicate(true))
	objective_changed.emit(objective_step, current_objective())
	journal_changed.emit(journal_entries.duplicate(true))
