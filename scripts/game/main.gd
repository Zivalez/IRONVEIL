extends Node3D

const PlayerScript = preload("res://scripts/game/player.gd")
const CameraRigScript = preload("res://scripts/game/camera_rig.gd")
const PickupScript = preload("res://scripts/game/pickup.gd")
const WorkshopSignScript = preload("res://scripts/game/workshop_sign.gd")
const WaterWheelScript = preload("res://scripts/game/water_wheel.gd")
const GearAssemblyScript = preload("res://scripts/game/gear_assembly.gd")
const MechanicalSawScript = preload("res://scripts/game/mechanical_saw.gd")
const MechanicalPressScript = preload("res://scripts/game/mechanical_press.gd")
const EnemyScript = preload("res://scripts/game/enemy.gd")
const HUDScript = preload("res://scripts/ui/hud.gd")
const OccluderScript = preload("res://scripts/game/occluder.gd")
const VisualFactory = preload("res://scripts/game/visual_factory.gd")
const PostProcessScript = preload("res://scripts/game/post_process.gd")
const ParticleFieldScript = preload("res://scripts/game/pixel_particle_field.gd")
const BridgeRepairScript = preload("res://scripts/game/bridge_repair.gd")
const TownNPCScript = preload("res://scripts/game/town_npc.gd")
const DungeonGateScript = preload("res://scripts/game/dungeon_gate.gd")
const ThermalValveScript = preload("res://scripts/game/thermal_valve.gd")
const BossScript = preload("res://scripts/game/boss_furnace_saint.gd")
const RemotePlayerScript = preload("res://scripts/game/remote_player.gd")

var player: CharacterBody3D
var camera_rig: Node3D
var hud: CanvasLayer
var remote_players: Dictionary = {}

func _ready() -> void:
	GameState.new_game()
	_build_environment()
	_build_vertical_slice_world()
	_spawn_player()
	_spawn_ui()
	_spawn_post_processing()
	_bind_network_visuals()
	GameState.add_journal(
		"Field Condition",
		"Observation",
		"You wake beside a cold camp on the Green Hollow road. An abandoned workshop, Ashwick, and a sealed Foundry lie along the old industrial route."
	)

func _build_environment() -> void:
	var world_environment := WorldEnvironment.new()
	var environment := Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color(0.035, 0.047, 0.047)
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color(0.38, 0.47, 0.43)
	environment.ambient_light_energy = 0.66
	world_environment.environment = environment
	add_child(world_environment)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-52.0, -28.0, 0.0)
	sun.light_color = Color(0.92, 0.84, 0.68)
	sun.light_energy = 1.15
	sun.shadow_enabled = true
	add_child(sun)

func _build_vertical_slice_world() -> void:
	# One continuous route: Green Hollow -> workshop -> broken bridge -> Ashwick -> Foundry Vault.
	_create_static_textured("ForestGround", Vector3(10.0, -0.3, 0.0), Vector3(45.0, 0.6, 38.0), "res://assets/pixel/forest_ground.png", Color(0.72, 0.82, 0.70))
	_create_static_textured("TownGround", Vector3(43.0, -0.28, 0.0), Vector3(20.0, 0.56, 30.0), "res://assets/pixel/town_stone.png", Color(0.76, 0.76, 0.68))
	_create_static_textured("FoundryGround", Vector3(68.0, -0.26, 0.0), Vector3(28.0, 0.52, 28.0), "res://assets/pixel/dungeon_floor.png", Color(0.66, 0.65, 0.62), 0.28, 0.84)
	_create_river_and_bridge()
	_build_forest()
	_build_workshop()
	_build_ashwick()
	_build_foundry()
	_spawn_world_resources()
	_spawn_world_enemies()
	_spawn_atmosphere()

func _create_river_and_bridge() -> void:
	var river := VisualFactory.make_box_mesh(Vector3(7.0, 0.08, 38.0), "res://assets/pixel/water.png", Color(0.50, 0.82, 0.88), 0.05, 0.25)
	river.name = "AshwickRiver"
	river.position = Vector3(28.0, 0.03, 0.0)
	add_child(river)
	# Invisible river blockers leave only the bridge crossing at z=0.
	_create_collision_only("RiverBlockNorth", Vector3(28.0, 0.6, 11.0), Vector3(7.0, 1.2, 15.0))
	_create_collision_only("RiverBlockSouth", Vector3(28.0, 0.6, -11.0), Vector3(7.0, 1.2, 15.0))
	var bridge: Node3D = BridgeRepairScript.new()
	bridge.name = "AshwickEastBridge"
	bridge.position = Vector3(28.0, 0.0, 0.0)
	add_child(bridge)

func _build_forest() -> void:
	for i in range(31):
		var x: float = -8.0 + float((i * 7) % 38)
		var z: float = -16.0 + float((i * 11) % 32)
		if (x > 8.0 and x < 25.0 and absf(z) < 8.0) or absf(x - 28.0) < 5.0:
			continue
		_create_tree(Vector3(x, 0.0, z), 0.82 + float(i % 4) * 0.08)
	for i in range(12):
		var grass: Sprite3D = VisualFactory.make_sprite("res://assets/pixel/grass.png", 0.032, true)
		grass.position = Vector3(-5.0 + float((i * 13) % 29), 0.35, -12.0 + float((i * 17) % 24))
		add_child(grass)

func _build_workshop() -> void:
	_create_static_textured("WorkshopFloor", Vector3(17.5, 0.08, -4.0), Vector3(14.0, 0.22, 8.0), "res://assets/pixel/workshop_floor.png", Color(0.82, 0.75, 0.66))
	_create_static_textured("WorkshopWallBack", Vector3(17.5, 1.5, -7.8), Vector3(14.0, 3.0, 0.35), "res://assets/pixel/stone_wall.png", Color(0.70, 0.66, 0.58))
	_create_static_textured("WorkshopWallSide", Vector3(24.3, 1.5, -4.0), Vector3(0.35, 3.0, 8.0), "res://assets/pixel/stone_wall.png", Color(0.70, 0.66, 0.58))
	var roof = OccluderScript.new()
	roof.name = "WorkshopRoofOccluder"
	roof.position = Vector3(17.5, 3.35, -4.0)
	add_child(roof)
	roof.configure(Vector3(14.2, 0.25, 8.2), Color(0.11, 0.10, 0.09))
	var sign: Node3D = WorkshopSignScript.new()
	sign.position = Vector3(9.3, 0.0, -3.0)
	add_child(sign)
	var wheel: Node3D = WaterWheelScript.new()
	wheel.position = Vector3(12.5, 0.0, -4.5)
	add_child(wheel)
	var gear: Node3D = GearAssemblyScript.new()
	gear.position = Vector3(16.0, 0.0, -4.5)
	add_child(gear)
	var saw: Node3D = MechanicalSawScript.new()
	saw.position = Vector3(20.0, 0.0, -4.5)
	add_child(saw)
	var press: Node3D = MechanicalPressScript.new()
	press.position = Vector3(20.5, 0.0, -1.4)
	add_child(press)
	var lamp := OmniLight3D.new()
	lamp.position = Vector3(19.0, 3.0, -3.8)
	lamp.light_color = Color(1.0, 0.56, 0.22)
	lamp.light_energy = 1.5
	lamp.omni_range = 7.0
	lamp.shadow_enabled = true
	add_child(lamp)

func _build_ashwick() -> void:
	for house_index in range(4):
		var z: float = -8.0 + float(house_index % 2) * 16.0
		var x: float = 37.0 + float(house_index / 2) * 9.0
		_create_house(Vector3(x, 0.0, z), house_index)
	var label: Label3D = VisualFactory.make_label("ASHWICK // INDUSTRIAL HAMLET", Color(0.92, 0.80, 0.46))
	label.position = Vector3(41.0, 3.0, 0.0)
	add_child(label)
	var mara: Node3D = TownNPCScript.new()
	mara.position = Vector3(40.0, 0.0, 3.0)
	add_child(mara)
	var town_lamp := OmniLight3D.new()
	town_lamp.position = Vector3(42.0, 3.2, 1.0)
	town_lamp.light_color = Color(1.0, 0.66, 0.30)
	town_lamp.light_energy = 1.7
	town_lamp.omni_range = 9.0
	town_lamp.shadow_enabled = true
	add_child(town_lamp)

func _build_foundry() -> void:
	# Outer industrial shell and gate.
	_create_static_textured("FoundryNorthWall", Vector3(68.0, 2.3, -13.5), Vector3(28.0, 4.6, 0.5), "res://assets/pixel/rust_metal.png", Color(0.72, 0.67, 0.60), 0.55, 0.62)
	_create_static_textured("FoundrySouthWall", Vector3(68.0, 2.3, 13.5), Vector3(28.0, 4.6, 0.5), "res://assets/pixel/rust_metal.png", Color(0.72, 0.67, 0.60), 0.55, 0.62)
	_create_static_textured("FoundryEastWall", Vector3(81.8, 2.3, 0.0), Vector3(0.5, 4.6, 27.0), "res://assets/pixel/rust_metal.png", Color(0.72, 0.67, 0.60), 0.55, 0.62)
	_create_static_textured("FoundryWestWallN", Vector3(54.2, 2.3, -8.1), Vector3(0.5, 4.6, 10.5), "res://assets/pixel/rust_metal.png", Color(0.72, 0.67, 0.60), 0.55, 0.62)
	_create_static_textured("FoundryWestWallS", Vector3(54.2, 2.3, 8.1), Vector3(0.5, 4.6, 10.5), "res://assets/pixel/rust_metal.png", Color(0.72, 0.67, 0.60), 0.55, 0.62)
	var gate: Node3D = DungeonGateScript.new()
	gate.position = Vector3(54.2, 0.0, 0.0)
	gate.rotation_degrees.y = 90.0
	add_child(gate)
	var valve_a: Node3D = ThermalValveScript.new()
	valve_a.configure("a")
	valve_a.position = Vector3(63.0, 0.0, -7.0)
	add_child(valve_a)
	var valve_b: Node3D = ThermalValveScript.new()
	valve_b.configure("b")
	valve_b.position = Vector3(63.0, 0.0, 7.0)
	add_child(valve_b)
	var boss: CharacterBody3D = BossScript.new()
	boss.position = Vector3(73.0, 0.0, 0.0)
	add_child(boss)
	for x in [59.0, 68.0, 77.0]:
		var foundry_light := OmniLight3D.new()
		foundry_light.position = Vector3(x, 3.1, 0.0)
		foundry_light.light_color = Color(1.0, 0.32, 0.10)
		foundry_light.light_energy = 1.8
		foundry_light.omni_range = 7.5
		foundry_light.shadow_enabled = true
		add_child(foundry_light)

func _spawn_world_resources() -> void:
	_spawn_pickup("wild_berries", 3, Vector3(3.5, 0.0, 2.0))
	_spawn_pickup("spring_water", 2, Vector3(5.0, 0.0, -3.0))
	_spawn_pickup("scrap", 1, Vector3(7.0, 0.0, -2.0))
	_spawn_pickup("scrap", 1, Vector3(8.0, 0.0, -4.0))
	_spawn_pickup("scrap", 1, Vector3(10.0, 0.0, -6.0))
	_spawn_pickup("scrap", 1, Vector3(22.0, 0.0, -6.2))
	_spawn_pickup("log", 2, Vector3(5.0, 0.0, 5.0))
	_spawn_pickup("log", 2, Vector3(9.0, 0.0, 4.0))
	# Phase-2 press stock after the original wheel + gear costs have been paid.
	_spawn_pickup("scrap", 2, Vector3(38.0, 0.0, -2.0))
	_spawn_pickup("scrap", 2, Vector3(46.0, 0.0, 2.0))

func _spawn_world_enemies() -> void:
	_spawn_enemy("hollow_vermin", Vector3(6.0, 0.7, -7.0))
	_spawn_enemy("hollow_vermin", Vector3(34.0, 0.7, 9.0))
	_spawn_enemy("hollow_stalker", Vector3(48.0, 0.7, -6.0))
	_spawn_enemy("hollow_stalker", Vector3(59.0, 0.7, 5.5))

func _spawn_atmosphere() -> void:
	var dust = ParticleFieldScript.new()
	dust.position = Vector3(12.0, 0.0, 0.0)
	dust.configure("res://assets/pixel/dust.png", 22, Vector3(42.0, 4.0, 32.0), Vector3(0.05, 0.08, 0.02), 0.024)
	add_child(dust)
	var steam = ParticleFieldScript.new()
	steam.position = Vector3(68.0, 0.0, 0.0)
	steam.configure("res://assets/pixel/steam.png", 18, Vector3(24.0, 5.0, 22.0), Vector3(0.03, 0.18, 0.01), 0.028)
	add_child(steam)

func _spawn_player() -> void:
	player = PlayerScript.new()
	player.name = "Player"
	player.position = Vector3(0.0, 0.8, 0.0)
	add_child(player)
	camera_rig = CameraRigScript.new()
	camera_rig.name = "CameraRig"
	camera_rig.target = player
	add_child(camera_rig)
	player.camera_rig = camera_rig

func _spawn_ui() -> void:
	hud = HUDScript.new()
	add_child(hud)
	player.interaction_prompt_changed.connect(hud.set_interaction_prompt)

func _spawn_post_processing() -> void:
	var post = PostProcessScript.new()
	post.name = "ModernPixelPost"
	add_child(post)

func _bind_network_visuals() -> void:
	NetworkManager.remote_player_state.connect(_on_remote_player_state)
	NetworkManager.remote_player_left.connect(_on_remote_player_left)

func _on_remote_player_state(peer_id: int, display_name: String, position_value: Vector3, yaw: float) -> void:
	var remote: Node3D = remote_players.get(peer_id, null) as Node3D
	if remote == null or not is_instance_valid(remote):
		remote = RemotePlayerScript.new()
		remote.configure(peer_id, display_name)
		remote.global_position = position_value
		add_child(remote)
		remote_players[peer_id] = remote
	if remote.has_method("set_network_state"):
		remote.set_network_state(position_value, yaw)

func _on_remote_player_left(peer_id: int) -> void:
	var remote_value: Variant = remote_players.get(peer_id, null)
	if remote_value is Node:
		(remote_value as Node).queue_free()
	remote_players.erase(peer_id)

func _spawn_pickup(item_id: String, quantity: int, pos: Vector3) -> void:
	var pickup = PickupScript.new()
	pickup.item_id = item_id
	pickup.quantity = quantity
	pickup.display_label = DataRegistry.display_name(item_id)
	pickup.position = pos
	add_child(pickup)

func _spawn_enemy(enemy_id: String, pos: Vector3) -> void:
	var enemy = EnemyScript.new()
	enemy.configure(enemy_id)
	enemy.position = pos
	add_child(enemy)

func _create_tree(pos: Vector3, scale_factor: float) -> void:
	var sprite: Sprite3D = VisualFactory.make_sprite("res://assets/pixel/tree.png", 0.055 * scale_factor, true)
	sprite.position = pos + Vector3.UP * 1.75 * scale_factor
	add_child(sprite)
	var body := StaticBody3D.new()
	body.position = pos
	body.collision_layer = 1
	body.collision_mask = 1
	add_child(body)
	var collision := CollisionShape3D.new()
	var shape := CylinderShape3D.new()
	shape.radius = 0.34 * scale_factor
	shape.height = 2.0 * scale_factor
	collision.shape = shape
	collision.position.y = 1.0 * scale_factor
	body.add_child(collision)

func _create_house(pos: Vector3, variant: int) -> void:
	var tint: Color = Color(0.78, 0.73, 0.63) if variant % 2 == 0 else Color(0.66, 0.70, 0.62)
	_create_static_textured("AshwickHouse%d" % variant, pos + Vector3.UP * 1.6, Vector3(6.0, 3.2, 5.0), "res://assets/pixel/stone_wall.png", tint)
	var roof := VisualFactory.make_box_mesh(Vector3(6.4, 0.35, 5.4), "res://assets/pixel/rust_metal.png", Color(0.58, 0.47, 0.39), 0.2, 0.78)
	roof.position = pos + Vector3.UP * 3.35
	add_child(roof)

func _create_static_textured(node_name: String, pos: Vector3, size: Vector3, texture_path: String, tint: Color, metallic: float = 0.0, roughness: float = 0.9) -> void:
	var body := StaticBody3D.new()
	body.name = node_name
	body.position = pos
	body.collision_layer = 1
	body.collision_mask = 1
	add_child(body)
	var mesh_instance: MeshInstance3D = VisualFactory.make_box_mesh(size, texture_path, tint, metallic, roughness)
	body.add_child(mesh_instance)
	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = size
	collision.shape = shape
	body.add_child(collision)

func _create_collision_only(node_name: String, pos: Vector3, size: Vector3) -> void:
	var body := StaticBody3D.new()
	body.name = node_name
	body.position = pos
	body.collision_layer = 1
	body.collision_mask = 1
	add_child(body)
	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = size
	collision.shape = shape
	body.add_child(collision)
