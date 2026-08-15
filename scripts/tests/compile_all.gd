extends SceneTree

const SCRIPT_PATHS: Array[String] = [
	"res://scripts/core/mechanical_network.gd",
	"res://scripts/core/tick_manager.gd",
	"res://scripts/data/data_registry.gd",
	"res://scripts/core/settings_manager.gd",
	"res://scripts/core/game_state.gd",
	"res://scripts/core/save_manager.gd",
	"res://scripts/core/audio_manager.gd",
	"res://scripts/core/chunk_manager.gd",
	"res://scripts/game/player.gd",
	"res://scripts/game/camera_rig.gd",
	"res://scripts/game/pickup.gd",
	"res://scripts/game/workshop_sign.gd",
	"res://scripts/game/water_wheel.gd",
	"res://scripts/game/gear_assembly.gd",
	"res://scripts/game/mechanical_saw.gd",
	"res://scripts/game/mechanical_press.gd",
	"res://scripts/game/enemy.gd",
	"res://scripts/game/occluder.gd",
	"res://scripts/ui/hud.gd",
	"res://scripts/core/boot.gd",
	"res://scripts/game/main.gd",
]

const SCENE_PATHS: Array[String] = [
	"res://scenes/boot.tscn",
	"res://scenes/main.tscn",
]

func _init() -> void:
	var failures: Array[String] = []
	for path in SCRIPT_PATHS:
		print("IRONVEIL_COMPILE_CHECK: ", path)
		var resource: Resource = ResourceLoader.load(path)
		if resource == null:
			failures.append("Could not compile/load script: %s" % path)

	for path in SCENE_PATHS:
		print("IRONVEIL_SCENE_CHECK: ", path)
		var resource: Resource = ResourceLoader.load(path)
		if resource == null or not (resource is PackedScene):
			failures.append("Could not parse/load scene: %s" % path)

	if failures.is_empty():
		print("IRONVEIL ALL-SCRIPT COMPILE GATE: PASS")
		quit(0)
		return

	for failure in failures:
		push_error(failure)
	print("IRONVEIL ALL-SCRIPT COMPILE GATE: FAIL (%d)" % failures.size())
	quit(1)
