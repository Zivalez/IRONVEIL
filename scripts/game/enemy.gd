extends CharacterBody3D

const VisualFactory = preload("res://scripts/game/visual_factory.gd")

var enemy_id: String = "hollow_vermin"
var definition: Dictionary = {}
var health: float = 1.0
var attack_cooldown: float = 0.0
var _gravity: float = 20.0
var _sprite: Sprite3D
var _animation_time: float = 0.0

func configure(id_value: String) -> void:
	enemy_id = id_value

func _ready() -> void:
	add_to_group("enemy")
	definition = DataRegistry.get_enemy(enemy_id)
	health = float(definition.get("health", 1.0))
	_gravity = float(ProjectSettings.get_setting("physics/3d/default_gravity", 20.0))
	_build_visual()
	TickManager.simulation_tick.connect(_on_simulation_tick)

func _build_visual() -> void:
	var path: String = "res://assets/pixel/hollow_stalker.png" if enemy_id in ["hollow_stalker", "frost_wraith", "veil_echo"] else "res://assets/pixel/hollow_vermin.png"
	_sprite = VisualFactory.make_sprite(path, 0.04, true)
	_sprite.position.y = 0.75
	if enemy_id == "ore_mite":
		_sprite.modulate = Color(0.78,0.58,0.34)
	elif enemy_id == "frost_wraith":
		_sprite.modulate = Color(0.58,0.88,0.94)
	elif enemy_id == "deep_crawler":
		_sprite.modulate = Color(0.48,0.62,0.50)
	elif enemy_id == "veil_echo":
		_sprite.modulate = Color(0.72,0.46,0.92)
	add_child(_sprite)
	var collision := CollisionShape3D.new()
	var shape := CapsuleShape3D.new()
	shape.radius = 0.34 if enemy_id == "hollow_vermin" else 0.43
	shape.height = 0.9 if enemy_id == "hollow_vermin" else 1.25
	collision.shape = shape
	collision.position.y = shape.height * 0.5
	add_child(collision)

func _on_simulation_tick(delta: float) -> void:
	_animation_time += delta
	attack_cooldown = maxf(attack_cooldown - delta, 0.0)
	var players: Array[Node] = get_tree().get_nodes_in_group("player")
	if players.is_empty() or not (players[0] is Node3D):
		return
	var player: Node3D = players[0] as Node3D
	var distance: float = global_position.distance_to(player.global_position)
	var aggression: float = 1.20 if bool(SettingsManager.get_value("gameplay", "aggressive_enemies", false)) else 1.0
	if distance < float(definition.get("detection_range", 6.0)) and distance > float(definition.get("attack_range", 1.3)):
		var direction: Vector3 = (player.global_position - global_position).normalized()
		var speed: float = float(definition.get("move_speed", 1.5)) * aggression
		velocity.x = direction.x * speed
		velocity.z = direction.z * speed
	else:
		velocity.x = move_toward(velocity.x, 0.0, 3.5 * delta)
		velocity.z = move_toward(velocity.z, 0.0, 3.5 * delta)
	if not is_on_floor():
		velocity.y -= _gravity * delta
	else:
		velocity.y = -0.1
	move_and_slide()
	if _sprite != null:
		var bob_on: bool = SettingsManager.juice_enabled("walk_bob")
		_sprite.position.y = 0.75 + (0.0 if not bob_on else sin(_animation_time * 7.0) * 0.045 * SettingsManager.juice_intensity())
		if absf(velocity.x) > 0.1:
			_sprite.flip_h = velocity.x < 0.0
	if distance <= float(definition.get("attack_range", 1.3)) and attack_cooldown <= 0.0:
		attack_cooldown = float(definition.get("attack_interval", 1.5))
		if player.has_method("apply_damage"):
			player.apply_damage(float(definition.get("attack_damage", 8.0)) * aggression)
			GameState.notify("%s hits you." % str(definition.get("name", enemy_id)), "error")

func apply_damage(amount: float) -> void:
	health = maxf(health - amount, 0.0)
	if health > 0.0:
		if _sprite != null and SettingsManager.juice_enabled("hit_flash"):
			_sprite.modulate = Color(1.0, 0.45, 0.40)
			if SettingsManager.juice_enabled("attack_squash"):
				var tw := create_tween()
				tw.tween_property(_sprite, "scale", Vector3(1.18, 0.82, 1.0), 0.05)
				tw.tween_property(_sprite, "scale", Vector3.ONE, 0.10)
		get_tree().create_timer(0.14).timeout.connect(_restore_tint)
		return
	var drops_value: Variant = definition.get("drops", {})
	if drops_value is Dictionary:
		var drops: Dictionary = drops_value as Dictionary
		for item_id_variant in drops:
			GameState.add_item(str(item_id_variant), int(drops[item_id_variant]))
	GameState.add_journal(str(definition.get("name", enemy_id)), "Confirmation", "Observed behavior and combat response have been recorded in the field journal.")
	GameState.notify("%s neutralized." % str(definition.get("name", enemy_id)), "success")
	AudioManager.play_game("hit")
	if _sprite != null and SettingsManager.juice_enabled("attack_squash"):
		var tw2 := create_tween()
		tw2.tween_property(_sprite, "scale", Vector3(1.4, 0.5, 1.0), 0.08)
		tw2.tween_property(_sprite, "modulate", Color(1, 1, 1, 0), 0.12)
		tw2.tween_callback(queue_free)
	else:
		queue_free()

func _restore_tint() -> void:
	if _sprite != null and is_instance_valid(_sprite):
		_sprite.modulate = Color.WHITE
