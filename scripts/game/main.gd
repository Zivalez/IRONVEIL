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
const RegionZoneScript = preload("res://scripts/game/region_zone.gd")
const FarmPlotScript = preload("res://scripts/game/farm_plot.gd")
const SettlementNPCScript = preload("res://scripts/game/settlement_npc.gd")
const WorkshopBenchScript = preload("res://scripts/game/workshop_bench.gd")
const WindmillSourceScript = preload("res://scripts/game/windmill_source.gd")
const IndustrialHammerScript = preload("res://scripts/game/industrial_hammer.gd")
const IndustrialStationScript = preload("res://scripts/game/industrial_station.gd")
const IrrigationPumpScript = preload("res://scripts/game/irrigation_pump.gd")
const EngineeringNodeScript = preload("res://scripts/game/engineering_node.gd")
const LateFabricatorScript = preload("res://scripts/game/late_fabricator.gd")
const VeilTerminalScript = preload("res://scripts/game/veil_terminal.gd")

var player: CharacterBody3D
var camera_rig: Node3D
var hud: CanvasLayer
var remote_players: Dictionary = {}
var _autosave_timer: Timer

func _ready() -> void:
	GameState.new_game()
	_build_environment()
	_build_vertical_slice_world()
	_build_phase3_regions()
	_build_phase4_regions()
	_spawn_player()
	_spawn_ui()
	_spawn_post_processing()
	_bind_network_visuals()
	_start_autosave()
	if str(AccountManager.active_world.get("kind", "personal")) == "shared":
		NetworkManager.create_room(str(AccountManager.active_world.get("name", "Shared World")), "", false)
	var server_snapshot: Dictionary = AccountManager.consume_pending_snapshot()
	if not server_snapshot.is_empty():
		SaveManager.apply_snapshot(server_snapshot, player)
		GameState.notify("Persistent world checkpoint restored.", "success")
	GameState.add_journal(
		"Field Condition",
		"Observation",
		"You wake beside a cold camp on the Green Hollow road. An abandoned workshop, Ashwick, and a sealed Foundry lie along the old industrial route."
	)

func _start_autosave() -> void:
	_autosave_timer = Timer.new()
	_autosave_timer.wait_time = 120.0
	_autosave_timer.autostart = true
	_autosave_timer.timeout.connect(_on_autosave)
	add_child(_autosave_timer)

func _on_autosave() -> void:
	if player != null and is_instance_valid(player):
		SaveManager.save_game(player)

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
	var workbench: Node3D = WorkshopBenchScript.new()
	workbench.position = Vector3(16.7, 0.0, -1.4)
	add_child(workbench)
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

func _build_phase3_regions() -> void:
	_build_region_zones()
	_build_ashlands_region()
	_build_flooded_basin_region()

func _build_region_zones() -> void:
	var green_zone: Area3D = RegionZoneScript.new()
	green_zone.configure("green_hollow", Vector3(92.0, 6.0, 44.0))
	green_zone.position = Vector3(24.0, 0.0, 0.0)
	add_child(green_zone)
	var ash_zone: Area3D = RegionZoneScript.new()
	ash_zone.configure("ashlands", Vector3(52.0, 6.0, 38.0))
	ash_zone.position = Vector3(108.0, 0.0, 0.0)
	add_child(ash_zone)
	var basin_zone: Area3D = RegionZoneScript.new()
	basin_zone.configure("flooded_basin", Vector3(54.0, 6.0, 42.0))
	basin_zone.position = Vector3(158.0, 0.0, 0.0)
	add_child(basin_zone)

func _build_ashlands_region() -> void:
	_create_static_textured("AshlandsGround", Vector3(108.0, -0.24, 0.0), Vector3(50.0, 0.48, 36.0), "res://assets/pixel/rust_metal.png", Color(0.55, 0.36, 0.25), 0.18, 0.94)
	var label: Label3D = VisualFactory.make_label("REGION II // ASHLANDS", Color(0.95, 0.58, 0.31))
	label.position = Vector3(100.0, 4.0, -12.0)
	add_child(label)
	for i in range(9):
		_create_static_textured("AshRuin%d" % i, Vector3(91.0 + float(i * 4), 1.0, -10.0 + float((i * 7) % 20)), Vector3(2.4, 2.0, 2.4), "res://assets/pixel/rust_metal.png", Color(0.53,0.48,0.42), 0.6, 0.5)
	var harker: Node3D = SettlementNPCScript.new()
	harker.configure("harker")
	harker.position = Vector3(96.0,0.0,4.0)
	add_child(harker)
	var ash_bench: Node3D = WorkshopBenchScript.new()
	ash_bench.position = Vector3(101.0,0.0,-3.0)
	add_child(ash_bench)
	var windmill: Node3D = WindmillSourceScript.new()
	windmill.position = Vector3(108.0,0.0,-5.0)
	add_child(windmill)
	var hammer: Node3D = IndustrialHammerScript.new()
	hammer.position = Vector3(116.0,0.0,-2.0)
	add_child(hammer)
	var precision: Node3D = IndustrialStationScript.new()
	precision.position = Vector3(116.0,0.0,3.0)
	add_child(precision)
	_spawn_pickup("iron_ore", 4, Vector3(102.0,0.0,8.0))
	_spawn_pickup("charcoal", 3, Vector3(105.0,0.0,10.0))
	_spawn_pickup("scrap", 4, Vector3(118.0,0.0,9.0))
	_spawn_enemy("hollow_stalker", Vector3(112.0,0.7,9.0))
	_spawn_enemy("hollow_stalker", Vector3(123.0,0.7,-8.0))
	var ash_dust = ParticleFieldScript.new()
	ash_dust.position = Vector3(108.0,0.0,0.0)
	ash_dust.configure("res://assets/pixel/dust.png", 26, Vector3(46.0,5.0,32.0), Vector3(0.08,0.03,0.01), 0.026)
	add_child(ash_dust)

func _build_flooded_basin_region() -> void:
	_create_static_textured("BasinGround", Vector3(158.0,-0.26,0.0), Vector3(50.0,0.52,40.0), "res://assets/pixel/town_stone.png", Color(0.43,0.54,0.50), 0.05, 0.92)
	var water := VisualFactory.make_box_mesh(Vector3(45.0,0.10,15.0), "res://assets/pixel/water.png", Color(0.40,0.72,0.78), 0.04, 0.28)
	water.position = Vector3(158.0,0.03,-10.0)
	add_child(water)
	var label: Label3D = VisualFactory.make_label("REGION III // FLOODED BASIN", Color(0.56,0.90,0.91))
	label.position = Vector3(150.0,4.0,10.0)
	add_child(label)
	var pump: Node3D = IrrigationPumpScript.new()
	pump.position = Vector3(148.0,0.0,-3.0)
	add_child(pump)
	var nia: Node3D = SettlementNPCScript.new()
	nia.configure("nia")
	nia.position = Vector3(164.0,0.0,7.0)
	add_child(nia)
	for i in range(3):
		var plot: Node3D = FarmPlotScript.new()
		plot.configure("basin_plot_%02d" % i)
		plot.position = Vector3(153.0 + float(i * 4),0.0,8.0)
		add_child(plot)
	_spawn_pickup("seed_tuber", 3, Vector3(151.0,0.0,4.0))
	_spawn_pickup("fiber", 5, Vector3(168.0,0.0,2.0))
	_spawn_pickup("spring_water", 4, Vector3(146.0,0.0,5.0))
	_spawn_pickup("scrap", 3, Vector3(171.0,0.0,-4.0))
	_spawn_enemy("hollow_vermin", Vector3(160.0,0.7,-1.0))
	_spawn_enemy("hollow_vermin", Vector3(172.0,0.7,10.0))

func _build_phase4_regions() -> void:
	_build_late_region_zones()
	_build_iron_mountains()
	_build_frostline()
	_build_the_deep()
	_build_veil_nexus()

func _build_late_region_zones() -> void:
	for zone_data in [
		["iron_mountains", Vector3(210.0, 0.0, 0.0), Vector3(48.0, 8.0, 40.0)],
		["frostline", Vector3(258.0, 0.0, 0.0), Vector3(48.0, 8.0, 40.0)],
		["the_deep", Vector3(306.0, 0.0, 0.0), Vector3(48.0, 8.0, 40.0)],
		["veil_nexus", Vector3(352.0, 0.0, 0.0), Vector3(44.0, 8.0, 38.0)],
	]:
		var zone: Area3D = RegionZoneScript.new()
		var zone_size: Vector3 = zone_data[2]
		var zone_position: Vector3 = zone_data[1]
		zone.configure(str(zone_data[0]), zone_size)
		zone.position = zone_position
		add_child(zone)

func _build_iron_mountains() -> void:
	_create_static_textured("IronMountainGround", Vector3(210.0,-0.24,0.0), Vector3(48.0,0.48,38.0), "res://assets/pixel/stone_wall.png", Color(0.43,0.45,0.42),0.32,0.82)
	var label: Label3D = VisualFactory.make_label("REGION IV // IRON MOUNTAINS", Color(0.78,0.75,0.62))
	label.position = Vector3(201.0,5.0,-13.0)
	add_child(label)
	for i in range(11):
		var height_value: float = 2.4 + float(i % 4) * 1.2
		_create_static_textured("MountainSpire%d" % i, Vector3(190.0 + float(i * 4),height_value * 0.5,-14.0 + float((i * 9) % 28)),Vector3(2.6,height_value,2.6),"res://assets/pixel/stone_wall.png",Color(0.45,0.46,0.43),0.28,0.90)
	var torren: Node3D = SettlementNPCScript.new()
	torren.configure("torren")
	torren.position = Vector3(198.0,0.0,6.0)
	add_child(torren)
	_spawn_engineering_node({"id":"mine_lift","name":"Counterweight Mine Lift","requirements":{"steel_beam":2,"precision_component":1},"rewards":{"pressure_alloy":2},"flag":"mine_lift_online","objective_from":22,"objective_to":23,"technology":"mechanical"},Vector3(212.0,0.0,-4.0))
	var fabricator: Node3D = LateFabricatorScript.new()
	fabricator.position = Vector3(204.0,0.0,7.0)
	add_child(fabricator)
	_spawn_pickup("pressure_alloy",2,Vector3(220.0,0.0,-8.0))
	_spawn_pickup("stone",6,Vector3(218.0,0.0,8.0))
	_spawn_pickup("iron_ore",6,Vector3(226.0,0.0,3.0))
	_spawn_enemy("ore_mite",Vector3(215.0,0.7,9.0))
	_spawn_enemy("ore_mite",Vector3(226.0,0.7,-7.0))

func _build_frostline() -> void:
	_create_static_textured("FrostlineGround",Vector3(258.0,-0.24,0.0),Vector3(48.0,0.48,38.0),"res://assets/pixel/stone_wall.png",Color(0.60,0.72,0.73),0.08,0.76)
	var label: Label3D = VisualFactory.make_label("REGION V // FROSTLINE",Color(0.68,0.91,0.94))
	label.position=Vector3(250.0,5.0,-13.0)
	add_child(label)
	for i in range(13):
		var shard := VisualFactory.make_box_mesh(Vector3(0.6,2.0 + float(i%3),0.6),"res://assets/pixel/water.png",Color(0.58,0.88,0.94),0.08,0.18)
		shard.position=Vector3(238.0 + float((i*7)%39),1.0,-13.0 + float((i*11)%27))
		shard.rotation_degrees.z=12.0 + float(i%4)*7.0
		add_child(shard)
	var sela: Node3D=SettlementNPCScript.new()
	sela.configure("sela")
	sela.position=Vector3(246.0,0.0,6.0)
	add_child(sela)
	_spawn_engineering_node({"id":"frostline_shelter","name":"Frostline Thermal Shelter","requirements":{"steel_beam":1,"insulation_fiber":2},"flag":"frostline_shelter_online","objective_from":25,"objective_to":26,"technology":"steam"},Vector3(252.0,0.0,5.0))
	_spawn_engineering_node({"id":"steam_engine","name":"Compound Steam Engine","requirements":{"pressure_vessel":1,"charcoal":3},"flag":"steam_engine_online","objective_from":26,"objective_to":27,"technology":"steam"},Vector3(261.0,0.0,-4.0))
	_spawn_engineering_node({"id":"regional_generator","name":"Regional Generator","requirements":{"copper_coil":2,"precision_component":1},"flag":"regional_generator_online","technology":"electrical","prerequisite_flag":"steam_engine_online","electrical_output_kw":22.0},Vector3(268.0,0.0,-4.0))
	_spawn_engineering_node({"id":"regional_purifier","name":"Climate Purification Array","requirements":{"filter_cartridge":2,"relay":1},"flag":"regional_purifier_online","objective_from":27,"objective_to":28,"technology":"electrical","prerequisite_flag":"regional_generator_online","electrical_load_kw":8.0},Vector3(272.0,0.0,6.0))
	var frost_fabricator: Node3D=LateFabricatorScript.new()
	frost_fabricator.position=Vector3(255.0,0.0,7.0)
	add_child(frost_fabricator)
	_spawn_pickup("insulation_fiber",5,Vector3(244.0,0.0,-7.0))
	_spawn_pickup("ice_core",2,Vector3(273.0,0.0,-10.0))
	_spawn_pickup("deep_ore",2,Vector3(266.0,0.0,10.0))
	_spawn_pickup("charcoal",4,Vector3(241.0,0.0,10.0))
	_spawn_enemy("frost_wraith",Vector3(258.0,0.7,10.0))
	_spawn_enemy("frost_wraith",Vector3(276.0,0.7,-8.0))

func _build_the_deep() -> void:
	_create_static_textured("DeepGround",Vector3(306.0,-0.24,0.0),Vector3(48.0,0.48,38.0),"res://assets/pixel/dungeon_floor.png",Color(0.24,0.27,0.27),0.38,0.72)
	var label: Label3D=VisualFactory.make_label("REGION VI // THE DEEP",Color(0.59,0.76,0.70))
	label.position=Vector3(298.0,4.5,-13.0)
	add_child(label)
	for i in range(9):
		_create_static_textured("DeepColumn%d"%i,Vector3(288.0+float(i*5),2.2,-12.0+float((i*8)%24)),Vector3(1.7,4.4,1.7),"res://assets/pixel/dungeon_floor.png",Color(0.30,0.31,0.31),0.45,0.68)
	var orum: Node3D=SettlementNPCScript.new()
	orum.configure("orum")
	orum.position=Vector3(296.0,0.0,7.0)
	add_child(orum)
	_spawn_engineering_node({"id":"deep_rail","name":"Deep Rail Exchange","requirements":{"rail_segment":4,"relay":1},"flag":"deep_rail_online","objective_from":29,"objective_to":30,"technology":"rail","prerequisite_flag":"regional_purifier_online","electrical_load_kw":6.0},Vector3(313.0,0.0,3.0))
	_spawn_pickup("relay_core",1,Vector3(317.0,0.0,-9.0))
	_spawn_pickup("ancient_circuit",2,Vector3(307.0,0.0,-7.0))
	_spawn_pickup("veil_crystal",2,Vector3(321.0,0.0,8.0))
	_spawn_pickup("deep_ore",4,Vector3(291.0,0.0,-5.0))
	_spawn_enemy("deep_crawler",Vector3(305.0,0.7,9.0))
	_spawn_enemy("deep_crawler",Vector3(320.0,0.7,-5.0))
	var deep_fabricator: Node3D=LateFabricatorScript.new()
	deep_fabricator.position=Vector3(299.0,0.0,-4.0)
	add_child(deep_fabricator)

func _build_veil_nexus() -> void:
	_create_static_textured("VeilNexusGround",Vector3(352.0,-0.24,0.0),Vector3(44.0,0.48,36.0),"res://assets/pixel/dungeon_floor.png",Color(0.30,0.25,0.39),0.25,0.36)
	var label: Label3D=VisualFactory.make_label("THE VEIL // NEXUS",Color(0.75,0.58,0.96))
	label.position=Vector3(352.0,6.0,-12.0)
	add_child(label)
	for i in range(12):
		var light:=OmniLight3D.new()
		light.position=Vector3(334.0+float((i*7)%37),1.6,-12.0+float((i*13)%25))
		light.light_color=Color(0.45,0.28,0.76)
		light.light_energy=1.2
		light.omni_range=5.5
		add_child(light)
	_spawn_engineering_node({"id":"veil_gateway","name":"Veil Gateway Interface","requirements":{"gateway_interface":1},"flag":"veil_gateway_online","objective_from":30,"objective_to":31,"technology":"veil","prerequisite_flag":"deep_rail_online","electrical_load_kw":12.0},Vector3(348.0,0.0,0.0))
	for terminal_data in [["restore","RESTORE",Vector3(359.0,0.0,-7.0)],["destroy","DESTROY",Vector3(362.0,0.0,0.0)],["rewrite","REWRITE",Vector3(359.0,0.0,7.0)]]:
		var terminal: Node3D=VeilTerminalScript.new()
		terminal.configure(str(terminal_data[0]),str(terminal_data[1]))
		var terminal_position: Vector3 = terminal_data[2]
		terminal.position=terminal_position
		add_child(terminal)
	_spawn_enemy("veil_echo",Vector3(340.0,0.7,9.0))
	_spawn_enemy("veil_echo",Vector3(368.0,0.7,-9.0))

func _spawn_engineering_node(config: Dictionary, pos: Vector3) -> void:
	var infrastructure: Node3D=EngineeringNodeScript.new()
	infrastructure.configure(config)
	infrastructure.position=pos
	add_child(infrastructure)

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
	NetworkManager.connection_state_changed.connect(_on_network_state_changed)

func _on_network_state_changed(state: String, _message: String) -> void:
	if state == "online" and str(AccountManager.active_world.get("kind", "personal")) == "shared":
		NetworkManager.bootstrap_shared_world(GameState.flags, GameState.world_objects)

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
