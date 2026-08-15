extends Node

# IMPORTANT: This test runner is launched as a normal Godot scene, not with
# `godot --script`. A normal project run initializes project settings and all
# autoload singletons before this scene enters the tree, matching the lifecycle
# used by native and Web builds.

const SCRIPT_PATHS: Array[String] = [
	"res://scripts/core/mechanical_network.gd",
	"res://scripts/core/tick_manager.gd",
	"res://scripts/data/data_registry.gd",
	"res://scripts/core/settings_manager.gd",
	"res://scripts/core/game_state.gd",
	"res://scripts/core/save_manager.gd",
	"res://scripts/core/audio_manager.gd",
	"res://scripts/core/chunk_manager.gd",
	"res://scripts/game/player.gd",
	"res://scripts/game/camera_rig.gd",
	"res://scripts/game/pickup.gd",
	"res://scripts/game/workshop_sign.gd",
	"res://scripts/game/water_wheel.gd",
	"res://scripts/game/gear_assembly.gd",
	"res://scripts/game/mechanical_saw.gd",
	"res://scripts/game/mechanical_press.gd",
	"res://scripts/game/enemy.gd",
	"res://scripts/game/occluder.gd",
	"res://scripts/ui/hud.gd",
	"res://scripts/core/boot.gd",
	"res://scripts/game/main.gd",
]

const SCENE_PATHS: Array[String] = [
	"res://scenes/boot.tscn",
	"res://scenes/main.tscn",
]

const REQUIRED_AUTOLOADS: Array[String] = [
	"DataRegistry",
	"TickManager",
	"ChunkManager",
	"SettingsManager",
	"GameState",
	"SaveManager",
	"AudioManager",
]

const DATA_PATHS: Array[String] = [
	"res://data/items.json",
	"res://data/recipes.json",
	"res://data/machines.json",
	"res://data/materials.json",
	"res://data/enemies.json",
	"res://data/biomes.json",
	"res://data/technologies.json",
]

const REGISTRY_CATALOGS: Array[String] = [
	"items",
	"recipes",
	"machines",
	"materials",
	"enemies",
	"biomes",
	"technologies",
]

var failures: Array[String] = []

func _ready() -> void:
	call_deferred("_run")

func _run() -> void:
	print("IRONVEIL CI: normal-scene lifecycle started")
	_check_autoloads()
	_compile_and_scene_gate()
	_test_data_files()
	_test_runtime_data_registry()
	_test_mechanical_network()
	await _test_boot_scene_runtime()
	_finish()

func _check_autoloads() -> void:
	for singleton_name in REQUIRED_AUTOLOADS:
		var singleton: Node = get_node_or_null("/root/" + singleton_name)
		if singleton == null:
			_fail("Autoload singleton missing at runtime: %s" % singleton_name)
		else:
			print("IRONVEIL_AUTOLOAD_OK: ", singleton_name)

func _compile_and_scene_gate() -> void:
	for path in SCRIPT_PATHS:
		print("IRONVEIL_COMPILE_CHECK: ", path)
		var resource: Resource = ResourceLoader.load(path)
		if resource == null:
			_fail("Could not compile/load script: %s" % path)
			continue
		if not (resource is Script):
			_fail("Expected Script resource, got another type: %s" % path)
			continue
		var script: Script = resource as Script
		if not script.can_instantiate():
			_fail("Script loaded but cannot be instantiated (compile/class error): %s" % path)

	for path in SCENE_PATHS:
		print("IRONVEIL_SCENE_CHECK: ", path)
		var resource: Resource = ResourceLoader.load(path)
		if resource == null or not (resource is PackedScene):
			_fail("Could not parse/load scene: %s" % path)

	if failures.is_empty():
		print("IRONVEIL ALL-SCRIPT COMPILE GATE: PASS")
	else:
		print("IRONVEIL ALL-SCRIPT COMPILE GATE: FAIL")

func _test_data_files() -> void:
	for path in DATA_PATHS:
		if not FileAccess.file_exists(path):
			_fail("Missing data catalog: %s" % path)
			continue
		var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
		if typeof(parsed) != TYPE_ARRAY:
			_fail("Data catalog is not a JSON array: %s" % path)

func _test_runtime_data_registry() -> void:
	var registry: Node = get_node_or_null("/root/DataRegistry")
	if registry == null:
		return
	for property_name in REGISTRY_CATALOGS:
		var catalog_value: Variant = registry.get(property_name)
		if not (catalog_value is Dictionary):
			_fail("DataRegistry.%s is not a Dictionary" % property_name)
			continue
		var catalog: Dictionary = catalog_value as Dictionary
		if catalog.is_empty():
			_fail("DataRegistry.%s loaded empty" % property_name)

func _test_mechanical_network() -> void:
	var script_resource: Script = ResourceLoader.load("res://scripts/core/mechanical_network.gd") as Script
	if script_resource == null:
		_fail("Mechanical network script could not be loaded.")
		return
	var network_value: Variant = script_resource.new()
	if not (network_value is RefCounted):
		_fail("Mechanical network could not be instantiated.")
		return
	var network: RefCounted = network_value as RefCounted

	network.call("add_source", "wheel", 32.0, 120.0, true)
	network.call("add_transformer", "gear", 3.0, 0.90, "gear")
	network.call("add_transformer", "belt", 1.0, 0.95, "belt")
	network.call("add_consumer", "saw", 70.0, 22.0, 0.92)
	network.call("connect_nodes", "wheel", "gear")
	network.call("connect_nodes", "gear", "belt")
	network.call("connect_nodes", "belt", "saw")
	network.call("solve")

	if not bool(network.call("is_powered", "saw")):
		_fail("Mechanical saw should be powered by the prototype chain.")
	if absf(float(network.call("get_rpm", "gear")) - 96.0) > 0.01:
		_fail("3:1 gearbox RPM transform is incorrect.")
	if absf(float(network.call("get_torque", "gear")) - 36.0) > 0.01:
		_fail("3:1 gearbox torque transform is incorrect.")
	if float(network.call("get_torque", "saw")) <= 22.0:
		_fail("Saw should receive enough post-loss torque.")

	network.call("set_source_enabled", "wheel", false)
	network.call("solve")
	if bool(network.call("is_powered", "saw")):
		_fail("Saw must stop when the water wheel source is disabled.")

func _test_boot_scene_runtime() -> void:
	var packed: PackedScene = ResourceLoader.load("res://scenes/boot.tscn") as PackedScene
	if packed == null:
		_fail("Project boot scene could not be parsed/loaded.")
		return

	var instance: Node = packed.instantiate()
	if instance == null:
		_fail("Project boot scene could not be instantiated.")
		return
	add_child(instance)

	# boot.gd defers main.tscn loading, then waits two frames itself. Give the
	# exact exported entry path enough frames to initialize all runtime nodes.
	for _frame in range(8):
		await get_tree().process_frame
	await get_tree().physics_frame
	await get_tree().process_frame

	if instance.get_node_or_null("Main") == null:
		_fail("Boot scene did not attach the Phase 1 gameplay scene.")
	if get_tree().get_nodes_in_group("players").is_empty():
		_fail("Runtime smoke test did not create a player.")
	if get_viewport().get_camera_3d() == null:
		_fail("Runtime smoke test did not create an active Camera3D.")

	var game_state: Node = get_node_or_null("/root/GameState")
	if game_state == null:
		_fail("GameState autoload disappeared during boot smoke test.")
	else:
		var network_value: Variant = game_state.get("mechanical_network")
		if not (network_value is RefCounted):
			_fail("GameState mechanical_network is missing or invalid.")
		else:
			var network: RefCounted = network_value as RefCounted
			var wheel_state_value: Variant = network.call("get_status", "water_wheel")
			var saw_state_value: Variant = network.call("get_status", "mechanical_saw")
			if not (wheel_state_value is Dictionary) or (wheel_state_value as Dictionary).is_empty():
				_fail("Runtime smoke test did not register the water wheel network source.")
			if not (saw_state_value is Dictionary) or (saw_state_value as Dictionary).is_empty():
				_fail("Runtime smoke test did not register the mechanical saw consumer.")

	instance.queue_free()
	await get_tree().process_frame

func _fail(message: String) -> void:
	failures.append(message)
	push_error("IRONVEIL_CI_FAILURE: " + message)

func _finish() -> void:
	if failures.is_empty():
		print("IRONVEIL HEADLESS TESTS: PASS")
		get_tree().quit(0)
		return

	print("IRONVEIL HEADLESS TESTS: FAIL (%d)" % failures.size())
	for failure in failures:
		print("  - ", failure)
	get_tree().quit(1)
