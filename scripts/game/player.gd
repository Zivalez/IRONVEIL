extends CharacterBody3D

signal interaction_prompt_changed(text: String)

var camera_rig: Node
var move_speed := 5.2
var sprint_speed := 7.0
var attack_cooldown := 0.0
var current_prompt := ""
var _gravity := 20.0

func _ready() -> void:
	add_to_group("players")
	add_to_group("player")
	_gravity = float(ProjectSettings.get_setting("physics/3d/default_gravity", 20.0))
	_build_visual()
	TickManager.simulation_tick.connect(_on_simulation_tick)
	GameState.survival_changed.connect(_on_survival_changed)

func _build_visual() -> void:
	var mesh := MeshInstance3D.new()
	var capsule := CapsuleMesh.new()
	capsule.radius = 0.42
	capsule.height = 1.6
	mesh.mesh = capsule
	mesh.position.y = 0.8
	var material := StandardMaterial3D.new()
	material.albedo_color = Color(0.36, 0.48, 0.48)
	material.roughness = 0.82
	mesh.material_override = material
	add_child(mesh)

	var collision := CollisionShape3D.new()
	var shape := CapsuleShape3D.new()
	shape.radius = 0.42
	shape.height = 1.6
	collision.shape = shape
	collision.position.y = 0.8
	add_child(collision)

func _on_simulation_tick(delta: float) -> void:
	attack_cooldown = maxf(attack_cooldown - delta, 0.0)

	var input := Vector2.ZERO
	if Input.is_key_pressed(KEY_A):
		input.x -= 1.0
	if Input.is_key_pressed(KEY_D):
		input.x += 1.0
	if Input.is_key_pressed(KEY_W):
		input.y -= 1.0
	if Input.is_key_pressed(KEY_S):
		input.y += 1.0
	input = input.normalized()

	var world_dir := Vector3(input.x, 0.0, input.y)
	if camera_rig != null and camera_rig.has_method("transform_input"):
		world_dir = camera_rig.transform_input(input).normalized()

	var hunger := float(GameState.survival.get("hunger", 100.0))
	var thirst := float(GameState.survival.get("thirst", 100.0))
	var fatigue_factor := 0.62 if hunger < 15.0 or thirst < 15.0 else 1.0
	var speed := sprint_speed if Input.is_key_pressed(KEY_SHIFT) and hunger > 20.0 else move_speed
	speed *= fatigue_factor

	velocity.x = world_dir.x * speed
	velocity.z = world_dir.z * speed
	if not is_on_floor():
		velocity.y -= _gravity * delta
	else:
		velocity.y = -0.1

	move_and_slide()
	_update_prompt()

func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventKey and event.pressed and not event.echo):
		return
	match event.keycode:
		KEY_F:
			_interact()
		KEY_SPACE:
			_attack()
		KEY_1:
			GameState.consume_food("wild_berries")
		KEY_C:
			GameState.craft("crude_gear")
		KEY_F5:
			SaveManager.save_game(self)
		KEY_F9:
			SaveManager.load_game(self)

func _nearest_interactable() -> Node:
	var nearest: Node = null
	var nearest_distance := 2.7
	for node in get_tree().get_nodes_in_group("interactable"):
		if not (node is Node3D):
			continue
		var d := global_position.distance_to(node.global_position)
		if d < nearest_distance:
			nearest = node
			nearest_distance = d
	return nearest

func _update_prompt() -> void:
	var node := _nearest_interactable()
	var next_prompt := ""
	if node != null and node.has_method("get_prompt"):
		next_prompt = str(node.get_prompt(self))
	if next_prompt != current_prompt:
		current_prompt = next_prompt
		interaction_prompt_changed.emit(current_prompt)

func _interact() -> void:
	var node := _nearest_interactable()
	if node == null:
		GameState.notify("Nothing useful within reach.", "info")
		return
	if node.has_method("interact"):
		node.interact(self)

func _attack() -> void:
	if attack_cooldown > 0.0:
		return
	attack_cooldown = 0.55
	var closest: Node3D = null
	var closest_distance := 2.1
	for node in get_tree().get_nodes_in_group("enemy"):
		if not (node is Node3D):
			continue
		var d := global_position.distance_to(node.global_position)
		if d < closest_distance:
			closest = node
			closest_distance = d
	if closest != null and closest.has_method("apply_damage"):
		closest.apply_damage(18.0)
		GameState.notify("Strike connected.", "info")
	else:
		GameState.notify("You swing through empty air.", "info")

func apply_damage(amount: float) -> void:
	GameState.survival["health"] = maxf(float(GameState.survival.get("health", 100.0)) - amount, 0.0)
	GameState.survival_changed.emit(GameState.survival.duplicate(true))
	if float(GameState.survival["health"]) <= 0.0:
		GameState.notify("You collapsed. Knowledge remains; body returns to camp.", "error")
		global_position = Vector3(0.0, 1.0, 0.0)
		GameState.survival["health"] = 65.0
		GameState.survival["hunger"] = maxf(float(GameState.survival["hunger"]), 25.0)
		GameState.survival["thirst"] = maxf(float(GameState.survival["thirst"]), 25.0)

func _on_survival_changed(_survival: Dictionary) -> void:
	pass
