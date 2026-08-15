extends CharacterBody3D

const VisualFactory = preload("res://scripts/game/visual_factory.gd")
const ENEMY_ID := "furnace_saint"
const VULNERABILITY_WINDOW_SECONDS := 15.0

var definition: Dictionary = {}
var health: float = 1.0
var max_health: float = 1.0
var attack_cooldown: float = 0.0
var _gravity: float = 20.0
var core_light: OmniLight3D
var sprite: Sprite3D

func _ready() -> void:
	add_to_group("enemy")
	add_to_group("boss")
	definition = DataRegistry.get_enemy(ENEMY_ID)
	max_health = float(definition.get("health", 220.0))
	health = float(GameState.get_flag("furnace_saint_health", max_health))
	_gravity = float(ProjectSettings.get_setting("physics/3d/default_gravity", 20.0))
	_build_visual()
	TickManager.simulation_tick.connect(_on_simulation_tick)
	TickManager.machine_tick.connect(_on_machine_tick)
	GameState.flag_changed.connect(_on_flag_changed)
	NetworkManager.boss_authority_state.connect(_on_authoritative_boss_state)
	var cached_state: Dictionary = NetworkManager.cached_boss_state()
	if NetworkManager.is_online() and not cached_state.is_empty():
		health = float(cached_state.get("health", health))
		max_health = float(cached_state.get("max_health", max_health))
	if bool(GameState.get_flag("furnace_saint_defeated", false)):
		queue_free()
	elif bool(GameState.get_flag("foundry_gate_open", false)):
		GameState.update_boss("Furnace Saint", health, max_health, _is_vulnerable())

func _build_visual() -> void:
	sprite = VisualFactory.make_sprite("res://assets/pixel/furnace_saint.png", 0.045, true)
	sprite.position.y = 1.5
	add_child(sprite)
	var collision := CollisionShape3D.new()
	var shape := CapsuleShape3D.new()
	shape.radius = 0.72
	shape.height = 2.4
	collision.shape = shape
	collision.position.y = 1.2
	add_child(collision)
	core_light = OmniLight3D.new()
	core_light.position = Vector3(0.0, 1.7, -0.2)
	core_light.light_color = Color(1.0, 0.42, 0.12)
	core_light.omni_range = 7.0
	core_light.light_energy = 2.2
	core_light.shadow_enabled = true
	add_child(core_light)

func _is_vulnerable() -> bool:
	return bool(GameState.get_flag("boss_vulnerable", false))

func _on_machine_tick(_delta: float) -> void:
	if _is_vulnerable() and not NetworkManager.is_online():
		var started_ms: int = int(GameState.get_flag("boss_vulnerability_started_ms", 0))
		if started_ms > 0 and float(Time.get_ticks_msec() - started_ms) / 1000.0 >= VULNERABILITY_WINDOW_SECONDS:
			GameState.set_flag("boss_vulnerable", false)
			GameState.set_flag("thermal_valve_a", false)
			GameState.set_flag("thermal_valve_b", false)
			GameState.notify("The Furnace Saint's armor reseals. Re-open both thermal valves.", "error")
	if bool(GameState.get_flag("foundry_gate_open", false)):
		GameState.update_boss("Furnace Saint", health, max_health, _is_vulnerable())
	if core_light != null:
		core_light.light_color = Color(0.32, 0.95, 0.95) if _is_vulnerable() else Color(1.0, 0.36, 0.10)
		core_light.light_energy = 3.0 if _is_vulnerable() else 2.1

func _on_simulation_tick(delta: float) -> void:
	attack_cooldown = maxf(attack_cooldown - delta, 0.0)
	var players: Array[Node] = get_tree().get_nodes_in_group("player")
	if players.is_empty() or not (players[0] is Node3D):
		return
	var player: Node3D = players[0] as Node3D
	var distance: float = global_position.distance_to(player.global_position)
	var detection_range: float = float(definition.get("detection_range", 12.0))
	var attack_range: float = float(definition.get("attack_range", 2.2))
	var aggression_multiplier: float = 1.18 if bool(SettingsManager.get_value("gameplay", "aggressive_enemies", false)) else 1.0
	var move_speed: float = float(definition.get("move_speed", 1.45)) * aggression_multiplier
	if distance < detection_range and distance > attack_range:
		var direction: Vector3 = player.global_position - global_position
		direction.y = 0.0
		direction = direction.normalized()
		velocity.x = direction.x * move_speed
		velocity.z = direction.z * move_speed
	else:
		velocity.x = move_toward(velocity.x, 0.0, 3.5 * delta)
		velocity.z = move_toward(velocity.z, 0.0, 3.5 * delta)
	if not is_on_floor():
		velocity.y -= _gravity * delta
	else:
		velocity.y = -0.1
	move_and_slide()
	if distance <= attack_range and attack_cooldown <= 0.0:
		attack_cooldown = float(definition.get("attack_interval", 1.9))
		if player.has_method("apply_damage"):
			player.apply_damage(float(definition.get("attack_damage", 18.0)) * aggression_multiplier)
			GameState.notify("The Furnace Saint slams the floor with superheated armor.", "error")

func apply_damage(amount: float) -> void:
	if bool(GameState.get_flag("furnace_saint_defeated", false)):
		return
	if NetworkManager.is_online():
		if _is_vulnerable():
			NetworkManager.submit_boss_damage(amount)
		else:
			GameState.add_journal(
				"Furnace Saint Armor",
				"Hypothesis",
				"Direct strikes barely mark the layered shell. The Foundry's pressure system may be the real weapon."
			)
			GameState.notify("Your strike skitters off sealed armor. Find a systemic weakness.", "error")
		return
	var actual_damage: float = amount if _is_vulnerable() else minf(amount, 1.0)
	health = maxf(health - actual_damage, 0.0)
	GameState.set_flag("furnace_saint_health", health)
	if not _is_vulnerable():
		GameState.add_journal(
			"Furnace Saint Armor",
			"Hypothesis",
			"Direct strikes barely mark the layered shell. The Foundry's pressure system may be the real weapon."
		)
		GameState.notify("Your strike skitters off sealed armor. Find a systemic weakness.", "error")
	else:
		GameState.notify("Thermally stressed armor fractures under the strike.", "success")
	GameState.update_boss("Furnace Saint", health, max_health, _is_vulnerable())
	if health <= 0.0:
		GameState.set_flag("furnace_saint_defeated", true)
		GameState.set_flag("boss_vulnerable", false)
		GameState.clear_boss()
		GameState.add_journal(
			"Furnace Saint",
			"Confirmation",
			"The guardian was not defeated by raw damage. Foundry pressure control created the only reliable opening in its armor."
		)
		if GameState.objective_step == 11:
			GameState.advance_objective(12)
		GameState.notify("VERTICAL SLICE COMPLETE // Furnace Saint defeated.", "success")
		AudioManager.play_ui("complete")
		queue_free()

func _on_authoritative_boss_state(authoritative_health: float, authoritative_max_health: float, vulnerable: bool) -> void:
	if not NetworkManager.is_online():
		return
	health = clampf(authoritative_health, 0.0, authoritative_max_health)
	max_health = maxf(authoritative_max_health, 1.0)
	GameState.flags["boss_vulnerable"] = vulnerable
	GameState.flag_changed.emit("boss_vulnerable", vulnerable)
	GameState.update_boss("Furnace Saint", health, max_health, vulnerable)

func _on_flag_changed(flag: String, value: Variant) -> void:
	if flag == "foundry_gate_open" and bool(value):
		GameState.update_boss("Furnace Saint", health, max_health, _is_vulnerable())
	elif flag == "furnace_saint_defeated" and bool(value) and not is_queued_for_deletion():
		GameState.clear_boss()
		GameState.add_journal(
			"Furnace Saint",
			"Confirmation",
			"The guardian was not defeated by raw damage. Foundry pressure control created the only reliable opening in its armor."
		)
		if GameState.objective_step == 11:
			GameState.advance_objective(12)
		GameState.notify("VERTICAL SLICE COMPLETE // Furnace Saint defeated.", "success")
		queue_free()
