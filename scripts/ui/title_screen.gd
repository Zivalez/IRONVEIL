extends CanvasLayer

signal start_requested()

var _status: Label
var _account_label: Label
var _auth_panel: PanelContainer
var _world_panel: PanelContainer
var _email: LineEdit
var _password: LineEdit
var _display_name: LineEdit
var _world_name: LineEdit
var _invite_code: LineEdit
var _world_list: ItemList
var _world_ids: Array[String] = []
var _continue_button: Button

func _ready() -> void:
	layer = 900
	_build()
	AccountManager.auth_changed.connect(_on_auth_changed)
	AccountManager.worlds_updated.connect(_on_worlds_updated)
	AccountManager.world_loaded.connect(_on_world_loaded)
	AccountManager.request_failed.connect(_on_request_failed)
	if AccountManager.is_authenticated():
		_on_auth_changed(true, AccountManager.account)
		AccountManager.refresh_session()
	else:
		_show_auth()

func _build() -> void:
	var background := ColorRect.new()
	background.set_anchors_preset(Control.PRESET_FULL_RECT)
	background.color = Color(0.018, 0.024, 0.023, 1.0)
	add_child(background)
	var rail := ColorRect.new()
	rail.set_anchors_preset(Control.PRESET_FULL_RECT)
	rail.offset_left = 70.0
	rail.offset_right = -70.0
	rail.color = Color(0.055, 0.064, 0.060, 1.0)
	rail.mouse_filter = Control.MOUSE_FILTER_IGNORE
	background.add_child(rail)
	var accent := ColorRect.new()
	accent.position = Vector2(70, 0)
	accent.size = Vector2(5, 720)
	accent.color = Color(0.78, 0.47, 0.19, 1.0)
	background.add_child(accent)

	var header := VBoxContainer.new()
	header.position = Vector2(112, 82)
	header.size = Vector2(560, 190)
	header.add_theme_constant_override("separation", 8)
	background.add_child(header)
	var eyebrow := Label.new()
	eyebrow.text = "FIELD SYSTEM // ONLINE"
	eyebrow.modulate = Color(0.78, 0.58, 0.34)
	eyebrow.add_theme_font_size_override("font_size", 14)
	header.add_child(eyebrow)
	var title := Label.new()
	title.text = "IRONVEIL"
	title.add_theme_font_size_override("font_size", 58)
	title.modulate = Color(0.92, 0.88, 0.76)
	header.add_child(title)
	var rule := ColorRect.new()
	rule.custom_minimum_size = Vector2(430, 2)
	rule.color = Color(0.42, 0.48, 0.42)
	header.add_child(rule)
	var subtitle := Label.new()
	subtitle.text = "MASTERY THROUGH UNDERSTANDING"
	subtitle.add_theme_font_size_override("font_size", 17)
	subtitle.modulate = Color(0.62, 0.72, 0.64)
	header.add_child(subtitle)
	var description := Label.new()
	description.text = "Survive. Observe. Build the systems that bring a broken world back online."
	description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	description.custom_minimum_size = Vector2(520, 50)
	header.add_child(description)

	_account_label = Label.new()
	_account_label.position = Vector2(112, 285)
	_account_label.size = Vector2(520, 28)
	_account_label.modulate = Color(0.60, 0.68, 0.61)
	background.add_child(_account_label)

	_auth_panel = _panel(Vector2(700, 74), Vector2(470, 540))
	background.add_child(_auth_panel)
	_build_auth_panel()
	_world_panel = _panel(Vector2(700, 74), Vector2(470, 570))
	background.add_child(_world_panel)
	_build_world_panel()

	var guest := Button.new()
	guest.text = "ENTER AS GUEST // LOCAL WORLD"
	guest.position = Vector2(112, 352)
	guest.size = Vector2(480, 54)
	_style_button(guest, true)
	guest.pressed.connect(_start_guest)
	background.add_child(guest)
	var guest_note := Label.new()
	guest_note.position = Vector2(112, 416)
	guest_note.size = Vector2(500, 76)
	guest_note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	guest_note.text = "Guest progress remains on this device. Sign in for server checkpoints, shared worlds, and cross-browser continuation."
	guest_note.modulate = Color(0.57, 0.61, 0.57)
	background.add_child(guest_note)

	_status = Label.new()
	_status.position = Vector2(112, 610)
	_status.size = Vector2(540, 58)
	_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_status.text = "WORLD SERVICE // READY"
	_status.modulate = Color(0.68, 0.74, 0.65)
	background.add_child(_status)

func _build_auth_panel() -> void:
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 12)
	_auth_panel.add_child(box)
	var heading := Label.new()
	heading.text = "ACCOUNT ACCESS"
	heading.add_theme_font_size_override("font_size", 23)
	box.add_child(heading)
	var note := Label.new()
	note.text = "One account keeps personal and shared worlds available on every browser."
	note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(note)
	_display_name = _field(box, "DISPLAY NAME", "Field Engineer", false)
	_email = _field(box, "EMAIL", "survivor@example.com", false)
	_password = _field(box, "PASSWORD", "10 characters minimum", true)
	var sign_in := Button.new()
	sign_in.text = "SIGN IN"
	_style_button(sign_in, true)
	sign_in.pressed.connect(_sign_in)
	box.add_child(sign_in)
	var register := Button.new()
	register.text = "CREATE ACCOUNT"
	_style_button(register, false)
	register.pressed.connect(_register)
	box.add_child(register)

func _build_world_panel() -> void:
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 10)
	_world_panel.add_child(box)
	var heading := Label.new()
	heading.text = "PERSISTENT WORLDS"
	heading.add_theme_font_size_override("font_size", 23)
	box.add_child(heading)
	_world_list = ItemList.new()
	_world_list.custom_minimum_size = Vector2(420, 230)
	_world_list.item_selected.connect(_on_world_selected)
	box.add_child(_world_list)
	_world_name = _field(box, "NEW WORLD NAME", "The Copper Meridian", false)
	var creation := HBoxContainer.new()
	box.add_child(creation)
	var personal := Button.new()
	personal.text = "NEW PERSONAL"
	_style_button(personal, false)
	personal.pressed.connect(_create_world.bind("personal"))
	creation.add_child(personal)
	var shared := Button.new()
	shared.text = "NEW SHARED"
	_style_button(shared, false)
	shared.pressed.connect(_create_world.bind("shared"))
	creation.add_child(shared)
	_invite_code = _field(box, "JOIN CODE", "8-character invite", false)
	var join := Button.new()
	join.text = "JOIN SHARED WORLD"
	_style_button(join, false)
	join.pressed.connect(_join_world)
	box.add_child(join)
	_continue_button = Button.new()
	_continue_button.text = "CONTINUE SELECTED WORLD"
	_continue_button.disabled = true
	_style_button(_continue_button, true)
	_continue_button.pressed.connect(_continue_world)
	box.add_child(_continue_button)
	var logout := Button.new()
	logout.text = "SIGN OUT"
	_style_button(logout, false)
	logout.pressed.connect(AccountManager.logout)
	box.add_child(logout)

func _field(parent: VBoxContainer, title: String, placeholder: String, secret: bool) -> LineEdit:
	var label := Label.new()
	label.text = title
	label.modulate = Color(0.65, 0.72, 0.64)
	parent.add_child(label)
	var edit := LineEdit.new()
	edit.placeholder_text = placeholder
	edit.secret = secret
	edit.custom_minimum_size.y = 38
	parent.add_child(edit)
	return edit

func _panel(position_value: Vector2, size_value: Vector2) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.position = position_value
	panel.size = size_value
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.035, 0.043, 0.040, 0.98)
	style.border_color = Color(0.25, 0.31, 0.27, 1.0)
	style.set_border_width_all(1)
	style.content_margin_left = 24
	style.content_margin_right = 24
	style.content_margin_top = 22
	style.content_margin_bottom = 22
	panel.add_theme_stylebox_override("panel", style)
	return panel

func _style_button(button: Button, primary: bool) -> void:
	button.custom_minimum_size = Vector2(190, 42)
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.60, 0.34, 0.13) if primary else Color(0.09, 0.12, 0.105)
	style.border_color = Color(0.82, 0.54, 0.25) if primary else Color(0.30, 0.38, 0.32)
	style.set_border_width_all(1)
	style.set_corner_radius_all(2)
	style.content_margin_left = 14
	style.content_margin_right = 14
	button.add_theme_stylebox_override("normal", style)

func _show_auth() -> void:
	_auth_panel.visible = true
	_world_panel.visible = false
	_account_label.text = "OFFLINE IDENTITY // GUEST ACCESS AVAILABLE"

func _on_auth_changed(authenticated: bool, account: Dictionary) -> void:
	if not authenticated:
		_show_auth()
		return
	_auth_panel.visible = false
	_world_panel.visible = true
	_account_label.text = "SIGNED IN // %s" % str(account.get("display_name", "SURVIVOR")).to_upper()
	_status.text = "ACCOUNT VERIFIED // FETCHING WORLDS"

func _on_worlds_updated(world_values: Array) -> void:
	_world_list.clear()
	_world_ids.clear()
	for value in world_values:
		if not (value is Dictionary):
			continue
		var world: Dictionary = value as Dictionary
		_world_ids.append(str(world.get("id", "")))
		var hours: float = float(world.get("playtime_seconds", 0)) / 3600.0
		_world_list.add_item("%s  //  %s  //  %.1fh  //  %s" % [str(world.get("name", "World")), str(world.get("kind", "personal")).to_upper(), hours, str(world.get("region", "green_hollow")).replace("_", " ").to_upper()])
	_status.text = "WORLD ARCHIVE // %d AVAILABLE" % _world_ids.size()
	if not _world_ids.is_empty():
		_world_list.select(0)
		_continue_button.disabled = false

func _on_world_selected(_index: int) -> void:
	_continue_button.disabled = false

func _sign_in() -> void:
	_status.text = "AUTHENTICATING..."
	AccountManager.login(_email.text, _password.text)

func _register() -> void:
	_status.text = "CREATING ACCOUNT..."
	AccountManager.register_account(_email.text, _password.text, _display_name.text)

func _create_world(kind: String) -> void:
	_status.text = "CREATING %s WORLD..." % kind.to_upper()
	AccountManager.create_world(_world_name.text, kind, {
		"scarce_resources": bool(SettingsManager.get_value("gameplay", "scarce_resources", false)),
		"harsh_climate": bool(SettingsManager.get_value("gameplay", "harsh_climate", false)),
		"aggressive_enemies": bool(SettingsManager.get_value("gameplay", "aggressive_enemies", false)),
	})

func _join_world() -> void:
	_status.text = "VALIDATING INVITE..."
	AccountManager.join_world(_invite_code.text)

func _continue_world() -> void:
	var selected: PackedInt32Array = _world_list.get_selected_items()
	if selected.is_empty() or selected[0] >= _world_ids.size():
		_on_request_failed("Select a world to continue.")
		return
	_continue_button.disabled = true
	_status.text = "LOADING AUTHORITATIVE CHECKPOINT..."
	AccountManager.load_world(_world_ids[selected[0]])

func _on_world_loaded(_world: Dictionary, _snapshot: Dictionary) -> void:
	_status.text = "CHECKPOINT VERIFIED // ENTERING WORLD"
	start_requested.emit()

func _start_guest() -> void:
	AccountManager.active_world_id = ""
	AccountManager.active_world.clear()
	AccountManager.pending_snapshot.clear()
	start_requested.emit()

func _on_request_failed(message: String) -> void:
	_status.text = "ATTENTION // " + message
	_status.modulate = Color(0.92, 0.48, 0.34)
	if _continue_button != null:
		_continue_button.disabled = false
