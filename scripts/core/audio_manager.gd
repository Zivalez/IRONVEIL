extends Node

const BASE_PATH := "res://audio/ui/mechanical/"
const CUES := {
	"hover": "hover.ogg",
	"press": "press.ogg",
	"complete": "complete.ogg",
	"error": "error.ogg",
	"toggle_on": "toggle-on.ogg",
	"toggle_off": "toggle-off.ogg",
	"open": "open.ogg",
	"close": "close.ogg",
}

func play_ui(cue: String) -> void:
	if not CUES.has(cue):
		return
	var path := BASE_PATH + str(CUES[cue])
	if not ResourceLoader.exists(path):
		return
	var stream = ResourceLoader.load(path)
	if stream == null:
		return
	var player := AudioStreamPlayer.new()
	player.bus = "SFX"
	player.stream = stream
	add_child(player)
	player.finished.connect(player.queue_free)
	player.play()
