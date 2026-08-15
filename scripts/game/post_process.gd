extends CanvasLayer

var material: ShaderMaterial
var overlay: ColorRect

func _ready() -> void:
	layer = 10
	overlay = ColorRect.new()
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.color = Color.WHITE
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	material = ShaderMaterial.new()
	material.shader = ResourceLoader.load("res://shaders/modern_pixel_post.gdshader") as Shader
	overlay.material = material
	add_child(overlay)
	SettingsManager.settings_changed.connect(_on_settings_changed)
	_apply_settings()

func _apply_settings() -> void:
	if material == null or overlay == null:
		return
	var enabled: bool = bool(SettingsManager.get_value("graphics", "post_processing", true))
	overlay.visible = enabled
	material.set_shader_parameter("quantize_enabled", bool(SettingsManager.get_value("graphics", "pixel_quantization", true)))
	material.set_shader_parameter("vignette_enabled", bool(SettingsManager.get_value("graphics", "vignette", true)))
	material.set_shader_parameter("color_steps", float(SettingsManager.get_value("graphics", "color_steps", 28.0)))
	material.set_shader_parameter("dither_strength", float(SettingsManager.get_value("graphics", "dither_strength", 0.012)))
	material.set_shader_parameter("vignette_strength", float(SettingsManager.get_value("graphics", "vignette_strength", 0.13)))
	material.set_shader_parameter("colorblind_mode", _colorblind_index(str(SettingsManager.get_value("accessibility", "colorblind_mode", "off"))))

func _on_settings_changed(_section: String, _key: String, _value: Variant) -> void:
	_apply_settings()

func _colorblind_index(value: String) -> int:
	match value:
		"protanopia":
			return 1
		"deuteranopia":
			return 2
		"tritanopia":
			return 3
		_:
			return 0
