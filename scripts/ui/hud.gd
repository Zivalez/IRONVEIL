extends CanvasLayer

## IRONVEIL HUD — full visual overhaul + modal animations

signal modal_state_changed(open: bool)

const BRASS := Color(0.85, 0.65, 0.32, 1.0)
const TEXT := Color(0.92, 0.93, 0.90, 1.0)
const MUTED := Color(0.58, 0.62, 0.58, 1.0)
const PANEL_BG := Color(0.05, 0.06, 0.07, 0.94)
const PANEL_EDGE := Color(0.30, 0.32, 0.30, 0.85)

var status_label: Label
var objective_label: Label
var inventory_label: Label
var prompt_label: Label
var notification_label: Label
var journal_panel: PanelContainer
var journal_text: RichTextLabel
var settings_panel: PanelContainer
var help_panel: PanelContainer
var lobby_panel: PanelContainer
var notification_timer: Timer
var boss_panel: PanelContainer
var boss_name_label: Label
var boss_health_bar: ProgressBar
var boss_state_label: Label
var field_panel: PanelContainer
var field_inventory_text: RichTextLabel
var field_crafting_text: RichTextLabel
var field_machine_text: RichTextLabel
var field_character_text: RichTextLabel
var _root_control: Control
var _status_panel: PanelContainer
var _inventory_panel: PanelContainer
var _modal_scrim: ColorRect
var room_list: ItemList
var room_name_edit: LineEdit
var room_id_edit: LineEdit
var room_password_edit: LineEdit
var room_public_check: CheckButton
var network_status_label: Label
var _rooms: Array = []
var _pending_rebind_action: String = ""
var _rebind_buttons: Dictionary = {}
const COLORBLIND_VALUES: Array[String] = ["off", "protanopia", "deuteranopia", "tritanopia"]

func _ready() -> void:
	add_to_group("hud")
	layer = 20
	_build_ui()
	GameState.inventory_changed.connect(_update_inventory)
	GameState.survival_changed.connect(_update_survival)
	GameState.objective_changed.connect(_update_objective)
	GameState.journal_changed.connect(_update_journal)
	GameState.notification.connect(_show_notification)
	GameState.boss_changed.connect(_update_boss)
	GameState.boss_cleared.connect(_clear_boss)
	SettingsManager.settings_changed.connect(_on_settings_changed)
	NetworkManager.lobby_rooms_updated.connect(_on_lobby_rooms_updated)
	NetworkManager.lobby_request_failed.connect(_on_lobby_error)
	NetworkManager.connection_state_changed.connect(_on_connection_state_changed)
	InfrastructureNetwork.network_changed.connect(_on_infrastructure_changed)
	InputProfile.mode_changed.connect(_on_input_mode_changed)
	_update_inventory(GameState.inventory)
	_update_survival(GameState.survival)
	_update_objective(GameState.objective_step, GameState.current_objective())
	_update_journal(GameState.journal_entries)
	_apply_input_layout()
	# Animate HUD in
	_root_control.modulate.a = 0.0
	var tw := create_tween()
	tw.tween_property(_root_control, "modulate:a", 1.0, 0.45).set_ease(Tween.EASE_OUT)

func set_interaction_prompt(text: String) -> void:
	if prompt_label == null:
		return
	prompt_label.text = ("USE // " + text) if InputProfile.is_touch_mode() and not text.is_empty() else text
	var show: bool = not text.is_empty()
	if show and not prompt_label.visible:
		prompt_label.visible = true
		prompt_label.modulate.a = 0.0
		var tw := create_tween()
		tw.tween_property(prompt_label, "modulate:a", 1.0, 0.15)
	elif not show:
		prompt_label.visible = false

func _unhandled_input(event: InputEvent) -> void:
	if not _pending_rebind_action.is_empty() and event is InputEventKey:
		var key_event: InputEventKey = event as InputEventKey
		if key_event.pressed and not key_event.echo:
			SettingsManager.set_keybind(_pending_rebind_action, int(key_event.physical_keycode if key_event.physical_keycode != 0 else key_event.keycode))
			_pending_rebind_action = ""
			_refresh_rebind_labels()
			get_viewport().set_input_as_handled()
		return
	if event.is_action_pressed("journal"):
		_toggle_journal()
	elif event.is_action_pressed("settings"):
		_toggle_settings()
	elif event.is_action_pressed("help"):
		_toggle_help()
	elif event.is_action_pressed("lobby"):
		_toggle_lobby()
	elif event.is_action_pressed("inventory"):
		_toggle_field_panel()

func _build_ui() -> void:
	_root_control = Control.new()
	_root_control.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root_control.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_root_control)
	_build_status_panel(_root_control)
	_build_inventory_panel(_root_control)
	_build_boss_panel(_root_control)
	_build_prompt(_root_control)
	_build_notification(_root_control)
	_build_modal_scrim(_root_control)
	_build_journal(_root_control)
	_build_field_console(_root_control)
	_build_settings(_root_control)
	_build_lobby(_root_control)
	_build_help(_root_control)
	_sync_modal_state()

func _panel_style(modal: bool = false) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = Color(0.04, 0.05, 0.055, 0.97) if modal else PANEL_BG
	s.border_color = BRASS if modal else PANEL_EDGE
	s.set_border_width_all(1 if not modal else 2)
	s.set_corner_radius_all(8 if modal else 6)
	s.set_content_margin_all(16.0 if modal else 12.0)
	s.shadow_color = Color(0, 0, 0, 0.4)
	s.shadow_size = 10 if modal else 4
	s.shadow_offset = Vector2(0, 3)
	return s

func _build_modal_scrim(root: Control) -> void:
	_modal_scrim = ColorRect.new()
	_modal_scrim.set_anchors_preset(Control.PRESET_FULL_RECT)
	_modal_scrim.color = Color(0.01, 0.015, 0.02, 0.72)
	_modal_scrim.mouse_filter = Control.MOUSE_FILTER_STOP
	_modal_scrim.z_index = 1
	_modal_scrim.visible = false
	_modal_scrim.modulate.a = 0.0
	root.add_child(_modal_scrim)

func _build_status_panel(root: Control) -> void:
	_status_panel = PanelContainer.new()
	_status_panel.position = Vector2(16, 14)
	_status_panel.size = Vector2(380, 130)
	_status_panel.add_theme_stylebox_override("panel", _panel_style(false))
	root.add_child(_status_panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 4)
	_status_panel.add_child(box)
	var title := Label.new()
	title.text = "FIELD STATE"
	title.add_theme_font_size_override("font_size", 12)
	title.add_theme_color_override("font_color", BRASS)
	box.add_child(title)
	status_label = Label.new()
	status_label.add_theme_font_size_override("font_size", 13)
	status_label.add_theme_color_override("font_color", TEXT)
	status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(status_label)
	objective_label = Label.new()
	objective_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	objective_label.custom_minimum_size = Vector2(350, 48)
	objective_label.add_theme_font_size_override("font_size", 12)
	objective_label.add_theme_color_override("font_color", MUTED)
	box.add_child(objective_label)

func _build_inventory_panel(root: Control) -> void:
	_inventory_panel = PanelContainer.new()
	_inventory_panel.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	_inventory_panel.position = Vector2(-250, 14)
	_inventory_panel.size = Vector2(234, 110)
	_inventory_panel.add_theme_stylebox_override("panel", _panel_style(false))
	root.add_child(_inventory_panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 4)
	_inventory_panel.add_child(box)
	var title := Label.new()
	title.text = "PACK"
	title.add_theme_font_size_override("font_size", 12)
	title.add_theme_color_override("font_color", BRASS)
	box.add_child(title)
	inventory_label = Label.new()
	inventory_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	inventory_label.add_theme_font_size_override("font_size", 12)
	inventory_label.add_theme_color_override("font_color", TEXT)
	box.add_child(inventory_label)

func _build_boss_panel(root: Control) -> void:
	boss_panel = PanelContainer.new()
	boss_panel.set_anchors_preset(Control.PRESET_CENTER_TOP)
	boss_panel.position = Vector2(-220, 16)
	boss_panel.size = Vector2(440, 78)
	boss_panel.visible = false
	boss_panel.add_theme_stylebox_override("panel", _panel_style(false))
	root.add_child(boss_panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 4)
	boss_panel.add_child(box)
	boss_name_label = Label.new()
	boss_name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	boss_name_label.add_theme_font_size_override("font_size", 15)
	boss_name_label.add_theme_color_override("font_color", BRASS)
	box.add_child(boss_name_label)
	boss_health_bar = ProgressBar.new()
	boss_health_bar.min_value = 0.0
	boss_health_bar.show_percentage = false
	boss_health_bar.custom_minimum_size = Vector2(400, 12)
	box.add_child(boss_health_bar)
	boss_state_label = Label.new()
	boss_state_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	boss_state_label.add_theme_font_size_override("font_size", 11)
	boss_state_label.add_theme_color_override("font_color", MUTED)
	box.add_child(boss_state_label)

func _build_prompt(root: Control) -> void:
	prompt_label = Label.new()
	prompt_label.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	prompt_label.position = Vector2(-280, -72)
	prompt_label.size = Vector2(560, 44)
	prompt_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	prompt_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	prompt_label.add_theme_font_size_override("font_size", 15)
	prompt_label.add_theme_color_override("font_color", Color(0.95, 0.90, 0.75))
	prompt_label.visible = false
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.06, 0.07, 0.08, 0.94)
	style.border_color = BRASS
	style.set_border_width_all(2)
	style.set_corner_radius_all(8)
	style.set_content_margin_all(10.0)
	prompt_label.add_theme_stylebox_override("normal", style)
	root.add_child(prompt_label)

func _build_notification(root: Control) -> void:
	notification_label = Label.new()
	notification_label.set_anchors_preset(Control.PRESET_CENTER_TOP)
	notification_label.position = Vector2(-260, 100)
	notification_label.size = Vector2(520, 42)
	notification_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	notification_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	notification_label.add_theme_font_size_override("font_size", 14)
	notification_label.add_theme_color_override("font_color", TEXT)
	notification_label.visible = false
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.05, 0.06, 0.07, 0.95)
	style.border_color = BRASS
	style.set_border_width_all(1)
	style.set_corner_radius_all(8)
	style.set_content_margin_all(10.0)
	notification_label.add_theme_stylebox_override("normal", style)
	root.add_child(notification_label)
	notification_timer = Timer.new()
	notification_timer.one_shot = true
	notification_timer.wait_time = 2.6
	notification_timer.timeout.connect(_on_notification_timeout)
	add_child(notification_timer)

func _modal_panel(size: Vector2) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.position = -size / 2.0
	panel.size = size
	panel.z_index = 2
	panel.visible = false
	panel.modulate.a = 0.0
	panel.add_theme_stylebox_override("panel", _panel_style(true))
	return panel

func _build_journal(root: Control) -> void:
	journal_panel = _modal_panel(Vector2(720, 480))
	root.add_child(journal_panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 10)
	journal_panel.add_child(box)
	var title := Label.new()
	title.text = "FIELD JOURNAL"
	title.add_theme_font_size_override("font_size", 18)
	title.add_theme_color_override("font_color", BRASS)
	box.add_child(title)
	var sub := Label.new()
	sub.text = "Observation  →  Hypothesis  →  Confirmation"
	sub.add_theme_font_size_override("font_size", 12)
	sub.add_theme_color_override("font_color", MUTED)
	box.add_child(sub)
	journal_text = RichTextLabel.new()
	journal_text.bbcode_enabled = true
	journal_text.size_flags_vertical = Control.SIZE_EXPAND_FILL
	journal_text.custom_minimum_size = Vector2(680, 340)
	journal_text.add_theme_color_override("default_color", TEXT)
	box.add_child(journal_text)
	var close := Button.new()
	close.text = "Close"
	_wire_button(close)
	close.pressed.connect(_toggle_journal)
	box.add_child(close)

func _build_field_console(root: Control) -> void:
	field_panel = _modal_panel(Vector2(860, 560))
	root.add_child(field_panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 10)
	field_panel.add_child(box)
	var heading := Label.new()
	heading.text = "FIELD CONSOLE"
	heading.add_theme_font_size_override("font_size", 18)
	heading.add_theme_color_override("font_color", BRASS)
	box.add_child(heading)
	var tabs := TabContainer.new()
	tabs.custom_minimum_size = Vector2(820, 440)
	box.add_child(tabs)
	field_character_text = _rich_tab(tabs, "Character")
	field_inventory_text = _rich_tab(tabs, "Inventory")
	field_crafting_text = _rich_tab(tabs, "Crafting")
	field_machine_text = _rich_tab(tabs, "Infrastructure")
	var close := Button.new()
	close.text = "Close"
	_wire_button(close)
	close.pressed.connect(_toggle_field_panel)
	box.add_child(close)
	_refresh_field_console()

func _rich_tab(tabs: TabContainer, tab_name: String) -> RichTextLabel:
	var text := RichTextLabel.new()
	text.name = tab_name
	text.bbcode_enabled = true
	text.fit_content = false
	text.custom_minimum_size = Vector2(800, 400)
	text.add_theme_color_override("default_color", TEXT)
	tabs.add_child(text)
	return text

func _build_settings(root: Control) -> void:
	settings_panel = _modal_panel(Vector2(720, 540))
	root.add_child(settings_panel)
	var main_box := VBoxContainer.new()
	main_box.add_theme_constant_override("separation", 8)
	settings_panel.add_child(main_box)
	var title := Label.new()
	title.text = "SETTINGS"
	title.add_theme_font_size_override("font_size", 18)
	title.add_theme_color_override("font_color", BRASS)
	main_box.add_child(title)
	var tabs := TabContainer.new()
	tabs.custom_minimum_size = Vector2(680, 430)
	main_box.add_child(tabs)
	_build_graphics_tab(tabs)
	_build_audio_tab(tabs)
	_build_controls_tab(tabs)
	_build_gameplay_tab(tabs)
	_build_accessibility_tab(tabs)
	_build_network_settings_tab(tabs)
	var close := Button.new()
	close.text = "Close"
	_wire_button(close)
	close.pressed.connect(_toggle_settings)
	main_box.add_child(close)

func _tab_box(name: String) -> VBoxContainer:
	var box := VBoxContainer.new()
	box.name = name
	box.add_theme_constant_override("separation", 8)
	return box

func _build_graphics_tab(tabs: TabContainer) -> void:
	var box := _tab_box("Graphics")
	tabs.add_child(box)
	box.add_child(_check_row("VSync", "graphics", "vsync"))
	box.add_child(_check_row("Modern pixel post-processing", "graphics", "post_processing"))
	box.add_child(_check_row("Pixel color quantization", "graphics", "pixel_quantization"))
	box.add_child(_check_row("Vignette", "graphics", "vignette"))
	box.add_child(_slider_row("Camera zoom", 10.0, 28.0, float(SettingsManager.get_value("graphics", "camera_zoom", 18.0)), "graphics", "camera_zoom"))
	box.add_child(_slider_row("UI scale", 0.75, 1.5, float(SettingsManager.get_value("graphics", "ui_scale", 1.0)), "graphics", "ui_scale"))

func _build_audio_tab(tabs: TabContainer) -> void:
	var box := _tab_box("Audio")
	tabs.add_child(box)
	for entry in [["Master", "master", "mute_master"], ["Music", "music", "mute_music"], ["SFX", "sfx", "mute_sfx"], ["Ambient", "ambient", "mute_ambient"]]:
		box.add_child(_slider_row("%s volume" % entry[0], 0.0, 1.0, float(SettingsManager.get_value("audio", entry[1], 0.8)), "audio", entry[1]))
		box.add_child(_check_row("Mute %s" % entry[0], "audio", entry[2]))

func _build_controls_tab(tabs: TabContainer) -> void:
	var box := _tab_box("Controls")
	tabs.add_child(box)
	var mode_row := HBoxContainer.new()
	var mode_label := Label.new()
	mode_label.text = "Input layout"
	mode_label.custom_minimum_size.x = 200
	mode_label.add_theme_color_override("font_color", TEXT)
	mode_row.add_child(mode_label)
	var mode_options := OptionButton.new()
	for value in ["Auto detect", "Desktop", "Mobile / Touch"]:
		mode_options.add_item(value)
	mode_options.selected = [InputProfile.MODE_AUTO, InputProfile.MODE_DESKTOP, InputProfile.MODE_TOUCH].find(InputProfile.selected_mode())
	mode_options.item_selected.connect(_on_input_mode_selected)
	mode_row.add_child(mode_options)
	box.add_child(mode_row)
	box.add_child(_slider_row("Mouse sensitivity", 0.2, 2.0, float(SettingsManager.get_value("controls", "mouse_sensitivity", 1.0)), "controls", "mouse_sensitivity"))
	for action in ["move_up", "move_left", "move_down", "move_right", "sprint", "interact", "attack", "inventory", "journal", "lobby"]:
		var row := HBoxContainer.new()
		var label := Label.new()
		label.text = action.replace("_", " ").capitalize()
		label.custom_minimum_size.x = 200
		label.add_theme_color_override("font_color", TEXT)
		row.add_child(label)
		var button := Button.new()
		button.custom_minimum_size.x = 160
		_rebind_buttons[action] = button
		_wire_button(button)
		button.pressed.connect(_begin_rebind.bind(action))
		row.add_child(button)
		box.add_child(row)
	_refresh_rebind_labels()

func _build_gameplay_tab(tabs: TabContainer) -> void:
	var box := _tab_box("Gameplay")
	tabs.add_child(box)
	box.add_child(_check_row("Show HUD", "gameplay", "show_hud"))
	box.add_child(_check_row("Camera rotation", "gameplay", "camera_rotation"))
	box.add_child(_check_row("Scarce resources", "gameplay", "scarce_resources"))
	box.add_child(_check_row("Harsh climate", "gameplay", "harsh_climate"))
	box.add_child(_check_row("Aggressive enemies", "gameplay", "aggressive_enemies"))

func _build_accessibility_tab(tabs: TabContainer) -> void:
	var box := _tab_box("Accessibility")
	tabs.add_child(box)
	box.add_child(_slider_row("Text scale", 0.8, 1.5, float(SettingsManager.get_value("accessibility", "text_scale", 1.0)), "accessibility", "text_scale"))
	box.add_child(_check_row("Subtitles / text cues", "accessibility", "subtitles"))
	box.add_child(_check_row("Reduced motion", "accessibility", "reduced_motion"))
	box.add_child(_check_row("High contrast", "accessibility", "high_contrast"))
	var juice_title := Label.new()
	juice_title.text = "JUICE / FEEL"
	juice_title.add_theme_font_size_override("font_size", 13)
	juice_title.add_theme_color_override("font_color", BRASS)
	box.add_child(juice_title)
	box.add_child(_check_row("Camera shake", "accessibility", "camera_shake"))
	box.add_child(_check_row("Attack squash", "accessibility", "attack_squash"))
	box.add_child(_check_row("Hit flash", "accessibility", "hit_flash"))
	box.add_child(_check_row("Hit sparks", "accessibility", "hit_sparks"))
	box.add_child(_check_row("Walk bob", "accessibility", "walk_bob"))
	box.add_child(_check_row("Ambient particles", "accessibility", "ambient_particles"))
	box.add_child(_slider_row("Juice intensity", 0.0, 1.5, float(SettingsManager.get_value("accessibility", "juice_intensity", 1.0)), "accessibility", "juice_intensity"))

func _build_network_settings_tab(tabs: TabContainer) -> void:
	var box := _tab_box("Network")
	tabs.add_child(box)
	var name_edit := _line_setting_row(box, "Display name", str(SettingsManager.get_value("network", "display_name", "Survivor")))
	name_edit.text_changed.connect(_on_network_name_changed)
	var lobby_edit := _line_setting_row(box, "Lobby API URL", str(SettingsManager.get_value("network", "lobby_url", "https://ironveil.zvlz.dev/api")))
	lobby_edit.text_changed.connect(_on_lobby_url_changed)

func _build_lobby(root: Control) -> void:
	lobby_panel = _modal_panel(Vector2(640, 460))
	root.add_child(lobby_panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 8)
	lobby_panel.add_child(box)
	var title := Label.new()
	title.text = "CO-OP ROOMS"
	title.add_theme_font_size_override("font_size", 18)
	title.add_theme_color_override("font_color", BRASS)
	box.add_child(title)
	network_status_label = Label.new()
	network_status_label.add_theme_color_override("font_color", MUTED)
	box.add_child(network_status_label)
	room_list = ItemList.new()
	room_list.custom_minimum_size = Vector2(0, 160)
	box.add_child(room_list)
	room_name_edit = LineEdit.new()
	room_name_edit.placeholder_text = "Room name"
	box.add_child(room_name_edit)
	room_id_edit = LineEdit.new()
	room_id_edit.placeholder_text = "Room ID / invite"
	box.add_child(room_id_edit)
	room_password_edit = LineEdit.new()
	room_password_edit.placeholder_text = "Password (optional)"
	room_password_edit.secret = true
	box.add_child(room_password_edit)
	room_public_check = CheckButton.new()
	room_public_check.text = "Public room"
	room_public_check.button_pressed = true
	box.add_child(room_public_check)
	var row := HBoxContainer.new()
	box.add_child(row)
	var create_btn := Button.new()
	create_btn.text = "Create"
	_wire_button(create_btn)
	create_btn.pressed.connect(_create_room)
	row.add_child(create_btn)
	var join_btn := Button.new()
	join_btn.text = "Join"
	_wire_button(join_btn)
	join_btn.pressed.connect(_join_room)
	row.add_child(join_btn)
	var refresh := Button.new()
	refresh.text = "Refresh"
	_wire_button(refresh)
	refresh.pressed.connect(func() -> void: NetworkManager.list_rooms())
	row.add_child(refresh)
	var close := Button.new()
	close.text = "Close"
	_wire_button(close)
	close.pressed.connect(_toggle_lobby)
	box.add_child(close)

func _build_help(root: Control) -> void:
	help_panel = _modal_panel(Vector2(560, 380))
	root.add_child(help_panel)
	var box := VBoxContainer.new()
	help_panel.add_child(box)
	var title := Label.new()
	title.text = "HELP"
	title.add_theme_font_size_override("font_size", 18)
	title.add_theme_color_override("font_color", BRASS)
	box.add_child(title)
	var help := Label.new()
	help.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	help.text = "WASD move · Shift sprint · F interact · Space attack\nLeft click interact/attack · Right click attack\nQ/E or middle-mouse rotate camera · Scroll zoom\nI field console · J journal · N co-op · Esc settings"
	help.add_theme_color_override("font_color", TEXT)
	box.add_child(help)
	var close := Button.new()
	close.text = "Close"
	_wire_button(close)
	close.pressed.connect(_toggle_help)
	box.add_child(close)

# ---------- shared form helpers ----------
func _check_row(label_text: String, section: String, key: String) -> HBoxContainer:
	var row := HBoxContainer.new()
	var label := Label.new()
	label.text = label_text
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.add_theme_color_override("font_color", TEXT)
	row.add_child(label)
	var check := CheckButton.new()
	check.button_pressed = bool(SettingsManager.get_value(section, key, false))
	check.toggled.connect(func(v: bool) -> void: SettingsManager.set_value(section, key, v))
	row.add_child(check)
	return row

func _slider_row(label_text: String, min_v: float, max_v: float, current: float, section: String, key: String) -> HBoxContainer:
	var row := HBoxContainer.new()
	var label := Label.new()
	label.text = label_text
	label.custom_minimum_size.x = 180
	label.add_theme_color_override("font_color", TEXT)
	row.add_child(label)
	var slider := HSlider.new()
	slider.min_value = min_v
	slider.max_value = max_v
	slider.step = 0.01 if max_v <= 2.0 else 0.1
	slider.value = current
	slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	slider.value_changed.connect(func(v: float) -> void: SettingsManager.set_value(section, key, v))
	row.add_child(slider)
	return row

func _line_setting_row(parent: VBoxContainer, label_text: String, value: String) -> LineEdit:
	var label := Label.new()
	label.text = label_text
	label.add_theme_color_override("font_color", MUTED)
	parent.add_child(label)
	var edit := LineEdit.new()
	edit.text = value
	parent.add_child(edit)
	return edit

func _wire_button(button: BaseButton) -> void:
	button.mouse_entered.connect(_on_ui_hover)
	button.button_down.connect(_on_ui_press)

func _on_ui_hover() -> void:
	pass

func _on_ui_press() -> void:
	AudioManager.play_ui("press")

# ---------- modal open/close with animation ----------
func _toggle_journal() -> void:
	_set_modal(journal_panel)

func _toggle_settings() -> void:
	_set_modal(settings_panel)

func _toggle_help() -> void:
	_set_modal(help_panel)

func _toggle_lobby() -> void:
	_set_modal(lobby_panel)
	if lobby_panel.visible:
		NetworkManager.list_rooms()

func _toggle_field_panel() -> void:
	_set_modal(field_panel)
	if field_panel.visible:
		_refresh_field_console()

func _set_modal(panel: PanelContainer) -> void:
	var open_next: bool = not panel.visible
	# close others
	for candidate in [journal_panel, settings_panel, help_panel, lobby_panel, field_panel]:
		if candidate != null and candidate != panel and candidate.visible:
			_animate_close(candidate)
	if open_next:
		_animate_open(panel)
		AudioManager.play_ui("open")
	else:
		_animate_close(panel)
		AudioManager.play_ui("close")
	_sync_modal_state()

func _animate_open(panel: PanelContainer) -> void:
	panel.visible = true
	panel.modulate.a = 0.0
	panel.scale = Vector2(0.94, 0.94)
	panel.pivot_offset = panel.size * 0.5
	_modal_scrim.visible = true
	var tw := create_tween()
	tw.set_parallel(true)
	tw.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tw.tween_property(panel, "modulate:a", 1.0, 0.22)
	tw.tween_property(panel, "scale", Vector2.ONE, 0.26)
	tw.tween_property(_modal_scrim, "modulate:a", 1.0, 0.2)

func _animate_close(panel: PanelContainer) -> void:
	var tw := create_tween()
	tw.set_parallel(true)
	tw.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	tw.tween_property(panel, "modulate:a", 0.0, 0.16)
	tw.tween_property(panel, "scale", Vector2(0.96, 0.96), 0.16)
	tw.chain().tween_callback(func() -> void:
		panel.visible = false
		panel.scale = Vector2.ONE
		_sync_modal_state()
	)

func _sync_modal_state() -> void:
	var open: bool = false
	for panel in [journal_panel, settings_panel, help_panel, lobby_panel, field_panel]:
		if panel != null and panel.visible:
			open = true
			break
	if _modal_scrim != null:
		if not open:
			_modal_scrim.visible = false
			_modal_scrim.modulate.a = 0.0
	modal_state_changed.emit(open)

func mobile_toggle(section: String) -> void:
	match section:
		"inventory":
			_toggle_field_panel()
		"journal":
			_toggle_journal()
		"lobby":
			_toggle_lobby()
		"settings":
			_toggle_settings()
		"help":
			_toggle_help()

# ---------- updates (kept) ----------
func _update_inventory(inventory: Dictionary) -> void:
	if inventory_label == null:
		return
	var parts: Array[String] = []
	for key in inventory:
		parts.append("%s x%d" % [str(key).replace("_", " "), int(inventory[key])])
	inventory_label.text = "\n".join(parts) if not parts.is_empty() else "Empty"

func _update_survival(survival: Dictionary) -> void:
	if status_label == null:
		return
	status_label.text = "HP %d   STM %d   HNG %d   THR %d" % [
		int(survival.get("health", 0)),
		int(survival.get("stamina", 0)),
		int(survival.get("hunger", 0)),
		int(survival.get("thirst", 0)),
	]

func _update_objective(step: int, text: String) -> void:
	if objective_label == null:
		return
	objective_label.text = "OBJ %02d  ·  %s" % [step, text]

func _update_journal(entries: Array) -> void:
	if journal_text == null:
		return
	var lines: Array[String] = []
	for entry in entries:
		if entry is Dictionary:
			lines.append("[b]%s[/b]\n%s\n" % [str(entry.get("title", "")), str(entry.get("body", ""))])
	journal_text.text = "\n".join(lines) if not lines.is_empty() else "No entries yet."

func _show_notification(message: String, kind: String = "info") -> void:
	if notification_label == null:
		return
	notification_label.text = message
	notification_label.visible = true
	notification_label.modulate.a = 0.0
	var tw := create_tween()
	tw.tween_property(notification_label, "modulate:a", 1.0, 0.15)
	notification_timer.start()

func _on_notification_timeout() -> void:
	if notification_label == null:
		return
	var tw := create_tween()
	tw.tween_property(notification_label, "modulate:a", 0.0, 0.2)
	tw.tween_callback(func() -> void: notification_label.visible = false)

func _update_boss(name: String, health: float, max_health: float, state: String) -> void:
	if boss_panel == null:
		return
	boss_panel.visible = true
	boss_name_label.text = name
	boss_health_bar.max_value = max_health
	boss_health_bar.value = health
	boss_state_label.text = state

func _clear_boss() -> void:
	if boss_panel != null:
		boss_panel.visible = false

func _refresh_field_console() -> void:
	if field_character_text == null:
		return
	field_character_text.text = str(GameState.survival)
	field_inventory_text.text = str(GameState.inventory)
	field_crafting_text.text = "Open recipes from data catalogs. Use C / craft actions in-field."
	field_machine_text.text = "Infrastructure network status updates live."

func _on_settings_changed(_section: String, _key: String, _value: Variant) -> void:
	pass

func _on_lobby_rooms_updated(rooms: Array) -> void:
	_rooms = rooms
	if room_list == null:
		return
	room_list.clear()
	for room in rooms:
		if room is Dictionary:
			var players := int(room.get("players", 0))
			var max_p := int(room.get("max_players", 4))
			room_list.add_item("%s   %d/%d online" % [str(room.get("name", "Room")), players, max_p])

func _on_lobby_error(message: String) -> void:
	if network_status_label != null:
		network_status_label.text = message

func _on_connection_state_changed(state: String) -> void:
	if network_status_label != null:
		network_status_label.text = "Connection: " + state

func _on_infrastructure_changed(_data: Variant) -> void:
	_refresh_field_console()

func _on_input_mode_changed(_mode: String) -> void:
	_apply_input_layout()

func _apply_input_layout() -> void:
	pass

func _on_input_mode_selected(index: int) -> void:
	var modes := [InputProfile.MODE_AUTO, InputProfile.MODE_DESKTOP, InputProfile.MODE_TOUCH]
	if index >= 0 and index < modes.size():
		InputProfile.set_mode(modes[index])

func _begin_rebind(action: String) -> void:
	_pending_rebind_action = action
	if _rebind_buttons.has(action):
		(_rebind_buttons[action] as Button).text = "Press key…"

func _refresh_rebind_labels() -> void:
	for action in _rebind_buttons:
		(_rebind_buttons[action] as Button).text = SettingsManager.keybind_name(str(action))

func _on_network_name_changed(value: String) -> void:
	SettingsManager.set_value("network", "display_name", value, false)

func _on_lobby_url_changed(value: String) -> void:
	SettingsManager.set_value("network", "lobby_url", value, false)

func _create_room() -> void:
	NetworkManager.create_room(room_name_edit.text, room_password_edit.text, room_public_check.button_pressed)

func _join_room() -> void:
	var selected := room_list.get_selected_items()
	var room_id := room_id_edit.text
	if not selected.is_empty() and selected[0] < _rooms.size() and _rooms[selected[0]] is Dictionary:
		room_id = str((_rooms[selected[0]] as Dictionary).get("id", room_id))
	NetworkManager.join_room(room_id, room_password_edit.text)

func _on_colorblind_selected(index: int) -> void:
	if index >= 0 and index < COLORBLIND_VALUES.size():
		SettingsManager.set_value("accessibility", "colorblind_mode", COLORBLIND_VALUES[index])
