extends Node3D

const VisualFactory = preload("res://scripts/game/visual_factory.gd")
const NODE_ID := "ashland_windmill"
var repaired: bool = false
var rotor: MeshInstance3D
var definition: Dictionary = {}

func _ready() -> void:
	add_to_group("interactable")
	definition = DataRegistry.get_machine(NODE_ID)
	repaired = bool(GameState.get_flag("ashlands_wind_online", false))
	GameState.mechanical_network.add_source(NODE_ID, float(definition.get("base_rpm", 44.0)), float(definition.get("base_torque", 96.0)), repaired)
	rotor = VisualFactory.make_box_mesh(Vector3(0.25, 5.2, 0.25), "res://assets/pixel/wood_texture.png", Color(0.76,0.67,0.5), 0.0, 0.9)
	rotor.position.y = 3.2
	add_child(rotor)
	TickManager.machine_tick.connect(_on_machine_tick)

func get_prompt(_player: Node) -> String:
	if not repaired:
		return "[%s] Repair Ashland Windmill | Scrap x3 + Plank x2" % SettingsManager.keybind_name("interact")
	return "Ashland Windmill ONLINE | %.0f RPM | %.0f Nm" % [GameState.mechanical_network.get_rpm(NODE_ID), GameState.mechanical_network.get_torque(NODE_ID)]

func interact(_player: Node) -> void:
	if repaired:
		return
	if not GameState.has_item("scrap",3) or not GameState.has_item("plank",2):
		GameState.notify("Need Scrap x3 and Plank x2.","error")
		return
	GameState.remove_item("scrap",3)
	GameState.remove_item("plank",2)
	repaired = true
	GameState.set_flag("ashlands_wind_online",true)
	GameState.mechanical_network.set_source_enabled(NODE_ID,true)
	GameState.advance_objective(15)
	GameState.notify("Ashland wind transmission is online.","success")

func _on_machine_tick(delta: float) -> void:
	if repaired and rotor != null:
		rotor.rotate_z(deg_to_rad((GameState.mechanical_network.get_rpm(NODE_ID)/60.0)*360.0*delta))
