extends Node3D

const VisualFactory = preload("res://scripts/game/visual_factory.gd")
const NODE_ID := "industrial_hammer"
var definition: Dictionary = {}
var accumulator: float = 0.0
var queue: int = 0
var output: int = 0
var hammer: MeshInstance3D

func _ready() -> void:
	add_to_group("interactable")
	definition = DataRegistry.get_machine(NODE_ID)
	queue = int(GameState.get_flag("industrial_hammer_queue",0))
	output = int(GameState.get_flag("industrial_hammer_output",0))
	GameState.mechanical_network.add_consumer(NODE_ID,float(definition.get("min_rpm",75.0)),float(definition.get("min_torque",30.0)),float(definition.get("efficiency",0.88)))
	GameState.mechanical_network.connect_nodes("ashland_windmill",NODE_ID)
	hammer = VisualFactory.make_box_mesh(Vector3(1.0,1.8,1.0),"res://assets/pixel/rust_metal.png",Color(0.68,0.65,0.58),0.75,0.42)
	hammer.position.y = 1.5
	add_child(hammer)
	TickManager.machine_tick.connect(_on_tick)

func get_prompt(_player: Node) -> String:
	if output > 0:
		return "[%s] Collect Steel Beam x%d" % [SettingsManager.keybind_name("interact"),output]
	return "[%s] Load Steel Bloom | %s" % [SettingsManager.keybind_name("interact"), "POWERED" if GameState.mechanical_network.is_powered(NODE_ID) else "NO POWER"]

func interact(_player: Node) -> void:
	if output > 0:
		GameState.add_item("steel_beam",output)
		output=0
		_store()
		return
	if queue >= 3:
		return
	if GameState.remove_item("steel_bloom",1):
		queue += 1
		_store()
		GameState.notify("Steel Bloom loaded into industrial hammer.","success")
	else:
		GameState.notify("Need Steel Bloom.","error")

func _on_tick(delta: float) -> void:
	if queue <= 0 or not GameState.mechanical_network.is_powered(NODE_ID):
		accumulator=0.0
		return
	accumulator += delta
	if accumulator >= float(definition.get("cycle_seconds",4.5)):
		accumulator=0.0
		queue -= 1
		output += 1
		_store()
		GameState.add_journal("Industrial Shaping","Confirmation","Industrial-tier crafting is only possible while a live machine network supplies sufficient RPM and torque.")

func _store() -> void:
	GameState.set_flag("industrial_hammer_queue",queue)
	GameState.set_flag("industrial_hammer_output",output)
