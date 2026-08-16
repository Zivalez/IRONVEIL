extends Node3D

const VisualFactory = preload("res://scripts/game/visual_factory.gd")

var item_id: String = "scrap"
var quantity: int = 1
var display_label: String = "Scrap"
var tint: Color = Color.WHITE
var _sprite: Sprite3D
var _t: float = 0.0

const PIXEL_ASSET_BY_ITEM := {
	"wild_berries": "res://assets/pixel/berries.png",
	"scrap": "res://assets/pixel/scrap.png",
	"log": "res://assets/pixel/log.png",
	"plank": "res://assets/pixel/plank.png",
	"crude_gear": "res://assets/pixel/gear.png",
	"pressed_plate": "res://assets/pixel/plate.png",
	"spring_water": "res://assets/pixel/water.png",
	"bandage": "res://assets/pixel/bandage.png",
}

func _ready() -> void:
	add_to_group("interactable")
	_t = randf() * TAU
	_build_visual()

func _process(delta: float) -> void:
	if _sprite == null:
		return
	if SettingsManager.juice_enabled("walk_bob"):
		_t += delta
		_sprite.position.y = 0.55 + sin(_t * 2.4) * 0.08 * SettingsManager.juice_intensity()

func _build_visual() -> void:
	var path: String = str(PIXEL_ASSET_BY_ITEM.get(item_id, "res://assets/pixel/scrap.png"))
	_sprite = VisualFactory.make_sprite(path, 0.034, true)
	_sprite.position.y = 0.55
	_sprite.modulate = tint
	add_child(_sprite)

func get_prompt(_player: Node) -> String:
	return "[%s] Pick up %s x%d" % [SettingsManager.keybind_name("interact"), display_label, quantity]

func interact(_player: Node) -> void:
	GameState.add_item(item_id, quantity)
	GameState.notify("Picked up %s x%d." % [display_label, quantity], "success")
	AudioManager.play_game("pickup")
	if item_id == "wild_berries":
		GameState.add_journal("Wild Berries", "Observation", "Dark berries grow on low shrubs. They smell sweet and show no obvious signs of rot.")
	elif item_id == "scrap":
		GameState.add_journal("Scrap Metal", "Observation", "Corroded fragments of pre-collapse machinery. Still workable with enough force.")
	elif item_id == "log":
		GameState.add_journal("Fallen Log", "Observation", "Dry enough to split. The grain suggests slow-grown forest wood.")
	queue_free()
