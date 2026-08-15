extends RefCounted

const DEFAULT_PIXEL_SIZE := 0.04

static func make_sprite(texture_path: String, pixel_size: float = DEFAULT_PIXEL_SIZE, shaded: bool = true) -> Sprite3D:
	var sprite := Sprite3D.new()
	var texture: Texture2D = ResourceLoader.load(texture_path) as Texture2D
	if texture != null:
		sprite.texture = texture
	sprite.pixel_size = pixel_size
	sprite.shaded = shaded
	sprite.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	sprite.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	sprite.alpha_cut = SpriteBase3D.ALPHA_CUT_DISCARD
	sprite.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	return sprite

static func make_material(
	texture_path: String,
	tint: Color = Color.WHITE,
	metallic: float = 0.0,
	roughness: float = 0.9,
	emission: Color = Color.BLACK,
	emission_energy: float = 0.0
) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = tint
	var texture: Texture2D = ResourceLoader.load(texture_path) as Texture2D
	if texture != null:
		material.albedo_texture = texture
	material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	material.texture_repeat = true
	material.metallic = clampf(metallic, 0.0, 1.0)
	material.roughness = clampf(roughness, 0.0, 1.0)
	if emission_energy > 0.0:
		material.emission_enabled = true
		material.emission = emission
		material.emission_energy_multiplier = emission_energy
	return material

static func make_box_mesh(size: Vector3, texture_path: String, tint: Color = Color.WHITE, metallic: float = 0.0, roughness: float = 0.9) -> MeshInstance3D:
	var instance := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size
	instance.mesh = mesh
	instance.material_override = make_material(texture_path, tint, metallic, roughness)
	return instance

static func make_label(text: String, color: Color = Color(0.92, 0.82, 0.55)) -> Label3D:
	var label := Label3D.new()
	label.text = text
	label.font_size = 24
	label.modulate = color
	label.outline_size = 6
	label.outline_modulate = Color(0.03, 0.04, 0.04, 0.95)
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.no_depth_test = false
	return label
