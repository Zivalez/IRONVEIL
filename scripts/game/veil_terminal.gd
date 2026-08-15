extends Node3D

const VisualFactory = preload("res://scripts/game/visual_factory.gd")

var ending_id: String = "restore"
var ending_name: String = "RESTORE"
var _label: Label3D

func configure(id: String, title: String) -> void:
	ending_id = id
	ending_name = title

func _ready() -> void:
	add_to_group("interactable")
	var pedestal := VisualFactory.make_box_mesh(Vector3(2.2, 1.5, 2.2), "res://assets/pixel/veil_glow.png", _color(), 0.25, 0.22)
	pedestal.position.y = 0.75
	add_child(pedestal)
	var core: Sprite3D = VisualFactory.make_sprite("res://assets/pixel/veil_glow.png", 0.12, true)
	core.position.y = 2.4
	add_child(core)
	_label = VisualFactory.make_label(ending_name, _color().lightened(0.28))
	_label.position.y = 3.5
	add_child(_label)

func _process(delta: float) -> void:
	rotation.y += delta * 0.18

func get_prompt(_player: Node) -> String:
	var chosen: String = str(GameState.get_flag("veil_ending", ""))
	if not chosen.is_empty():
		return "THE VEIL HAS BEEN %s" % chosen.to_upper()
	return "[%s] Choose %s" % [SettingsManager.keybind_name("interact"), ending_name]

func interact(_player: Node) -> void:
	if not str(GameState.get_flag("veil_ending", "")).is_empty():
		GameState.notify("The Veil already carries your final decision.", "info")
		return
	if not bool(GameState.get_flag("veil_gateway_online", false)):
		GameState.notify("The gateway interface is incomplete.", "error")
		return
	GameState.set_flag("veil_ending", ending_id)
	GameState.set_flag("game_complete", true)
	GameState.advance_objective(32)
	GameState.add_journal("The Veil: %s" % ending_name, "Confirmation", _ending_text())
	GameState.notify("ENDING // %s — your infrastructure made this choice possible." % ending_name, "success")

func _ending_text() -> String:
	match ending_id:
		"restore":
			return "The original network returns under safeguards built from every regional lesson. Order is restored, but responsibility remains centralized."
		"destroy":
			return "The central network is dismantled. Settlements retain the distributed infrastructure and knowledge needed to remain independent."
		_:
			return "The Veil is rewritten as a federated system: shared knowledge, local control, and no single point of failure."

func _color() -> Color:
	match ending_id:
		"restore":
			return Color(0.42, 0.72, 0.86)
		"destroy":
			return Color(0.91, 0.43, 0.28)
		_:
			return Color(0.67, 0.45, 0.90)
