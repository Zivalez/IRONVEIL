class_name MechanicalNetwork
extends RefCounted

var nodes: Dictionary = {}
var edges: Dictionary = {}

func clear() -> void:
	nodes.clear()
	edges.clear()

func add_source(node_id: String, rpm: float, torque: float, enabled: bool = false) -> void:
	nodes[node_id] = {
		"kind": "source",
		"base_rpm": maxf(rpm, 0.0),
		"base_torque": maxf(torque, 0.0),
		"enabled": enabled,
		"rpm": 0.0,
		"torque": 0.0,
		"powered": false,
	}
	edges[node_id] = edges.get(node_id, [])

func add_transformer(node_id: String, ratio: float = 1.0, efficiency: float = 0.95, kind: String = "gear") -> void:
	nodes[node_id] = {
		"kind": kind,
		"ratio": maxf(ratio, 0.01),
		"efficiency": clampf(efficiency, 0.0, 1.0),
		"rpm": 0.0,
		"torque": 0.0,
		"powered": false,
	}
	edges[node_id] = edges.get(node_id, [])

func add_consumer(node_id: String, min_rpm: float, min_torque: float, efficiency: float = 0.92) -> void:
	nodes[node_id] = {
		"kind": "consumer",
		"min_rpm": maxf(min_rpm, 0.0),
		"min_torque": maxf(min_torque, 0.0),
		"efficiency": clampf(efficiency, 0.0, 1.0),
		"rpm": 0.0,
		"torque": 0.0,
		"powered": false,
	}
	edges[node_id] = edges.get(node_id, [])

func connect_nodes(from_id: String, to_id: String) -> bool:
	if not nodes.has(from_id) or not nodes.has(to_id):
		return false
	var list: Array = edges.get(from_id, [])
	if not list.has(to_id):
		list.append(to_id)
	edges[from_id] = list
	return true

func disconnect_nodes(from_id: String, to_id: String) -> void:
	var list: Array = edges.get(from_id, [])
	list.erase(to_id)
	edges[from_id] = list

func set_source_enabled(node_id: String, enabled: bool) -> void:
	if not nodes.has(node_id):
		return
	var node: Dictionary = nodes[node_id]
	if node.get("kind", "") != "source":
		return
	node["enabled"] = enabled
	nodes[node_id] = node

func solve() -> void:
	for node_id in nodes:
		var reset_node: Dictionary = nodes[node_id]
		reset_node["rpm"] = 0.0
		reset_node["torque"] = 0.0
		reset_node["powered"] = false
		nodes[node_id] = reset_node

	var queue: Array[String] = []
	var visit_count: Dictionary = {}

	for node_id in nodes:
		var node: Dictionary = nodes[node_id]
		if node.get("kind", "") == "source" and bool(node.get("enabled", false)):
			node["rpm"] = float(node.get("base_rpm", 0.0))
			node["torque"] = float(node.get("base_torque", 0.0))
			node["powered"] = node["rpm"] > 0.0 and node["torque"] > 0.0
			nodes[node_id] = node
			queue.append(node_id)

	while not queue.is_empty():
		var current_id: String = str(queue.pop_front())
		visit_count[current_id] = int(visit_count.get(current_id, 0)) + 1
		if int(visit_count[current_id]) > nodes.size() + 1:
			push_warning("Mechanical network cycle detected around %s" % current_id)
			continue

		var parent: Dictionary = nodes[current_id]
		if not bool(parent.get("powered", false)):
			continue

		var children: Array = edges.get(current_id, [])
		for child_variant in children:
			var child_id := str(child_variant)
			if not nodes.has(child_id):
				continue
			var child: Dictionary = nodes[child_id]
			var incoming_rpm := float(parent.get("rpm", 0.0))
			var incoming_torque := float(parent.get("torque", 0.0))
			var kind := str(child.get("kind", ""))

			if kind == "gear" or kind == "belt":
				var ratio := float(child.get("ratio", 1.0))
				var efficiency := float(child.get("efficiency", 1.0))
				child["rpm"] = incoming_rpm * ratio
				child["torque"] = (incoming_torque / maxf(ratio, 0.01)) * efficiency
				child["powered"] = child["rpm"] > 0.0 and child["torque"] > 0.0
			elif kind == "consumer":
				var consumer_eff := float(child.get("efficiency", 1.0))
				child["rpm"] = incoming_rpm
				child["torque"] = incoming_torque * consumer_eff
				child["powered"] = (
					float(child["rpm"]) >= float(child.get("min_rpm", 0.0))
					and float(child["torque"]) >= float(child.get("min_torque", 0.0))
				)
			nodes[child_id] = child
			queue.append(child_id)

func is_powered(node_id: String) -> bool:
	return bool(nodes.get(node_id, {}).get("powered", false))

func get_rpm(node_id: String) -> float:
	return float(nodes.get(node_id, {}).get("rpm", 0.0))

func get_torque(node_id: String) -> float:
	return float(nodes.get(node_id, {}).get("torque", 0.0))

func get_status(node_id: String) -> Dictionary:
	return nodes.get(node_id, {}).duplicate(true)

func to_dict() -> Dictionary:
	return {
		"nodes": nodes.duplicate(true),
		"edges": edges.duplicate(true),
	}

func from_dict(data: Dictionary) -> void:
	nodes = data.get("nodes", {}).duplicate(true)
	edges = data.get("edges", {}).duplicate(true)
