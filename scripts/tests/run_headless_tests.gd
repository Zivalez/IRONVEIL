extends SceneTree

const MechanicalNetworkClass = preload("res://scripts/core/mechanical_network.gd")

func _init() -> void:
	var failures: Array[String] = []
	_test_mechanical_network(failures)
	_test_data_files(failures)

	if failures.is_empty():
		print("IRONVEIL HEADLESS TESTS: PASS")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		print("IRONVEIL HEADLESS TESTS: FAIL (%d)" % failures.size())
		quit(1)

func _test_mechanical_network(failures: Array[String]) -> void:
	var network = MechanicalNetworkClass.new()
	network.add_source("wheel", 32.0, 120.0, true)
	network.add_transformer("gear", 3.0, 0.90, "gear")
	network.add_transformer("belt", 1.0, 0.95, "belt")
	network.add_consumer("saw", 70.0, 22.0, 0.92)
	network.connect_nodes("wheel", "gear")
	network.connect_nodes("gear", "belt")
	network.connect_nodes("belt", "saw")
	network.solve()

	if not network.is_powered("saw"):
		failures.append("Mechanical saw should be powered by the prototype chain.")
	if absf(network.get_rpm("gear") - 96.0) > 0.01:
		failures.append("3:1 gearbox RPM transform is incorrect.")
	if absf(network.get_torque("gear") - 36.0) > 0.01:
		failures.append("3:1 gearbox torque transform is incorrect.")
	if network.get_torque("saw") <= 22.0:
		failures.append("Saw should receive enough post-loss torque.")

	network.set_source_enabled("wheel", false)
	network.solve()
	if network.is_powered("saw"):
		failures.append("Saw must stop when the water wheel source is disabled.")

func _test_data_files(failures: Array[String]) -> void:
	for path in [
		"res://data/items.json",
		"res://data/recipes.json",
		"res://data/machines.json",
		"res://data/materials.json",
		"res://data/enemies.json",
		"res://data/biomes.json",
		"res://data/technologies.json",
	]:
		if not FileAccess.file_exists(path):
			failures.append("Missing data catalog: %s" % path)
			continue
		var parsed = JSON.parse_string(FileAccess.get_file_as_string(path))
		if typeof(parsed) != TYPE_ARRAY:
			failures.append("Data catalog is not a JSON array: %s" % path)
