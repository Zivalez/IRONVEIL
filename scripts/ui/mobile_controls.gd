extends CanvasLayer

const VirtualJoystickScript = preload("res://scripts/ui/virtual_joystick.gd")

var player: Node
var camera_rig: Node
var hud: CanvasLayer
var _root: Control
var _controls_root: Control
var _rotate_notice: PanelContainer
var _gesture_fingers: Dictionary = {}
var _gesture_start: Dictionary = {}
var _last_pinch_distance: float = 0.0
var _modal_open: bool = false

func configure(player_value: Node, camera_value: Node, hud_value: CanvasLayer) -> void:
	player = player_value
	camera_rig = camera_value
	hud = hud_value

func _ready() -> void:
	layer = 80
	_build_ui()
	get_viewport().size_changed.connect(_apply_layout)
	InputProfile.mode_changed.connect(_on_mode_changed)
	if hud != null and hud.has_signal("modal_state_changed"):
		hud.modal_state_changed.connect(_on_modal_state_changed)
	_on_mode_changed(InputProfile.resolved_mode())

func _build_ui() -> void:
	_root = Control.new()
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_root)

	_controls_root = Control.new()
	_controls_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_controls_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(_controls_root)

	var joystick: Control = VirtualJoystickScript.new()
	joystick.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	joystick.position = Vector2(22, -206)
	joystick.size = Vector2(184, 184)
	joystick.vector_changed.connect(InputProfile.set_movement)
	_controls_root.add_child(joystick)

	var actions := Control.new()
	actions.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	actions.position = Vector2(-278, -238)
	actions.size = Vector2(258, 216)
	actions.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_controls_root.add_child(actions)
	var attack := _action_button("STRIKE", Vector2(146, 100), Vector2(104, 104), true)
	attack.pressed.connect(_queue_action.bind("attack"))
	actions.add_child(attack)
	var interact := _action_button("USE", Vector2(56, 34), Vector2(92, 82), false)
	interact.pressed.connect(_queue_action.bind("interact"))
	actions.add_child(interact)
	var sprint := _action_button("RUN", Vector2(32, 128), Vector2(94, 72), false)
	sprint.button_down.connect(InputProfile.set_sprint.bind(true))
	sprint.button_up.connect(InputProfile.set_sprint.bind(false))
	actions.add_child(sprint)

	var quick_bar := HBoxContainer.new()
	quick_bar.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	quick_bar.position = Vector2(-410, 18)
	quick_bar.size = Vector2(392, 50)
	quick_bar.add_theme_constant_override("separation", 8)
	quick_bar.mouse_filter = Control.MOUSE_FILTER_PASS
	_controls_root.add_child(quick_bar)
	for entry in [["PACK", "inventory"], ["JOURNAL", "journal"], ["ROOM", "lobby"], ["MENU", "settings"]]:
		var button := _action_button(str(entry[0]), Vector2.ZERO, Vector2(90, 46), false)
		button.pressed.connect(_toggle_hud.bind(str(entry[1])))
		quick_bar.add_child(button)

	var utility := HBoxContainer.new()
	utility.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	utility.position = Vector2(-382, -78)
	utility.size = Vector2(190, 54)
	utility.add_theme_constant_override("separation", 8)
	utility.mouse_filter = Control.MOUSE_FILTER_PASS
	_controls_root.add_child(utility)
	for entry in [["FOOD", "eat_quick"], ["AID", "medical_quick"]]:
		var button := _action_button(str(entry[0]), Vector2.ZERO, Vector2(88, 48), false)
		button.pressed.connect(_queue_action.bind(str(entry[1])))
		utility.add_child(button)

	_rotate_notice = PanelContainer.new()
	_rotate_notice.set_anchors_preset(Control.PRESET_CENTER)
	_rotate_notice.position = Vector2(-240, -90)
	_rotate_notice.size = Vector2(480, 180)
	_rotate_notice.add_theme_stylebox_override("panel", _panel_style(0.98))
	var notice := Label.new()
	notice.text = "ROTATE DEVICE\n\nIRONVEIL mobile play is designed for landscape orientation."
	notice.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	notice.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	notice.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	notice.add_theme_font_size_override("font_size", 22)
	_rotate_notice.add_child(notice)
	_root.add_child(_rotate_notice)

func _input(event: InputEvent) -> void:
	if not visible or not InputProfile.is_touch_mode():
		return
	if event is InputEventScreenTouch:
		var touch: InputEventScreenTouch = event as InputEventScreenTouch
		if touch.pressed:
			if _is_gesture_area(touch.position):
				_gesture_fingers[touch.index] = touch.position
				_gesture_start[touch.index] = touch.position
		else:
			if _gesture_start.has(touch.index) and _gesture_fingers.has(touch.index):
				var travel: Vector2 = (_gesture_fingers[touch.index] as Vector2) - (_gesture_start[touch.index] as Vector2)
				if absf(travel.x) > 88.0 and absf(travel.x) > absf(travel.y) * 1.4 and camera_rig != null and camera_rig.has_method("rotate_step"):
					camera_rig.rotate_step(-1 if travel.x > 0.0 else 1)
			_gesture_fingers.erase(touch.index)
			_gesture_start.erase(touch.index)
			_last_pinch_distance = 0.0
	elif event is InputEventScreenDrag:
		var drag: InputEventScreenDrag = event as InputEventScreenDrag
		if _gesture_fingers.has(drag.index):
			_gesture_fingers[drag.index] = drag.position
		if _gesture_fingers.size() == 2:
			var points: Array = _gesture_fingers.values()
			var distance: float = (points[0] as Vector2).distance_to(points[1] as Vector2)
			if _last_pinch_distance > 0.0 and camera_rig != null and camera_rig.has_method("adjust_zoom"):
				camera_rig.adjust_zoom((_last_pinch_distance - distance) * 0.025)
			_last_pinch_distance = distance

func _is_gesture_area(position_value: Vector2) -> bool:
	var viewport_size: Vector2 = get_viewport().get_visible_rect().size
	if position_value.y > viewport_size.y - 250.0:
		return false
	if position_value.y < 86.0 and position_value.x > viewport_size.x - 430.0:
		return false
	return true

func _queue_action(action: String) -> void:
	InputProfile.queue_action(action)
	AudioManager.play_ui("press")

func _toggle_hud(section: String) -> void:
	if hud != null and hud.has_method("mobile_toggle"):
		hud.mobile_toggle(section)

func _on_mode_changed(mode: String) -> void:
	visible = mode == InputProfile.MODE_TOUCH
	_apply_layout()

func _apply_layout() -> void:
	if _controls_root == null or _rotate_notice == null:
		return
	var viewport_size: Vector2 = get_viewport().get_visible_rect().size
	var portrait: bool = viewport_size.y > viewport_size.x * 1.05
	_controls_root.visible = not portrait and not _modal_open
	_rotate_notice.visible = portrait and visible

func _on_modal_state_changed(open: bool) -> void:
	_modal_open = open
	InputProfile.clear_touch_state()
	_apply_layout()

func _action_button(text_value: String, position_value: Vector2, size_value: Vector2, primary: bool) -> Button:
	var button := Button.new()
	button.text = text_value
	button.position = position_value
	button.size = size_value
	button.custom_minimum_size = size_value
	button.focus_mode = Control.FOCUS_NONE
	button.add_theme_font_size_override("font_size", 16 if primary else 14)
	var style: StyleBoxFlat = _panel_style(0.84 if primary else 0.68)
	style.bg_color = Color(0.52, 0.27, 0.10, 0.84) if primary else Color(0.035, 0.050, 0.046, 0.68)
	button.add_theme_stylebox_override("normal", style)
	var pressed_style: StyleBoxFlat = style.duplicate() as StyleBoxFlat
	pressed_style.bg_color = Color(0.78, 0.43, 0.16, 0.94)
	button.add_theme_stylebox_override("pressed", pressed_style)
	return button

func _panel_style(alpha: float) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.025, 0.034, 0.032, alpha)
	style.border_color = Color(0.69, 0.48, 0.24, minf(alpha + 0.1, 1.0))
	style.set_border_width_all(2)
	style.set_corner_radius_all(12)
	style.set_content_margin_all(12.0)
	return style
