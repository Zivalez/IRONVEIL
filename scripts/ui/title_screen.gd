extends CanvasLayer

## IRONVEIL Title — full UI overhaul
## Dark industrial, responsive center layout, entry animations

signal start_requested()

const BG := Color(0.04, 0.045, 0.05, 1.0)
const CARD := Color(0.07, 0.08, 0.09, 0.97)
const CARD_EDGE := Color(0.28, 0.30, 0.32, 0.9)
const BRASS := Color(0.85, 0.65, 0.32, 1.0)
const BRASS_DIM := Color(0.55, 0.42, 0.22, 1.0)
const TEXT := Color(0.92, 0.93, 0.90, 1.0)
const MUTED := Color(0.55, 0.58, 0.55, 1.0)
const GOOD := Color(0.40, 0.82, 0.55, 1.0)
const BAD := Color(0.90, 0.35, 0.32, 1.0)
const ACCENT_BTN := Color(0.82, 0.42, 0.22, 1.0)

var _root: Control
var _card: PanelContainer
var _hero_col: VBoxContainer
var _auth_panel: PanelContainer
var _world_panel: PanelContainer
var _status: Label
var _service_dot: ColorRect
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
var _left_pane: Control
var _right_pane: Control

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
		_control_scrim.modulate.a = 0.0
		var tw := create_tween()
		tw.tween_property(_control_scrim, "modulate:a", 1.0, 0.35)
	if AccountManager.is_authenticated():
		_on_auth_changed(true, AccountManager.account)
		AccountManager.refresh_session()
	else:
		_show_auth()

func _build() -> void:
	_root = Control.new()
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_root)

	var bg := ColorRect.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.color = BG
	_root.add_child(bg)
	_add_vignette(_root)
	_add_soft_grid(_root)

	# Center stage
	var stage := CenterContainer.new()
	stage.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.add_child(stage)

	_card = PanelContainer.new()
	_card.custom_minimum_size = Vector2(1080, 580)
	_card.add_theme_stylebox_override("panel", _card_style())
	stage.add_child(_card)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 36)
	margin.add_theme_constant_override("margin_right", 36)
	margin.add_theme_constant_override("margin_top", 28)
	margin.add_theme_constant_override("margin_bottom", 28)
	_card.add_child(margin)

	var main_col := VBoxContainer.new()
	main_col.add_theme_constant_override("separation", 18)
	margin.add_child(main_col)

	_build_header(main_col)

	var body := HBoxContainer.new()
	body.add_theme_constant_override("separation", 28)
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	main_col.add_child(body)

	_left_pane = VBoxContainer.new()
	_left_pane.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_left_pane.add_theme_constant_override("separation", 12)
	body.add_child(_left_pane)
	_build_hero(_left_pane)

	_right_pane = Control.new()
	_right_pane.custom_minimum_size = Vector2(420, 420)
	_right_pane.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.add_child(_right_pane)
	_build_auth(_right_pane)
	_build_world_panel(_right_pane)

	_build_control_choice(_root)

func _add_vignette(parent: Control) -> void:
	var v := ColorRect.new()
	v.set_anchors_preset(Control.PRESET_FULL_RECT)
	v.color = Color(0, 0, 0, 0.35)
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	# soft edge via modulate only; full dark vignette-lite
	parent.add_child(v)
	v.modulate = Color(1, 1, 1, 0.25)

func _add_soft_grid(parent: Control) -> void:
	for i in range(0, 20):
		var h := ColorRect.new()
		h.set_anchors_preset(Control.PRESET_TOP_WIDE)
		h.offset_top = float(i) * 48.0
		h.offset_bottom = h.offset_top + 1.0
		h.color = Color(1, 1, 1, 0.03)
		h.mouse_filter = Control.MOUSE_FILTER_IGNORE
		parent.add_child(h)

func _build_header(parent: VBoxContainer) -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 14)
	parent.add_child(row)

	var brand_box := VBoxContainer.new()
	brand_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(brand_box)
	var tag := _lab("IRONVEIL  ·  FIELD NETWORK", 12, BRASS)
	brand_box.add_child(tag)
	var title := _lab("SIX REGIONS  →  THE VEIL", 20, TEXT)
	brand_box.add_child(title)

	var svc := HBoxContainer.new()
	svc.add_theme_constant_override("separation", 8)
	row.add_child(svc)
	_service_dot = ColorRect.new()
	_service_dot.custom_minimum_size = Vector2(10, 10)
	_service_dot.color = MUTED
	svc.add_child(_service_dot)
	_service_text = _lab("CHECKING SERVICE", 12, MUTED)
	svc.add_child(_service_text)
	var build := _lab("1.4.0", 11, MUTED)
	row.add_child(build)

	var rule := ColorRect.new()
	rule.custom_minimum_size = Vector2(0, 2)
	rule.color = BRASS_DIM
	rule.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	parent.add_child(rule)

func _build_hero(parent: VBoxContainer) -> void:
	_hero_col = parent
	parent.add_child(_lab("SURVIVAL  ·  ENGINEERING  ·  PERSISTENT WORLDS", 11, MUTED))
	var heading := _lab("Build the system.\nOutlive the world.", 36, TEXT)
	heading.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	parent.add_child(heading)
	var copy := _lab(
		"Knowledge matters more than levels. Restore machines, connect power, and carry your world across devices.",
		14, MUTED
	)
	copy.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	copy.custom_minimum_size = Vector2(360, 60)
	parent.add_child(copy)

	var accent := ColorRect.new()
	accent.custom_minimum_size = Vector2(64, 3)
	accent.color = BRASS
	parent.add_child(accent)

	_status = _lab("READY", 13, MUTED)
	parent.add_child(_status)

	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	parent.add_child(spacer)

	var actions := VBoxContainer.new()
	actions.add_theme_constant_override("separation", 10)
	parent.add_child(actions)

	var guest := Button.new()
	guest.text = "ENTER AS GUEST"
	guest.custom_minimum_size = Vector2(0, 48)
	_style_btn(guest, "primary")
	guest.pressed.connect(_start_guest)
	actions.add_child(guest)

	_control_button = Button.new()
	_control_button.text = "INPUT / %s" % InputProfile.resolved_mode().to_upper()
	_control_button.custom_minimum_size = Vector2(0, 40)
	_style_btn(_control_button, "ghost")
	_control_button.pressed.connect(_show_control_choice)
	actions.add_child(_control_button)

func _build_auth(parent: Control) -> void:
	_auth_panel = PanelContainer.new()
	_auth_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	_auth_panel.add_theme_stylebox_override("panel", _inner_card_style())
	parent.add_child(_auth_panel)
	var m := MarginContainer.new()
	m.add_theme_constant_override("margin_left", 22)
	m.add_theme_constant_override("margin_right", 22)
	m.add_theme_constant_override("margin_top", 20)
	m.add_theme_constant_override("margin_bottom", 20)
	_auth_panel.add_child(m)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 10)
	m.add_child(box)
	box.add_child(_lab("ACCOUNT", 11, BRASS))
	box.add_child(_lab("Return to the field", 22, TEXT))
	var note := _lab("Nickname + password only. No email.", 13, MUTED)
	box.add_child(note)
	_nickname = _field(box, "NICKNAME", "FieldEngineer", false)
	_password = _field(box, "PASSWORD", "10 characters minimum", true)
	_password.text_submitted.connect(func(_v: String) -> void: _sign_in())
	var sign_in := Button.new()
	sign_in.text = "SIGN IN"
	sign_in.custom_minimum_size = Vector2(0, 48)
	_style_btn(sign_in, "primary")
	sign_in.pressed.connect(_sign_in)
	box.add_child(sign_in)
	var register := Button.new()
	register.text = "CREATE ACCOUNT"
	register.custom_minimum_size = Vector2(0, 42)
	_style_btn(register, "ghost")
	register.pressed.connect(_register)
	box.add_child(register)

func _build_world_panel(parent: Control) -> void:
	_world_panel = PanelContainer.new()
	_world_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	_world_panel.visible = false
	_world_panel.add_theme_stylebox_override("panel", _inner_card_style())
	parent.add_child(_world_panel)
	var m := MarginContainer.new()
	m.add_theme_constant_override("margin_left", 20)
	m.add_theme_constant_override("margin_right", 20)
	m.add_theme_constant_override("margin_top", 16)
	m.add_theme_constant_override("margin_bottom", 16)
	_world_panel.add_child(m)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 8)
	m.add_child(box)

	var header := HBoxContainer.new()
	box.add_child(header)
	var titles := VBoxContainer.new()
	titles.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(titles)
	titles.add_child(_lab("WORLDS", 11, BRASS))
	_identity = _lab("CHOOSE ROUTE", 18, TEXT)
	titles.add_child(_identity)
	var logout := Button.new()
	logout.text = "SIGN OUT"
	logout.custom_minimum_size = Vector2(96, 34)
	_style_btn(logout, "ghost")
	logout.pressed.connect(AccountManager.logout)
	header.add_child(logout)

	var mode_row := HBoxContainer.new()
	mode_row.add_theme_constant_override("separation", 6)
	box.add_child(mode_row)
	for index in range(3):
		var button := Button.new()
		button.text = ["WORLDS", "CREATE", "JOIN"][index]
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.custom_minimum_size = Vector2(0, 34)
		_style_btn(button, "ghost")
		var idx := index
		button.pressed.connect(func() -> void: _select_mode(idx))
		mode_row.add_child(button)
		_mode_buttons.append(button)

	var stack := Control.new()
	stack.custom_minimum_size = Vector2(0, 220)
	stack.size_flags_vertical = Control.SIZE_EXPAND_FILL
	box.add_child(stack)

	# Worlds list view
	var list_view := VBoxContainer.new()
	list_view.set_anchors_preset(Control.PRESET_FULL_RECT)
	stack.add_child(list_view)
	_world_list = ItemList.new()
	_world_list.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_world_list.custom_minimum_size = Vector2(0, 140)
	_style_item_list(_world_list)
	_world_list.item_selected.connect(_on_world_selected)
	list_view.add_child(_world_list)
	_world_details = _lab("Select a world.", 12, MUTED)
	_world_details.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	list_view.add_child(_world_details)
	_world_usage = _lab("", 11, MUTED)
	list_view.add_child(_world_usage)
	_continue_button = Button.new()
	_continue_button.text = "ENTER WORLD"
	_continue_button.custom_minimum_size = Vector2(0, 44)
	_style_btn(_continue_button, "primary")
	_continue_button.pressed.connect(_continue_world)
	list_view.add_child(_continue_button)
	_mode_views.append(list_view)

	# Create view
	var create_view := VBoxContainer.new()
	create_view.set_anchors_preset(Control.PRESET_FULL_RECT)
	create_view.visible = false
	stack.add_child(create_view)
	_world_name = _field(create_view, "WORLD NAME", "Ashwick Checkpoint", false)
	create_view.add_child(_lab("KIND", 11, MUTED))
	_world_kind = OptionButton.new()
	_world_kind.add_item("Personal")
	_world_kind.set_item_metadata(0, "personal")
	_world_kind.add_item("Shared")
	_world_kind.set_item_metadata(1, "shared")
	_style_option(_world_kind)
	create_view.add_child(_world_kind)
	var create_btn := Button.new()
	create_btn.text = "CREATE WORLD"
	create_btn.custom_minimum_size = Vector2(0, 44)
	_style_btn(create_btn, "primary")
	create_btn.pressed.connect(_create_world)
	create_view.add_child(create_btn)
	_mode_views.append(create_view)

	# Join view
	var join_view := VBoxContainer.new()
	join_view.set_anchors_preset(Control.PRESET_FULL_RECT)
	join_view.visible = false
	stack.add_child(join_view)
	_invite_code = _field(join_view, "INVITE CODE", "ABCD-1234", false)
	var join_btn := Button.new()
	join_btn.text = "JOIN SHARED WORLD"
	join_btn.custom_minimum_size = Vector2(0, 44)
	_style_btn(join_btn, "primary")
	join_btn.pressed.connect(_join_world)
	join_view.add_child(join_btn)
	_mode_views.append(join_view)

	_select_mode(0)

func _build_control_choice(parent: Control) -> void:
	_control_scrim = ColorRect.new()
	_control_scrim.set_anchors_preset(Control.PRESET_FULL_RECT)
	_control_scrim.color = Color(0.02, 0.02, 0.03, 0.82)
	_control_scrim.visible = false
	_control_scrim.mouse_filter = Control.MOUSE_FILTER_STOP
	parent.add_child(_control_scrim)
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	_control_scrim.add_child(center)
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(420, 260)
	panel.add_theme_stylebox_override("panel", _card_style())
	center.add_child(panel)
	var m := MarginContainer.new()
	m.add_theme_constant_override("margin_left", 28)
	m.add_theme_constant_override("margin_right", 28)
	m.add_theme_constant_override("margin_top", 24)
	m.add_theme_constant_override("margin_bottom", 24)
	panel.add_child(m)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 12)
	m.add_child(box)
	box.add_child(_lab("CONTROL PROFILE", 12, BRASS))
	box.add_child(_lab("How will you play?", 22, TEXT))
	var touch := Button.new()
	touch.text = "MOBILE / TOUCH"
	touch.custom_minimum_size = Vector2(0, 48)
	_style_btn(touch, "primary")
	touch.pressed.connect(_choose_control_mode.bind(InputProfile.MODE_TOUCH))
	box.add_child(touch)
	var desktop := Button.new()
	desktop.text = "DESKTOP / KEYBOARD + MOUSE"
	desktop.custom_minimum_size = Vector2(0, 48)
	_style_btn(desktop, "ghost")
	desktop.pressed.connect(_choose_control_mode.bind(InputProfile.MODE_DESKTOP))
	box.add_child(desktop)

# ---------- style helpers ----------
func _card_style() -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = CARD
	s.border_color = BRASS_DIM
	s.set_border_width_all(1)
	s.set_corner_radius_all(10)
	s.shadow_color = Color(0, 0, 0, 0.45)
	s.shadow_size = 16
	s.shadow_offset = Vector2(0, 6)
	return s

func _inner_card_style() -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = Color(0.05, 0.055, 0.06, 0.95)
	s.border_color = CARD_EDGE
	s.set_border_width_all(1)
	s.set_corner_radius_all(8)
	return s

func _lab(text: String, size: int, color: Color) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	return l

func _field(parent: VBoxContainer, title: String, placeholder: String, secret: bool) -> LineEdit:
	parent.add_child(_lab(title, 11, MUTED))
	var edit := LineEdit.new()
	edit.placeholder_text = placeholder
	edit.secret = secret
	edit.custom_minimum_size = Vector2(0, 40)
	var normal := StyleBoxFlat.new()
	normal.bg_color = Color(0.09, 0.10, 0.11, 1.0)
	normal.border_color = CARD_EDGE
	normal.set_border_width_all(1)
	normal.set_corner_radius_all(6)
	normal.content_margin_left = 12
	normal.content_margin_right = 12
	var focus := normal.duplicate() as StyleBoxFlat
	focus.border_color = BRASS
	edit.add_theme_stylebox_override("normal", normal)
	edit.add_theme_stylebox_override("focus", focus)
	edit.add_theme_color_override("font_color", TEXT)
	edit.add_theme_color_override("font_placeholder_color", Color(0.45, 0.48, 0.45))
	parent.add_child(edit)
	return edit

func _style_btn(button: Button, variant: String) -> void:
	var bg := Color(0.12, 0.13, 0.14, 1.0)
	var border := CARD_EDGE
	var fg := TEXT
	if variant == "primary":
		bg = ACCENT_BTN
		border = ACCENT_BTN
		fg = Color(1, 0.97, 0.94)
	elif variant == "ghost":
		bg = Color(0.08, 0.09, 0.10, 1.0)
		border = CARD_EDGE
	var normal := StyleBoxFlat.new()
	normal.bg_color = bg
	normal.border_color = border
	normal.set_border_width_all(1)
	normal.set_corner_radius_all(6)
	normal.content_margin_left = 14
	normal.content_margin_right = 14
	normal.content_margin_top = 8
	normal.content_margin_bottom = 8
	var hover := normal.duplicate() as StyleBoxFlat
	hover.bg_color = bg.lightened(0.12)
	hover.border_color = BRASS
	var pressed := normal.duplicate() as StyleBoxFlat
	pressed.bg_color = bg.darkened(0.12)
	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("pressed", pressed)
	button.add_theme_color_override("font_color", fg)
	button.add_theme_color_override("font_hover_color", TEXT)
	button.mouse_entered.connect(func() -> void: AudioManager.play_ui("hover"))
	button.button_down.connect(func() -> void: AudioManager.play_ui("press"))

func _style_item_list(list: ItemList) -> void:
	var panel := StyleBoxFlat.new()
	panel.bg_color = Color(0.06, 0.07, 0.08, 1.0)
	panel.border_color = CARD_EDGE
	panel.set_border_width_all(1)
	panel.set_corner_radius_all(6)
	panel.content_margin_left = 8
	panel.content_margin_top = 8
	panel.content_margin_right = 8
	panel.content_margin_bottom = 8
	list.add_theme_stylebox_override("panel", panel)
	list.add_theme_color_override("font_color", MUTED)
	list.add_theme_color_override("font_selected_color", TEXT)

func _style_option(option: OptionButton) -> void:
	var normal := StyleBoxFlat.new()
	normal.bg_color = Color(0.09, 0.10, 0.11, 1.0)
	normal.border_color = CARD_EDGE
	normal.set_border_width_all(1)
	normal.set_corner_radius_all(6)
	normal.content_margin_left = 12
	option.add_theme_stylebox_override("normal", normal)
	option.add_theme_color_override("font_color", TEXT)

# ---------- animation ----------
func _animate_entry() -> void:
	_card.modulate.a = 0.0
	_card.scale = Vector2(0.96, 0.96)
	_card.pivot_offset = _card.custom_minimum_size * 0.5
	var tw := create_tween()
	tw.set_parallel(true)
	tw.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tw.tween_property(_card, "modulate:a", 1.0, 0.45)
	tw.tween_property(_card, "scale", Vector2.ONE, 0.50)
	_left_pane.modulate.a = 0.0
	_right_pane.modulate.a = 0.0
	tw.chain().tween_property(_left_pane, "modulate:a", 1.0, 0.28)
	tw.parallel().tween_property(_right_pane, "modulate:a", 1.0, 0.32)

func _animate_panel_swap(hide_panel: Control, show_panel: Control) -> void:
	show_panel.visible = true
	show_panel.modulate.a = 0.0
	var tw := create_tween()
	tw.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tw.tween_property(hide_panel, "modulate:a", 0.0, 0.18)
	tw.tween_callback(func() -> void: hide_panel.visible = false)
	tw.tween_property(show_panel, "modulate:a", 1.0, 0.28)

# ---------- logic (preserved) ----------
func _select_mode(index: int) -> void:
	for i in range(_mode_views.size()):
		_mode_views[i].visible = (i == index)
	for i in range(_mode_buttons.size()):
		_style_btn(_mode_buttons[i], "primary" if i == index else "ghost")

func _show_auth() -> void:
	if _world_panel.visible:
		_animate_panel_swap(_world_panel, _auth_panel)
	else:
		_auth_panel.visible = true
		_world_panel.visible = false

func _show_worlds() -> void:
	if _auth_panel.visible:
		_animate_panel_swap(_auth_panel, _world_panel)
	else:
		_world_panel.visible = true
		_auth_panel.visible = false

func _sign_in() -> void:
	_set_status("SIGNING IN…", false)
	AccountManager.sign_in(_nickname.text.strip_edges(), _password.text)

func _register() -> void:
	_set_status("CREATING ACCOUNT…", false)
	AccountManager.register(_nickname.text.strip_edges(), _password.text)

func _on_auth_changed(authenticated: bool, account: Dictionary) -> void:
	if authenticated:
		_identity.text = str(account.get("nickname", "Survivor")).to_upper()
		_show_worlds()
		_set_status("SIGNED IN", false)
		AccountManager.list_worlds()
	else:
		_show_auth()
		_set_status("READY", false)

func _on_worlds_updated(worlds: Array) -> void:
	_world_ids.clear()
	_world_values.clear()
	_world_list.clear()
	for w in worlds:
		if not (w is Dictionary):
			continue
		var world: Dictionary = w
		var id_value: String = str(world.get("id", ""))
		var name_value: String = str(world.get("name", "World"))
		var kind: String = str(world.get("kind", "personal"))
		_world_ids.append(id_value)
		_world_values.append(world)
		_world_list.add_item("%s  ·  %s" % [name_value, kind.to_upper()])
	if _world_ids.is_empty():
		_world_details.text = "No worlds yet. Create one or join with a code."
	elif _world_list.item_count > 0:
		_world_list.select(0)
		_on_world_selected(0)

func _on_world_limit_updated(used: int, limit_value: int) -> void:
	_world_usage.text = "Slots  %d / %d" % [used, limit_value]

func _on_world_selected(index: int) -> void:
	if index < 0 or index >= _world_values.size():
		return
	var world: Dictionary = _world_values[index]
	_world_details.text = "%s · updated %s" % [
		str(world.get("kind", "personal")).to_upper(),
		str(world.get("updated_at", "—"))
	]

func _create_world() -> void:
	if _world_name.text.strip_edges().is_empty():
		_on_request_failed("Enter a world name first.")
		return
	var kind: String = str(_world_kind.get_item_metadata(_world_kind.selected))
	_set_status("CREATING %s WORLD…" % kind.to_upper(), false)
	AccountManager.create_world(_world_name.text, kind, {
		"scarce_resources": bool(SettingsManager.get_value("gameplay", "scarce_resources", false)),
		"harsh_climate": bool(SettingsManager.get_value("gameplay", "harsh_climate", false)),
		"aggressive_enemies": bool(SettingsManager.get_value("gameplay", "aggressive_enemies", false)),
	})

func _join_world() -> void:
	if _invite_code.text.strip_edges().is_empty():
		_on_request_failed("Enter an invite code first.")
		return
	_set_status("VALIDATING INVITE…", false)
	AccountManager.join_world(_invite_code.text.to_upper())

func _continue_world() -> void:
	var selected: PackedInt32Array = _world_list.get_selected_items()
	if selected.is_empty() or selected[0] >= _world_ids.size():
		_on_request_failed("Select a world to enter.")
		return
	_continue_button.disabled = true
	_set_status("LOADING CHECKPOINT…", false)
	AccountManager.load_world(_world_ids[selected[0]])

func _on_world_loaded(_world: Dictionary, _snapshot: Dictionary) -> void:
	_set_status("ENTERING WORLD…", false)
	# fade out then start
	var tw := create_tween()
	tw.tween_property(_root, "modulate:a", 0.0, 0.35)
	tw.tween_callback(func() -> void: start_requested.emit())

func _start_guest() -> void:
	AccountManager.active_world_id = ""
	AccountManager.active_world.clear()
	AccountManager.pending_snapshot.clear()
	var tw := create_tween()
	tw.tween_property(_root, "modulate:a", 0.0, 0.30)
	tw.tween_callback(func() -> void: start_requested.emit())

func _show_control_choice() -> void:
	_control_scrim.visible = true
	_control_scrim.modulate.a = 0.0
	var tw := create_tween()
	tw.tween_property(_control_scrim, "modulate:a", 1.0, 0.25)

func _choose_control_mode(mode: String) -> void:
	InputProfile.set_mode(mode)
	var tw := create_tween()
	tw.tween_property(_control_scrim, "modulate:a", 0.0, 0.2)
	tw.tween_callback(func() -> void: _control_scrim.visible = false)
	_set_status("INPUT / %s" % mode.to_upper(), false)

func _on_control_mode_changed(mode: String) -> void:
	if _control_button != null:
		_control_button.text = "INPUT / %s" % mode.to_upper()

func _on_request_failed(message: String) -> void:
	_set_status(message, true)
	if _continue_button != null:
		_continue_button.disabled = false

func _on_service_status_changed(online: bool, detail: String) -> void:
	_service_dot.color = GOOD if online else BAD
	_service_text.add_theme_color_override("font_color", GOOD if online else BAD)
	_service_text.text = "SERVICE ONLINE" if online else "SERVICE OFFLINE"
	_service_text.tooltip_text = detail
	if not online:
		_set_status(detail, true)

func _set_status(message: String, is_error: bool) -> void:
	_status.text = message
	_status.add_theme_color_override("font_color", BAD if is_error else MUTED)
