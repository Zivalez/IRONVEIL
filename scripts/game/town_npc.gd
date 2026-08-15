extends Node3D

const VisualFactory = preload("res://scripts/game/visual_factory.gd")

var npc_name: String = "Archivist Mara"
var sprite: Sprite3D

func _ready() -> void:
	add_to_group("interactable")
	sprite = VisualFactory.make_sprite("res://assets/pixel/archivist.png", 0.04, true)
	sprite.position.y = 0.95
	add_child(sprite)
	var label: Label3D = VisualFactory.make_label(npc_name, Color(0.72, 0.91, 0.87))
	label.position = Vector3(0.0, 2.25, 0.0)
	add_child(label)

func get_prompt(_player: Node) -> String:
	if bool(GameState.get_flag("mara_spoken", false)):
		return "[%s] Speak with %s" % [SettingsManager.keybind_name("interact"), npc_name]
	return "[%s] Ask %s about the Foundry" % [SettingsManager.keybind_name("interact"), npc_name]

func interact(_player: Node) -> void:
	if not bool(GameState.get_flag("bridge_repaired", false)):
		GameState.notify("Mara points toward the broken east bridge. 'Make the road usable first.'", "info")
		return
	if bool(GameState.get_flag("mara_spoken", false)):
		GameState.notify("Mara: 'The old Foundry gate accepts shaped plates. The pressure valves inside may expose its guardian.'", "info")
		return
	GameState.set_flag("mara_spoken", true)
	GameState.add_journal(
		"Ashwick Foundry",
		"Observation",
		"Archivist Mara says the sealed Foundry east of town was built around a mechanical pressure system. Two relief valves still feed the guardian chamber."
	)
	GameState.add_journal(
		"Furnace Guardian",
		"Hypothesis",
		"If the guardian's armor is heat-cycled by the Foundry pressure system, a short thermal weakness may appear."
	)
	if GameState.objective_step == 7:
		GameState.advance_objective(8)
	GameState.notify("Mara marked the Foundry entrance in your journal.", "success")
