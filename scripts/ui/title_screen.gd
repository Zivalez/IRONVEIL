extends CanvasLayer

signal start_requested()

const INK := Color(0.015, 0.021, 0.019, 1.0)
const PANEL := Color(0.043, 0.054, 0.048, 0.98)
const DEEP := Color(0.022, 0.029, 0.026, 1.0)
const LINE := Color(0.25, 0.32, 0.27, 1.0)
const TEXT := Color(0.92, 0.89, 0.80, 1.0)
const MUTED := Color(0.57, 0.65, 0.58, 1.0)
const COPPER := Color(0.79, 0.45, 0.17, 1.0)
const COPPER_LIGHT := Color(0.96, 0.65, 0.30, 1.0)
const GREEN := Color(0.39, 0.75, 0.50, 1.0)
const ALERT := Color(0.95, 0.43, 0.28, 1.0)

var _status: Label
var _service_dot: Label
var _service_text: Label
var _account_label: Label
var _auth_panel: PanelContainer
var _world_panel: PanelContainer
var _nickname: LineEdit
var _password: LineEdit
var _world_name: LineEdit
var _world_kind: OptionButton
var _invite_code: LineEdit
var _world_list: ItemList
var _world_ids: Array[String] = []
var _world_values: Array[Dictionary] = []
var _world_details: Label
var _world_empty: Label
var _continue_button: Button
var _world_tabs: TabContainer
var _control_choice: PanelContainer
var _control_scrim: ColorRect
var _control_mode_button: Button

func _ready() -> void:
	layer = 900
	_build()
	AccountManager.auth_changed.connect(_on_auth_changed)
	AccountManager.worlds_updated.connect(_on_worlds_updated)
	AccountManager.world_loaded.connect(_on_world_loaded)
	AccountManager.request_failed.connect(_on_request_failed)
	AccountManager.service_status_changed.connect(_on_service_status_changed)
	InputProfile.mode_changed.connect(_on_control_mode_changed)
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
	background.color = INK
	add_child(background)
	_add_grid(background)
	_build_top_bar(background)
	_build_side_panel(background)
	_auth_panel = _panel(Vector2(424, 132), Vector2(792, 528), true)
	background.add_child(_auth_panel)
	_build_auth_panel()
	_world_panel = _panel(Vector2(424, 132), Vector2(792, 528), true)
	background.add_child(_world_panel)
	_build_world_panel()
	_build_control_choice(background)

func _add_grid(parent: Control) -> void:
	var rail := ColorRect.new()
	rail.size = Vector2(8, 720)
	rail.color = COPPER
	parent.add_child(rail)
	for x in range(56, 1280, 96):
		var line := ColorRect.new()
		line.position = Vector2(x, 0)
		line.size = Vector2(1, 720)
		line.color = Color(0.14, 0.18, 0.16, 0.2)
		line.mouse_filter = Control.MOUSE_FILTER_IGNORE
		parent.add_child(line)
	for y in range(48, 720, 72):
		var line := ColorRect.new()
		line.position = Vector2(0, y)
		line.size = Vector2(1280, 1)
		line.color = Color(0.14, 0.18, 0.16, 0.16)
		line.mouse_filter = Control.MOUSE_FILTER_IGNORE
		parent.add_child(line)

func _build_top_bar(parent: Control) -> void:
	var top := _panel(Vector2(64, 34), Vector2(1152, 76), false)
	parent.add_child(top)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 16)
	top.add_child(row)
	var mark := TextureRect.new()
	mark.texture = load("res://assets/branding/ironveil_icon.png")
	mark.custom_minimum_size = Vector2(46, 46)
	mark.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	mark.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	row.add_child(mark)
	var brand := VBoxContainer.new()
	brand.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	brand.add_theme_constant_override("separation", -3)
	row.add_child(brand)
	brand.add_child(_label("IRONVEIL", 28, TEXT))
	brand.add_child(_label("FIELD NETWORK  /  BUILD 1.2.0", 12, MUTED))
	var service := HBoxContainer.new()
	service.custom_minimum_size = Vector2(220, 46)
	service.alignment = BoxContainer.ALIGNMENT_END
	service.add_theme_constant_override("separation", 8)
	row.add_child(service)
	_service_dot = _label("O", 18, MUTED)
	service.add_child(_service_dot)
	_service_text = _label("CHECKING SERVICE", 13, MUTED)
	service.add_child(_service_text)

func _build_side_panel(parent: Control) -> void:
	var side := _panel(Vector2(64, 132), Vector2(340, 528), true)
	parent.add_child(side)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 14)
	side.add_child(box)
	box.add_child(_label("FIELD ACCESS", 13, COPPER_LIGHT))
	box.add_child(_label("A WORLD THAT\nREMEMBERS", 31, TEXT))
	var rule := ColorRect.new()
	rule.custom_minimum_size = Vector2(290, 2)
	rule.color = COPPER
	box.add_child(rule)
	var intro := _label("Survive the six regions. Restore the machines. Carry your progress between devices.", 16, MUTED)
	intro.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	intro.custom_minimum_size = Vector2(290, 74)
	box.add_child(intro)
	var identity := _inset()
	identity.custom_minimum_size = Vector2(290, 72)
	box.add_child(identity)
	_account_label = _label("", 15, TEXT)
	_account_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	identity.add_child(_account_label)
	var guest := Button.new()
	guest.text = "PLAY LOCAL WORLD"
	guest.tooltip_text = "Progress stays in this browser."
	_style_button(guest, false)
	guest.custom_minimum_size = Vector2(290, 48)
	guest.pressed.connect(_start_guest)
	box.add_child(guest)
	_control_mode_button = Button.new()
	_control_mode_button.text = "INPUT  /  %s" % InputProfile.resolved_mode().to_upper()
	_style_button(_control_mode_button, false)
	_control_mode_button.custom_minimum_size = Vector2(290, 42)
	_control_mode_button.pressed.connect(_show_control_choice)
	box.add_child(_control_mode_button)
	_status = _label("READY FOR FIELD ACCESS", 13, MUTED)
	_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_status.custom_minimum_size = Vector2(290, 52)
	box.add_child(_status)

func _build_auth_panel() -> void:
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 15)
	_auth_panel.add_child(box)
	box.add_child(_label("ACCOUNT GATEWAY", 13, COPPER_LIGHT))
	box.add_child(_label("RETURN TO YOUR WORLD", 30, TEXT))
	box.add_child(_label("Use your nickname and password. No email is required.", 15, MUTED))
	var columns := HBoxContainer.new()
	columns.add_theme_constant_override("separation", 22)
	columns.size_flags_vertical = Control.SIZE_EXPAND_FILL
	box.add_child(columns)
	var form := VBoxContainer.new()
	form.custom_minimum_size = Vector2(445, 300)
	form.add_theme_constant_override("separation", 10)
	columns.add_child(form)
	_nickname = _field(form, "NICKNAME", "FieldEngineer", false)
	_password = _field(form, "PASSWORD", "10 characters minimum", true)
	_password.text_submitted.connect(func(_value: String) -> void: _sign_in())
	var sign_in := Button.new()
	sign_in.text = "SIGN IN AND VIEW WORLDS"
	_style_button(sign_in, true)
	sign_in.custom_minimum_size.y = 52
	sign_in.pressed.connect(_sign_in)
	form.add_child(sign_in)
	var register := Button.new()
	register.text = "CREATE NEW ACCOUNT"
	register.tooltip_text = "Uses the nickname and password entered above."
	_style_button(register, false)
	register.custom_minimum_size.y = 46
	register.pressed.connect(_register)
	form.add_child(register)
	var info := _inset()
	info.custom_minimum_size = Vector2(250, 280)
	columns.add_child(info)
	var info_box := VBoxContainer.new()
	info_box.add_theme_constant_override("separation", 14)
	info.add_child(info_box)
	info_box.add_child(_label("ACCOUNT INCLUDES", 14, COPPER_LIGHT))
	for text_value in ["+  PERSISTENT CHECKPOINTS", "+  PERSONAL WORLDS", "+  SHARED WORLD ACCESS", "+  CROSS DEVICE LOGIN"]:
		var item := _label(str(text_value), 14, MUTED)
		item.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		info_box.add_child(item)

func _build_world_panel() -> void:
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 9)
	_world_panel.add_child(box)
	var header := HBoxContainer.new()
	box.add_child(header)
	var titles := VBoxContainer.new()
	titles.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(titles)
	titles.add_child(_label("WORLD ARCHIVE", 13, COPPER_LIGHT))
	titles.add_child(_label("CHOOSE YOUR DESTINATION", 25, TEXT))
	var logout := Button.new()
	logout.text = "SIGN OUT"
	_style_button(logout, false)
	logout.custom_minimum_size = Vector2(116, 40)
	logout.pressed.connect(AccountManager.logout)
	header.add_child(logout)
	_world_tabs = TabContainer.new()
	_world_tabs.custom_minimum_size = Vector2(738, 395)
	_world_tabs.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_style_tabs(_world_tabs)
	box.add_child(_world_tabs)
	_build_worlds_tab()
	_build_create_tab()
	_build_join_tab()

func _build_worlds_tab() -> void:
	var margin := _tab("MY WORLDS")
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 14)
	margin.add_child(row)
	var list_box := VBoxContainer.new()
	list_box.custom_minimum_size = Vector2(432, 310)
	list_box.add_theme_constant_override("separation", 8)
	row.add_child(list_box)
	list_box.add_child(_label("AVAILABLE WORLDS", 12, MUTED))
	_world_list = ItemList.new()
	_world_list.custom_minimum_size = Vector2(432, 250)
	_world_list.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_world_list.item_selected.connect(_on_world_selected)
	_style_item_list(_world_list)
	list_box.add_child(_world_list)
	_world_empty = _label("No worlds yet. Open CREATE WORLD to begin.", 13, MUTED)
	_world_empty.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	list_box.add_child(_world_empty)
	var detail := _inset()
	detail.custom_minimum_size = Vector2(260, 310)
	row.add_child(detail)
	var detail_box := VBoxContainer.new()
	detail_box.add_theme_constant_override("separation", 12)
	detail.add_child(detail_box)
	detail_box.add_child(_label("SELECTED WORLD", 13, COPPER_LIGHT))
	_world_details = _label("Select a world from the archive.", 14, MUTED)
	_world_details.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_world_details.custom_minimum_size = Vector2(220, 160)
	detail_box.add_child(_world_details)
	_continue_button = Button.new()
	_continue_button.text = "ENTER WORLD"
	_continue_button.disabled = true
	_style_button(_continue_button, true)
	_continue_button.custom_minimum_size = Vector2(220, 52)
	_continue_button.pressed.connect(_continue_world)
	detail_box.add_child(_continue_button)

func _build_create_tab() -> void:
	var margin := _tab("CREATE WORLD")
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 24)
	margin.add_child(row)
	var form := VBoxContainer.new()
	form.custom_minimum_size = Vector2(430, 300)
	form.add_theme_constant_override("separation", 10)
	row.add_child(form)
	form.add_child(_label("OPEN A NEW FRONTIER", 21, TEXT))
	_world_name = _field(form, "WORLD NAME", "The Copper Meridian", false)
	form.add_child(_label("WORLD TYPE", 12, MUTED))
	_world_kind = OptionButton.new()
	_world_kind.add_item("PERSONAL  /  PRIVATE PROGRESS")
	_world_kind.set_item_metadata(0, "personal")
	_world_kind.add_item("SHARED  /  INVITE FRIENDS")
	_world_kind.set_item_metadata(1, "shared")
	_world_kind.custom_minimum_size = Vector2(430, 46)
	_style_option(_world_kind)
	form.add_child(_world_kind)
	var create := Button.new()
	create.text = "CREATE WORLD"
	_style_button(create, true)
	create.custom_minimum_size = Vector2(430, 54)
	create.pressed.connect(_create_world)
	form.add_child(create)
	var guide := _inset()
	guide.custom_minimum_size = Vector2(245, 250)
	row.add_child(guide)
	var guide_text := _label("PERSONAL\nOnly your account can enter.\n\nSHARED\nCreate invite codes for other survivors.\n\nBoth types use server checkpoints.", 14, MUTED)
	guide_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	guide.add_child(guide_text)

func _build_join_tab() -> void:
	var margin := _tab("JOIN BY CODE")
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 24)
	margin.add_child(row)
	var form := VBoxContainer.new()
	form.custom_minimum_size = Vector2(430, 300)
	form.add_theme_constant_override("separation", 12)
	row.add_child(form)
	form.add_child(_label("JOIN A SHARED WORLD", 21, TEXT))
	form.add_child(_label("Enter the invite code from the world owner.", 14, MUTED))
	_invite_code = _field(form, "INVITE CODE", "AB12CD34", false)
	_invite_code.max_length = 16
	var join := Button.new()
	join.text = "JOIN WORLD"
	_style_button(join, true)
	join.custom_minimum_size = Vector2(430, 54)
	join.pressed.connect(_join_world)
	form.add_child(join)
	var guide := _inset()
	guide.custom_minimum_size = Vector2(245, 230)
	row.add_child(guide)
	var guide_text := _label("ONE CODE\nThe world is added to your archive.\n\nRETURN ANY TIME\nUse MY WORLDS to enter again.", 14, MUTED)
	guide_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	guide.add_child(guide_text)

func _build_control_choice(parent: Control) -> void:
	_control_scrim = ColorRect.new()
	_control_scrim.set_anchors_preset(Control.PRESET_FULL_RECT)
	_control_scrim.color = Color(0.008, 0.011, 0.010, 0.9)
	_control_scrim.mouse_filter = Control.MOUSE_FILTER_STOP
	_control_scrim.z_index = 29
	_control_scrim.visible = false
	parent.add_child(_control_scrim)
	_control_choice = _panel(Vector2(370, 190), Vector2(540, 340), true)
	_control_choice.z_index = 30
	_control_scrim.add_child(_control_choice)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 16)
	_control_choice.add_child(box)
	box.add_child(_label("INPUT PROFILE", 13, COPPER_LIGHT))
	box.add_child(_label("HOW ARE YOU PLAYING?", 26, TEXT))
	var touch := Button.new()
	touch.text = "MOBILE  /  TOUCH CONTROLS"
	_style_button(touch, true)
	touch.custom_minimum_size = Vector2(480, 62)
	touch.pressed.connect(_choose_control_mode.bind(InputProfile.MODE_TOUCH))
	box.add_child(touch)
	var desktop := Button.new()
	desktop.text = "DESKTOP  /  KEYBOARD AND MOUSE"
	_style_button(desktop, false)
	desktop.custom_minimum_size = Vector2(480, 62)
	desktop.pressed.connect(_choose_control_mode.bind(InputProfile.MODE_DESKTOP))
	box.add_child(desktop)

func _label(text: String, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", font_size)
	label.modulate = color
	return label

func _field(parent: VBoxContainer, title: String, placeholder: String, secret: bool) -> LineEdit:
	parent.add_child(_label(title, 12, MUTED))
	var edit := LineEdit.new()
	edit.placeholder_text = placeholder
	edit.secret = secret
	edit.custom_minimum_size.y = 44
	var normal := _box(DEEP, LINE, 3)
	normal.content_margin_left = 13
	normal.content_margin_right = 13
	var focus := normal.duplicate() as StyleBoxFlat
	focus.border_color = COPPER_LIGHT
	edit.add_theme_stylebox_override("normal", normal)
	edit.add_theme_stylebox_override("focus", focus)
	edit.add_theme_color_override("font_color", TEXT)
	edit.add_theme_color_override("font_placeholder_color", Color(0.41, 0.47, 0.42, 1.0))
	parent.add_child(edit)
	return edit

func _panel(position_value: Vector2, size_value: Vector2, raised: bool) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.position = position_value
	panel.size = size_value
	var style := _box(PANEL, LINE, 4)
	style.shadow_color = Color(0, 0, 0, 0.34)
	style.shadow_size = 9 if raised else 4
	style.content_margin_left = 24
	style.content_margin_right = 24
	style.content_margin_top = 19
	style.content_margin_bottom = 19
	panel.add_theme_stylebox_override("panel", style)
	return panel

func _inset() -> PanelContainer:
	var panel := PanelContainer.new()
	var style := _box(DEEP, Color(0.18, 0.24, 0.20, 1.0), 3)
	style.content_margin_left = 16
	style.content_margin_right = 16
	style.content_margin_top = 14
	style.content_margin_bottom = 14
	panel.add_theme_stylebox_override("panel", style)
	return panel

func _box(color: Color, border: Color, radius: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.border_color = border
	style.set_border_width_all(1)
	style.set_corner_radius_all(radius)
	return style

func _style_button(button: Button, primary: bool) -> void:
	button.custom_minimum_size = Vector2(190, 42)
	button.add_theme_color_override("font_color", TEXT)
	button.add_theme_color_override("font_hover_color", Color.WHITE)
	var normal := _box(Color(0.58, 0.31, 0.11, 1.0) if primary else Color(0.075, 0.094, 0.083, 1.0), COPPER if primary else LINE, 3)
	normal.content_margin_left = 14
	normal.content_margin_right = 14
	var hover := normal.duplicate() as StyleBoxFlat
	hover.bg_color = Color(0.72, 0.40, 0.15, 1.0) if primary else Color(0.11, 0.14, 0.12, 1.0)
	hover.border_color = COPPER_LIGHT
	var disabled := normal.duplicate() as StyleBoxFlat
	disabled.bg_color = Color(0.045, 0.052, 0.047, 1.0)
	disabled.border_color = Color(0.14, 0.17, 0.15, 1.0)
	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("disabled", disabled)

func _style_tabs(tabs: TabContainer) -> void:
	tabs.add_theme_stylebox_override("panel", _box(DEEP, LINE, 3))
	var selected := _box(Color(0.16, 0.11, 0.065, 1.0), COPPER, 3)
	selected.content_margin_left = 16
	selected.content_margin_right = 16
	selected.content_margin_top = 9
	selected.content_margin_bottom = 9
	var unselected := selected.duplicate() as StyleBoxFlat
	unselected.bg_color = PANEL
	unselected.border_color = LINE
	tabs.add_theme_stylebox_override("tab_selected", selected)
	tabs.add_theme_stylebox_override("tab_unselected", unselected)
	tabs.add_theme_color_override("font_selected_color", COPPER_LIGHT)
	tabs.add_theme_color_override("font_unselected_color", MUTED)

func _style_item_list(list: ItemList) -> void:
	var panel_style := _box(Color(0.016, 0.022, 0.019, 1.0), LINE, 3)
	panel_style.content_margin_left = 8
	panel_style.content_margin_right = 8
	panel_style.content_margin_top = 8
	panel_style.content_margin_bottom = 8
	list.add_theme_stylebox_override("panel", panel_style)
	var selected := _box(Color(0.25, 0.16, 0.08, 1.0), COPPER, 2)
	list.add_theme_stylebox_override("selected", selected)
	list.add_theme_stylebox_override("selected_focus", selected)
	list.add_theme_color_override("font_color", MUTED)
	list.add_theme_color_override("font_selected_color", TEXT)

func _style_option(option: OptionButton) -> void:
	option.add_theme_color_override("font_color", TEXT)
	var style := _box(DEEP, LINE, 3)
	style.content_margin_left = 13
	style.content_margin_right = 13
	option.add_theme_stylebox_override("normal", style)

func _tab(title: String) -> MarginContainer:
	var margin := MarginContainer.new()
	margin.name = title
	margin.add_theme_constant_override("margin_left", 14)
	margin.add_theme_constant_override("margin_right", 14)
	margin.add_theme_constant_override("margin_top", 14)
	margin.add_theme_constant_override("margin_bottom", 14)
	_world_tabs.add_child(margin)
	return margin

func _show_control_choice() -> void:
	_control_scrim.visible = true

func _choose_control_mode(mode: String) -> void:
	InputProfile.set_mode(mode)
	_control_scrim.visible = false
	_set_status("INPUT PROFILE  /  %s" % mode.to_upper(), false)

func _on_control_mode_changed(mode: String) -> void:
	if _control_mode_button != null:
		_control_mode_button.text = "INPUT  /  %s" % mode.to_upper()

func _show_auth() -> void:
	_auth_panel.visible = true
	_world_panel.visible = false
	_account_label.text = "GUEST MODE\nLocal world access available"

func _on_auth_changed(authenticated: bool, account: Dictionary) -> void:
	if not authenticated:
		_show_auth()
		return
	_auth_panel.visible = false
	_world_panel.visible = true
	_account_label.text = "SIGNED IN\n%s" % str(account.get("display_name", "SURVIVOR")).to_upper()
	_set_status("ACCOUNT VERIFIED  /  LOADING WORLDS", false)

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
			_world_list.add_item("%s\n%s  /  %s" % [str(world.get("name", "World")), str(world.get("kind", "personal")).to_upper(), region])
	_world_empty.visible = _world_ids.is_empty()
	_continue_button.disabled = _world_ids.is_empty()
	_set_status("WORLD ARCHIVE  /  %d AVAILABLE" % _world_ids.size(), false)
	if _world_ids.is_empty():
		_world_details.text = "Your archive is empty.\n\nOpen CREATE WORLD to start a new frontier."
	else:
		_world_list.select(0)
		_on_world_selected(0)
		_world_tabs.current_tab = 0

func _on_world_selected(index: int) -> void:
	if index < 0 or index >= _world_values.size():
		return
	var world: Dictionary = _world_values[index]
	var region: String = str(world.get("region", "green_hollow")).replace("_", " ").to_upper()
	var hours: float = float(world.get("playtime_seconds", 0)) / 3600.0
	_world_details.text = "%s\n\nTYPE  /  %s\nREGION  /  %s\nPLAYTIME  /  %.1f HOURS" % [str(world.get("name", "WORLD")).to_upper(), str(world.get("kind", "personal")).to_upper(), region, hours]
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
	_set_status("CHECKPOINT VERIFIED  /  ENTERING WORLD", false)
	start_requested.emit()

func _start_guest() -> void:
	AccountManager.active_world_id = ""
	AccountManager.active_world.clear()
	AccountManager.pending_snapshot.clear()
	start_requested.emit()

func _on_request_failed(message: String) -> void:
	_set_status("ATTENTION  /  " + message, true)
	if _continue_button != null:
		_continue_button.disabled = false

func _on_service_status_changed(online: bool, detail: String) -> void:
	_service_dot.modulate = GREEN if online else ALERT
	_service_text.modulate = GREEN if online else ALERT
	_service_text.text = "WORLD SERVICE ONLINE" if online else "WORLD SERVICE OFFLINE"
	_service_text.tooltip_text = detail
	if not online:
		_set_status("SERVICE CHECK FAILED  /  " + detail, true)

func _set_status(message: String, is_error: bool) -> void:
	_status.text = message
	_status.modulate = ALERT if is_error else MUTED
