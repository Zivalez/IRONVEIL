extends CharacterBody3D

signal interaction_prompt_changed(text: String)

const VisualFactory = preload("res://scripts/game/visual_factory.gd")

var camera_rig: Node
var move_speed: float = 5.2
var sprint_speed: float = 7.0
var attack_cooldown: float = 0.0
var current_prompt: String = ""
var _gravity: float = 20.0
var _network_accumulator: float = 0.0
var _sprite: Sprite3D
var _sprint_stamina_accumulator: float = 0.0

func _ready() -> void:
	add_to_group("players")
	add_to_group("player")
	_gravity = float(ProjectSettings.get_setting("physics/3d/default_gravity", 20.0))
	_build_visual()
	TickManager.simulation_tick.connect(_on_simulation_tick)
	GameState.survival_changed.connect(_on_survival_changed)

func _build_visual() -> void:
	_sprite = VisualFactory.make_sprite("res://assets/pixel/player.png", 0.04, true)
	_sprite.position.y = 0.95
	add_child(_sprite)
	var collision := CollisionShape3D.new()
	var shape := CapsuleShape3D.new()
	shape.radius = 0.38
	shape.height = 1.45
	collision.shape = shape
	collision.position.y = 0.75
	add_child(collision)

func _on_simulation_tick(delta: float) -> void:
	attack_cooldown = maxf(attack_cooldown - delta, 0.0)
	var input: Vector2 = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	var world_dir: Vector3 = Vector3(input.x, 0.0, input.y)
	if camera_rig != null and camera_rig.has_method("transform_input"):
		world_dir = camera_rig.transform_input(input).normalized()
	var hunger: float = float(GameState.survival.get("hunger", 100.0))
	var thirst: float = float(GameState.survival.get("thirst", 100.0))
	var fatigue: float = float(GameState.survival.get("fatigue", 0.0))
	var leg_penalty: float = 0.78 if GameState.injuries.has("left_leg") or GameState.injuries.has("right_leg") else 1.0
	var fatigue_factor: float = clampf(1.0 - fatigue / 160.0, 0.55, 1.0)
	if hunger < 15.0 or thirst < 15.0:
		fatigue_factor *= 0.68
	var wants_sprint: bool = Input.is_action_pressed("sprint") and world_dir.length() > 0.1 and hunger > 20.0
	var can_sprint: bool = wants_sprint and float(GameState.survival.get("stamina", 0.0)) > 4.0
	var speed: float = sprint_speed if can_sprint else move_speed
	if can_sprint:
		_sprint_stamina_accumulator += delta
		if _sprint_stamina_accumulator >= 0.25:
			GameState.spend_stamina(2.5)
			_sprint_stamina_accumulator = 0.0
	else:
		_sprint_stamina_accumulator = 0.0
		if world_dir.length() < 0.1:
			GameState.rest_recovery(delta)
	speed *= fatigue_factor * leg_penalty
	velocity.x = world_dir.x * speed
	velocity.z = world_dir.z * speed
	if not is_on_floor():
		velocity.y -= _gravity * delta
	else:
		velocity.y = -0.1
	move_and_slide()
	_update_prompt()
	_network_accumulator += delta
	if _network_accumulator >= 0.10:
		_network_accumulator = 0.0
		NetworkManager.submit_local_player_state(global_position, rotation.y)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("interact"):
		_interact()
	elif event.is_action_pressed("attack"):
		_attack()
	elif event.is_action_pressed("eat_quick"):
		if not GameState.consume_food("field_tuber"):
			if not GameState.consume_food("wild_berries"):
				GameState.consume_food("spring_water")
	elif event.is_action_pressed("medical_quick"):
		if not GameState.use_medical("bandage"):
			GameState.use_medical("salve")
	elif event.is_action_pressed("craft_gear"):
		GameState.craft("crude_gear", "handcraft")
	elif event.is_action_pressed("craft_bandage"):
		GameState.craft("field_bandage", "handcraft")
	elif event.is_action_pressed("save"):
		SaveManager.save_game(self)
	elif event.is_action_pressed("load"):
		SaveManager.load_game(self)

func _nearest_interactable() -> Node:
	var nearest: Node = null
	var nearest_distance: float = 2.8
	for node_value in get_tree().get_nodes_in_group("interactable"):
		if not (node_value is Node3D):
			continue
		var node: Node3D = node_value as Node3D
		var d: float = global_position.distance_to(node.global_position)
		if d < nearest_distance:
			nearest = node
			nearest_distance = d
	return nearest

func _update_prompt() -> void:
	var node: Node = _nearest_interactable()
	var next_prompt: String = ""
	if node != null and node.has_method("get_prompt"):
		next_prompt = str(node.get_prompt(self))
	if next_prompt != current_prompt:
		current_prompt = next_prompt
		interaction_prompt_changed.emit(current_prompt)

func _interact() -> void:
	var node: Node = _nearest_interactable()
	if node == null:
		GameState.notify("Nothing useful within reach.", "info")
		return
	if node.has_method("interact"):
		node.interact(self)

func _attack() -> void:
	if attack_cooldown > 0.0:
		return
	if not GameState.spend_stamina(14.0):
		GameState.notify("Too exhausted to attack effectively.", "error")
		return
	var arm_penalty: float = 1.25 if GameState.injuries.has("left_arm") or GameState.injuries.has("right_arm") else 1.0
	attack_cooldown = 0.55 * arm_penalty
	var closest: Node3D = null
	var closest_distance: float = 2.2
	for node_value in get_tree().get_nodes_in_group("enemy"):
		if not (node_value is Node3D):
			continue
		var node: Node3D = node_value as Node3D
		var d: float = global_position.distance_to(node.global_position)
		if d < closest_distance:
			closest = node
			closest_distance = d
	if closest != null and closest.has_method("apply_damage"):
		closest.apply_damage(18.0 if arm_penalty <= 1.0 else 13.0)
		GameState.notify("Strike connected.", "info")
	else:
		GameState.notify("You swing through empty air.", "info")

func apply_damage(amount: float) -> void:
	GameState.apply_damage(amount, "cut")
	if float(GameState.survival.get("health", 0.0)) <= 0.0:
		GameState.notify("You collapsed. Knowledge remains; body returns to camp.", "error")
		global_position = Vector3(0.0, 1.0, 0.0)
		GameState.survival["health"] = 65.0
		GameState.survival["hunger"] = maxf(float(GameState.survival.get("hunger", 0.0)), 25.0)
		GameState.survival["thirst"] = maxf(float(GameState.survival.get("thirst", 0.0)), 25.0)
		GameState.survival["stress"] = minf(float(GameState.survival.get("stress", 0.0)) + 15.0, 100.0)
		GameState.survival_changed.emit(GameState.survival.duplicate(true))

func _on_survival_changed(_survival: Dictionary) -> void:
	pass
