extends Node

signal inventory_changed(inventory: Dictionary)
signal survival_changed(survival: Dictionary)
signal objective_changed(step: int, text: String)
signal journal_changed(entries: Array)
signal notification(message: String, kind: String)
signal boss_changed(name: String, health: float, max_health: float, vulnerable: bool)
signal boss_cleared()
signal flag_changed(flag: String, value: Variant)
signal region_changed(region_id: String, display_name: String)
signal injuries_changed(injuries: Dictionary)

const MechanicalNetworkClass = preload("res://scripts/core/mechanical_network.gd")
const BODY_PARTS: Array[String] = ["torso", "left_arm", "right_arm", "left_leg", "right_leg", "head"]
const CRAFT_TIER_RANK := {"handcraft": 0, "workshop": 1, "industrial": 2}

var inventory: Dictionary = {}
var survival: Dictionary = {}
var injuries: Dictionary = {}
var objective_step: int = 0
var journal_entries: Array[Dictionary] = []
var flags: Dictionary = {}
var world_objects: Dictionary = {}
var current_region_id: String = "green_hollow"
var ambient_temperature: float = 18.0
var mechanical_network: MechanicalNetwork = MechanicalNetworkClass.new()
var _applying_remote_flag: bool = false
var _applying_remote_world_object: bool = false
var _damage_event_counter: int = 0

const OBJECTIVES: Array[String] = [
	"Find something edible in Green Hollow.",
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
	"VERTICAL SLICE COMPLETE // Furnace Saint defeated. Survey the Ashlands.",
	"Trade with Machinist Harker and recover metallurgy stock.",
	"Bring the Ashland wind transmission online.",
	"Use workshop processing to make a Steel Bloom.",
	"Use the powered industrial hammer to form a Steel Beam.",
	"Reach the Flooded Basin and inspect the dead irrigation header.",
	"Restore the basin irrigation pump and connect irrigation pipe.",
	"Plant, water, and harvest a Field Tuber crop.",
	"Trade with Grower Nia and stabilize the food-water loop.",
	"MVP LOOP COMPLETE // Three regions connected.",
	"Cross the northern pass and survey the Iron Mountains.",
	"Rebuild the mine lift with structural steel and precision components.",
	"Recover pressure-grade alloy from the high mine.",
	"Reach Frostline and establish a heated shelter.",
	"Bring the steam engine online and stabilize its pressure.",
	"Restore electrical generation and the regional purification network.",
	"Descend into The Deep and recover the dormant relay core.",
	"Repair the Deep Rail to reconnect all regional logistics.",
	"Carry the relay core to the Veil Nexus and assemble the gateway interface.",
	"Choose the future of The Veil: Restore, Destroy, or Rewrite.",
	"IRONVEIL COMPLETE // Final choice recorded.",
]

func _ready() -> void:
	TickManager.farming_tick.connect(_on_survival_tick)
	TickManager.machine_tick.connect(_on_machine_tick)
	NetworkManager.shared_object_received.connect(_on_remote_world_object)
	new_game()

func new_game() -> void:
	inventory = {}
	survival = {
		"hunger": 72.0,
		"thirst": 76.0,
		"health": 100.0,
		"max_health": 100.0,
		"stamina": 100.0,
		"max_stamina": 100.0,
		"fatigue": 18.0,
		"body_temperature": 36.8,
		"stress": 12.0,
		"morale": 65.0,
		"infection_risk": 0.0,
	}
	injuries = {}
	objective_step = 0
	journal_entries = []
	flags = {}
	world_objects = {}
	current_region_id = "green_hollow"
	ambient_temperature = 18.0
	_damage_event_counter = 0
	mechanical_network.clear()
	InfrastructureNetwork.clear()
	clear_boss()
	_emit_all()

func _on_machine_tick(_delta: float) -> void:
	mechanical_network.solve()

func _on_survival_tick(delta: float) -> void:
	var harsh_multiplier: float = 1.45 if bool(SettingsManager.get_value("gameplay", "harsh_climate", false)) else 1.0
	var fatigue: float = float(survival.get("fatigue", 0.0))
	var hunger_drain: float = 0.32 + fatigue * 0.0015
	var thirst_drain: float = 0.50 + maxf(ambient_temperature - 22.0, 0.0) * 0.015
	survival["hunger"] = maxf(float(survival.get("hunger", 0.0)) - hunger_drain * delta * harsh_multiplier, 0.0)
	survival["thirst"] = maxf(float(survival.get("thirst", 0.0)) - thirst_drain * delta * harsh_multiplier, 0.0)

	var target_body_temperature: float = 36.8 + clampf((ambient_temperature - 20.0) * 0.035, -1.8, 1.8)
	var body_temperature: float = float(survival.get("body_temperature", 36.8))
	body_temperature = move_toward(body_temperature, target_body_temperature, 0.018 * delta * harsh_multiplier)
	survival["body_temperature"] = body_temperature

	var deprivation: bool = float(survival["hunger"]) <= 0.0 or float(survival["thirst"]) <= 0.0
	var thermal_danger: bool = body_temperature < 35.2 or body_temperature > 38.4
	if deprivation:
		survival["health"] = maxf(float(survival.get("health", 100.0)) - 2.0 * delta, 0.0)
	if thermal_danger:
		survival["health"] = maxf(float(survival.get("health", 100.0)) - 0.8 * delta, 0.0)
		survival["stress"] = minf(float(survival.get("stress", 0.0)) + 0.8 * delta, 100.0)

	var infection_risk: float = float(survival.get("infection_risk", 0.0))
	var untreated_count: int = 0
	for injury_value in injuries.values():
		if injury_value is Dictionary and not bool((injury_value as Dictionary).get("treated", false)):
			untreated_count += 1
	if untreated_count > 0:
		infection_risk = minf(infection_risk + float(untreated_count) * 0.05 * delta, 100.0)
	else:
		infection_risk = maxf(infection_risk - 0.03 * delta, 0.0)
	survival["infection_risk"] = infection_risk
	if infection_risk > 65.0:
		survival["health"] = maxf(float(survival.get("health", 100.0)) - 0.25 * delta, 0.0)

	if float(survival["hunger"]) > 60.0 and float(survival["thirst"]) > 60.0 and not thermal_danger and infection_risk < 40.0:
		survival["health"] = minf(float(survival.get("health", 100.0)) + 0.18 * delta, float(survival.get("max_health", 100.0)))
		survival["morale"] = minf(float(survival.get("morale", 50.0)) + 0.07 * delta, 100.0)
		survival["stress"] = maxf(float(survival.get("stress", 0.0)) - 0.08 * delta, 0.0)

	var stamina_regen: float = maxf(4.0 - float(survival.get("fatigue", 0.0)) * 0.025, 1.0)
	survival["stamina"] = minf(float(survival.get("stamina", 100.0)) + stamina_regen * delta, float(survival.get("max_stamina", 100.0)))
	survival_changed.emit(survival.duplicate(true))

func spend_stamina(amount: float) -> bool:
	var stamina: float = float(survival.get("stamina", 0.0))
	if stamina < amount:
		return false
	survival["stamina"] = maxf(stamina - amount, 0.0)
	survival["fatigue"] = minf(float(survival.get("fatigue", 0.0)) + amount * 0.025, 100.0)
	survival_changed.emit(survival.duplicate(true))
	return true

func rest_recovery(delta: float) -> void:
	survival["fatigue"] = maxf(float(survival.get("fatigue", 0.0)) - 1.2 * delta, 0.0)

func set_region_context(region_id: String) -> void:
	var biome: Dictionary = DataRegistry.get_biome(region_id)
	if biome.is_empty():
		return
	current_region_id = region_id
	ambient_temperature = float(biome.get("ambient_temperature", 20.0))
	region_changed.emit(region_id, str(biome.get("name", region_id)))
	add_journal("Region: %s" % str(biome.get("name", region_id)), "Observation", "Ambient conditions changed. Survival load now reflects this region's climate and hazards.")

func add_item(item_id: String, quantity: int = 1) -> void:
	if quantity <= 0:
		return
	inventory[item_id] = int(inventory.get(item_id, 0)) + quantity
	inventory_changed.emit(inventory.duplicate(true))
	if item_id == "pressed_plate" and objective_step == 8 and has_item("pressed_plate", 2):
		advance_objective(9)
	if item_id == "steel_bloom" and objective_step == 15:
		advance_objective(16)
	if item_id == "steel_beam" and objective_step == 16:
		advance_objective(17)
	if item_id == "field_tuber" and objective_step == 19:
		advance_objective(20)
	if item_id == "pressure_alloy" and objective_step == 23:
		advance_objective(24)
	if item_id == "relay_core" and objective_step == 28:
		set_flag("deep_relay_recovered", true)
		advance_objective(29)

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
	if not (nutrition_value is Dictionary) or not remove_item(item_id, 1):
		return false
	var nutrition: Dictionary = nutrition_value as Dictionary
	survival["hunger"] = minf(100.0, float(survival["hunger"]) + float(nutrition.get("hunger", 0.0)))
	survival["thirst"] = minf(100.0, float(survival["thirst"]) + float(nutrition.get("thirst", 0.0)))
	survival["morale"] = minf(100.0, float(survival.get("morale", 50.0)) + 2.0)
	survival_changed.emit(survival.duplicate(true))
	notify("Consumed %s." % DataRegistry.display_name(item_id), "success")
	if objective_step == 0:
		advance_objective(1)
	return true

func apply_damage(amount: float, injury_type: String = "cut") -> void:
	survival["health"] = maxf(float(survival.get("health", 100.0)) - amount, 0.0)
	survival["stress"] = minf(float(survival.get("stress", 0.0)) + amount * 0.7, 100.0)
	if amount >= 10.0:
		var body_part: String = BODY_PARTS[_damage_event_counter % BODY_PARTS.size()]
		_damage_event_counter += 1
		injuries[body_part] = {"type": injury_type, "severity": clampf(amount / 20.0, 0.25, 1.0), "treated": false}
		injuries_changed.emit(injuries.duplicate(true))
	survival_changed.emit(survival.duplicate(true))

func use_medical(item_id: String) -> bool:
	if item_id == "bandage":
		if not remove_item("bandage", 1):
			return false
		for part_variant in injuries.keys():
			var part: String = str(part_variant)
			var injury_value: Variant = injuries.get(part, {})
			if injury_value is Dictionary:
				var injury: Dictionary = (injury_value as Dictionary).duplicate(true)
				if not bool(injury.get("treated", false)):
					injury["treated"] = true
					injuries[part] = injury
					survival["infection_risk"] = maxf(float(survival.get("infection_risk", 0.0)) - 18.0, 0.0)
					injuries_changed.emit(injuries.duplicate(true))
					notify("Bandaged %s." % part.replace("_", " "), "success")
					return true
	if item_id == "salve" and remove_item("salve", 1):
		survival["infection_risk"] = maxf(float(survival.get("infection_risk", 0.0)) - 35.0, 0.0)
		survival_changed.emit(survival.duplicate(true))
		notify("Applied antiseptic salve.", "success")
		return true
	return false

func can_craft(recipe_id: String, station_tier: String = "handcraft") -> bool:
	var recipe: Dictionary = DataRegistry.get_recipe(recipe_id)
	if recipe.is_empty():
		return false
	var recipe_tier: String = str(recipe.get("tier", "handcraft"))
	if int(CRAFT_TIER_RANK.get(station_tier, 0)) < int(CRAFT_TIER_RANK.get(recipe_tier, 0)):
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

func craft(recipe_id: String, station_tier: String = "handcraft") -> bool:
	var recipe: Dictionary = DataRegistry.get_recipe(recipe_id)
	if recipe.is_empty():
		return false
	var recipe_tier: String = str(recipe.get("tier", "handcraft"))
	if int(CRAFT_TIER_RANK.get(station_tier, 0)) < int(CRAFT_TIER_RANK.get(recipe_tier, 0)):
		notify("%s requires a %s station." % [str(recipe.get("name", recipe_id)), recipe_tier], "error")
		return false
	if not can_craft(recipe_id, station_tier):
		notify("Missing materials for %s." % str(recipe.get("name", recipe_id)), "error")
		return false
	var inputs_value: Variant = recipe.get("inputs", {})
	var outputs_value: Variant = recipe.get("outputs", {})
	if not (inputs_value is Dictionary) or not (outputs_value is Dictionary):
		return false
	var inputs: Dictionary = inputs_value as Dictionary
	var outputs: Dictionary = outputs_value as Dictionary
	for item_id_variant in inputs:
		remove_item(str(item_id_variant), int(inputs[item_id_variant]))
	for item_id_variant in outputs:
		add_item(str(item_id_variant), int(outputs[item_id_variant]))
	notify("Crafted %s [%s]." % [str(recipe.get("name", recipe_id)), recipe_tier], "success")
	add_journal("Crafting: %s" % str(recipe.get("name", recipe_id)), "Confirmation", "The process works reliably at the %s tier." % recipe_tier)
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
		"thermal_valve_a", "thermal_valve_b", "ashlands_wind_online",
		"basin_irrigation_online", "phase3_mvp_complete", "mine_lift_online",
		"frostline_shelter_online", "steam_engine_online", "regional_generator_online",
		"regional_purifier_online", "deep_relay_recovered", "deep_rail_online",
		"veil_gateway_online", "veil_ending", "game_complete"
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

func set_world_object(object_id: String, state: Dictionary) -> void:
	world_objects[object_id] = state.duplicate(true)
	if not _applying_remote_world_object and NetworkManager.is_online() and not NetworkManager.is_server_mode():
		NetworkManager.submit_world_object(object_id, state)

func _on_remote_world_object(object_id: String, state: Dictionary) -> void:
	_applying_remote_world_object = true
	world_objects[object_id] = state.duplicate(true)
	_applying_remote_world_object = false

func get_world_object(object_id: String) -> Dictionary:
	var value: Variant = world_objects.get(object_id, {})
	return (value as Dictionary).duplicate(true) if value is Dictionary else {}

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
		"injuries": injuries.duplicate(true),
		"objective_step": objective_step,
		"journal_entries": journal_entries.duplicate(true),
		"flags": flags.duplicate(true),
		"world_objects": world_objects.duplicate(true),
		"current_region_id": current_region_id,
		"ambient_temperature": ambient_temperature,
		"mechanical_network": mechanical_network.to_dict(),
		"infrastructure_network": InfrastructureNetwork.snapshot(),
	}

func restore(data: Dictionary) -> void:
	var inventory_value: Variant = data.get("inventory", {})
	if inventory_value is Dictionary:
		inventory = (inventory_value as Dictionary).duplicate(true)
	var survival_value: Variant = data.get("survival", survival)
	if survival_value is Dictionary:
		survival = (survival_value as Dictionary).duplicate(true)
	var injuries_value: Variant = data.get("injuries", {})
	if injuries_value is Dictionary:
		injuries = (injuries_value as Dictionary).duplicate(true)
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
	var world_objects_value: Variant = data.get("world_objects", {})
	if world_objects_value is Dictionary:
		world_objects = (world_objects_value as Dictionary).duplicate(true)
	current_region_id = str(data.get("current_region_id", "green_hollow"))
	ambient_temperature = float(data.get("ambient_temperature", 18.0))
	var network_value: Variant = data.get("mechanical_network", {})
	if network_value is Dictionary:
		mechanical_network.from_dict(network_value as Dictionary)
	var infrastructure_value: Variant = data.get("infrastructure_network", {})
	if infrastructure_value is Dictionary:
		InfrastructureNetwork.restore(infrastructure_value as Dictionary)
	_emit_all()

func _emit_all() -> void:
	inventory_changed.emit(inventory.duplicate(true))
	survival_changed.emit(survival.duplicate(true))
	injuries_changed.emit(injuries.duplicate(true))
	objective_changed.emit(objective_step, current_objective())
	journal_changed.emit(journal_entries.duplicate(true))
	region_changed.emit(current_region_id, str(DataRegistry.get_biome(current_region_id).get("name", current_region_id)))
