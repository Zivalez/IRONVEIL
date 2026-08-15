extends Node3D

const VisualFactory = preload("res://scripts/game/visual_factory.gd")
const NODE_ID := "irrigation_pump"
var definition: Dictionary = {}
var connected: bool = false

func _ready() -> void:
	add_to_group("interactable")
	definition = DataRegistry.get_machine(NODE_ID)
	connected = bool(GameState.get_flag("basin_header_connected", false))
	GameState.mechanical_network.add_consumer(NODE_ID,float(definition.get("min_rpm",45.0)),float(definition.get("min_torque",18.0)),float(definition.get("efficiency",0.91)))
	GameState.mechanical_network.connect_nodes("ashland_windmill",NODE_ID)
	var body := VisualFactory.make_box_mesh(Vector3(2.2,1.4,1.6),"res://assets/pixel/rust_metal.png",Color(0.53,0.62,0.60),0.58,0.52)
	body.position.y=0.7
	add_child(body)
	TickManager.machine_tick.connect(_on_tick)

func get_prompt(_player: Node) -> String:
	if not connected:
		return "[%s] Connect irrigation header | Irrigation Pipe x2 + Precision Component x1" % SettingsManager.keybind_name("interact")
	return "Irrigation Pump | %s" % ("FLOWING" if bool(GameState.get_flag("basin_irrigation_online",false)) else "NO MECHANICAL POWER")

func interact(_player: Node) -> void:
	if connected:
		return
	if not GameState.has_item("irrigation_pipe",2) or not GameState.has_item("precision_component",1):
		GameState.notify("Need Irrigation Pipe x2 and Precision Component x1.","error")
		return
	GameState.remove_item("irrigation_pipe",2)
	GameState.remove_item("precision_component",1)
	connected=true
	GameState.set_flag("basin_header_connected",true)
	GameState.notify("Irrigation header connected. It still needs live shaft power.","success")

func _on_tick(_delta: float) -> void:
	var online: bool = connected and GameState.mechanical_network.is_powered(NODE_ID)
	if bool(GameState.get_flag("basin_irrigation_online",false)) != online:
		GameState.set_flag("basin_irrigation_online",online)
		if online and GameState.objective_step == 18:
			GameState.advance_objective(19)
			GameState.notify("Flooded Basin irrigation is flowing.","success")
