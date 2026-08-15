extends SceneTree

var failures: Array[String] = []

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	_test_mechanical_network()
	_test_data_files()
	await _test_boot_scene_runtime()

	if failures.is_empty():
		print("IRONVEIL HEADLESS TESTS: PASS")
		quit(0)
		return

	for failure in failures:
		push_error(failure)
	print("IRONVEIL HEADLESS TESTS: FAIL (%d)" % failures.size())
	quit(1)

func _test_mechanical_network() -> void:
	var script_resource: Script = ResourceLoader.load("res://scripts/core/mechanical_network.gd") as Script
	if script_resource == null:
		failures.append("Mechanical network script could not be loaded.")
		return
	var network_value: Variant = script_resource.new()
	if not (network_value is RefCounted):
		failures.append("Mechanical network could not be instantiated.")
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
		failures.append("Mechanical saw should be powered by the prototype chain.")
	if absf(float(network.call("get_rpm", "gear")) - 96.0) > 0.01:
		failures.append("3:1 gearbox RPM transform is incorrect.")
	if absf(float(network.call("get_torque", "gear")) - 36.0) > 0.01:
		failures.append("3:1 gearbox torque transform is incorrect.")
	if float(network.call("get_torque", "saw")) <= 22.0:
		failures.append("Saw should receive enough post-loss torque.")

	network.call("set_source_enabled", "wheel", false)
	network.call("solve")
	if bool(network.call("is_powered", "saw")):
		failures.append("Saw must stop when the water wheel source is disabled.")

func _test_data_files() -> void:
	var paths: Array[String] = [
		"res://data/items.json",
		"res://data/recipes.json",
		"res://data/machines.json",
		"res://data/materials.json",
		"res://data/enemies.json",
		"res://data/biomes.json",
		"res://data/technologies.json",
	]
	for path in paths:
		if not FileAccess.file_exists(path):
			failures.append("Missing data catalog: %s" % path)
			continue
		var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
		if typeof(parsed) != TYPE_ARRAY:
			failures.append("Data catalog is not a JSON array: %s" % path)

func _test_boot_scene_runtime() -> void:
	# Reproduce the same entry path used by Web/native exports: boot.tscn loads
	# main.tscn dynamically and only removes its diagnostic overlay after a player
	# and active Camera3D exist.
	var packed: PackedScene = ResourceLoader.load("res://scenes/boot.tscn") as PackedScene
	if packed == null:
		failures.append("Project boot scene could not be parsed/loaded.")
		return

	var instance: Node = packed.instantiate()
	if instance == null:
		failures.append("Project boot scene could not be instantiated.")
		return
	root.add_child(instance)
	await process_frame
	await process_frame
	await physics_frame
	await process_frame

	if instance.get_node_or_null("Main") == null:
		failures.append("Boot scene did not attach the Phase 1 gameplay scene.")
	if get_nodes_in_group("players").is_empty():
		failures.append("Runtime smoke test did not create a player.")
	if root.get_camera_3d() == null:
		failures.append("Runtime smoke test did not create an active Camera3D.")
	if not GameState.mechanical_network.nodes.has("water_wheel"):
		failures.append("Runtime smoke test did not register the water wheel network source.")
	if not GameState.mechanical_network.nodes.has("mechanical_saw"):
		failures.append("Runtime smoke test did not register the mechanical saw consumer.")

	instance.queue_free()
	await process_frame
