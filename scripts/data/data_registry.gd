extends Node

var items: Dictionary = {}
var recipes: Dictionary = {}
var machines: Dictionary = {}
var materials: Dictionary = {}
var enemies: Dictionary = {}
var biomes: Dictionary = {}
var technologies: Dictionary = {}

const CATALOGS := {
	"items": "res://data/items.json",
	"recipes": "res://data/recipes.json",
	"machines": "res://data/machines.json",
	"materials": "res://data/materials.json",
	"enemies": "res://data/enemies.json",
	"biomes": "res://data/biomes.json",
	"technologies": "res://data/technologies.json",
}

func _ready() -> void:
	reload_all()

func reload_all() -> void:
	for catalog_name in CATALOGS:
		var loaded := _load_catalog(CATALOGS[catalog_name])
		set(catalog_name, loaded)

func _load_catalog(path: String) -> Dictionary:
	var result: Dictionary = {}
	if not FileAccess.file_exists(path):
		push_warning("Missing data catalog: %s" % path)
		return result
	var text := FileAccess.get_file_as_string(path)
	var parsed = JSON.parse_string(text)
	if typeof(parsed) != TYPE_ARRAY:
		push_error("Catalog must be a JSON array: %s" % path)
		return result
	for record in parsed:
		if typeof(record) != TYPE_DICTIONARY or not record.has("id"):
			continue
		result[str(record["id"])] = record
	return result

func get_item(item_id: String) -> Dictionary:
	return items.get(item_id, {})

func get_recipe(recipe_id: String) -> Dictionary:
	return recipes.get(recipe_id, {})

func get_machine(machine_id: String) -> Dictionary:
	return machines.get(machine_id, {})

func display_name(item_id: String) -> String:
	var item := get_item(item_id)
	return str(item.get("name", item_id))
