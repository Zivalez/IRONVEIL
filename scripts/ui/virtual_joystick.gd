extends Control

signal vector_changed(value: Vector2)

var radius: float = 72.0
var knob_radius: float = 29.0
var _finger_index: int = -1
var _value: Vector2 = Vector2.ZERO

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	custom_minimum_size = Vector2(176, 176)
	queue_redraw()

func _gui_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		var touch: InputEventScreenTouch = event as InputEventScreenTouch
		if touch.pressed and _finger_index == -1:
			_finger_index = touch.index
			_update_from_position(touch.position)
			accept_event()
		elif not touch.pressed and touch.index == _finger_index:
			_finger_index = -1
			_set_value(Vector2.ZERO)
			accept_event()
	elif event is InputEventScreenDrag:
		var drag: InputEventScreenDrag = event as InputEventScreenDrag
		if drag.index == _finger_index:
			_update_from_position(drag.position)
			accept_event()
	elif event is InputEventMouseButton:
		var mouse_button: InputEventMouseButton = event as InputEventMouseButton
		if mouse_button.button_index == MOUSE_BUTTON_LEFT:
			_finger_index = 0 if mouse_button.pressed else -1
			if mouse_button.pressed:
				_update_from_position(mouse_button.position)
			else:
				_set_value(Vector2.ZERO)
			accept_event()
	elif event is InputEventMouseMotion and _finger_index == 0:
		_update_from_position((event as InputEventMouseMotion).position)
		accept_event()

func _notification(what: int) -> void:
	if what == NOTIFICATION_DRAW:
		var center: Vector2 = size * 0.5
		draw_circle(center, radius, Color(0.025, 0.035, 0.033, 0.56))
		draw_arc(center, radius, 0.0, TAU, 48, Color(0.63, 0.47, 0.25, 0.75), 3.0, true)
		draw_circle(center + _value * radius, knob_radius, Color(0.76, 0.48, 0.22, 0.84))
		draw_arc(center + _value * radius, knob_radius, 0.0, TAU, 32, Color(0.96, 0.79, 0.52, 0.92), 2.0, true)

func _update_from_position(local_position: Vector2) -> void:
	var delta: Vector2 = local_position - size * 0.5
	_set_value(delta / radius)

func _set_value(next_value: Vector2) -> void:
	_value = next_value.limit_length(1.0)
	if _value.length() < 0.12:
		_value = Vector2.ZERO
	vector_changed.emit(_value)
	queue_redraw()
