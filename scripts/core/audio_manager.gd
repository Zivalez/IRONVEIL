extends Node

## AudioManager — UI cues + gameplay procedural fallbacks + ambient beds
## File-based cues play when present; otherwise short procedural tones keep feedback alive.

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

# Gameplay cue names (procedural if no file)
const GAMEPLAY_TONES := {
	"attack": {"freq": 180.0, "ms": 45, "vol": 0.22},
	"hit": {"freq": 320.0, "ms": 55, "vol": 0.28},
	"miss": {"freq": 140.0, "ms": 35, "vol": 0.14},
	"interact": {"freq": 420.0, "ms": 40, "vol": 0.18},
	"pickup": {"freq": 560.0, "ms": 50, "vol": 0.20},
	"damage": {"freq": 110.0, "ms": 90, "vol": 0.30},
	"ui_soft": {"freq": 480.0, "ms": 25, "vol": 0.12},
}

var _ambient_player: AudioStreamPlayer
var _ambient_region: String = ""

func play_ui(cue: String) -> void:
	if not CUES.has(cue):
		_play_tone("ui_soft")
		return
	var path: String = BASE_PATH + str(CUES[cue])
	if ResourceLoader.exists(path):
		_play_stream(path, "SFX", 0.0)
	else:
		_play_tone("ui_soft")

func play_game(cue: String) -> void:
	# Prefer real files under audio/game/ if you add them later
	var file_path := "res://audio/game/%s.ogg" % cue
	if ResourceLoader.exists(file_path):
		_play_stream(file_path, "SFX", 0.0)
		return
	_play_tone(cue)

func set_ambient_region(region_id: String) -> void:
	if region_id == _ambient_region:
		return
	_ambient_region = region_id
	_refresh_ambient()

func _refresh_ambient() -> void:
	if _ambient_player != null and is_instance_valid(_ambient_player):
		_ambient_player.stop()
		_ambient_player.queue_free()
		_ambient_player = null
	var path := "res://audio/ambient/%s.ogg" % _ambient_region
	if not ResourceLoader.exists(path):
		# Soft procedural bed so world is never fully silent
		_start_procedural_ambient()
		return
	var stream: AudioStream = ResourceLoader.load(path) as AudioStream
	if stream == null:
		return
	_ambient_player = AudioStreamPlayer.new()
	_ambient_player.bus = "Ambient"
	_ambient_player.stream = stream
	_ambient_player.volume_db = -6.0
	add_child(_ambient_player)
	_ambient_player.play()

func _start_procedural_ambient() -> void:
	# Very quiet low noise bed — better than total silence
	var gen := AudioStreamGenerator.new()
	gen.mix_rate = 22050
	gen.buffer_length = 0.5
	_ambient_player = AudioStreamPlayer.new()
	_ambient_player.bus = "Ambient"
	_ambient_player.stream = gen
	_ambient_player.volume_db = -28.0
	add_child(_ambient_player)
	_ambient_player.play()
	var playback: AudioStreamGeneratorPlayback = _ambient_player.get_stream_playback() as AudioStreamGeneratorPlayback
	if playback == null:
		return
	# Fill a short buffer of soft noise; it will loop via continuous fill in process if needed
	_fill_noise(playback, 0.4)

func _fill_noise(playback: AudioStreamGeneratorPlayback, seconds: float) -> void:
	var rate := 22050.0
	var frames: int = int(seconds * rate)
	for i in range(frames):
		var n: float = (randf() * 2.0 - 1.0) * 0.04
		playback.push_frame(Vector2(n, n))

func _play_stream(path: String, bus: String, volume_db: float) -> void:
	var stream: AudioStream = ResourceLoader.load(path) as AudioStream
	if stream == null:
		return
	var player := AudioStreamPlayer.new()
	player.bus = bus
	player.stream = stream
	player.volume_db = volume_db
	add_child(player)
	player.finished.connect(player.queue_free)
	player.play()

func _play_tone(cue: String) -> void:
	if not GAMEPLAY_TONES.has(cue):
		cue = "ui_soft"
	var cfg: Dictionary = GAMEPLAY_TONES[cue]
	var freq: float = float(cfg.get("freq", 300.0))
	var ms: float = float(cfg.get("ms", 40.0))
	var vol: float = float(cfg.get("vol", 0.2))
	var sample_rate := 22050.0
	var frames: int = int((ms / 1000.0) * sample_rate)
	var data := PackedVector2Array()
	data.resize(frames)
	for i in range(frames):
		var t: float = float(i) / sample_rate
		var env: float = 1.0 - (float(i) / float(maxi(frames, 1)))
		env = env * env
		var s: float = sin(TAU * freq * t) * vol * env
		data[i] = Vector2(s, s)
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = int(sample_rate)
	wav.stereo = true
	var bytes := PackedByteArray()
	bytes.resize(frames * 4)
	for i in range(frames):
		var sample: int = int(clampf(data[i].x, -1.0, 1.0) * 32767.0)
		bytes[i * 4] = sample & 0xFF
		bytes[i * 4 + 1] = (sample >> 8) & 0xFF
		bytes[i * 4 + 2] = sample & 0xFF
		bytes[i * 4 + 3] = (sample >> 8) & 0xFF
	wav.data = bytes
	var player := AudioStreamPlayer.new()
	player.bus = "SFX"
	player.stream = wav
	add_child(player)
	player.finished.connect(player.queue_free)
	player.play()
