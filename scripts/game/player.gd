extends CharacterBody3D

## Player — hybrid mouse + keyboard + juice + modal input lock

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
var _animation_time: float = 0.0
var _hit_flash_time: float = 0.0
var _attack_dir: Vector3 = Vector3.FORWARD
var _input_locked: bool = false

const VOID_Y := -7.0
const WORLD_MIN_X := -20.0
const WORLD_MAX_X := 380.0
const WORLD_Z_LIMIT := 25.0

func _process(delta: float) -> void:
	if _sprite == null:
		return
	_animation_time += delta
	var moving: bool = (not _input_locked) and Vector2(velocity.x, velocity.z).length() > 0.2
	var intensity: float = SettingsManager.juice_intensity()
	var walk_bob_on: bool = SettingsManager.juice_enabled("walk_bob")
	var sprinting: bool = Input.is_action_pressed("sprint") or InputProfile.sprint_held
	var bob: float = 0.0
	if walk_bob_on and moving:
		bob = absf(sin(_animation_time * (13.0 if sprinting else 9.0))) * 0.07 * intensity
	_sprite.position.y = 0.95 + bob

	if walk_bob_on and moving and intensity > 0.01:
		var squash: float = 1.0 + sin(_animation_time * (12.0 if sprinting else 8.0)) * 0.03 * intensity
		_sprite.scale = Vector3(1.0 / squash, squash, 1.0)
	elif _hit_flash_time <= 0.0 and attack_cooldown <= 0.05:
		_sprite.scale = _sprite.scale.lerp(Vector3.ONE, 1.0 - exp(-12.0 * delta))

	if absf(velocity.x) > 0.1:
		_sprite.flip_h = velocity.x < 0.0

	if _hit_flash_time > 0.0 and SettingsManager.juice_enabled("hit_flash"):
		_hit_flash_time = maxf(_hit_flash_time - delta, 0.0)
		if _sprite != null:
			_sprite.modulate = Color(1.0, 0.55, 0.55) if fmod(_hit_flash_time * 18.0, 1.0) > 0.5 else Color.WHITE
	elif _sprite != null and _sprite.modulate != Color.WHITE:
		_sprite.modulate = _sprite.modulate.lerp(Color.WHITE, 1.0 - exp(-10.0 * delta))

func _ready() -> void:
	add_to_group("players")
	add_to_group("player")
	_gravity = float(ProjectSettings.get_setting("physics/3d/default_gravity", 20.0))
	_build_visual()
	TickManager.simulation_tick.connect(_on_simulation_tick)
	GameState.survival_changed.connect(_on_survival_changed)
	# Modal lock: connect once HUD exists (deferred from main or via group)
	call_deferred("_bind_hud_modal")

func _bind_hud_modal() -> void:
	var hud_nodes := get_tree().get_nodes_in_group("hud")
	for n in hud_nodes:
		if n.has_signal("modal_state_changed"):
			if not n.modal_state_changed.is_connected(_on_modal_state_changed):
				n.modal_state_changed.connect(_on_modal_state_changed)

func _on_modal_state_changed(open: bool) -> void:
	_input_locked = open
	if open:
		velocity = Vector3.ZERO
		InputProfile.clear_touch_state()

func set_input_locked(locked: bool) -> void:
	_input_locked = locked
	if locked:
		velocity = Vector3.ZERO

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
	if _input_locked:
		velocity.x = 0.0
		velocity.z = 0.0
		if not is_on_floor():
			velocity.y -= _gravity * delta
		else:
			velocity.y = -0.1
		move_and_slide()
		return

	var input: Vector2 = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	if InputProfile.is_touch_mode():
		input = InputProfile.movement_vector
		_consume_touch_actions()
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
	var wants_sprint: bool = (Input.is_action_pressed("sprint") or InputProfile.sprint_held) and world_dir.length() > 0.1 and hunger > 20.0
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
	if _outside_playable_world():
		_recover_from_void()
		return
	_update_prompt()
	_update_attack_dir_from_mouse()
	_network_accumulator += delta
	if _network_accumulator >= 0.10:
		_network_accumulator = 0.0
		NetworkManager.submit_local_player_state(global_position, rotation.y)

func _outside_playable_world() -> bool:
	return global_position.y < VOID_Y or global_position.x < WORLD_MIN_X or global_position.x > WORLD_MAX_X or absf(global_position.z) > WORLD_Z_LIMIT

func _recover_from_void() -> void:
	velocity = Vector3.ZERO
	apply_damage(999.0)
	if camera_rig != null and camera_rig.has_method("snap_to_target"):
		camera_rig.snap_to_target()

func _consume_touch_actions() -> void:
	if _input_locked:
		return
	if InputProfile.consume_action("interact"):
		_interact()
	if InputProfile.consume_action("attack"):
		_attack()
	if InputProfile.consume_action("eat_quick"):
		if not GameState.consume_food("field_tuber"):
			if not GameState.consume_food("wild_berries"):
				GameState.consume_food("spring_water")
	if InputProfile.consume_action("medical_quick"):
		if not GameState.use_medical("bandage"):
			GameState.use_medical("salve")

func _unhandled_input(event: InputEvent) -> void:
	if _input_locked:
		return
	if event is InputEventMouseButton and not InputProfile.is_touch_mode():
		var mb: InputEventMouseButton = event as InputEventMouseButton
		if mb.pressed:
			if mb.button_index == MOUSE_BUTTON_LEFT:
				if current_prompt != "":
					_interact()
				else:
					_attack()
				get_viewport().set_input_as_handled()
				return
			elif mb.button_index == MOUSE_BUTTON_RIGHT:
				_attack()
				get_viewport().set_input_as_handled()
				return
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

func _update_attack_dir_from_mouse() -> void:
	if InputProfile.is_touch_mode() or camera_rig == null or not ("camera" in camera_rig) or camera_rig.camera == null:
		if velocity.length() > 0.15:
			_attack_dir = Vector3(velocity.x, 0.0, velocity.z).normalized()
		return
	var cam: Camera3D = camera_rig.camera
	var mouse_pos: Vector2 = get_viewport().get_mouse_position()
	var from: Vector3 = cam.project_ray_origin(mouse_pos)
	var dir: Vector3 = cam.project_ray_normal(mouse_pos)
	var plane := Plane(Vector3.UP, global_position.y)
	var hit: Variant = plane.intersects_ray(from, dir)
	if hit is Vector3:
		var to: Vector3 = (hit as Vector3) - global_position
		to.y = 0.0
		if to.length() > 0.2:
			_attack_dir = to.normalized()
			if absf(_attack_dir.x) > 0.1 and _sprite != null:
				_sprite.flip_h = _attack_dir.x < 0.0

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
	if _input_locked:
		return
	var node: Node = _nearest_interactable()
	if node == null:
		GameState.notify("Nothing useful within reach.", "info")
		return
	if node.has_method("interact"):
		node.interact(self)
		_play_interact_juice()
		AudioManager.play_game("interact")

func _attack() -> void:
	if _input_locked or attack_cooldown > 0.0:
		return
	if not GameState.spend_stamina(14.0):
		GameState.notify("Too exhausted to attack effectively.", "error")
		AudioManager.play_game("miss")
		return
	var arm_penalty: float = 1.25 if GameState.injuries.has("left_arm") or GameState.injuries.has("right_arm") else 1.0
	attack_cooldown = 0.55 * arm_penalty
	var intensity: float = SettingsManager.juice_intensity()
	AudioManager.play_game("attack")

	if SettingsManager.juice_enabled("attack_squash") and _sprite != null and intensity > 0.01:
		var tween: Tween = create_tween()
		tween.tween_property(_sprite, "scale", Vector3(1.22, 0.78, 1.0), 0.06 * (1.1 - intensity * 0.2)).set_ease(Tween.EASE_OUT)
		tween.tween_property(_sprite, "scale", Vector3(0.92, 1.12, 1.0), 0.07)
		tween.tween_property(_sprite, "scale", Vector3.ONE, 0.12).set_ease(Tween.EASE_OUT)

	if SettingsManager.juice_enabled("camera_shake") and camera_rig != null and camera_rig.has_method("add_shake"):
		camera_rig.add_shake(0.18 * intensity, 0.12)

	var closest: Node3D = null
	var closest_distance: float = 2.4
	var best_score: float = -999.0
	for node_value in get_tree().get_nodes_in_group("enemy"):
		if not (node_value is Node3D):
			continue
		var node: Node3D = node_value as Node3D
		var to_enemy: Vector3 = node.global_position - global_position
		to_enemy.y = 0.0
		var d: float = to_enemy.length()
		if d > closest_distance:
			continue
		var dir_score: float = 0.0
		if d > 0.05:
			dir_score = to_enemy.normalized().dot(_attack_dir)
		var score: float = (1.0 - d / closest_distance) + dir_score * 0.65
		if score > best_score:
			best_score = score
			closest = node
			closest_distance = d

	if closest != null and closest.has_method("apply_damage"):
		closest.apply_damage(18.0 if arm_penalty <= 1.0 else 13.0)
		GameState.notify("Strike connected.", "info")
		AudioManager.play_game("hit")
		if SettingsManager.juice_enabled("camera_shake") and camera_rig != null and camera_rig.has_method("add_shake"):
			camera_rig.add_shake(0.42 * intensity, 0.20)
		if SettingsManager.juice_enabled("hit_sparks"):
			_spawn_hit_spark(closest.global_position)
	else:
		GameState.notify("You swing through empty air.", "info")
		AudioManager.play_game("miss")

func _play_interact_juice() -> void:
	if not SettingsManager.juice_enabled("attack_squash") or _sprite == null:
		return
	var tween: Tween = create_tween()
	tween.tween_property(_sprite, "scale", Vector3(1.08, 0.94, 1.0), 0.05)
	tween.tween_property(_sprite, "scale", Vector3.ONE, 0.10)

func _spawn_hit_spark(at: Vector3) -> void:
	var spark := MeshInstance3D.new()
	var mesh := SphereMesh.new()
	mesh.radius = 0.12
	mesh.height = 0.24
	spark.mesh = mesh
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(1.0, 0.85, 0.35)
	mat.emission_enabled = true
	mat.emission = Color(1.0, 0.7, 0.2)
	mat.emission_energy_multiplier = 2.5 * SettingsManager.juice_intensity()
	spark.material_override = mat
	spark.global_position = at + Vector3(0, 0.9, 0)
	get_tree().current_scene.add_child(spark)
	var tw := spark.create_tween()
	tw.tween_property(spark, "scale", Vector3(1.8, 1.8, 1.8), 0.08)
	tw.tween_property(spark, "modulate", Color(1, 1, 1, 0), 0.18)
	tw.tween_callback(spark.queue_free)

func apply_damage(amount: float) -> void:
	GameState.apply_damage(amount, "cut")
	AudioManager.play_game("damage")
	if SettingsManager.juice_enabled("hit_flash"):
		_hit_flash_time = 0.35
	if SettingsManager.juice_enabled("camera_shake") and camera_rig != null and camera_rig.has_method("add_shake"):
		camera_rig.add_shake(0.55 * SettingsManager.juice_intensity(), 0.28)
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
