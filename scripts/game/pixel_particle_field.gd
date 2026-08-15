extends Node3D

const VisualFactory = preload("res://scripts/game/visual_factory.gd")

var texture_path: String = "res://assets/pixel/dust.png"
var particle_count: int = 18
var extent: Vector3 = Vector3(12.0, 3.0, 12.0)
var drift: Vector3 = Vector3(0.08, 0.12, 0.03)
var pixel_size: float = 0.03
var _particles: Array[Sprite3D] = []
var _origins: Array[Vector3] = []

func configure(path: String, count: int, bounds: Vector3, velocity: Vector3, size: float = 0.03) -> void:
	texture_path = path
	particle_count = count
	extent = bounds
	drift = velocity
	pixel_size = size

func _ready() -> void:
	for i in range(particle_count):
		var sprite: Sprite3D = VisualFactory.make_sprite(texture_path, pixel_size, false)
		sprite.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		var seed_x: float = fmod(float(i * 37), 97.0) / 97.0
		var seed_y: float = fmod(float(i * 53), 89.0) / 89.0
		var seed_z: float = fmod(float(i * 71), 83.0) / 83.0
		sprite.position = Vector3(
			(seed_x - 0.5) * extent.x,
			seed_y * extent.y,
			(seed_z - 0.5) * extent.z
		)
		add_child(sprite)
		_particles.append(sprite)
		_origins.append(sprite.position)

func _process(delta: float) -> void:
	for i in range(_particles.size()):
		var sprite: Sprite3D = _particles[i]
		sprite.position += drift * delta
		var origin: Vector3 = _origins[i]
		if absf(sprite.position.x - origin.x) > extent.x * 0.45 or sprite.position.y > extent.y or absf(sprite.position.z - origin.z) > extent.z * 0.45:
			sprite.position = Vector3(origin.x, 0.05, origin.z)
