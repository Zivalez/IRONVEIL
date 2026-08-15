extends Node3D

var target: Node3D
var yaw: float = deg_to_rad(45.0)
var distance: float = 18.0
var height: float = 16.0
var camera: Camera3D
var _last_occluder: Node = null

func _ready() -> void:
	camera = Camera3D.new()
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = float(SettingsManager.get_value("graphics", "camera_zoom", 18.0))
	camera.current = true
	add_child(camera)
	_update_camera_transform()
	SettingsManager.settings_changed.connect(_on_settings_changed)

func _process(_delta: float) -> void:
	if target != null:
		global_position = target.global_position
	_update_camera_transform()
	_update_occlusion()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey:
		var key_event: InputEventKey = event as InputEventKey
		if key_event.pressed and not key_event.echo:
			if key_event.keycode == KEY_Q:
				yaw += deg_to_rad(90.0)
			elif key_event.keycode == KEY_E:
				yaw -= deg_to_rad(90.0)
	if event is InputEventMouseButton:
		var mouse_event: InputEventMouseButton = event as InputEventMouseButton
		if mouse_event.pressed:
			if mouse_event.button_index == MOUSE_BUTTON_WHEEL_UP:
				camera.size = maxf(10.0, camera.size - 1.0)
			elif mouse_event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
				camera.size = minf(28.0, camera.size + 1.0)

func transform_input(input: Vector2) -> Vector3:
	var local_direction: Vector3 = Vector3(input.x, 0.0, input.y)
	return local_direction.rotated(Vector3.UP, yaw)

func _update_camera_transform() -> void:
	if camera == null:
		return
	var horizontal: Vector3 = Vector3(distance, 0.0, distance).rotated(Vector3.UP, yaw - deg_to_rad(45.0))
	camera.position = Vector3(horizontal.x, height, horizontal.z)
	camera.look_at(Vector3.ZERO, Vector3.UP)

func _update_occlusion() -> void:
	if target == null or camera == null or not is_inside_tree():
		return
	var query: PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.create(camera.global_position, target.global_position + Vector3.UP * 0.7, 2)
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
		camera.size = float(value)
