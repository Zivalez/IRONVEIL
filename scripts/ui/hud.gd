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
var notification_timer: Timer

var _quality_button: OptionButton

func _ready() -> void:
	_build_ui()
	GameState.inventory_changed.connect(_update_inventory)
	GameState.survival_changed.connect(_update_survival)
	GameState.objective_changed.connect(_update_objective)
	GameState.journal_changed.connect(_update_journal)
	GameState.notification.connect(_show_notification)
	SettingsManager.settings_changed.connect(_on_settings_changed)

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
	var key_event: InputEventKey = event as InputEventKey
	if key_event == null or not key_event.pressed or key_event.echo:
		return
	match key_event.keycode:
		KEY_J:
			_toggle_journal()
		KEY_ESCAPE:
			_toggle_settings()
		KEY_H:
			_toggle_help()

func _build_ui() -> void:
	var root: Control = Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)

	_build_status_panel(root)
	_build_inventory_panel(root)
	_build_prompt(root)
	_build_notification(root)
	_build_journal(root)
	_build_settings(root)
	_build_help(root)

func _build_status_panel(root: Control) -> void:
	var top_left: PanelContainer = _panel(Vector2(18, 18), Vector2(370, 138), false)
	root.add_child(top_left)
	var stats_box: VBoxContainer = VBoxContainer.new()
	stats_box.add_theme_constant_override("separation", 5)
	top_left.add_child(stats_box)

	var title: Label = Label.new()
	title.text = "IRONVEIL // FIELD STATE"
	title.add_theme_font_size_override("font_size", 18)
	stats_box.add_child(title)

	status_label = Label.new()
	status_label.text = "HP 100 | HUNGER 100 | THIRST 100"
	stats_box.add_child(status_label)

	objective_label = Label.new()
	objective_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	objective_label.custom_minimum_size = Vector2(340, 52)
	stats_box.add_child(objective_label)

func _build_inventory_panel(root: Control) -> void:
	var top_right: PanelContainer = _panel(Vector2(-318, 18), Vector2(300, 180), true)
	root.add_child(top_right)
	inventory_label = Label.new()
	inventory_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	inventory_label.text = "FIELD PACK"
	top_right.add_child(inventory_label)

func _build_prompt(root: Control) -> void:
	prompt_label = Label.new()
	prompt_label.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	prompt_label.position = Vector2(-280, -90)
	prompt_label.size = Vector2(560, 48)
	prompt_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	prompt_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	prompt_label.add_theme_font_size_override("font_size", 18)
	prompt_label.visible = false
	var prompt_style: StyleBoxFlat = StyleBoxFlat.new()
	prompt_style.bg_color = Color(0.05, 0.06, 0.06, 0.90)
	prompt_style.border_color = Color(0.56, 0.44, 0.22, 0.90)
	prompt_style.set_border_width_all(1)
	prompt_label.add_theme_stylebox_override("normal", prompt_style)
	root.add_child(prompt_label)

func _build_notification(root: Control) -> void:
	notification_label = Label.new()
	notification_label.set_anchors_preset(Control.PRESET_CENTER_TOP)
	notification_label.position = Vector2(-280, 22)
	notification_label.size = Vector2(560, 46)
	notification_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	notification_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	notification_label.visible = false
	root.add_child(notification_label)

	notification_timer = Timer.new()
	notification_timer.one_shot = true
	notification_timer.wait_time = 2.8
	notification_timer.timeout.connect(_on_notification_timeout)
	add_child(notification_timer)

func _build_journal(root: Control) -> void:
	journal_panel = _modal_panel(Vector2(760, 500))
	journal_panel.visible = false
	root.add_child(journal_panel)

	var journal_box: VBoxContainer = VBoxContainer.new()
	journal_panel.add_child(journal_box)

	var journal_title: Label = Label.new()
	journal_title.text = "FIELD JOURNAL // OBSERVE -> HYPOTHESIZE -> CONFIRM"
	journal_title.add_theme_font_size_override("font_size", 19)
	journal_box.add_child(journal_title)

	journal_text = RichTextLabel.new()
	journal_text.bbcode_enabled = true
	journal_text.custom_minimum_size = Vector2(710, 400)
	journal_box.add_child(journal_text)

	var journal_close: Button = Button.new()
	journal_close.text = "Close [J]"
	_wire_button(journal_close)
	journal_close.pressed.connect(_on_journal_close_pressed)
	journal_box.add_child(journal_close)

func _build_settings(root: Control) -> void:
	settings_panel = _build_settings_panel()
	settings_panel.visible = false
	root.add_child(settings_panel)

func _build_help(root: Control) -> void:
	help_panel = _modal_panel(Vector2(620, 360))
	root.add_child(help_panel)

	var help_box: VBoxContainer = VBoxContainer.new()
	help_panel.add_child(help_box)

	var help_title: Label = Label.new()
	help_title.text = "FIRST PLAYABLE // CONTROLS"
	help_title.add_theme_font_size_override("font_size", 20)
	help_box.add_child(help_title)

	var help: Label = Label.new()
	help.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	help.text = "WASD  Move    Shift  Sprint    F  Interact\nQ / E  Rotate camera 90 deg    Mouse wheel  Zoom\n1  Eat Wild Berries    C  Craft Crude Gear\nSpace  Melee attack    J  Journal    Esc  Settings\nF5  Save    F9  Load    H  Toggle this help\n\nGoal: find food -> inspect workshop -> repair water wheel -> connect gear -> load logs -> let the saw create planks automatically."
	help.custom_minimum_size = Vector2(570, 235)
	help_box.add_child(help)

	var dismiss: Button = Button.new()
	dismiss.text = "Enter the forest"
	_wire_button(dismiss)
	dismiss.pressed.connect(_on_help_close_pressed)
	help_box.add_child(dismiss)

func _build_settings_panel() -> PanelContainer:
	var panel: PanelContainer = _modal_panel(Vector2(570, 500))
	var box: VBoxContainer = VBoxContainer.new()
	box.add_theme_constant_override("separation", 9)
	panel.add_child(box)

	var title: Label = Label.new()
	title.text = "SYSTEM SETTINGS"
	title.add_theme_font_size_override("font_size", 20)
	box.add_child(title)

	var vsync: CheckButton = CheckButton.new()
	vsync.text = "VSync"
	vsync.button_pressed = bool(SettingsManager.get_value("graphics", "vsync", true))
	_wire_button(vsync)
	vsync.toggled.connect(_on_vsync_toggled)
	box.add_child(vsync)

	var quality_row: HBoxContainer = HBoxContainer.new()
	box.add_child(quality_row)
	var quality_label: Label = Label.new()
	quality_label.text = "Quality preset"
	quality_label.custom_minimum_size.x = 190
	quality_row.add_child(quality_label)

	_quality_button = OptionButton.new()
	_quality_button.add_item("Low")
	_quality_button.add_item("Medium")
	_quality_button.add_item("High")
	var current_quality: String = str(SettingsManager.get_value("graphics", "quality", "medium"))
	var quality_index: int = ["low", "medium", "high"].find(current_quality)
	_quality_button.select(maxi(quality_index, 0))
	_wire_button(_quality_button)
	_quality_button.item_selected.connect(_on_quality_selected)
	quality_row.add_child(_quality_button)

	box.add_child(_slider_row("Camera zoom", 10.0, 28.0, float(SettingsManager.get_value("graphics", "camera_zoom", 18.0)), "graphics", "camera_zoom"))
	box.add_child(_slider_row("UI scale", 0.75, 1.5, float(SettingsManager.get_value("graphics", "ui_scale", 1.0)), "graphics", "ui_scale"))
	box.add_child(HSeparator.new())
	box.add_child(_slider_row("Master volume", 0.0, 1.0, float(SettingsManager.get_value("audio", "master", 0.8)), "audio", "master"))
	box.add_child(_slider_row("Music volume", 0.0, 1.0, float(SettingsManager.get_value("audio", "music", 0.7)), "audio", "music"))
	box.add_child(_slider_row("SFX volume", 0.0, 1.0, float(SettingsManager.get_value("audio", "sfx", 0.8)), "audio", "sfx"))
	box.add_child(_slider_row("Ambient volume", 0.0, 1.0, float(SettingsManager.get_value("audio", "ambient", 0.7)), "audio", "ambient"))

	var close: Button = Button.new()
	close.text = "Close [Esc]"
	_wire_button(close)
	close.pressed.connect(_on_settings_close_pressed)
	box.add_child(close)
	return panel

func _slider_row(label_text: String, minimum: float, maximum: float, current_value: float, section: String, key: String) -> HBoxContainer:
	var row: HBoxContainer = HBoxContainer.new()
	var label: Label = Label.new()
	label.text = label_text
	label.custom_minimum_size.x = 190
	row.add_child(label)

	var slider: HSlider = HSlider.new()
	slider.min_value = minimum
	slider.max_value = maximum
	slider.step = 0.05 if maximum <= 2.0 else 0.5
	slider.value = current_value
	slider.custom_minimum_size.x = 300
	slider.value_changed.connect(_on_slider_changed.bind(section, key))
	row.add_child(slider)
	return row

func _panel(panel_position: Vector2, panel_size: Vector2, anchor_to_right: bool = false) -> PanelContainer:
	var panel: PanelContainer = PanelContainer.new()
	panel.size = panel_size
	if anchor_to_right:
		panel.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	panel.position = panel_position
	panel.add_theme_stylebox_override("panel", _panel_style(false))
	return panel

func _modal_panel(panel_size: Vector2) -> PanelContainer:
	var panel: PanelContainer = PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.position = -panel_size / 2.0
	panel.size = panel_size
	panel.add_theme_stylebox_override("panel", _panel_style(true))
	return panel

func _panel_style(modal: bool) -> StyleBoxFlat:
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = Color(0.025, 0.032, 0.032, 0.97) if modal else Color(0.035, 0.043, 0.043, 0.91)
	style.border_color = Color(0.50, 0.39, 0.20, 0.95) if modal else Color(0.26, 0.29, 0.27, 0.85)
	style.set_border_width_all(2 if modal else 1)
	style.corner_radius_top_left = 7 if modal else 5
	style.corner_radius_top_right = 7 if modal else 5
	style.corner_radius_bottom_left = 7 if modal else 5
	style.corner_radius_bottom_right = 7 if modal else 5
	style.set_content_margin_all(20.0 if modal else 14.0)
	return style

func _wire_button(button: BaseButton) -> void:
	button.mouse_entered.connect(_on_ui_hover)
	button.button_down.connect(_on_ui_press)

func _toggle_journal() -> void:
	if journal_panel == null:
		return
	journal_panel.visible = not journal_panel.visible
	AudioManager.play_ui("open" if journal_panel.visible else "close")

func _toggle_settings() -> void:
	if settings_panel == null:
		return
	settings_panel.visible = not settings_panel.visible
	AudioManager.play_ui("open" if settings_panel.visible else "close")

func _toggle_help() -> void:
	if help_panel != null:
		help_panel.visible = not help_panel.visible

func _on_journal_close_pressed() -> void:
	if journal_panel != null:
		journal_panel.visible = false
	AudioManager.play_ui("close")

func _on_settings_close_pressed() -> void:
	if settings_panel != null:
		settings_panel.visible = false
	AudioManager.play_ui("close")

func _on_help_close_pressed() -> void:
	if help_panel != null:
		help_panel.visible = false

func _on_notification_timeout() -> void:
	if notification_label != null:
		notification_label.visible = false

func _on_ui_hover() -> void:
	AudioManager.play_ui("hover")

func _on_ui_press() -> void:
	AudioManager.play_ui("press")

func _on_vsync_toggled(enabled: bool) -> void:
	SettingsManager.set_value("graphics", "vsync", enabled)

func _on_quality_selected(index: int) -> void:
	var values: Array[String] = ["low", "medium", "high"]
	if index >= 0 and index < values.size():
		SettingsManager.set_value("graphics", "quality", values[index])

func _on_slider_changed(value: float, section: String, key: String) -> void:
	SettingsManager.set_value(section, key, value)

func _update_survival(survival: Dictionary) -> void:
	if status_label == null:
		return
	status_label.text = "HP %3.0f   HUNGER %3.0f   THIRST %3.0f" % [
		float(survival.get("health", 0.0)),
		float(survival.get("hunger", 0.0)),
		float(survival.get("thirst", 0.0))
	]

func _update_objective(step: int, text: String) -> void:
	if objective_label != null:
		objective_label.text = "OBJECTIVE %02d\n%s" % [step + 1, text]

func _update_inventory(inventory: Dictionary) -> void:
	if inventory_label == null:
		return
	var lines: Array[String] = ["FIELD PACK", "------------"]
	if inventory.is_empty():
		lines.append("(empty)")
	else:
		var ids: Array = inventory.keys()
		ids.sort()
		for item_id_variant in ids:
			var item_id: String = str(item_id_variant)
			lines.append("%s  x%d" % [DataRegistry.display_name(item_id), int(inventory.get(item_id, 0))])
	lines.append("")
	lines.append("[1] Eat berries")
	lines.append("[C] Craft crude gear")
	inventory_label.text = "\n".join(lines)

func _update_journal(entries: Array) -> void:
	if journal_text == null:
		return
	var body: String = ""
	if entries.is_empty():
		body = "[i]No confirmed field notes yet. Observe the world.[/i]"
	else:
		for entry_variant in entries:
			if not (entry_variant is Dictionary):
				continue
			var entry: Dictionary = entry_variant
			body += "[b]%s[/b]  [color=#b28b45]%s[/color]\n%s\n\n" % [
				str(entry.get("title", "")),
				str(entry.get("stage", "")),
				str(entry.get("body", ""))
			]
	journal_text.text = body

func _show_notification(message: String, kind: String) -> void:
	if notification_label == null or notification_timer == null:
		return
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

func _on_settings_changed(_section: String, _key: String, _value: Variant) -> void:
	pass
