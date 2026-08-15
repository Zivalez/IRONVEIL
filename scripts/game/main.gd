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

var player: CharacterBody3D
var camera_rig: Node3D
var hud: CanvasLayer

func _ready() -> void:
	GameState.new_game()
	_build_environment()
	_build_region()
	_spawn_player()
	_spawn_ui()
	GameState.add_journal(
		"Field Condition",
		"Observation",
		"You wake beside a cold camp in a forest bordering abandoned industrial ruins. Hunger is already beginning to matter."
	)

func _build_environment() -> void:
	var world_environment := WorldEnvironment.new()
	var environment := Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color(0.055, 0.065, 0.062)
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color(0.48, 0.53, 0.49)
	environment.ambient_light_energy = 0.62
	world_environment.environment = environment
	add_child(world_environment)

	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-52.0, -28.0, 0.0)
	sun.light_color = Color(0.92, 0.86, 0.70)
	sun.light_energy = 1.1
	sun.shadow_enabled = true
	add_child(sun)

func _build_region() -> void:
	_create_static_box("Ground", Vector3(0.0, -0.25, 0.0), Vector3(54.0, 0.5, 54.0), Color(0.12, 0.16, 0.12), 1)
	_create_visual_box("River", Vector3(14.0, 0.03, 0.0), Vector3(4.0, 0.08, 54.0), Color(0.08, 0.20, 0.22))

	for i in range(18):
		var x := -18.0 + float((i * 7) % 31)
		var z := -19.0 + float((i * 11) % 35)
		if absf(x - 14.0) < 4.0 or (x > 7.0 and x < 23.0 and z > -9.0 and z < 2.0):
			continue
		_create_tree(Vector3(x, 0.0, z), 0.85 + float(i % 4) * 0.12)

	_create_static_box("WorkshopFloor", Vector3(17.5, 0.1, -4.0), Vector3(14.0, 0.25, 8.0), Color(0.20, 0.18, 0.15), 1)
	_create_static_box("WorkshopWallBack", Vector3(17.5, 1.5, -7.8), Vector3(14.0, 3.0, 0.35), Color(0.18, 0.16, 0.14), 1)
	_create_static_box("WorkshopWallSide", Vector3(24.3, 1.5, -4.0), Vector3(0.35, 3.0, 8.0), Color(0.18, 0.16, 0.14), 1)

	var roof = OccluderScript.new()
	roof.name = "WorkshopRoofOccluder"
	roof.position = Vector3(17.5, 3.35, -4.0)
	add_child(roof)
	roof.configure(Vector3(14.2, 0.25, 8.2), Color(0.11, 0.10, 0.09))

	var sign = WorkshopSignScript.new()
	sign.position = Vector3(9.3, 0.0, -3.0)
	add_child(sign)

	var wheel = WaterWheelScript.new()
	wheel.position = Vector3(12.5, 0.0, -4.5)
	add_child(wheel)

	var gear = GearAssemblyScript.new()
	gear.position = Vector3(16.0, 0.0, -4.5)
	add_child(gear)

	var saw = MechanicalSawScript.new()
	saw.position = Vector3(20.0, 0.0, -4.5)
	add_child(saw)

	var press = MechanicalPressScript.new()
	press.position = Vector3(20.5, 0.0, -1.4)
	add_child(press)

	_spawn_pickup("wild_berries", 3, "Wild Berries", Vector3(3.5, 0.0, 2.0), Color(0.33, 0.16, 0.25))
	_spawn_pickup("scrap", 1, "Scrap", Vector3(7.0, 0.0, -2.0), Color(0.38, 0.34, 0.30))
	_spawn_pickup("scrap", 1, "Scrap", Vector3(8.0, 0.0, -4.0), Color(0.38, 0.34, 0.30))
	_spawn_pickup("scrap", 1, "Scrap", Vector3(10.0, 0.0, -6.0), Color(0.38, 0.34, 0.30))
	_spawn_pickup("scrap", 1, "Scrap", Vector3(22.0, 0.0, -6.2), Color(0.38, 0.34, 0.30))
	_spawn_pickup("log", 2, "Logs", Vector3(5.0, 0.0, 5.0), Color(0.31, 0.20, 0.10))
	_spawn_pickup("log", 2, "Logs", Vector3(9.0, 0.0, 4.0), Color(0.31, 0.20, 0.10))

	var enemy = EnemyScript.new()
	enemy.position = Vector3(6.0, 0.7, -7.0)
	add_child(enemy)

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

func _spawn_pickup(item_id: String, quantity: int, label: String, pos: Vector3, tint: Color) -> void:
	var pickup = PickupScript.new()
	pickup.item_id = item_id
	pickup.quantity = quantity
	pickup.display_label = label
	pickup.tint = tint
	pickup.position = pos
	add_child(pickup)

func _create_tree(pos: Vector3, scale_factor: float) -> void:
	var trunk := MeshInstance3D.new()
	var trunk_mesh := CylinderMesh.new()
	trunk_mesh.top_radius = 0.18 * scale_factor
	trunk_mesh.bottom_radius = 0.26 * scale_factor
	trunk_mesh.height = 2.2 * scale_factor
	trunk.mesh = trunk_mesh
	trunk.position = pos + Vector3.UP * (1.1 * scale_factor)
	var trunk_mat := StandardMaterial3D.new()
	trunk_mat.albedo_color = Color(0.21, 0.15, 0.09)
	trunk_mat.roughness = 1.0
	trunk.material_override = trunk_mat
	add_child(trunk)

	var crown := MeshInstance3D.new()
	var crown_mesh := SphereMesh.new()
	crown_mesh.radius = 1.1 * scale_factor
	crown_mesh.height = 2.0 * scale_factor
	crown.mesh = crown_mesh
	crown.position = pos + Vector3.UP * (2.55 * scale_factor)
	var crown_mat := StandardMaterial3D.new()
	crown_mat.albedo_color = Color(0.10, 0.20, 0.12)
	crown_mat.roughness = 1.0
	crown.material_override = crown_mat
	add_child(crown)

func _create_visual_box(node_name: String, pos: Vector3, size: Vector3, color: Color) -> void:
	var mesh_instance := MeshInstance3D.new()
	mesh_instance.name = node_name
	var mesh := BoxMesh.new()
	mesh.size = size
	mesh_instance.mesh = mesh
	mesh_instance.position = pos
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.78
	mesh_instance.material_override = material
	add_child(mesh_instance)

func _create_static_box(node_name: String, pos: Vector3, size: Vector3, color: Color, layer: int) -> void:
	var body := StaticBody3D.new()
	body.name = node_name
	body.position = pos
	body.collision_layer = layer
	body.collision_mask = 1
	add_child(body)

	var mesh_instance := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size
	mesh_instance.mesh = mesh
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.88
	mesh_instance.material_override = material
	body.add_child(mesh_instance)

	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = size
	collision.shape = shape
	body.add_child(collision)
