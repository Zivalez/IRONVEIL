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
	prompt_label.text = text
	prompt_label.visible = not text.is_empty()

func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventKey and event.pressed and not event.echo):
		return
	if event.keycode == KEY_J:
		journal_panel.visible = not journal_panel.visible
		if journal_panel.visible:
			AudioManager.play_ui("open")
	elif event.keycode == KEY_ESCAPE:
		settings_panel.visible = not settings_panel.visible
		if settings_panel.visible:
			AudioManager.play_ui("open")
		else:
			AudioManager.play_ui("close")
	elif event.keycode == KEY_H:
		help_panel.visible = not help_panel.visible

func _build_ui() -> void:
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(root)

	var top_left := _panel(Vector2(18, 18), Vector2(370, 138))
	root.add_child(top_left)
	var stats_box := VBoxContainer.new()
	stats_box.add_theme_constant_override("separation", 5)
	top_left.add_child(stats_box)

	var title := Label.new()
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

	var top_right := _panel(Vector2(-318, 18), Vector2(300, 180), true)
	root.add_child(top_right)
	inventory_label = Label.new()
	inventory_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	inventory_label.text = "FIELD PACK"
	top_right.add_child(inventory_label)

	prompt_label = Label.new()
	prompt_label.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	prompt_label.position = Vector2(-280, -90)
	prompt_label.size = Vector2(560, 48)
	prompt_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	prompt_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	prompt_label.add_theme_font_size_override("font_size", 18)
	prompt_label.visible = false
	var prompt_style := StyleBoxFlat.new()
	prompt_style.bg_color = Color(0.05, 0.06, 0.06, 0.90)
	prompt_style.border_color = Color(0.56, 0.44, 0.22, 0.9)
	prompt_style.set_border_width_all(1)
	prompt_label.add_theme_stylebox_override("normal", prompt_style)
	root.add_child(prompt_label)

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
	notification_timer.timeout.connect(func(): notification_label.visible = false)
	add_child(notification_timer)

	journal_panel = _modal_panel(Vector2(760, 500))
	journal_panel.visible = false
	root.add_child(journal_panel)
	var journal_box := VBoxContainer.new()
	journal_panel.add_child(journal_box)
	var journal_title := Label.new()
	journal_title.text = "FIELD JOURNAL // OBSERVE → HYPOTHESIZE → CONFIRM"
	journal_title.add_theme_font_size_override("font_size", 19)
	journal_box.add_child(journal_title)
	journal_text = RichTextLabel.new()
	journal_text.bbcode_enabled = true
	journal_text.custom_minimum_size = Vector2(710, 400)
	journal_box.add_child(journal_text)
	var journal_close := Button.new()
	journal_close.text = "Close [J]"
	_wire_button(journal_close)
	journal_close.pressed.connect(func(): journal_panel.visible = false)
	journal_box.add_child(journal_close)

	settings_panel = _build_settings_panel()
	settings_panel.visible = false
	root.add_child(settings_panel)

	help_panel = _modal_panel(Vector2(620, 360))
	root.add_child(help_panel)
	var help_box := VBoxContainer.new()
	help_panel.add_child(help_box)
	var help_title := Label.new()
	help_title.text = "FIRST PLAYABLE // CONTROLS"
	help_title.add_theme_font_size_override("font_size", 20)
	help_box.add_child(help_title)
	var help := Label.new()
	help.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	help.text = (
		"WASD  Move    Shift  Sprint    F  Interact\n"
		"Q / E  Rotate camera 90°    Mouse wheel  Zoom\n"
		"1  Eat Wild Berries    C  Craft Crude Gear\n"
		"Space  Melee attack    J  Journal    Esc  Settings\n"
		"F5  Save    F9  Load    H  Toggle this help\n\n"
		"Goal: find food → inspect workshop → repair water wheel → connect gear → load logs → let the saw create planks automatically."
	)
	help.custom_minimum_size = Vector2(570, 235)
	help_box.add_child(help)
	var dismiss := Button.new()
	dismiss.text = "Enter the forest"
	_wire_button(dismiss)
	dismiss.pressed.connect(func(): help_panel.visible = false)
	help_box.add_child(dismiss)

func _build_settings_panel() -> PanelContainer:
	var panel := _modal_panel(Vector2(570, 500))
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 9)
	panel.add_child(box)

	var title := Label.new()
	title.text = "SYSTEM SETTINGS"
	title.add_theme_font_size_override("font_size", 20)
	box.add_child(title)

	var vsync := CheckButton.new()
	vsync.text = "VSync"
	vsync.button_pressed = bool(SettingsManager.get_value("graphics", "vsync", true))
	_wire_button(vsync)
	vsync.toggled.connect(func(value: bool): SettingsManager.set_value("graphics", "vsync", value))
	box.add_child(vsync)

	var quality_row := HBoxContainer.new()
	box.add_child(quality_row)
	var quality_label := Label.new()
	quality_label.text = "Quality preset"
	quality_label.custom_minimum_size.x = 190
	quality_row.add_child(quality_label)
	var quality := OptionButton.new()
	for item in ["low", "medium", "high"]:
		quality.add_item(item.capitalize())
	var current_quality := str(SettingsManager.get_value("graphics", "quality", "medium"))
	quality.select(["low", "medium", "high"].find(current_quality))
	_wire_button(quality)
	quality.item_selected.connect(func(index: int): SettingsManager.set_value("graphics", "quality", ["low", "medium", "high"][index]))
	quality_row.add_child(quality)

	box.add_child(_slider_row("Camera zoom", 10.0, 28.0, float(SettingsManager.get_value("graphics", "camera_zoom", 18.0)), func(value: float): SettingsManager.set_value("graphics", "camera_zoom", value)))
	box.add_child(_slider_row("UI scale", 0.75, 1.5, float(SettingsManager.get_value("graphics", "ui_scale", 1.0)), func(value: float): SettingsManager.set_value("graphics", "ui_scale", value)))
	box.add_child(HSeparator.new())
	box.add_child(_slider_row("Master volume", 0.0, 1.0, float(SettingsManager.get_value("audio", "master", 0.8)), func(value: float): SettingsManager.set_value("audio", "master", value)))
	box.add_child(_slider_row("Music volume", 0.0, 1.0, float(SettingsManager.get_value("audio", "music", 0.7)), func(value: float): SettingsManager.set_value("audio", "music", value)))
	box.add_child(_slider_row("SFX volume", 0.0, 1.0, float(SettingsManager.get_value("audio", "sfx", 0.8)), func(value: float): SettingsManager.set_value("audio", "sfx", value)))
	box.add_child(_slider_row("Ambient volume", 0.0, 1.0, float(SettingsManager.get_value("audio", "ambient", 0.7)), func(value: float): SettingsManager.set_value("audio", "ambient", value)))

	var close := Button.new()
	close.text = "Close [Esc]"
	_wire_button(close)
	close.pressed.connect(func(): panel.visible = false)
	box.add_child(close)
	return panel

func _slider_row(label_text: String, minimum: float, maximum: float, value: float, callback: Callable) -> HBoxContainer:
	var row := HBoxContainer.new()
	var label := Label.new()
	label.text = label_text
	label.custom_minimum_size.x = 190
	row.add_child(label)
	var slider := HSlider.new()
	slider.min_value = minimum
	slider.max_value = maximum
	slider.step = 0.05 if maximum <= 2.0 else 0.5
	slider.value = value
	slider.custom_minimum_size.x = 300
	slider.value_changed.connect(callback)
	row.add_child(slider)
	return row

func _panel(position: Vector2, size: Vector2, anchor_right: bool = false) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.size = size
	if anchor_right:
		panel.set_anchors_preset(Control.PRESET_TOP_RIGHT)
		panel.position = position
	else:
		panel.position = position
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.035, 0.043, 0.043, 0.91)
	style.border_color = Color(0.26, 0.29, 0.27, 0.85)
	style.set_border_width_all(1)
	style.corner_radius_top_left = 5
	style.corner_radius_top_right = 5
	style.corner_radius_bottom_left = 5
	style.corner_radius_bottom_right = 5
	style.content_margin_left = 14
	style.content_margin_right = 14
	style.content_margin_top = 12
	style.content_margin_bottom = 12
	panel.add_theme_stylebox_override("panel", style)
	return panel

func _modal_panel(size: Vector2) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.position = -size / 2.0
	panel.size = size
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.025, 0.032, 0.032, 0.97)
	style.border_color = Color(0.50, 0.39, 0.20, 0.95)
	style.set_border_width_all(2)
	style.corner_radius_top_left = 7
	style.corner_radius_top_right = 7
	style.corner_radius_bottom_left = 7
	style.corner_radius_bottom_right = 7
	style.content_margin_left = 20
	style.content_margin_right = 20
	style.content_margin_top = 18
	style.content_margin_bottom = 18
	panel.add_theme_stylebox_override("panel", style)
	return panel

func _wire_button(button: BaseButton) -> void:
	button.mouse_entered.connect(func(): AudioManager.play_ui("hover"))
	button.button_down.connect(func(): AudioManager.play_ui("press"))

func _update_survival(survival: Dictionary) -> void:
	status_label.text = "HP %3.0f   HUNGER %3.0f   THIRST %3.0f" % [
		float(survival.get("health", 0.0)),
		float(survival.get("hunger", 0.0)),
		float(survival.get("thirst", 0.0))
	]

func _update_objective(step: int, text: String) -> void:
	objective_label.text = "OBJECTIVE %02d\n%s" % [step + 1, text]

func _update_inventory(inventory: Dictionary) -> void:
	var lines := ["FIELD PACK", "────────────"]
	if inventory.is_empty():
		lines.append("(empty)")
	else:
		var ids := inventory.keys()
		ids.sort()
		for item_id in ids:
			lines.append("%s  x%d" % [DataRegistry.display_name(str(item_id)), int(inventory[item_id])])
	lines.append("")
	lines.append("[1] Eat berries")
	lines.append("[C] Craft crude gear")
	inventory_label.text = "\n".join(lines)

func _update_journal(entries: Array) -> void:
	var body := ""
	if entries.is_empty():
		body = "[i]No confirmed field notes yet. Observe the world.[/i]"
	else:
		for entry in entries:
			body += "[b]%s[/b]  [color=#b28b45]%s[/color]\n%s\n\n" % [
				str(entry.get("title", "")),
				str(entry.get("stage", "")),
				str(entry.get("body", ""))
			]
	journal_text.text = body

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

func _on_settings_changed(_section: String, _key: String, _value) -> void:
	pass
