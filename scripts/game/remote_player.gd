extends Node3D

const VisualFactory = preload("res://scripts/game/visual_factory.gd")

var peer_id: int = 0
var display_name: String = "Survivor"
var target_position: Vector3 = Vector3.ZERO
var target_yaw: float = 0.0
var sprite: Sprite3D
var name_label: Label3D

func configure(id_value: int, name_value: String) -> void:
	peer_id = id_value
	display_name = name_value

func _ready() -> void:
	add_to_group("remote_player")
	sprite = VisualFactory.make_sprite("res://assets/pixel/remote_player.png", 0.04, true)
	sprite.position.y = 0.95
	add_child(sprite)
	name_label = VisualFactory.make_label(display_name, Color(0.56, 0.86, 0.94))
	name_label.position = Vector3(0.0, 2.15, 0.0)
	add_child(name_label)

func set_network_state(position_value: Vector3, yaw_value: float) -> void:
	target_position = position_value
	target_yaw = yaw_value

func _process(delta: float) -> void:
	global_position = global_position.lerp(target_position, clampf(delta * 10.0, 0.0, 1.0))
	rotation.y = lerp_angle(rotation.y, target_yaw, clampf(delta * 8.0, 0.0, 1.0))
