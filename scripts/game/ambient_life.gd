extends Node3D

## AmbientLife — denser dust/steam/embers + soft region tint markers
## Keeps world from feeling empty even with placeholder art.

const ParticleFieldScript = preload("res://scripts/game/pixel_particle_field.gd")
const VisualFactory = preload("res://scripts/game/visual_factory.gd")

# Region centers along the horizontal corridor (matches main world layout)
const REGION_MARKERS := [
	{"id": "green_hollow", "x": 12.0, "tint": Color(0.45, 0.70, 0.48), "dust": true, "steam": false},
	{"id": "workshop", "x": 42.0, "tint": Color(0.55, 0.50, 0.38), "dust": true, "steam": true},
	{"id": "ashwick", "x": 68.0, "tint": Color(0.50, 0.48, 0.42), "dust": true, "steam": true},
	{"id": "foundry", "x": 92.0, "tint": Color(0.70, 0.40, 0.28), "dust": true, "steam": true},
	{"id": "ashlands", "x": 118.0, "tint": Color(0.62, 0.48, 0.30), "dust": true, "steam": false},
	{"id": "flooded", "x": 150.0, "tint": Color(0.35, 0.55, 0.62), "dust": false, "steam": true},
	{"id": "iron_mountains", "x": 190.0, "tint": Color(0.48, 0.50, 0.55), "dust": true, "steam": false},
	{"id": "frostline", "x": 250.0, "tint": Color(0.55, 0.70, 0.78), "dust": true, "steam": true},
	{"id": "the_deep", "x": 300.0, "tint": Color(0.35, 0.42, 0.38), "dust": true, "steam": false},
	{"id": "veil_nexus", "x": 350.0, "tint": Color(0.55, 0.38, 0.72), "dust": true, "steam": true},
]

var _player: Node3D
var _last_region: String = ""

func configure(player: Node3D) -> void:
	_player = player

func _ready() -> void:
	if not SettingsManager.juice_enabled("ambient_particles"):
		return
	_spawn_fields()
	SettingsManager.settings_changed.connect(_on_settings)

func _process(_delta: float) -> void:
	if _player == null or not is_instance_valid(_player):
		return
	var x: float = _player.global_position.x
	var best_id := "green_hollow"
	var best_d := 9999.0
	for r in REGION_MARKERS:
		var d: float = absf(x - float(r["x"]))
		if d < best_d:
			best_d = d
			best_id = str(r["id"])
	if best_id != _last_region:
		_last_region = best_id
		AudioManager.set_ambient_region(best_id)

func _spawn_fields() -> void:
	for r in REGION_MARKERS:
		var x: float = float(r["x"])
		if bool(r.get("dust", false)):
			var dust = ParticleFieldScript.new()
			dust.position = Vector3(x, 0.0, 0.0)
			dust.configure("res://assets/pixel/dust.png", 28, Vector3(36.0, 4.5, 28.0), Vector3(0.06, 0.09, 0.02), 0.024)
			add_child(dust)
		if bool(r.get("steam", false)):
			var steam = ParticleFieldScript.new()
			steam.position = Vector3(x + 4.0, 0.2, 0.0)
			steam.configure("res://assets/pixel/steam.png", 16, Vector3(18.0, 5.5, 16.0), Vector3(0.02, 0.16, 0.01), 0.028)
			add_child(steam)
		# Soft ground glow plate for regional color identity
		var plate := MeshInstance3D.new()
		var mesh := BoxMesh.new()
		mesh.size = Vector3(22.0, 0.04, 18.0)
		plate.mesh = mesh
		var mat := StandardMaterial3D.new()
		var tint: Color = r["tint"]
		mat.albedo_color = Color(tint.r, tint.g, tint.b, 0.18)
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		plate.material_override = mat
		plate.position = Vector3(x, 0.02, 0.0)
		add_child(plate)

func _on_settings(section: String, key: String, _value: Variant) -> void:
	if section == "accessibility" and key in ["ambient_particles", "reduced_motion"]:
		# Simple approach: visibility toggle on children
		var on: bool = SettingsManager.juice_enabled("ambient_particles")
		for c in get_children():
			if c is Node3D:
				(c as Node3D).visible = on
