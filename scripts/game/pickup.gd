extends Node3D

const VisualFactory = preload("res://scripts/game/visual_factory.gd")

var item_id: String = "scrap"
var quantity: int = 1
var display_label: String = "Scrap"
var tint: Color = Color.WHITE

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
	_build_visual()

func _build_visual() -> void:
	var path: String = str(PIXEL_ASSET_BY_ITEM.get(item_id, "res://assets/pixel/scrap.png"))
	var sprite: Sprite3D = VisualFactory.make_sprite(path, 0.032, true)
	sprite.position.y = 0.55
	sprite.modulate = tint
	add_child(sprite)

func get_prompt(_player: Node) -> String:
	return "[%s] Pick up %s x%d" % [SettingsManager.keybind_name("interact"), display_label, quantity]

func interact(_player: Node) -> void:
	GameState.add_item(item_id, quantity)
	GameState.notify("Picked up %s x%d." % [display_label, quantity], "success")
	if item_id == "wild_berries":
		GameState.add_journal("Wild Berries", "Observation", "Dark berries grow on low shrubs. They smell sweet and show no obvious signs of rot.")
	elif item_id == "scrap":
		GameState.add_journal("Machine Scrap", "Observation", "Usable steel fragments remain around abandoned industrial structures.")
	elif item_id == "spring_water":
		GameState.add_journal("Ashwick Spring", "Confirmation", "The cold spring runs clear enough to replenish thirst without industrial filtration.")
	queue_free()
