extends Node3D

func _ready() -> void:
	add_to_group("interactable")
	var post := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = Vector3(1.6, 1.2, 0.15)
	post.mesh = mesh
	post.position.y = 1.0
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.18, 0.16, 0.13)
	mat.roughness = 0.9
	post.material_override = mat
	add_child(post)

func get_prompt(_player: Node) -> String:
	return "[F] Inspect abandoned workshop"

func interact(_player: Node) -> void:
	GameState.add_journal(
		"Abandoned Workshop",
		"Observation",
		"A water-driven transmission once powered this workshop. The wheel is damaged, but the shaft line still points toward a saw bench."
	)
	GameState.add_journal(
		"Abandoned Workshop",
		"Hypothesis",
		"If the water wheel can produce torque again, a gear and belt could carry that power into the saw."
	)
	if GameState.objective_step <= 1:
		GameState.advance_objective(2)
	GameState.notify("The workshop layout begins to make sense.", "info")
