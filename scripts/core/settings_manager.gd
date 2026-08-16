extends Node

signal settings_changed(section: String, key: String, value: Variant)

const SETTINGS_PATH := "user://settings.cfg"
const DEFAULT_LOBBY_URL := "https://ironveil.zvlz.dev/api"

const KEYBIND_DEFAULTS := {
	"move_left": KEY_A,
	"move_right": KEY_D,
	"move_up": KEY_W,
	"move_down": KEY_S,
	"sprint": KEY_SHIFT,
	"interact": KEY_F,
	"attack": KEY_SPACE,
	"eat_quick": KEY_1,
	"medical_quick": KEY_2,
	"craft_gear": KEY_C,
	"craft_bandage": KEY_B,
	"journal": KEY_J,
	"inventory": KEY_I,
	"settings": KEY_ESCAPE,
	"help": KEY_H,
	"lobby": KEY_N,
	"save": KEY_F5,
	"load": KEY_F9,
	"camera_left": KEY_Q,
	"camera_right": KEY_E,
	"camera_reset": KEY_R,
}

var settings: Dictionary = {
	"graphics": {
		"resolution_width": 1280,
		"resolution_height": 720,
		"fullscreen": false,
		"vsync": true,
		"quality": "medium",
		"shadow_quality": "medium",
		"post_processing": true,
		"pixel_quantization": true,
		"vignette": true,
		"color_steps": 28.0,
		"dither_strength": 0.012,
		"vignette_strength": 0.13,
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
		"input_mode": "auto",
		"keybinds": KEYBIND_DEFAULTS.duplicate(true),
	},
	"gameplay": {
		"show_hud": true,
		"scarce_resources": false,
		"harsh_climate": false,
		"aggressive_enemies": false,
		"camera_rotation": true,
	},
	"accessibility": {
		"text_scale": 1.0,
		"colorblind_mode": "off",
		"subtitles": true,
		"reduced_motion": false,
		"high_contrast": false,
		"camera_shake": true,
	},
	"network": {
		"display_name": "Survivor",
		"lobby_url": DEFAULT_LOBBY_URL,
		"region": "auto",
	},
}

func _ready() -> void:
	_ensure_audio_buses()
	load_settings()
	_ensure_input_actions()
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
		var defaults_value: Variant = settings.get(section, {})
		if not (defaults_value is Dictionary):
			continue
		var defaults: Dictionary = defaults_value as Dictionary
		for key in defaults:
			settings[section][key] = config.get_value(section, key, defaults[key])
	# Merge new keybind defaults into older save files instead of replacing them.
	var binds_value: Variant = get_value("controls", "keybinds", {})
	var binds: Dictionary = {}
	if binds_value is Dictionary:
		binds = (binds_value as Dictionary).duplicate(true)
	for action in KEYBIND_DEFAULTS:
		if not binds.has(action):
			binds[action] = KEYBIND_DEFAULTS[action]
	settings["controls"]["keybinds"] = binds
	_migrate_network_url()

func _migrate_network_url() -> void:
	var current: String = str(get_value("network", "lobby_url", "")).strip_edges()
	if current.is_empty() or current.contains("127.0.0.1") or current.contains("localhost"):
		settings["network"]["lobby_url"] = DEFAULT_LOBBY_URL
		save_settings()

func save_settings() -> void:
	var config := ConfigFile.new()
	for section in settings:
		var section_value: Variant = settings[section]
		if not (section_value is Dictionary):
			continue
		for key in section_value:
			config.set_value(section, key, section_value[key])
	config.save(SETTINGS_PATH)

func get_value(section: String, key: String, fallback: Variant = null) -> Variant:
	var section_value: Variant = settings.get(section, {})
	if not (section_value is Dictionary):
		return fallback
	var section_dict: Dictionary = section_value as Dictionary
	return section_dict.get(key, fallback)

func set_value(section: String, key: String, value: Variant, apply_now: bool = true) -> void:
	if not settings.has(section) or not (settings[section] is Dictionary):
		settings[section] = {}
	var section_dict: Dictionary = settings[section] as Dictionary
	section_dict[key] = value
	settings[section] = section_dict
	if apply_now:
		apply_all()
	save_settings()
	settings_changed.emit(section, key, value)

func set_keybind(action: String, keycode: int) -> void:
	var binds_value: Variant = get_value("controls", "keybinds", {})
	var binds: Dictionary = {}
	if binds_value is Dictionary:
		binds = (binds_value as Dictionary).duplicate(true)
	binds[action] = int(keycode)
	set_value("controls", "keybinds", binds, false)
	_apply_keybind(action, int(keycode))

func get_keybind(action: String) -> int:
	var binds_value: Variant = get_value("controls", "keybinds", {})
	if binds_value is Dictionary:
		var binds: Dictionary = binds_value as Dictionary
		return int(binds.get(action, KEYBIND_DEFAULTS.get(action, KEY_NONE)))
	return int(KEYBIND_DEFAULTS.get(action, KEY_NONE))

func keybind_name(action: String) -> String:
	return OS.get_keycode_string(get_keybind(action))

func _ensure_input_actions() -> void:
	var binds_value: Variant = get_value("controls", "keybinds", {})
	var binds: Dictionary = {}
	if binds_value is Dictionary:
		binds = binds_value as Dictionary
	for action_variant in KEYBIND_DEFAULTS:
		var action: String = str(action_variant)
		if not InputMap.has_action(action):
			InputMap.add_action(action)
		_apply_keybind(action, int(binds.get(action, KEYBIND_DEFAULTS[action])))

func _apply_keybind(action: String, keycode: int) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action)
	InputMap.action_erase_events(action)
	var event := InputEventKey.new()
	event.physical_keycode = keycode
	InputMap.action_add_event(action, event)

func apply_all() -> void:
	_apply_graphics()
	_apply_audio()
	_ensure_input_actions()

func _apply_graphics() -> void:
	if DisplayServer.get_name() != "headless":
		var vsync_enabled: bool = bool(get_value("graphics", "vsync", true))
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED if vsync_enabled else DisplayServer.VSYNC_DISABLED)
		if OS.get_name() != "Web":
			var fullscreen: bool = bool(get_value("graphics", "fullscreen", false))
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN if fullscreen else DisplayServer.WINDOW_MODE_WINDOWED)
			if not fullscreen:
				var width: int = int(get_value("graphics", "resolution_width", 1280))
				var height: int = int(get_value("graphics", "resolution_height", 720))
				DisplayServer.window_set_size(Vector2i(width, height))
	var ui_scale: float = float(get_value("graphics", "ui_scale", 1.0))
	var text_scale: float = float(get_value("accessibility", "text_scale", 1.0))
	get_tree().root.content_scale_factor = clampf(ui_scale * text_scale, 0.75, 1.75)

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
