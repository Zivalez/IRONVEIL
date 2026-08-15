extends Node3D

var item_id := "scrap"
var quantity := 1
var display_label := "Scrap"
var tint := Color(0.45, 0.38, 0.30)

func _ready() -> void:
	add_to_group("interactable")
	_build_visual()

func _build_visual() -> void:
	var mesh_instance := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = Vector3(0.55, 0.35, 0.55)
	mesh_instance.mesh = mesh
	var material := StandardMaterial3D.new()
	material.albedo_color = tint
	material.metallic = 0.45 if item_id == "scrap" else 0.0
	material.roughness = 0.75
	mesh_instance.material_override = material
	mesh_instance.position.y = 0.25
	add_child(mesh_instance)

func get_prompt(_player: Node) -> String:
	return "[F] Pick up %s x%d" % [display_label, quantity]

func interact(_player: Node) -> void:
	GameState.add_item(item_id, quantity)
	GameState.notify("Picked up %s x%d." % [display_label, quantity], "success")
	if item_id == "wild_berries":
		GameState.add_journal(
			"Wild Berries",
			"Observation",
			"Dark berries grow on low shrubs. They smell sweet and show no obvious signs of rot. Press [1] to eat one."
		)
	elif item_id == "scrap":
		GameState.add_journal(
			"Machine Scrap",
			"Observation",
			"Usable steel fragments remain around the abandoned industrial structures."
		)
	queue_free()
