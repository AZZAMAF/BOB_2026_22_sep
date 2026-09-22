## audio_manager.gd
## Manages all audio playback. Autoload singleton: "AudioManager"
## Audio files go in res://assets/audio/. Filenames must match keys below.
extends Node

# ─── SFX Map ─────────────────────────────────────────────────────────────────
# Maps logical name → filename under res://assets/audio/
const SFX_FILES := {
	"dial_click":         "dial_click.wav",
	"blue_button":        "blue_button.wav",
	"red_button":         "red_button.wav",
	"low_power_warning":  "low_power_warning.wav",
	"decision_beep":      "decision_beep.wav",
	"startup_init":       "startup_init.wav",
	"collapse":           "collapse.wav",
}

const MUSIC_FILES := {
	"ambient":            "ambient_loop.ogg",
	"ending_A":           "ending_hopeful.ogg",
	"ending_B":           "ending_melancholic.ogg",
	"ending_C":           "ending_catastrophic.ogg",
}

# ─── Players ─────────────────────────────────────────────────────────────────
var _sfx_players: Array[AudioStreamPlayer] = []
var _music_player: AudioStreamPlayer = null
var _muted: bool = false

const SFX_POOL_SIZE := 8

# ─── Lifecycle ───────────────────────────────────────────────────────────────
func _ready() -> void:
	# Create SFX pool
	for i in SFX_POOL_SIZE:
		var p := AudioStreamPlayer.new()
		p.bus = "SFX"
		add_child(p)
		_sfx_players.append(p)

	# Create music player
	_music_player = AudioStreamPlayer.new()
	_music_player.bus = "Music"
	_music_player.autoplay = false
	add_child(_music_player)

	# Start ambient music when monitoring begins
	GameManager.state_changed.connect(_on_state_changed)

# ─── Public API ───────────────────────────────────────────────────────────────

func play_sfx(name: String) -> void:
	if _muted:
		return
	var filename: String = SFX_FILES.get(name, "")
	if filename.is_empty():
		push_warning("AudioManager: unknown sfx '%s'" % name)
		return
	var path: String = "res://assets/audio/" + filename
	if not ResourceLoader.exists(path):
		# File not yet created (placeholder); skip silently during dev
		return
	var stream: AudioStream = load(path)
	if stream == null:
		return
	var player: AudioStreamPlayer = _get_free_sfx_player()
	if player:
		player.stream = stream
		player.play()

func play_music(name: String) -> void:
	if _muted:
		return
	var filename: String = MUSIC_FILES.get(name, "")
	if filename.is_empty():
		push_warning("AudioManager: unknown music track '%s'" % name)
		return
	var path: String = "res://assets/audio/" + filename
	if not ResourceLoader.exists(path):
		return
	var stream: AudioStream = load(path)
	if stream == null:
		return
	_music_player.stream = stream
	_music_player.play()

func play_ending_music(ending: String) -> void:
	# Stop ambient, start ending track
	_music_player.stop()
	play_music("ending_" + ending)

func set_muted(m: bool) -> void:
	_muted = m
	if m:
		_music_player.stop()
		for p in _sfx_players:
			p.stop()
	else:
		play_music("ambient")

## Distort ambient music proportionally to overall decay (0.0–1.0)
func set_distortion(amount: float) -> void:
	# Pitch-bend the ambient as a basic "distortion" effect
	# amount: 0 = normal, 1 = heavily distorted
	_music_player.pitch_scale = lerpf(1.0, 0.75, amount)

# ─── Internal ─────────────────────────────────────────────────────────────────
func _get_free_sfx_player() -> AudioStreamPlayer:
	for p in _sfx_players:
		if not p.playing:
			return p
	# All busy — steal oldest (first in pool)
	return _sfx_players[0]

func _on_state_changed(state: String) -> void:
	match state:
		"MONITORING":
			play_music("ambient")
		"STARTUP":
			play_sfx("startup_init")
