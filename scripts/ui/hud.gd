extends CanvasLayer

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
	_update_inventory(GameState.inventory)
	_update_survival(GameState.survival)
	_update_objective(GameState.objective_step, GameState.current_objective())
	_update_journal(GameState.journal_entries)

func set_interaction_prompt(text: String) -> void:
	if prompt_label == null:
		return
	prompt_label.text = text
	prompt_label.visible = not text.is_empty()

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

func _build_ui() -> void:
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)
	_build_status_panel(root)
	_build_inventory_panel(root)
	_build_boss_panel(root)
	_build_prompt(root)
	_build_notification(root)
	_build_journal(root)
	_build_settings(root)
	_build_lobby(root)
	_build_help(root)

func _build_status_panel(root: Control) -> void:
	var top_left: PanelContainer = _panel(Vector2(18, 18), Vector2(420, 150), false)
	root.add_child(top_left)
	var box := VBoxContainer.new()
	top_left.add_child(box)
	var title := Label.new()
	title.text = "IRONVEIL // FIELD STATE"
	title.add_theme_font_size_override("font_size", 18)
	box.add_child(title)
	status_label = Label.new()
	box.add_child(status_label)
	objective_label = Label.new()
	objective_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	objective_label.custom_minimum_size = Vector2(390, 60)
	box.add_child(objective_label)

func _build_inventory_panel(root: Control) -> void:
	var top_right: PanelContainer = _panel(Vector2(-338, 18), Vector2(320, 218), true)
	root.add_child(top_right)
	inventory_label = Label.new()
	inventory_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	top_right.add_child(inventory_label)

func _build_boss_panel(root: Control) -> void:
	boss_panel = _panel(Vector2(-280, 74), Vector2(560, 92), false)
	boss_panel.set_anchors_preset(Control.PRESET_CENTER_TOP)
	boss_panel.position = Vector2(-280, 74)
	boss_panel.visible = false
	root.add_child(boss_panel)
	var box := VBoxContainer.new()
	boss_panel.add_child(box)
	boss_name_label = Label.new()
	boss_name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	boss_name_label.add_theme_font_size_override("font_size", 18)
	box.add_child(boss_name_label)
	boss_health_bar = ProgressBar.new()
	boss_health_bar.min_value = 0.0
	boss_health_bar.show_percentage = false
	boss_health_bar.custom_minimum_size = Vector2(520, 16)
	box.add_child(boss_health_bar)
	boss_state_label = Label.new()
	boss_state_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(boss_state_label)

func _build_prompt(root: Control) -> void:
	prompt_label = Label.new()
	prompt_label.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	prompt_label.position = Vector2(-330, -90)
	prompt_label.size = Vector2(660, 48)
	prompt_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	prompt_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	prompt_label.add_theme_font_size_override("font_size", 18)
	prompt_label.visible = false
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.05, 0.06, 0.06, 0.90)
	style.border_color = Color(0.56, 0.44, 0.22, 0.90)
	style.set_border_width_all(1)
	prompt_label.add_theme_stylebox_override("normal", style)
	root.add_child(prompt_label)

func _build_notification(root: Control) -> void:
	notification_label = Label.new()
	notification_label.set_anchors_preset(Control.PRESET_CENTER_TOP)
	notification_label.position = Vector2(-300, 18)
	notification_label.size = Vector2(600, 46)
	notification_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	notification_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	notification_label.visible = false
	root.add_child(notification_label)
	notification_timer = Timer.new()
	notification_timer.one_shot = true
	notification_timer.wait_time = 3.0
	notification_timer.timeout.connect(_on_notification_timeout)
	add_child(notification_timer)

func _build_journal(root: Control) -> void:
	journal_panel = _modal_panel(Vector2(800, 540))
	journal_panel.visible = false
	root.add_child(journal_panel)
	var box := VBoxContainer.new()
	journal_panel.add_child(box)
	var title := Label.new()
	title.text = "FIELD JOURNAL // OBSERVATION -> HYPOTHESIS -> CONFIRMATION"
	title.add_theme_font_size_override("font_size", 19)
	box.add_child(title)
	journal_text = RichTextLabel.new()
	journal_text.bbcode_enabled = true
	journal_text.custom_minimum_size = Vector2(750, 430)
	box.add_child(journal_text)
	var close := Button.new()
	close.text = "Close [%s]" % SettingsManager.keybind_name("journal")
	_wire_button(close)
	close.pressed.connect(_on_journal_close_pressed)
	box.add_child(close)

func _build_settings(root: Control) -> void:
	settings_panel = _modal_panel(Vector2(780, 590))
	settings_panel.visible = false
	root.add_child(settings_panel)
	var main_box := VBoxContainer.new()
	settings_panel.add_child(main_box)
	var title := Label.new()
	title.text = "IRONVEIL // SYSTEM SETTINGS"
	title.add_theme_font_size_override("font_size", 20)
	main_box.add_child(title)
	var tabs := TabContainer.new()
	tabs.custom_minimum_size = Vector2(730, 475)
	main_box.add_child(tabs)
	_build_graphics_tab(tabs)
	_build_audio_tab(tabs)
	_build_controls_tab(tabs)
	_build_gameplay_tab(tabs)
	_build_accessibility_tab(tabs)
	_build_network_settings_tab(tabs)
	var close := Button.new()
	close.text = "Close [%s]" % SettingsManager.keybind_name("settings")
	_wire_button(close)
	close.pressed.connect(_on_settings_close_pressed)
	main_box.add_child(close)

func _build_graphics_tab(tabs: TabContainer) -> void:
	var box := _tab_box("Graphics")
	tabs.add_child(box)
	box.add_child(_check_row("VSync", "graphics", "vsync"))
	box.add_child(_check_row("Modern pixel post-processing", "graphics", "post_processing"))
	box.add_child(_check_row("Pixel color quantization", "graphics", "pixel_quantization"))
	box.add_child(_check_row("Vignette", "graphics", "vignette"))
	box.add_child(_slider_row("Camera zoom", 10.0, 28.0, float(SettingsManager.get_value("graphics", "camera_zoom", 18.0)), "graphics", "camera_zoom"))
	box.add_child(_slider_row("UI scale", 0.75, 1.5, float(SettingsManager.get_value("graphics", "ui_scale", 1.0)), "graphics", "ui_scale"))
	box.add_child(_slider_row("Palette steps", 12.0, 48.0, float(SettingsManager.get_value("graphics", "color_steps", 28.0)), "graphics", "color_steps"))
	box.add_child(_slider_row("Dither strength", 0.0, 0.04, float(SettingsManager.get_value("graphics", "dither_strength", 0.012)), "graphics", "dither_strength"))

func _build_audio_tab(tabs: TabContainer) -> void:
	var box := _tab_box("Audio")
	tabs.add_child(box)
	for entry in [["Master", "master", "mute_master"], ["Music", "music", "mute_music"], ["SFX", "sfx", "mute_sfx"], ["Ambient", "ambient", "mute_ambient"]]:
		box.add_child(_slider_row("%s volume" % entry[0], 0.0, 1.0, float(SettingsManager.get_value("audio", entry[1], 0.8)), "audio", entry[1]))
		box.add_child(_check_row("Mute %s" % entry[0], "audio", entry[2]))

func _build_controls_tab(tabs: TabContainer) -> void:
	var box := _tab_box("Controls")
	tabs.add_child(box)
	box.add_child(_slider_row("Mouse sensitivity", 0.2, 2.0, float(SettingsManager.get_value("controls", "mouse_sensitivity", 1.0)), "controls", "mouse_sensitivity"))
	for action in ["move_up", "move_left", "move_down", "move_right", "sprint", "interact", "attack", "camera_left", "camera_right", "journal", "lobby"]:
		var row := HBoxContainer.new()
		var label := Label.new()
		label.text = action.replace("_", " ").capitalize()
		label.custom_minimum_size.x = 220
		row.add_child(label)
		var button := Button.new()
		button.custom_minimum_size.x = 220
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
	box.add_child(_check_row("Allow 90-degree camera rotation", "gameplay", "camera_rotation"))
	box.add_child(_check_row("Scarce resources world modifier", "gameplay", "scarce_resources"))
	box.add_child(_check_row("Harsh climate world modifier", "gameplay", "harsh_climate"))
	box.add_child(_check_row("Aggressive enemies world modifier", "gameplay", "aggressive_enemies"))

func _build_accessibility_tab(tabs: TabContainer) -> void:
	var box := _tab_box("Accessibility")
	tabs.add_child(box)
	box.add_child(_slider_row("Text scale", 0.8, 1.5, float(SettingsManager.get_value("accessibility", "text_scale", 1.0)), "accessibility", "text_scale"))
	box.add_child(_check_row("Subtitles / text cues", "accessibility", "subtitles"))
	var row := HBoxContainer.new()
	var label := Label.new()
	label.text = "Colorblind palette"
	label.custom_minimum_size.x = 220
	row.add_child(label)
	var options := OptionButton.new()
	for name in ["Off", "Protanopia", "Deuteranopia", "Tritanopia"]:
		options.add_item(name)
	options.select(maxi(COLORBLIND_VALUES.find(str(SettingsManager.get_value("accessibility", "colorblind_mode", "off"))), 0))
	options.item_selected.connect(_on_colorblind_selected)
	row.add_child(options)
	box.add_child(row)

func _build_network_settings_tab(tabs: TabContainer) -> void:
	var box := _tab_box("Network")
	tabs.add_child(box)
	var name_edit := _line_setting_row(box, "Display name", str(SettingsManager.get_value("network", "display_name", "Survivor")))
	name_edit.text_changed.connect(_on_network_name_changed)
	var lobby_edit := _line_setting_row(box, "Lobby API URL", str(SettingsManager.get_value("network", "lobby_url", "http://127.0.0.1:8081")))
	lobby_edit.text_changed.connect(_on_lobby_url_changed)
	var note := Label.new()
	note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	note.text = "Public HTTPS deployment requires an HTTPS lobby URL and WSS room endpoint. The lobby validates room passwords server-side and enforces 4 players per room."
	box.add_child(note)

func _build_lobby(root: Control) -> void:
	lobby_panel = _modal_panel(Vector2(720, 520))
	lobby_panel.visible = false
	root.add_child(lobby_panel)
	var box := VBoxContainer.new()
	lobby_panel.add_child(box)
	var title := Label.new()
	title.text = "CO-OP ROOM TERMINAL // 2-4 PLAYERS"
	title.add_theme_font_size_override("font_size", 20)
	box.add_child(title)
	network_status_label = Label.new()
	network_status_label.text = "OFFLINE"
	box.add_child(network_status_label)
	room_list = ItemList.new()
	room_list.custom_minimum_size = Vector2(670, 230)
	box.add_child(room_list)
	var form := GridContainer.new()
	form.columns = 2
	box.add_child(form)
	form.add_child(_form_label("Room name"))
	room_name_edit = LineEdit.new()
	room_name_edit.placeholder_text = "Ashwick Expedition"
	form.add_child(room_name_edit)
	form.add_child(_form_label("Room ID / invite code"))
	room_id_edit = LineEdit.new()
	room_id_edit.placeholder_text = "For private rooms, paste the room ID here"
	form.add_child(room_id_edit)
	form.add_child(_form_label("Password (optional)"))
	room_password_edit = LineEdit.new()
	room_password_edit.secret = true
	form.add_child(room_password_edit)
	form.add_child(_form_label("Public listing"))
	room_public_check = CheckButton.new()
	room_public_check.button_pressed = true
	form.add_child(room_public_check)
	var buttons := HBoxContainer.new()
	box.add_child(buttons)
	var refresh := Button.new()
	refresh.text = "Refresh"
	_wire_button(refresh)
	refresh.pressed.connect(_on_room_refresh)
	buttons.add_child(refresh)
	var create := Button.new()
	create.text = "Create"
	_wire_button(create)
	create.pressed.connect(_on_room_create)
	buttons.add_child(create)
	var join := Button.new()
	join.text = "Join selected"
	_wire_button(join)
	join.pressed.connect(_on_room_join)
	buttons.add_child(join)
	var disconnect := Button.new()
	disconnect.text = "Disconnect"
	_wire_button(disconnect)
	disconnect.pressed.connect(_on_room_disconnect)
	buttons.add_child(disconnect)
	var close := Button.new()
	close.text = "Close [%s]" % SettingsManager.keybind_name("lobby")
	_wire_button(close)
	close.pressed.connect(_toggle_lobby)
	box.add_child(close)

func _build_help(root: Control) -> void:
	help_panel = _modal_panel(Vector2(700, 420))
	root.add_child(help_panel)
	var box := VBoxContainer.new()
	help_panel.add_child(box)
	var title := Label.new()
	title.text = "PHASE 2 // ASHWICK VERTICAL SLICE"
	title.add_theme_font_size_override("font_size", 20)
	box.add_child(title)
	var help := Label.new()
	help.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	help.custom_minimum_size = Vector2(650, 300)
	help.text = "Move %s/%s/%s/%s  • Sprint %s  • Interact %s  • Attack %s\nRotate camera %s/%s  • Journal %s  • Lobby %s  • Settings %s\nQuick consume %s  • Craft gear %s  • Save/Load %s/%s\n\nRoute: survive Green Hollow -> revive the workshop -> automate planks -> repair Ashwick bridge -> meet Archivist Mara -> press steel plates -> enter the Foundry Vault -> use BOTH thermal relief valves -> defeat the Furnace Saint during the thermal-shock window.\n\nKnowledge is progression. If brute force fails, observe the system." % [SettingsManager.keybind_name("move_up"), SettingsManager.keybind_name("move_left"), SettingsManager.keybind_name("move_down"), SettingsManager.keybind_name("move_right"), SettingsManager.keybind_name("sprint"), SettingsManager.keybind_name("interact"), SettingsManager.keybind_name("attack"), SettingsManager.keybind_name("camera_left"), SettingsManager.keybind_name("camera_right"), SettingsManager.keybind_name("journal"), SettingsManager.keybind_name("lobby"), SettingsManager.keybind_name("settings"), SettingsManager.keybind_name("eat_quick"), SettingsManager.keybind_name("craft_gear"), SettingsManager.keybind_name("save"), SettingsManager.keybind_name("load")]
	box.add_child(help)
	var dismiss := Button.new()
	dismiss.text = "Enter Green Hollow"
	_wire_button(dismiss)
	dismiss.pressed.connect(_on_help_close_pressed)
	box.add_child(dismiss)

func _tab_box(tab_name: String) -> VBoxContainer:
	var box := VBoxContainer.new()
	box.name = tab_name
	box.add_theme_constant_override("separation", 7)
	return box

func _line_setting_row(box: VBoxContainer, label_text: String, value: String) -> LineEdit:
	var row := HBoxContainer.new()
	box.add_child(row)
	var label := Label.new()
	label.text = label_text
	label.custom_minimum_size.x = 220
	row.add_child(label)
	var edit := LineEdit.new()
	edit.text = value
	edit.custom_minimum_size.x = 420
	row.add_child(edit)
	return edit

func _form_label(text: String) -> Label:
	var label := Label.new()
	label.text = text
	label.custom_minimum_size.x = 180
	return label

func _check_row(label_text: String, section: String, key: String) -> CheckButton:
	var check := CheckButton.new()
	check.text = label_text
	check.button_pressed = bool(SettingsManager.get_value(section, key, false))
	_wire_button(check)
	check.toggled.connect(_on_check_toggled.bind(section, key))
	return check

func _slider_row(label_text: String, minimum: float, maximum: float, current_value: float, section: String, key: String) -> HBoxContainer:
	var row := HBoxContainer.new()
	var label := Label.new()
	label.text = label_text
	label.custom_minimum_size.x = 220
	row.add_child(label)
	var slider := HSlider.new()
	slider.min_value = minimum
	slider.max_value = maximum
	slider.step = 0.001 if maximum <= 0.1 else (0.05 if maximum <= 2.0 else 0.5)
	slider.value = current_value
	slider.custom_minimum_size.x = 400
	slider.value_changed.connect(_on_slider_changed.bind(section, key))
	row.add_child(slider)
	return row

func _panel(panel_position: Vector2, panel_size: Vector2, anchor_to_right: bool = false) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.size = panel_size
	if anchor_to_right:
		panel.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	panel.position = panel_position
	panel.add_theme_stylebox_override("panel", _panel_style(false))
	return panel

func _modal_panel(panel_size: Vector2) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.position = -panel_size / 2.0
	panel.size = panel_size
	panel.add_theme_stylebox_override("panel", _panel_style(true))
	return panel

func _panel_style(modal: bool) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.025, 0.032, 0.032, 0.97) if modal else Color(0.035, 0.043, 0.043, 0.91)
	style.border_color = Color(0.50, 0.39, 0.20, 0.95) if modal else Color(0.26, 0.29, 0.27, 0.85)
	style.set_border_width_all(2 if modal else 1)
	var radius: int = 7 if modal else 5
	style.corner_radius_top_left = radius
	style.corner_radius_top_right = radius
	style.corner_radius_bottom_left = radius
	style.corner_radius_bottom_right = radius
	style.set_content_margin_all(20.0 if modal else 14.0)
	return style

func _wire_button(button: BaseButton) -> void:
	button.mouse_entered.connect(_on_ui_hover)
	button.button_down.connect(_on_ui_press)

func _toggle_journal() -> void:
	journal_panel.visible = not journal_panel.visible
	AudioManager.play_ui("open" if journal_panel.visible else "close")

func _toggle_settings() -> void:
	settings_panel.visible = not settings_panel.visible
	AudioManager.play_ui("open" if settings_panel.visible else "close")

func _toggle_help() -> void:
	help_panel.visible = not help_panel.visible

func _toggle_lobby() -> void:
	lobby_panel.visible = not lobby_panel.visible
	if lobby_panel.visible:
		NetworkManager.list_rooms()
	AudioManager.play_ui("open" if lobby_panel.visible else "close")

func _on_journal_close_pressed() -> void:
	journal_panel.visible = false

func _on_settings_close_pressed() -> void:
	settings_panel.visible = false

func _on_help_close_pressed() -> void:
	help_panel.visible = false

func _on_notification_timeout() -> void:
	notification_label.visible = false

func _on_ui_hover() -> void:
	AudioManager.play_ui("hover")

func _on_ui_press() -> void:
	AudioManager.play_ui("press")


func _on_check_toggled(enabled: bool, section: String, key: String) -> void:
	SettingsManager.set_value(section, key, enabled)

func _on_colorblind_selected(index: int) -> void:
	if index >= 0 and index < COLORBLIND_VALUES.size():
		SettingsManager.set_value("accessibility", "colorblind_mode", COLORBLIND_VALUES[index])

func _on_network_name_changed(value: String) -> void:
	SettingsManager.set_value("network", "display_name", value.strip_edges().substr(0, 24), false)

func _on_lobby_url_changed(value: String) -> void:
	SettingsManager.set_value("network", "lobby_url", value.strip_edges(), false)

func _on_slider_changed(value: float, section: String, key: String) -> void:
	SettingsManager.set_value(section, key, value)

func _begin_rebind(action: String) -> void:
	_pending_rebind_action = action
	var button_value: Variant = _rebind_buttons.get(action, null)
	if button_value is Button:
		(button_value as Button).text = "Press a key..."

func _refresh_rebind_labels() -> void:
	for action_variant in _rebind_buttons:
		var action: String = str(action_variant)
		var button_value: Variant = _rebind_buttons[action_variant]
		if button_value is Button:
			(button_value as Button).text = SettingsManager.keybind_name(action)

func _on_room_refresh() -> void:
	NetworkManager.list_rooms()

func _on_room_create() -> void:
	NetworkManager.create_room(room_name_edit.text, room_password_edit.text, room_public_check.button_pressed)

func _on_room_join() -> void:
	var selected: PackedInt32Array = room_list.get_selected_items()
	if selected.is_empty():
		var direct_room_id: String = room_id_edit.text.strip_edges()
		if direct_room_id.is_empty():
			_show_notification("Select a public room or enter a private room ID.", "error")
			return
		NetworkManager.join_room(direct_room_id, room_password_edit.text)
		return
	var index: int = selected[0]
	if index < 0 or index >= _rooms.size() or not (_rooms[index] is Dictionary):
		return
	var room: Dictionary = _rooms[index] as Dictionary
	var selected_room_id: String = str(room.get("id", ""))
	room_id_edit.text = selected_room_id
	NetworkManager.join_room(selected_room_id, room_password_edit.text)

func _on_room_disconnect() -> void:
	NetworkManager.stop_network()

func _on_lobby_rooms_updated(rooms: Array) -> void:
	_rooms = rooms.duplicate(true)
	room_list.clear()
	for room_value in _rooms:
		if not (room_value is Dictionary):
			continue
		var room: Dictionary = room_value as Dictionary
		room_list.add_item("%s  [%d/%d]%s" % [str(room.get("name", "Room")), int(room.get("players", 0)), int(room.get("max_players", 4)), "  LOCKED" if bool(room.get("requires_password", false)) else ""])

func _on_lobby_error(message: String) -> void:
	_show_notification(message, "error")
	if network_status_label != null:
		network_status_label.text = "LOBBY ERROR // " + message

func _on_connection_state_changed(state: String, message: String) -> void:
	if network_status_label != null:
		network_status_label.text = "%s // %s" % [state.to_upper(), message]
	if state == "online" and room_id_edit != null:
		room_id_edit.text = NetworkManager.current_room_id()
	_show_notification(message, "success" if state == "online" else "info")

func _update_survival(survival: Dictionary) -> void:
	status_label.text = "HP %3.0f   HUNGER %3.0f   THIRST %3.0f" % [float(survival.get("health", 0.0)), float(survival.get("hunger", 0.0)), float(survival.get("thirst", 0.0))]

func _update_objective(step: int, text: String) -> void:
	objective_label.text = "OBJECTIVE %02d/%02d\n%s" % [step + 1, GameState.OBJECTIVES.size(), text]

func _update_inventory(inventory: Dictionary) -> void:
	var lines: Array[String] = ["FIELD PACK", "------------"]
	if inventory.is_empty():
		lines.append("(empty)")
	else:
		var ids: Array = inventory.keys()
		ids.sort()
		for id_value in ids:
			var item_id: String = str(id_value)
			lines.append("%s  x%d" % [DataRegistry.display_name(item_id), int(inventory.get(item_id, 0))])
	lines.append("")
	lines.append("[%s] Consume   [%s] Gear" % [SettingsManager.keybind_name("eat_quick"), SettingsManager.keybind_name("craft_gear")])
	lines.append("[%s] Journal   [%s] Co-op" % [SettingsManager.keybind_name("journal"), SettingsManager.keybind_name("lobby")])
	inventory_label.text = "\n".join(lines)

func _update_journal(entries: Array) -> void:
	var body: String = ""
	if entries.is_empty():
		body = "[i]No confirmed field notes yet. Observe the world.[/i]"
	else:
		for entry_value in entries:
			if not (entry_value is Dictionary):
				continue
			var entry: Dictionary = entry_value as Dictionary
			body += "[b]%s[/b]  [color=#b28b45]%s[/color]\n%s\n\n" % [str(entry.get("title", "")), str(entry.get("stage", "")), str(entry.get("body", ""))]
	journal_text.text = body

func _update_boss(name: String, health: float, max_health: float, vulnerable: bool) -> void:
	boss_panel.visible = true
	boss_name_label.text = name.to_upper()
	boss_health_bar.max_value = maxf(max_health, 1.0)
	boss_health_bar.value = health
	boss_state_label.text = "THERMAL JOINTS EXPOSED // STRIKE NOW" if vulnerable else "SEALED ARMOR // USE THE FOUNDRY PRESSURE SYSTEM"
	boss_state_label.modulate = Color(0.47, 0.95, 0.94) if vulnerable else Color(0.95, 0.58, 0.31)

func _clear_boss() -> void:
	boss_panel.visible = false

func _show_notification(message: String, kind: String) -> void:
	notification_label.text = message
	match kind:
		"success":
			notification_label.modulate = Color(0.72, 0.90, 0.72)
			AudioManager.play_ui("complete")
		"error":
			notification_label.modulate = Color(0.95, 0.60, 0.48)
			AudioManager.play_ui("error")
		_:
			notification_label.modulate = Color(0.85, 0.83, 0.70)
	notification_label.visible = true
	notification_timer.start()

func _on_settings_changed(section: String, key: String, _value: Variant) -> void:
	if section == "gameplay" and key == "show_hud":
		var show_hud: bool = bool(SettingsManager.get_value("gameplay", "show_hud", true))
		status_label.get_parent().get_parent().visible = show_hud
		inventory_label.get_parent().visible = show_hud
	if section == "controls":
		_refresh_rebind_labels()
		_update_inventory(GameState.inventory)
