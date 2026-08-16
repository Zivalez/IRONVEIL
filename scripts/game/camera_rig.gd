extends Node3D

## CameraRig — polished version
## Adds: screen shake, stronger velocity look-ahead, soft zoom easing,
## and optional mouse-drag rotation (hybrid control).

var target: Node3D
var yaw: float = deg_to_rad(45.0)
var target_yaw: float = deg_to_rad(45.0)
var distance: float = 18.0
var height: float = 16.0
var follow_damping: float = 12.0
var look_ahead_seconds: float = 0.22
var camera: Camera3D
var _last_occluder: Node = null

# Juice
var _shake_strength: float = 0.0
var _shake_time: float = 0.0
var _shake_duration: float = 0.0
var _zoom_target: float = 18.0
var _drag_rotating: bool = false
var _drag_last_x: float = 0.0

func _ready() -> void:
	add_to_group("camera_rig")
	if target != null:
		global_position = target.global_position
	camera = Camera3D.new()
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	_zoom_target = float(SettingsManager.get_value("graphics", "camera_zoom", 18.0))
	camera.size = _zoom_target
	camera.current = true
	add_child(camera)
	_update_camera_transform()
	SettingsManager.settings_changed.connect(_on_settings_changed)

func _process(delta: float) -> void:
	if target != null:
		var velocity_value: Vector3 = target.velocity if target is CharacterBody3D else Vector3.ZERO
		var look: float = look_ahead_seconds
		if bool(SettingsManager.get_value("accessibility", "reduced_motion", false)):
			look = 0.0
		var desired: Vector3 = target.global_position + Vector3(velocity_value.x, 0.0, velocity_value.z) * look
		desired.x = clampf(desired.x, -18.0, 374.0)
		desired.z = clampf(desired.z, -23.0, 23.0)
		var reduced_motion: bool = bool(SettingsManager.get_value("accessibility", "reduced_motion", false))
		var weight: float = 1.0 if reduced_motion else 1.0 - exp(-follow_damping * delta)
		global_position = global_position.lerp(desired, weight)

	# Smooth yaw
	yaw = lerp_angle(yaw, target_yaw, 1.0 - exp(-9.0 * delta))

	# Soft zoom
	if camera != null:
		camera.size = lerpf(camera.size, _zoom_target, 1.0 - exp(-8.0 * delta))

	# Decay shake
	if _shake_time > 0.0:
		_shake_time = maxf(_shake_time - delta, 0.0)
		var t: float = _shake_time / maxf(_shake_duration, 0.001)
		_shake_strength = lerpf(0.0, _shake_strength, t)
	else:
		_shake_strength = 0.0

	_update_camera_transform()
	_update_occlusion()

func _unhandled_input(event: InputEvent) -> void:
	if bool(SettingsManager.get_value("gameplay", "camera_rotation", true)):
		if event.is_action_pressed("camera_left"):
			target_yaw += deg_to_rad(90.0)
		elif event.is_action_pressed("camera_right"):
			target_yaw -= deg_to_rad(90.0)
		elif event.is_action_pressed("camera_reset"):
			target_yaw = deg_to_rad(45.0)

	# Mouse wheel zoom
	if event is InputEventMouseButton:
		var mouse_event: InputEventMouseButton = event as InputEventMouseButton
		if mouse_event.pressed:
			if mouse_event.button_index == MOUSE_BUTTON_WHEEL_UP:
				adjust_zoom(-1.2)
			elif mouse_event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
				adjust_zoom(1.2)
			# Middle mouse drag to rotate (hybrid)
			elif mouse_event.button_index == MOUSE_BUTTON_MIDDLE:
				_drag_rotating = true
				_drag_last_x = mouse_event.position.x
		else:
			if mouse_event.button_index == MOUSE_BUTTON_MIDDLE:
				_drag_rotating = false

	if event is InputEventMouseMotion and _drag_rotating:
		var motion: InputEventMouseMotion = event as InputEventMouseMotion
		var dx: float = motion.position.x - _drag_last_x
		_drag_last_x = motion.position.x
		if absf(dx) > 2.0:
			target_yaw -= deg_to_rad(90.0) * signf(dx)
			_drag_rotating = false  # snap 90° like keyboard

func rotate_step(direction: int) -> void:
	if bool(SettingsManager.get_value("gameplay", "camera_rotation", true)):
		target_yaw += deg_to_rad(90.0) * clampi(direction, -1, 1)

func adjust_zoom(delta: float) -> void:
	_zoom_target = clampf(_zoom_target + delta, 10.0, 28.0)
	SettingsManager.set_value("graphics", "camera_zoom", _zoom_target, false)

func snap_to_target() -> void:
	if target != null:
		global_position = target.global_position
		_update_camera_transform()

func transform_input(input: Vector2) -> Vector3:
	return Vector3(input.x, 0.0, input.y).rotated(Vector3.UP, yaw)

## Call this from combat / heavy impacts
func add_shake(strength: float = 0.35, duration: float = 0.22) -> void:
	if bool(SettingsManager.get_value("accessibility", "reduced_motion", false)):
		return
	if not bool(SettingsManager.get_value("accessibility", "camera_shake", true)):
		return
	_shake_strength = maxf(_shake_strength, strength)
	_shake_duration = maxf(_shake_duration, duration)
	_shake_time = _shake_duration

func _update_camera_transform() -> void:
	if camera == null:
		return
	var horizontal: Vector3 = Vector3(distance, 0.0, distance).rotated(Vector3.UP, yaw - deg_to_rad(45.0))
	var shake_offset: Vector3 = Vector3.ZERO
	if _shake_strength > 0.01:
		shake_offset = Vector3(
			randf_range(-1.0, 1.0) * _shake_strength,
			randf_range(-0.6, 0.6) * _shake_strength,
			randf_range(-1.0, 1.0) * _shake_strength
		)
	camera.position = Vector3(horizontal.x, height, horizontal.z) + shake_offset
	camera.look_at(global_position + Vector3.UP * 0.8 + shake_offset * 0.3, Vector3.UP)

func _update_occlusion() -> void:
	if target == null or camera == null or not is_inside_tree():
		return
	var query: PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.create(
		camera.global_position, target.global_position + Vector3.UP * 0.7, 2
	)
	var result: Dictionary = get_world_3d().direct_space_state.intersect_ray(query)
	var collider_value: Variant = result.get("collider", null)
	var next_occluder: Node = collider_value as Node if collider_value is Node else null
	if next_occluder == _last_occluder:
		return
	if _last_occluder != null and is_instance_valid(_last_occluder) and _last_occluder.has_method("set_faded"):
		_last_occluder.set_faded(false)
	_last_occluder = next_occluder
	if _last_occluder != null and _last_occluder.has_method("set_faded"):
		_last_occluder.set_faded(true)

func _on_settings_changed(section: String, key: String, value: Variant) -> void:
	if section == "graphics" and key == "camera_zoom" and camera != null:
		_zoom_target = float(value)
