extends Node3D

const VisualFactory = preload("res://scripts/game/visual_factory.gd")

var plot_id: String = "green_plot_01"
var crop_id: String = "field_tuber"
var state: Dictionary = {}
var crop_sprite: Sprite3D

func configure(id: String, crop: String = "field_tuber") -> void:
	plot_id = id
	crop_id = crop

func _ready() -> void:
	add_to_group("interactable")
	add_to_group("farm_plot")
	state = GameState.get_world_object(plot_id)
	if state.is_empty():
		state = {"stage":"empty", "growth":0.0, "water":45.0, "fertility":80.0, "sunlight":82.0, "pests":0.0}
	_build_visual()
	TickManager.farming_tick.connect(_on_farming_tick)
	_refresh_visual()

func _build_visual() -> void:
	var bed := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = Vector3(3.2, 0.18, 2.0)
	bed.mesh = mesh
	bed.position.y = 0.09
	bed.material_override = VisualFactory.make_material("res://assets/pixel/forest_ground.png", Color(0.52, 0.38, 0.24), 0.0, 1.0)
	add_child(bed)
	crop_sprite = VisualFactory.make_sprite("res://assets/pixel/grass.png", 0.042, true)
	crop_sprite.position = Vector3(0.0, 0.75, 0.0)
	add_child(crop_sprite)

func get_prompt(_player: Node) -> String:
	var stage: String = str(state.get("stage", "empty"))
	if stage == "empty":
		return "[%s] Plant Tuber Seed | requires Seed x1" % SettingsManager.keybind_name("interact")
	if stage == "mature":
		return "[%s] Harvest Field Tubers" % SettingsManager.keybind_name("interact")
	if float(state.get("water", 0.0)) < 35.0:
		return "[%s] Water Crop | Water x1 | growth %.0f%%" % [SettingsManager.keybind_name("interact"), float(state.get("growth", 0.0))]
	return "Crop %.0f%% | water %.0f | fertility %.0f" % [float(state.get("growth", 0.0)), float(state.get("water", 0.0)), float(state.get("fertility", 0.0))]

func interact(_player: Node) -> void:
	var stage: String = str(state.get("stage", "empty"))
	if stage == "empty":
		if not GameState.remove_item("seed_tuber", 1):
			GameState.notify("Need a Tuber Seed.", "error")
			return
		state["stage"] = "growing"
		state["growth"] = 0.0
		state["pests"] = 0.0
		_store()
		GameState.add_journal("Field Agriculture", "Observation", "The crop bed tracks water, fertility, temperature and pest pressure rather than using a simple timer.")
		GameState.notify("Tuber seed planted.", "success")
		return
	if stage == "mature":
		var crop: Dictionary = DataRegistry.get_crop(crop_id)
		GameState.add_item(str(crop.get("harvest_item", "field_tuber")), int(crop.get("harvest_count", 3)))
		state = {"stage":"empty", "growth":0.0, "water":25.0, "fertility":maxf(float(state.get("fertility", 50.0)) - 12.0, 15.0), "sunlight":82.0, "pests":0.0}
		_store()
		_refresh_visual()
		GameState.notify("Harvested mature Field Tubers.", "success")
		return
	if GameState.remove_item("spring_water", 1):
		state["water"] = minf(float(state.get("water", 0.0)) + 45.0, 100.0)
		_store()
		GameState.notify("Crop bed watered.", "success")
	else:
		GameState.notify("Need clean water for the crop bed.", "error")

func _on_farming_tick(delta: float) -> void:
	if str(state.get("stage", "empty")) != "growing":
		return
	var crop: Dictionary = DataRegistry.get_crop(crop_id)
	if crop.is_empty():
		return
	var water: float = float(state.get("water", 0.0))
	var fertility: float = float(state.get("fertility", 0.0))
	var pests: float = float(state.get("pests", 0.0))
	var sunlight: float = float(state.get("sunlight", 82.0))
	var irrigation_bonus: float = 0.55 if bool(GameState.get_flag("basin_irrigation_online", false)) else 0.0
	water = clampf(water - float(crop.get("water_per_tick", 0.7)) * delta + irrigation_bonus * delta, 0.0, 100.0)
	fertility = clampf(fertility - float(crop.get("fertility_drain_per_tick", 0.12)) * delta, 0.0, 100.0)
	if water < 20.0:
		pests = minf(pests + 0.18 * delta, 100.0)
	else:
		pests = maxf(pests - 0.03 * delta, 0.0)
	var temp: float = float(DataRegistry.get_biome("flooded_basin").get("ambient_temperature", 13.0))
	var temp_ok: bool = temp >= float(crop.get("preferred_temperature_min", 10.0)) and temp <= float(crop.get("preferred_temperature_max", 26.0))
	var condition: float = clampf(minf(minf(water / 55.0, fertility / 55.0), sunlight / 70.0), 0.0, 1.0)
	if not temp_ok:
		condition *= 0.35
	condition *= clampf(1.0 - pests / 120.0, 0.15, 1.0)
	var growth_seconds: float = maxf(float(crop.get("growth_seconds", 150.0)), 1.0)
	var growth: float = float(state.get("growth", 0.0)) + (100.0 / growth_seconds) * delta * condition
	state["water"] = water
	state["fertility"] = fertility
	state["pests"] = pests
	state["sunlight"] = sunlight
	state["growth"] = minf(growth, 100.0)
	if growth >= 100.0:
		state["stage"] = "mature"
		GameState.add_journal("Field Agriculture", "Confirmation", "Reliable harvest requires water, suitable temperature and healthy soil. Powered irrigation removes much of the repeated watering chore.")
	_store()
	_refresh_visual()

func _store() -> void:
	GameState.set_world_object(plot_id, state)

func _refresh_visual() -> void:
	if crop_sprite == null:
		return
	var stage: String = str(state.get("stage", "empty"))
	crop_sprite.visible = stage != "empty"
	var growth: float = float(state.get("growth", 0.0))
	var scale_value: float = 0.45 + growth / 180.0
	crop_sprite.scale = Vector3.ONE * scale_value
