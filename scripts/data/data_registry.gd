extends Node

var items: Dictionary = {}
var recipes: Dictionary = {}
var machines: Dictionary = {}
var materials: Dictionary = {}
var enemies: Dictionary = {}
var biomes: Dictionary = {}
var technologies: Dictionary = {}
var crops: Dictionary = {}
var npcs: Dictionary = {}

const CATALOGS := {
	"items": "res://data/items.json",
	"recipes": "res://data/recipes.json",
	"machines": "res://data/machines.json",
	"materials": "res://data/materials.json",
	"enemies": "res://data/enemies.json",
	"biomes": "res://data/biomes.json",
	"technologies": "res://data/technologies.json",
	"crops": "res://data/crops.json",
	"npcs": "res://data/npcs.json",
}

func _ready() -> void:
	reload_all()

func reload_all() -> void:
	for catalog_name in CATALOGS:
		var catalog_path: String = str(CATALOGS[catalog_name])
		var loaded: Dictionary = _load_catalog(catalog_path)
		set(catalog_name, loaded)

func _load_catalog(path: String) -> Dictionary:
	var result: Dictionary = {}
	if not FileAccess.file_exists(path):
		push_warning("Missing data catalog: %s" % path)
		return result
	var text: String = FileAccess.get_file_as_string(path)
	var parsed: Variant = JSON.parse_string(text)
	if not (parsed is Array):
		push_error("Catalog must be a JSON array: %s" % path)
		return result
	var records: Array = parsed as Array
	for record_value in records:
		if not (record_value is Dictionary):
			continue
		var record: Dictionary = record_value as Dictionary
		if not record.has("id"):
			continue
		result[str(record["id"])] = record
	return result

func get_item(item_id: String) -> Dictionary:
	return _get_record(items, item_id)

func get_recipe(recipe_id: String) -> Dictionary:
	return _get_record(recipes, recipe_id)

func get_machine(machine_id: String) -> Dictionary:
	return _get_record(machines, machine_id)

func get_material(material_id: String) -> Dictionary:
	return _get_record(materials, material_id)

func get_enemy(enemy_id: String) -> Dictionary:
	return _get_record(enemies, enemy_id)

func get_biome(biome_id: String) -> Dictionary:
	return _get_record(biomes, biome_id)

func get_technology(technology_id: String) -> Dictionary:
	return _get_record(technologies, technology_id)

func get_crop(crop_id: String) -> Dictionary:
	return _get_record(crops, crop_id)

func get_npc(npc_id: String) -> Dictionary:
	return _get_record(npcs, npc_id)

func _get_record(catalog: Dictionary, record_id: String) -> Dictionary:
	var value: Variant = catalog.get(record_id, {})
	return (value as Dictionary).duplicate(true) if value is Dictionary else {}

func display_name(item_id: String) -> String:
	var item: Dictionary = get_item(item_id)
	return str(item.get("name", item_id))
