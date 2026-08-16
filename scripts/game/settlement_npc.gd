extends Node3D

var _anim_t: float = 0.0
var _sprite_ref: Sprite3D

const VisualFactory = preload("res://scripts/game/visual_factory.gd")

var npc_id: String = "mara"
var definition: Dictionary = {}

func configure(id: String) -> void:
	npc_id = id

func _ready() -> void:
	add_to_group("interactable")
	add_to_group("npc")
	definition = DataRegistry.get_npc(npc_id)
	var sprite_path: String = "res://assets/pixel/archivist.png"
	var sprite: Sprite3D = VisualFactory.make_sprite(sprite_path, 0.04, true)
	sprite.position.y = 0.95
	add_child(sprite)
	var label: Label3D = VisualFactory.make_label(str(definition.get("name", npc_id)), Color(0.76, 0.91, 0.82))
	label.position = Vector3(0.0, 2.25, 0.0)
	add_child(label)

func get_prompt(_player: Node) -> String:
	return "[%s] Trade / speak with %s (%s)" % [SettingsManager.keybind_name("interact"), str(definition.get("name", npc_id)), str(definition.get("specialization", "survivor"))]

func interact(_player: Node) -> void:
	if definition.is_empty():
		return
	var cost_value: Variant = definition.get("cost", {})
	var offer_value: Variant = definition.get("offer", {})
	if not (cost_value is Dictionary) or not (offer_value is Dictionary):
		return
	var cost: Dictionary = cost_value as Dictionary
	for item_variant in cost:
		if not GameState.has_item(str(item_variant), int(cost[item_variant])):
			GameState.notify("%s: %s" % [str(definition.get("name", npc_id)), str(definition.get("dialogue", "I need something first."))], "info")
			return
	for item_variant in cost:
		GameState.remove_item(str(item_variant), int(cost[item_variant]))
	var offer: Dictionary = offer_value as Dictionary
	for item_variant in offer:
		GameState.add_item(str(item_variant), int(offer[item_variant]))
	var trade_flag: String = "npc_trade_" + npc_id
	GameState.set_flag(trade_flag, true)
	GameState.add_journal("Settlement Trade: %s" % str(definition.get("name", npc_id)), "Confirmation", "Settlements value useful production, not abstract quest currency. Specialization determines what each person can supply.")
	if npc_id == "harker" and GameState.objective_step == 13:
		GameState.advance_objective(14)
	elif npc_id == "nia" and GameState.objective_step == 20:
		GameState.set_flag("phase3_mvp_complete", true)
		GameState.advance_objective(21)
	GameState.notify("Barter completed with %s." % str(definition.get("name", npc_id)), "success")


func _process(delta: float) -> void:
	if _sprite_ref == null:
		for c in get_children():
			if c is Sprite3D:
				_sprite_ref = c as Sprite3D
				break
	if _sprite_ref != null and SettingsManager.juice_enabled("walk_bob"):
		_anim_t += delta
		_sprite_ref.position.y = 0.9 + sin(_anim_t * 2.0) * 0.04 * SettingsManager.juice_intensity()
