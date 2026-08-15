extends Node3D

const VisualFactory = preload("res://scripts/game/visual_factory.gd")

func _ready() -> void:
	add_to_group("interactable")
	var sign: Sprite3D = VisualFactory.make_sprite("res://assets/pixel/sign_arrow.png", 0.035, true)
	sign.position.y = 1.2
	add_child(sign)
	var label: Label3D = VisualFactory.make_label("ABANDONED WORKSHOP", Color(0.91, 0.74, 0.38))
	label.position = Vector3(0.0, 2.0, 0.0)
	add_child(label)

func get_prompt(_player: Node) -> String:
	return "[%s] Inspect abandoned workshop" % SettingsManager.keybind_name("interact")

func interact(_player: Node) -> void:
	GameState.add_journal("Abandoned Workshop", "Observation", "A water-driven transmission once powered this workshop. The wheel is damaged, but the shaft line still points toward a saw bench.")
	GameState.add_journal("Abandoned Workshop", "Hypothesis", "If the water wheel can produce torque again, a gear and belt could carry that power into the saw.")
	if GameState.objective_step <= 1:
		GameState.advance_objective(2)
	GameState.notify("The workshop layout begins to make sense.", "info")
