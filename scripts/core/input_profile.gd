extends Node

signal mode_changed(mode: String)

const MODE_AUTO := "auto"
const MODE_DESKTOP := "desktop"
const MODE_TOUCH := "touch"

var movement_vector: Vector2 = Vector2.ZERO
var sprint_held: bool = false
var _queued_actions: Array[String] = []

func _ready() -> void:
	get_viewport().size_changed.connect(_on_viewport_size_changed)

func is_touch_capable() -> bool:
	if DisplayServer.is_touchscreen_available():
		return true
	if OS.get_name() == "Web" and Engine.has_singleton("JavaScriptBridge"):
		var bridge: Object = Engine.get_singleton("JavaScriptBridge")
		var touch_points: Variant = bridge.call("eval", "navigator.maxTouchPoints || 0")
		var coarse_pointer: Variant = bridge.call("eval", "window.matchMedia && window.matchMedia('(pointer: coarse)').matches")
		return int(touch_points) > 0 or bool(coarse_pointer)
	return false

func selected_mode() -> String:
	return str(SettingsManager.get_value("controls", "input_mode", MODE_AUTO))

func resolved_mode() -> String:
	var selected: String = selected_mode()
	if selected == MODE_TOUCH or selected == MODE_DESKTOP:
		return selected
	return MODE_TOUCH if is_touch_capable() else MODE_DESKTOP

func is_touch_mode() -> bool:
	return resolved_mode() == MODE_TOUCH

func should_offer_first_choice() -> bool:
	return selected_mode() == MODE_AUTO and is_touch_capable()

func set_mode(mode: String) -> void:
	if mode not in [MODE_AUTO, MODE_DESKTOP, MODE_TOUCH]:
		return
	SettingsManager.set_value("controls", "input_mode", mode, false)
	if mode != MODE_TOUCH:
		clear_touch_state()
	mode_changed.emit(resolved_mode())

func set_movement(value: Vector2) -> void:
	movement_vector = value.limit_length(1.0) if is_touch_mode() else Vector2.ZERO

func set_sprint(pressed: bool) -> void:
	sprint_held = pressed and is_touch_mode()

func queue_action(action: String) -> void:
	if is_touch_mode() and not _queued_actions.has(action):
		_queued_actions.append(action)

func consume_action(action: String) -> bool:
	var index: int = _queued_actions.find(action)
	if index == -1:
		return false
	_queued_actions.remove_at(index)
	return true

func clear_touch_state() -> void:
	movement_vector = Vector2.ZERO
	sprint_held = false
	_queued_actions.clear()

func _on_viewport_size_changed() -> void:
	if selected_mode() == MODE_AUTO:
		mode_changed.emit(resolved_mode())
