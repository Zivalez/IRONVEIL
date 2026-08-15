extends Node

signal settings_changed(section: String, key: String, value: Variant)

const SETTINGS_PATH := "user://settings.cfg"

var settings: Dictionary = {
	"graphics": {
		"resolution_width": 1280,
		"resolution_height": 720,
		"fullscreen": false,
		"vsync": true,
		"quality": "medium",
		"shadow_quality": "medium",
		"post_processing": true,
		"camera_zoom": 18.0,
		"ui_scale": 1.0,
	},
	"audio": {
		"master": 0.8,
		"music": 0.7,
		"sfx": 0.8,
		"ambient": 0.7,
		"mute_master": false,
		"mute_music": false,
		"mute_sfx": false,
		"mute_ambient": false,
	},
	"controls": {
		"mouse_sensitivity": 1.0,
	},
	"gameplay": {
		"show_hud": true,
	},
	"accessibility": {
		"text_scale": 1.0,
		"colorblind_mode": "off",
		"subtitles": true,
	},
}

func _ready() -> void:
	_ensure_audio_buses()
	load_settings()
	apply_all()

func _ensure_audio_buses() -> void:
	for bus_name in ["Music", "SFX", "Ambient"]:
		if AudioServer.get_bus_index(bus_name) == -1:
			AudioServer.add_bus(AudioServer.bus_count)
			AudioServer.set_bus_name(AudioServer.bus_count - 1, bus_name)

func load_settings() -> void:
	var config := ConfigFile.new()
	if config.load(SETTINGS_PATH) != OK:
		save_settings()
		return
	for section in settings:
		if not config.has_section(section):
			continue
		var defaults: Dictionary = settings[section]
		for key in defaults:
			settings[section][key] = config.get_value(section, key, defaults[key])

func save_settings() -> void:
	var config := ConfigFile.new()
	for section in settings:
		for key in settings[section]:
			config.set_value(section, key, settings[section][key])
	config.save(SETTINGS_PATH)

func get_value(section: String, key: String, fallback: Variant = null) -> Variant:
	var section_value: Variant = settings.get(section, {})
	if not (section_value is Dictionary):
		return fallback
	var section_dict: Dictionary = section_value
	return section_dict.get(key, fallback)

func set_value(section: String, key: String, value: Variant, apply_now: bool = true) -> void:
	if not settings.has(section):
		settings[section] = {}
	settings[section][key] = value
	if apply_now:
		apply_all()
	save_settings()
	settings_changed.emit(section, key, value)

func apply_all() -> void:
	_apply_graphics()
	_apply_audio()

func _apply_graphics() -> void:
	# Godot's --headless display server has no window to configure. The CI runtime
	# smoke test still applies non-window settings below.
	if DisplayServer.get_name() != "headless":
		var vsync_enabled: bool = bool(get_value("graphics", "vsync", true))
		DisplayServer.window_set_vsync_mode(
			DisplayServer.VSYNC_ENABLED if vsync_enabled else DisplayServer.VSYNC_DISABLED
		)

		if OS.get_name() != "Web":
			var fullscreen: bool = bool(get_value("graphics", "fullscreen", false))
			DisplayServer.window_set_mode(
				DisplayServer.WINDOW_MODE_FULLSCREEN if fullscreen else DisplayServer.WINDOW_MODE_WINDOWED
			)
			if not fullscreen:
				var width: int = int(get_value("graphics", "resolution_width", 1280))
				var height: int = int(get_value("graphics", "resolution_height", 720))
				DisplayServer.window_set_size(Vector2i(width, height))

	var scale: float = float(get_value("graphics", "ui_scale", 1.0))
	get_tree().root.content_scale_factor = clampf(scale, 0.75, 1.5)

func _apply_audio() -> void:
	_apply_bus("Master", "master", "mute_master")
	_apply_bus("Music", "music", "mute_music")
	_apply_bus("SFX", "sfx", "mute_sfx")
	_apply_bus("Ambient", "ambient", "mute_ambient")

func _apply_bus(bus_name: String, volume_key: String, mute_key: String) -> void:
	var index: int = AudioServer.get_bus_index(bus_name)
	if index == -1:
		return
	var linear: float = clampf(float(get_value("audio", volume_key, 0.8)), 0.0, 1.0)
	AudioServer.set_bus_volume_db(index, linear_to_db(maxf(linear, 0.0001)))
	AudioServer.set_bus_mute(index, bool(get_value("audio", mute_key, false)))
