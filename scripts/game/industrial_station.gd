extends Node3D

const VisualFactory = preload("res://scripts/game/visual_factory.gd")
const NODE_ID := "precision_bench"
var definition: Dictionary = {}

func _ready() -> void:
	add_to_group("interactable")
	definition = DataRegistry.get_machine(NODE_ID)
	GameState.mechanical_network.add_consumer(NODE_ID,float(definition.get("min_rpm",60.0)),float(definition.get("min_torque",20.0)),float(definition.get("efficiency",0.9)))
	GameState.mechanical_network.connect_nodes("ashland_windmill",NODE_ID)
	var body := VisualFactory.make_box_mesh(Vector3(1.9,1.1,1.3),"res://assets/pixel/rust_metal.png",Color(0.64,0.68,0.62),0.68,0.38)
	body.position.y=0.55
	add_child(body)

func get_prompt(_player: Node) -> String:
	return "[%s] Precision Bench | craft Precision Component | %s" % [SettingsManager.keybind_name("interact"), "POWERED" if GameState.mechanical_network.is_powered(NODE_ID) else "NO POWER"]

func interact(_player: Node) -> void:
	if not GameState.mechanical_network.is_powered(NODE_ID):
		GameState.notify("Precision bench needs live mechanical power.","error")
		return
	GameState.craft("precision_component","industrial")
