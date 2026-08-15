extends Node

signal network_changed(state: Dictionary)

var sources: Dictionary = {}
var consumers: Dictionary = {}
var switches: Dictionary = {}
var storage_kwh: float = 0.0
var storage_capacity_kwh: float = 18.0
var pollution: float = 0.0
var steam_pressure_kpa: float = 0.0

func _ready() -> void:
	TickManager.machine_tick.connect(_on_machine_tick)

func clear() -> void:
	sources.clear()
	consumers.clear()
	switches.clear()
	storage_kwh = 0.0
	pollution = 0.0
	steam_pressure_kpa = 0.0
	network_changed.emit(snapshot())

func register_source(id: String, output_kw: float, renewable: bool) -> void:
	sources[id] = {"output_kw": maxf(output_kw, 0.0), "enabled": true, "renewable": renewable}
	network_changed.emit(snapshot())

func register_consumer(id: String, load_kw: float, priority: int = 1) -> void:
	consumers[id] = {"load_kw": maxf(load_kw, 0.0), "enabled": true, "priority": clampi(priority, 0, 3), "powered": false}
	network_changed.emit(snapshot())

func set_switch(id: String, enabled: bool) -> void:
	switches[id] = enabled
	if consumers.has(id):
		consumers[id]["enabled"] = enabled
	if sources.has(id):
		sources[id]["enabled"] = enabled
	network_changed.emit(snapshot())

func is_powered(id: String) -> bool:
	return bool(consumers.get(id, {}).get("powered", false))

func set_steam_pressure(value: float) -> void:
	steam_pressure_kpa = clampf(value, 0.0, 1200.0)

func _on_machine_tick(delta: float) -> void:
	var generation: float = 0.0
	for source_value in sources.values():
		if source_value is Dictionary and bool((source_value as Dictionary).get("enabled", true)):
			generation += float((source_value as Dictionary).get("output_kw", 0.0))
	var remaining: float = generation
	var ordered: Array = consumers.keys()
	ordered.sort_custom(func(a: Variant, b: Variant) -> bool: return int(consumers[a].get("priority", 1)) > int(consumers[b].get("priority", 1)))
	for id_value in ordered:
		var id: String = str(id_value)
		var consumer: Dictionary = consumers[id]
		var load: float = float(consumer.get("load_kw", 0.0))
		var enabled: bool = bool(consumer.get("enabled", true))
		consumer["powered"] = enabled and remaining + storage_kwh * 3.6 >= load
		if bool(consumer["powered"]):
			var direct: float = minf(remaining, load)
			remaining -= direct
			var deficit: float = load - direct
			storage_kwh = maxf(storage_kwh - deficit * delta / 3600.0, 0.0)
		consumers[id] = consumer
	if remaining > 0.0:
		storage_kwh = minf(storage_kwh + remaining * delta / 3600.0, storage_capacity_kwh)
	var dirty_generation: float = 0.0
	for source_value in sources.values():
		if source_value is Dictionary and bool((source_value as Dictionary).get("enabled", true)) and not bool((source_value as Dictionary).get("renewable", false)):
			dirty_generation += float((source_value as Dictionary).get("output_kw", 0.0))
	pollution = clampf(pollution + dirty_generation * delta * 0.00008 - (0.003 if GameState.get_flag("regional_purifier_online", false) else 0.0005) * delta, 0.0, 100.0)
	network_changed.emit(snapshot())

func snapshot() -> Dictionary:
	return {
		"sources": sources.duplicate(true),
		"consumers": consumers.duplicate(true),
		"switches": switches.duplicate(true),
		"storage_kwh": storage_kwh,
		"storage_capacity_kwh": storage_capacity_kwh,
		"pollution": pollution,
		"steam_pressure_kpa": steam_pressure_kpa,
	}

func restore(data: Dictionary) -> void:
	var source_value: Variant = data.get("sources", {})
	var consumer_value: Variant = data.get("consumers", {})
	var switch_value: Variant = data.get("switches", {})
	sources = (source_value as Dictionary).duplicate(true) if source_value is Dictionary else {}
	consumers = (consumer_value as Dictionary).duplicate(true) if consumer_value is Dictionary else {}
	switches = (switch_value as Dictionary).duplicate(true) if switch_value is Dictionary else {}
	storage_kwh = float(data.get("storage_kwh", 0.0))
	storage_capacity_kwh = float(data.get("storage_capacity_kwh", 18.0))
	pollution = float(data.get("pollution", 0.0))
	steam_pressure_kpa = float(data.get("steam_pressure_kpa", 0.0))
	network_changed.emit(snapshot())
