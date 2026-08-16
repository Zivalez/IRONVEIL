## Title screen — visual polish pass 1.4
extends CanvasLayer

signal start_requested()

const PAPER := Color("#f3ead7")
const PAPER_DARK := Color("#e8ddc7")
const INK := Color("#201d18")
const CARBON := Color("#1d1a16")
const CARBON_RAISED := Color("#29251f")
const ORANGE := Color("#e84d2a")
const WINE := Color("#ad2f4b")
const LIGHT := Color("#f3ead7")
const MUTED_DARK := Color("#6e665b")
const MUTED_LIGHT := Color("#b8ad9c")
const GREEN := Color("#61a66d")
const ALERT := Color("#d74632")

var _frame: PanelContainer
var _hero: Control
var _auth_panel: PanelContainer
var _world_panel: PanelContainer
var _status: Label
var _service_dot: Label
var _service_text: Label
var _identity: Label
var _nickname: LineEdit
var _password: LineEdit
var _world_name: LineEdit
var _world_kind: OptionButton
var _invite_code: LineEdit
var _world_list: ItemList
var _world_details: Label
var _world_usage: Label
var _continue_button: Button
var _world_ids: Array[String] = []
var _world_values: Array[Dictionary] = []
var _mode_buttons: Array[Button] = []
var _mode_views: Array[Control] = []
var _control_scrim: ColorRect
var _control_button: Button

func _ready() -> void:
	layer = 900
	_build()
	AccountManager.auth_changed.connect(_on_auth_changed)
	AccountManager.worlds_updated.connect(_on_worlds_updated)
	AccountManager.world_limit_updated.connect(_on_world_limit_updated)
	AccountManager.world_loaded.connect(_on_world_loaded)
	AccountManager.request_failed.connect(_on_request_failed)
	AccountManager.service_status_changed.connect(_on_service_status_changed)
	InputProfile.mode_changed.connect(_on_control_mode_changed)
	_animate_entry()
	AccountManager.probe_service()
	if InputProfile.should_offer_first_choice():
		_control_scrim.visible = true
	if AccountManager.is_authenticated():
		_on_auth_changed(true, AccountManager.account)
		AccountManager.refresh_session()
	else:
		_show_auth()

func _build() -> void:
	var background := ColorRect.new()
	background.set_anchors_preset(Control.PRESET_FULL_RECT)
	background.color = PAPER
	add_child(background)
	_add_grid(background)

	var shadow := ColorRect.new()
	shadow.position = Vector2(77, 55)
	shadow.size = Vector2(1136, 622)
	shadow.color = ORANGE
	shadow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	background.add_child(shadow)

	_frame = PanelContainer.new()
	_frame.position = Vector2(68, 44)
	_frame.size = Vector2(1136, 622)
	_frame.add_theme_stylebox_override("panel", _box(PAPER, INK, 1))
	background.add_child(_frame)
	var stage := Control.new()
	_frame.add_child(stage)
	_build_header(stage)
	_build_hero(stage)
	_build_auth(stage)
	_build_world_panel(stage)
	_build_control_choice(background)

func _add_grid(parent: Control) -> void:
	for x in range(0, 1281, 64):
		var line := ColorRect.new()
		line.position = Vector2(x, 0)
		line.size = Vector2(1, 720)
		line.color = Color(0.20, 0.18, 0.15, 0.10)
		line.mouse_filter = Control.MOUSE_FILTER_IGNORE
		parent.add_child(line)
	for y in range(0, 721, 64):
		var line := ColorRect.new()
		line.position = Vector2(0, y)
		line.size = Vector2(1280, 1)
		line.color = Color(0.20, 0.18, 0.15, 0.10)
		line.mouse_filter = Control.MOUSE_FILTER_IGNORE
		parent.add_child(line)

func _build_header(stage: Control) -> void:
	var icon_back := ColorRect.new()
	icon_back.position = Vector2(34, 26)
	icon_back.size = Vector2(54, 54)
	icon_back.color = INK
	stage.add_child(icon_back)
	var icon := TextureRect.new()
	icon.texture = load("res://assets/branding/ironveil_icon.png")
	icon.position = Vector2(7, 7)
	icon.size = Vector2(40, 40)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon_back.add_child(icon)
	var icon_accent := ColorRect.new()
	icon_accent.position = Vector2(0, 49)
	icon_accent.size = Vector2(54, 5)
	icon_accent.color = ORANGE
	icon_back.add_child(icon_accent)

	var brand_small := _label("IRONVEIL FIELD NETWORK", 12, ORANGE)
	brand_small.position = Vector2(102, 28)
	brand_small.size = Vector2(280, 20)
	stage.add_child(brand_small)
	var brand := _label("SIX REGIONS", 23, INK)
	brand.position = Vector2(102, 45)
	brand.size = Vector2(280, 34)
	stage.add_child(brand)

	_service_dot = _label("O", 17, MUTED_DARK)
	_service_dot.position = Vector2(834, 37)
	_service_dot.size = Vector2(20, 24)
	stage.add_child(_service_dot)
	_service_text = _label("CHECKING WORLD SERVICE", 12, MUTED_DARK)
	_service_text.position = Vector2(856, 40)
	_service_text.size = Vector2(210, 24)
	stage.add_child(_service_text)
	var build := _label("BUILD 1.3.0", 11, MUTED_DARK)
	build.position = Vector2(972, 67)
	build.size = Vector2(110, 18)
	build.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	stage.add_child(build)

	var top_rule := ColorRect.new()
	top_rule.position = Vector2(34, 98)
	top_rule.size = Vector2(1068, 1)
	top_rule.color = Color(0.13, 0.11, 0.09, 0.28)
	stage.add_child(top_rule)

func _build_hero(stage: Control) -> void:
	_hero = Control.new()
	_hero.position = Vector2(58, 128)
	_hero.size = Vector2(520, 450)
	stage.add_child(_hero)
	var eyebrow := _label("SURVIVAL ENGINEERING / PERSISTENT WORLDS", 11, MUTED_DARK)
	eyebrow.position = Vector2(0, 0)
	eyebrow.size = Vector2(500, 22)
	_hero.add_child(eyebrow)
	var heading := _label("Build the system.\nOutlive the world.", 44, INK)
	heading.position = Vector2(0, 33)
	heading.size = Vector2(535, 116)
	_hero.add_child(heading)
	var copy := _label("Enter a field where knowledge matters more than levels. Restore machines, connect infrastructure, and carry your world between devices.", 15, MUTED_DARK)
	copy.position = Vector2(4, 170)
	copy.size = Vector2(500, 72)
	copy.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_hero.add_child(copy)
	var accent := ColorRect.new()
	accent.position = Vector2(4, 258)
	accent.size = Vector2(490, 4)
	accent.color = ORANGE
	accent.name = "HeroAccent"
	_hero.add_child(accent)

	_identity = _label("GUEST ACCESS / LOCAL SAVE", 12, INK)
	_identity.position = Vector2(4, 284)
	_identity.size = Vector2(500, 23)
	_hero.add_child(_identity)
	var guest := Button.new()
	guest.text = "PLAY LOCAL WORLD"
	guest.position = Vector2(4, 324)
	guest.size = Vector2(238, 58)
	_style_button(guest, "dark")
	guest.pressed.connect(_start_guest)
	_hero.add_child(guest)
	_control_button = Button.new()
	_control_button.text = "INPUT / %s" % InputProfile.resolved_mode().to_upper()
	_control_button.position = Vector2(258, 324)
	_control_button.size = Vector2(238, 58)
	_style_button(_control_button, "wine")
	_control_button.pressed.connect(_show_control_choice)
	_hero.add_child(_control_button)
	_status = _label("READY FOR FIELD ACCESS", 11, MUTED_DARK)
	_status.position = Vector2(4, 406)
	_status.size = Vector2(500, 34)
	_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_hero.add_child(_status)

func _build_auth(stage: Control) -> void:
	_auth_panel = _dark_panel(Vector2(630, 126), Vector2(472, 452))
	stage.add_child(_auth_panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 11)
	_auth_panel.add_child(box)
	box.add_child(_label("ACCOUNT / PERSISTENT ACCESS", 11, MUTED_LIGHT))
	box.add_child(_label("RETURN TO THE FIELD", 27, LIGHT))
	var line := ColorRect.new()
	line.custom_minimum_size = Vector2(410, 4)
	line.color = ORANGE
	box.add_child(line)
	var note := _label("Nickname and password only. No email required.", 14, MUTED_LIGHT)
	note.custom_minimum_size = Vector2(410, 28)
	box.add_child(note)
	_nickname = _field(box, "NICKNAME", "FieldEngineer", false)
	_password = _field(box, "PASSWORD", "10 characters minimum", true)
	_password.text_submitted.connect(func(_value: String) -> void: _sign_in())
	var sign_in := Button.new()
	sign_in.text = "SIGN IN AND VIEW WORLDS"
	sign_in.custom_minimum_size = Vector2(410, 56)
	_style_button(sign_in, "orange")
	sign_in.pressed.connect(_sign_in)
	box.add_child(sign_in)
	var register := Button.new()
	register.text = "CREATE NEW ACCOUNT"
	register.custom_minimum_size = Vector2(410, 48)
	_style_button(register, "outline_light")
	register.pressed.connect(_register)
	box.add_child(register)

func _build_world_panel(stage: Control) -> void:
	_world_panel = _dark_panel(Vector2(610, 112), Vector2(492, 480))
	stage.add_child(_world_panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 9)
	_world_panel.add_child(box)
	var header := HBoxContainer.new()
	box.add_child(header)
	var titles := VBoxContainer.new()
	titles.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(titles)
	titles.add_child(_label("ACCOUNT / WORLD ARCHIVE", 11, MUTED_LIGHT))
	titles.add_child(_label("CHOOSE THE ROUTE", 25, LIGHT))
	var logout := Button.new()
	logout.text = "SIGN OUT"
	logout.custom_minimum_size = Vector2(98, 38)
	_style_button(logout, "outline_light")
	logout.pressed.connect(AccountManager.logout)
	header.add_child(logout)
	var orange_rule := ColorRect.new()
	orange_rule.custom_minimum_size = Vector2(438, 4)
	orange_rule.color = ORANGE
	box.add_child(orange_rule)

	var mode_row := HBoxContainer.new()
	mode_row.add_theme_constant_override("separation", 6)
	box.add_child(mode_row)
	for index in range(3):
		var button := Button.new()
		button.text = ["WORLDS", "CREATE", "JOIN CODE"][index]
		button.custom_minimum_size = Vector2(142, 38)
		button.pressed.connect(_show_world_mode.bind(index))
		mode_row.add_child(button)
		_mode_buttons.append(button)

	var stack := Control.new()
	stack.custom_minimum_size = Vector2(438, 322)
	stack.size_flags_vertical = Control.SIZE_EXPAND_FILL
	box.add_child(stack)
	_build_world_list_view(stack)
	_build_create_view(stack)
	_build_join_view(stack)
	_show_world_mode(0)

func _build_world_list_view(stack: Control) -> void:
	var view := VBoxContainer.new()
	view.set_anchors_preset(Control.PRESET_FULL_RECT)
	view.add_theme_constant_override("separation", 8)
	stack.add_child(view)
	_mode_views.append(view)
	var list_head := HBoxContainer.new()
	view.add_child(list_head)
	var available := _label("AVAILABLE WORLDS", 11, MUTED_LIGHT)
	available.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list_head.add_child(available)
	_world_usage = _label("0 / 12 OWNED", 11, MUTED_LIGHT)
	list_head.add_child(_world_usage)
	_world_list = ItemList.new()
	_world_list.custom_minimum_size = Vector2(438, 154)
	_world_list.item_selected.connect(_on_world_selected)
	_style_item_list(_world_list)
	view.add_child(_world_list)
	_world_details = _label("No world selected. Create one or join by code.", 13, MUTED_LIGHT)
	_world_details.custom_minimum_size = Vector2(438, 62)
	_world_details.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	view.add_child(_world_details)
	_continue_button = Button.new()
	_continue_button.text = "ENTER SELECTED WORLD"
	_continue_button.disabled = true
	_continue_button.custom_minimum_size = Vector2(438, 52)
	_style_button(_continue_button, "orange")
	_continue_button.pressed.connect(_continue_world)
	view.add_child(_continue_button)

func _build_create_view(stack: Control) -> void:
	var view := VBoxContainer.new()
	view.set_anchors_preset(Control.PRESET_FULL_RECT)
	view.add_theme_constant_override("separation", 10)
	stack.add_child(view)
	_mode_views.append(view)
	view.add_child(_label("OPEN A NEW FRONTIER", 19, LIGHT))
	var note := _label("Name the world, select its access type, then create it.", 13, MUTED_LIGHT)
	note.custom_minimum_size = Vector2(438, 36)
	view.add_child(note)
	_world_name = _field(view, "WORLD NAME", "The Copper Meridian", false)
	view.add_child(_label("WORLD TYPE", 11, MUTED_LIGHT))
	_world_kind = OptionButton.new()
	_world_kind.add_item("PERSONAL / PRIVATE PROGRESS")
	_world_kind.set_item_metadata(0, "personal")
	_world_kind.add_item("SHARED / INVITE SURVIVORS")
	_world_kind.set_item_metadata(1, "shared")
	_world_kind.custom_minimum_size = Vector2(438, 46)
	_style_option(_world_kind)
	view.add_child(_world_kind)
	var create := Button.new()
	create.text = "CREATE WORLD"
	create.custom_minimum_size = Vector2(438, 54)
	_style_button(create, "orange")
	create.pressed.connect(_create_world)
	view.add_child(create)

func _build_join_view(stack: Control) -> void:
	var view := VBoxContainer.new()
	view.set_anchors_preset(Control.PRESET_FULL_RECT)
	view.add_theme_constant_override("separation", 12)
	stack.add_child(view)
	_mode_views.append(view)
	view.add_child(_label("JOIN A SHARED WORLD", 19, LIGHT))
	var note := _label("Enter the invite code from the world owner. It will be added to your archive.", 13, MUTED_LIGHT)
	note.custom_minimum_size = Vector2(438, 58)
	note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	view.add_child(note)
	_invite_code = _field(view, "INVITE CODE", "AB12CD34", false)
	_invite_code.max_length = 16
	var join := Button.new()
	join.text = "JOIN WORLD"
	join.custom_minimum_size = Vector2(438, 54)
	_style_button(join, "wine")
	join.pressed.connect(_join_world)
	view.add_child(join)

func _build_control_choice(parent: Control) -> void:
	_control_scrim = ColorRect.new()
	_control_scrim.set_anchors_preset(Control.PRESET_FULL_RECT)
	_control_scrim.color = Color(0.08, 0.07, 0.06, 0.88)
	_control_scrim.mouse_filter = Control.MOUSE_FILTER_STOP
	_control_scrim.z_index = 30
	_control_scrim.visible = false
	parent.add_child(_control_scrim)
	var shadow := ColorRect.new()
	shadow.position = Vector2(387, 207)
	shadow.size = Vector2(520, 310)
	shadow.color = ORANGE
	_control_scrim.add_child(shadow)
	var panel := PanelContainer.new()
	panel.position = Vector2(375, 195)
	panel.size = Vector2(520, 310)
	var style := _box(PAPER, INK, 1)
	style.content_margin_left = 28
	style.content_margin_right = 28
	style.content_margin_top = 24
	style.content_margin_bottom = 24
	panel.add_theme_stylebox_override("panel", style)
	_control_scrim.add_child(panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 14)
	panel.add_child(box)
	box.add_child(_label("INPUT PROFILE", 11, ORANGE))
	box.add_child(_label("HOW ARE YOU PLAYING?", 25, INK))
	var touch := Button.new()
	touch.text = "MOBILE / TOUCH CONTROLS"
	touch.custom_minimum_size = Vector2(464, 58)
	_style_button(touch, "orange")
	touch.pressed.connect(_choose_control_mode.bind(InputProfile.MODE_TOUCH))
	box.add_child(touch)
	var desktop := Button.new()
	desktop.text = "DESKTOP / KEYBOARD AND MOUSE"
	desktop.custom_minimum_size = Vector2(464, 58)
	_style_button(desktop, "dark")
	desktop.pressed.connect(_choose_control_mode.bind(InputProfile.MODE_DESKTOP))
	box.add_child(desktop)

func _dark_panel(position_value: Vector2, size_value: Vector2) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.position = position_value
	panel.size = size_value
	var style := _box(CARBON, Color("#5b544a"), 1)
	style.content_margin_left = 26
	style.content_margin_right = 26
	style.content_margin_top = 24
	style.content_margin_bottom = 24
	panel.add_theme_stylebox_override("panel", style)
	return panel

func _field(parent: VBoxContainer, title: String, placeholder: String, secret: bool) -> LineEdit:
	parent.add_child(_label(title, 11, MUTED_LIGHT))
	var edit := LineEdit.new()
	edit.placeholder_text = placeholder
	edit.secret = secret
	edit.custom_minimum_size = Vector2(410, 44)
	var normal := _box(CARBON_RAISED, Color("#756b5e"), 0)
	normal.content_margin_left = 13
	normal.content_margin_right = 13
	var focus := normal.duplicate() as StyleBoxFlat
	focus.border_color = ORANGE
	edit.add_theme_stylebox_override("normal", normal)
	edit.add_theme_stylebox_override("focus", focus)
	edit.add_theme_color_override("font_color", LIGHT)
	edit.add_theme_color_override("font_placeholder_color", Color("#847a6c"))
	parent.add_child(edit)
	return edit

func _style_button(button: Button, variant: String) -> void:
	var background := INK
	var border := INK
	var font_color := LIGHT
	if variant == "orange":
		background = ORANGE
		border = ORANGE
		font_color = LIGHT
	elif variant == "wine":
		background = WINE
		border = WINE
		font_color = LIGHT
	elif variant == "outline_light":
		background = CARBON
		border = Color("#c5b9a6")
		font_color = LIGHT
	var normal := _box(background, border, 0)
	normal.content_margin_left = 12
	normal.content_margin_right = 12
	var hover := normal.duplicate() as StyleBoxFlat
	hover.bg_color = ORANGE if variant != "orange" else Color("#f06440")
	hover.border_color = ORANGE
	var pressed := normal.duplicate() as StyleBoxFlat
	pressed.bg_color = Color("#c73a20") if variant == "orange" else Color("#171410")
	var disabled := normal.duplicate() as StyleBoxFlat
	disabled.bg_color = Color("#3b3730")
	disabled.border_color = Color("#575147")
	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("pressed", pressed)
	button.add_theme_stylebox_override("disabled", disabled)
	button.add_theme_color_override("font_color", font_color)
	button.add_theme_color_override("font_hover_color", LIGHT)
	button.add_theme_color_override("font_disabled_color", Color("#81786b"))

func _style_mode_button(button: Button, selected: bool) -> void:
	_style_button(button, "orange" if selected else "outline_light")

func _style_item_list(list: ItemList) -> void:
	var panel := _box(CARBON_RAISED, Color("#5b544a"), 0)
	panel.content_margin_left = 8
	panel.content_margin_right = 8
	panel.content_margin_top = 8
	panel.content_margin_bottom = 8
	list.add_theme_stylebox_override("panel", panel)
	var selected := _box(Color("#4b271f"), ORANGE, 0)
	list.add_theme_stylebox_override("selected", selected)
	list.add_theme_stylebox_override("selected_focus", selected)
	list.add_theme_color_override("font_color", MUTED_LIGHT)
	list.add_theme_color_override("font_selected_color", LIGHT)

func _style_option(option: OptionButton) -> void:
	var normal := _box(CARBON_RAISED, Color("#756b5e"), 0)
	normal.content_margin_left = 13
	normal.content_margin_right = 13
	option.add_theme_stylebox_override("normal", normal)
	option.add_theme_color_override("font_color", LIGHT)

func _box(color: Color, border: Color, radius: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.border_color = border
	style.set_border_width_all(1)
	style.set_corner_radius_all(radius)
	return style

func _label(text: String, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", font_size)
	label.modulate = color
	return label

func _animate_entry() -> void:
	var frame_target_y: float = _frame.position.y
	_frame.position.y += 14.0
	_frame.modulate.a = 0.0
	_hero.modulate.a = 0.0
	_auth_panel.modulate.a = 0.0
	_world_panel.modulate.a = 0.0
	var tween := create_tween()
	tween.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(_frame, "position:y", frame_target_y, 0.42)
	tween.parallel().tween_property(_frame, "modulate:a", 1.0, 0.32)
	tween.tween_interval(0.06)
	tween.tween_property(_hero, "modulate:a", 1.0, 0.32)
	tween.parallel().tween_property(_auth_panel, "modulate:a", 1.0, 0.32)
	tween.parallel().tween_property(_world_panel, "modulate:a", 1.0, 0.32)
	var pulse := create_tween().set_loops()
	pulse.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	pulse.tween_property(_service_dot, "modulate:a", 0.35, 0.8)
	pulse.tween_property(_service_dot, "modulate:a", 1.0, 0.8)

func _show_world_mode(index: int) -> void:
	for mode_index in range(_mode_views.size()):
		_mode_views[mode_index].visible = mode_index == index
		_style_mode_button(_mode_buttons[mode_index], mode_index == index)
	if index >= 0 and index < _mode_views.size():
		var view := _mode_views[index]
		view.modulate.a = 0.0
		create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT).tween_property(view, "modulate:a", 1.0, 0.22)

func _show_auth() -> void:
	_auth_panel.visible = true
	_world_panel.visible = false
	_identity.text = "GUEST ACCESS / LOCAL SAVE"

func _on_auth_changed(authenticated: bool, account: Dictionary) -> void:
	if not authenticated:
		_show_auth()
		return
	_auth_panel.visible = false
	_world_panel.visible = true
	_identity.text = "SIGNED IN / %s" % str(account.get("display_name", "SURVIVOR")).to_upper()
	_set_status("ACCOUNT VERIFIED / LOADING WORLD ARCHIVE", false)

func _on_worlds_updated(values: Array) -> void:
	_world_list.clear()
	_world_ids.clear()
	_world_values.clear()
	for value in values:
		if value is Dictionary:
			var world: Dictionary = (value as Dictionary).duplicate(true)
			_world_values.append(world)
			_world_ids.append(str(world.get("id", "")))
			var region: String = str(world.get("region", "green_hollow")).replace("_", " ").to_upper()
			_world_list.add_item("%s\n%s / %s" % [str(world.get("name", "World")), str(world.get("kind", "personal")).to_upper(), region])
	_continue_button.disabled = _world_ids.is_empty()
	if _world_ids.is_empty():
		_world_details.text = "No worlds yet. Open CREATE or JOIN CODE."
	else:
		_world_list.select(0)
		_on_world_selected(0)
		_show_world_mode(0)
	_set_status("WORLD ARCHIVE / %d AVAILABLE" % _world_ids.size(), false)

func _on_world_limit_updated(owned: int, limit: int) -> void:
	_world_usage.text = "%d / %d OWNED" % [owned, limit]
	_world_usage.modulate = ALERT if owned >= limit else MUTED_LIGHT

func _on_world_selected(index: int) -> void:
	if index < 0 or index >= _world_values.size():
		return
	var world: Dictionary = _world_values[index]
	var region: String = str(world.get("region", "green_hollow")).replace("_", " ").to_upper()
	var hours: float = float(world.get("playtime_seconds", 0)) / 3600.0
	_world_details.text = "%s / %s / %s / %.1f HOURS" % [str(world.get("name", "WORLD")).to_upper(), str(world.get("kind", "personal")).to_upper(), region, hours]
	_continue_button.disabled = false

func _sign_in() -> void:
	if _nickname.text.strip_edges().is_empty() or _password.text.is_empty():
		_on_request_failed("Enter your nickname and password.")
		return
	_set_status("AUTHENTICATING ACCOUNT", false)
	AccountManager.login(_nickname.text, _password.text)

func _register() -> void:
	if _nickname.text.strip_edges().is_empty() or _password.text.length() < 10:
		_on_request_failed("Use a nickname and a password with at least 10 characters.")
		return
	_set_status("CREATING ACCOUNT", false)
	AccountManager.register_account(_nickname.text, _password.text)

func _create_world() -> void:
	if _world_name.text.strip_edges().is_empty():
		_on_request_failed("Enter a world name first.")
		return
	var kind: String = str(_world_kind.get_item_metadata(_world_kind.selected))
	_set_status("CREATING %s WORLD" % kind.to_upper(), false)
	AccountManager.create_world(_world_name.text, kind, {
		"scarce_resources": bool(SettingsManager.get_value("gameplay", "scarce_resources", false)),
		"harsh_climate": bool(SettingsManager.get_value("gameplay", "harsh_climate", false)),
		"aggressive_enemies": bool(SettingsManager.get_value("gameplay", "aggressive_enemies", false)),
	})

func _join_world() -> void:
	if _invite_code.text.strip_edges().is_empty():
		_on_request_failed("Enter an invite code first.")
		return
	_set_status("VALIDATING INVITE CODE", false)
	AccountManager.join_world(_invite_code.text.to_upper())

func _continue_world() -> void:
	var selected: PackedInt32Array = _world_list.get_selected_items()
	if selected.is_empty() or selected[0] >= _world_ids.size():
		_on_request_failed("Select a world to enter.")
		return
	_continue_button.disabled = true
	_set_status("VERIFYING WORLD CHECKPOINT", false)
	AccountManager.load_world(_world_ids[selected[0]])

func _on_world_loaded(_world: Dictionary, _snapshot: Dictionary) -> void:
	_set_status("CHECKPOINT VERIFIED / ENTERING WORLD", false)
	start_requested.emit()

func _start_guest() -> void:
	AccountManager.active_world_id = ""
	AccountManager.active_world.clear()
	AccountManager.pending_snapshot.clear()
	start_requested.emit()

func _show_control_choice() -> void:
	_control_scrim.visible = true

func _choose_control_mode(mode: String) -> void:
	InputProfile.set_mode(mode)
	_control_scrim.visible = false
	_set_status("INPUT PROFILE / %s" % mode.to_upper(), false)

func _on_control_mode_changed(mode: String) -> void:
	_control_button.text = "INPUT / %s" % mode.to_upper()

func _on_request_failed(message: String) -> void:
	_set_status("ATTENTION / " + message, true)
	if _continue_button != null:
		_continue_button.disabled = false

func _on_service_status_changed(online: bool, detail: String) -> void:
	_service_dot.modulate = GREEN if online else ALERT
	_service_text.modulate = GREEN if online else ALERT
	_service_text.text = "WORLD SERVICE ONLINE" if online else "WORLD SERVICE OFFLINE"
	_service_text.tooltip_text = detail
	if not online:
		_set_status("SERVICE CHECK FAILED / " + detail, true)

func _set_status(message: String, is_error: bool) -> void:
	_status.text = message
	_status.modulate = ALERT if is_error else MUTED_DARK
