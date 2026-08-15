extends CharacterBody3D

const ENEMY_ID := "hollow_vermin"
var definition: Dictionary = {}
var health := 1.0
var attack_cooldown := 0.0
var _gravity := 20.0

func _ready() -> void:
	add_to_group("enemy")
	definition = DataRegistry.enemies.get(ENEMY_ID, {})
	health = float(definition.get("health", 1.0))
	_gravity = float(ProjectSettings.get_setting("physics/3d/default_gravity", 20.0))
	_build_visual()
	TickManager.simulation_tick.connect(_on_simulation_tick)

func _build_visual() -> void:
	var mesh_instance := MeshInstance3D.new()
	var mesh := CapsuleMesh.new()
	mesh.radius = 0.32
	mesh.height = 0.8
	mesh_instance.mesh = mesh
	mesh_instance.position.y = 0.4
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.26, 0.16, 0.12)
	mat.roughness = 0.9
	mesh_instance.material_override = mat
	add_child(mesh_instance)

	var collision := CollisionShape3D.new()
	var shape := CapsuleShape3D.new()
	shape.radius = 0.32
	shape.height = 0.8
	collision.shape = shape
	collision.position.y = 0.4
	add_child(collision)

func _on_simulation_tick(delta: float) -> void:
	attack_cooldown = maxf(attack_cooldown - delta, 0.0)
	var players := get_tree().get_nodes_in_group("player")
	if players.is_empty():
		return
	var player = players[0]
	var distance := global_position.distance_to(player.global_position)
	var detection_range := float(definition.get("detection_range", 0.0))
	var attack_range := float(definition.get("attack_range", 0.0))
	var move_speed := float(definition.get("move_speed", 0.0))
	if distance < detection_range and distance > attack_range - 0.1:
		var direction := (player.global_position - global_position)
		direction.y = 0.0
		direction = direction.normalized()
		velocity.x = direction.x * move_speed
		velocity.z = direction.z * move_speed
	else:
		velocity.x = move_toward(velocity.x, 0.0, 4.0 * delta)
		velocity.z = move_toward(velocity.z, 0.0, 4.0 * delta)

	if not is_on_floor():
		velocity.y -= _gravity * delta
	else:
		velocity.y = -0.1
	move_and_slide()

	if distance <= attack_range and attack_cooldown <= 0.0:
		attack_cooldown = float(definition.get("attack_interval", 1.5))
		if player.has_method("apply_damage"):
			player.apply_damage(float(definition.get("attack_damage", 0.0)))
			GameState.notify("A Hollow Vermin bites you.", "error")

func apply_damage(amount: float) -> void:
	health -= amount
	if health <= 0.0:
		for item_id in definition.get("drops", {}):
			GameState.add_item(str(item_id), int(definition["drops"][item_id]))
		GameState.add_journal(
			"Hollow Vermin",
			"Observation",
			"Small scavengers become aggressive at close range. Their bodies carry fragments of machine scrap."
		)
		GameState.notify("Hollow Vermin defeated. Salvage recovered.", "success")
		queue_free()
