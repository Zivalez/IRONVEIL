extends Node

var _overlay: CanvasLayer
var _status_label: Label
var _detail_label: Label

func _ready() -> void:
	_build_boot_overlay()
	call_deferred("_start_gameplay")

func _build_boot_overlay() -> void:
	_overlay = CanvasLayer.new()
	_overlay.layer = 1000
	add_child(_overlay)

	var root := ColorRect.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.color = Color(0.018, 0.022, 0.022, 1.0)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_overlay.add_child(root)

	var center := VBoxContainer.new()
	center.set_anchors_preset(Control.PRESET_CENTER)
	center.position = Vector2(-310, -90)
	center.size = Vector2(620, 180)
	center.alignment = BoxContainer.ALIGNMENT_CENTER
	center.add_theme_constant_override("separation", 12)
	root.add_child(center)

	var title := Label.new()
	title.text = "IRONVEIL // BOOT SEQUENCE"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 24)
	center.add_child(title)

	_status_label = Label.new()
	_status_label.text = "Initializing field simulation..."
	_status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_status_label.add_theme_font_size_override("font_size", 17)
	center.add_child(_status_label)

	_detail_label = Label.new()
	_detail_label.text = ""
	_detail_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_detail_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_detail_label.custom_minimum_size = Vector2(600, 70)
	center.add_child(_detail_label)

func _start_gameplay() -> void:
	_status_label.text = "Loading gameplay scene..."
	var packed = ResourceLoader.load("res://scenes/main.tscn")
	if packed == null or not (packed is PackedScene):
		_show_failure("Gameplay scene could not be loaded.", "Open the browser developer console (F12) for the exact Godot parser/resource error.")
		return

	var gameplay := (packed as PackedScene).instantiate()
	if gameplay == null:
		_show_failure("Gameplay scene could not be instantiated.", "The Web export is present, but the game scene failed during startup.")
		return

	add_child(gameplay)
	await get_tree().process_frame
	await get_tree().process_frame

	var has_player := not get_tree().get_nodes_in_group("players").is_empty()
	var has_camera := get_viewport().get_camera_3d() != null
	if not has_player or not has_camera:
		var details: Array[String] = []
		if not has_player:
			details.append("player node missing")
		if not has_camera:
			details.append("active Camera3D missing")
		_show_failure("Gameplay startup did not complete.", "Detected: %s. Check F12 Console for the first Godot error." % ", ".join(details))
		return

	print("IRONVEIL_BOOT_OK: gameplay scene, player, and active camera initialized")
	_overlay.queue_free()

func _show_failure(title: String, details: String) -> void:
	push_error("IRONVEIL_BOOT_FAILURE: %s %s" % [title, details])
	_status_label.text = "BOOT FAILURE // " + title
	_status_label.modulate = Color(0.95, 0.55, 0.42)
	_detail_label.text = details
