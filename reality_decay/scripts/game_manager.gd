## game_manager.gd
## Master game state machine. Autoload singleton: "GameManager"
extends Node

# ─── Signals ────────────────────────────────────────────────────────────────
signal state_changed(new_state: String)
signal district_saved(district_index: int)
signal game_ended(ending: String, score: int)
signal power_changed(new_power: float)
signal emergency_halt_used(uses_remaining: int)
signal reality_decay_changed(pct: float)

# ─── Enums / Constants ───────────────────────────────────────────────────────
enum GameState { STARTUP, MONITORING, DECISION, ENDING }

const DIFFICULTY_SETTINGS := {
	"easy":   { "start_power": 120.0, "decay_rate": 0.8 },
	"normal": { "start_power": 100.0, "decay_rate": 1.0 },
	"hard":   { "start_power":  80.0, "decay_rate": 1.3 },
}

const MAX_BLUE_USES    := 2
const MAX_RED_USES     := 5
const STABILIZE_COST   := 10.0
const SAVE_COST        := 30.0
const HALT_COST        := 50.0
const HALT_DURATION    := 3.0          # seconds
const STABILIZE_BONUS  := 20.0         # stability % added per stabilize press
const STABILIZE_DUR    := 5.0          # seconds the bonus decay-pause lasts
const DECAY_ACCEL_RATE := 0.1          # extra % per second added every 30 s
const ACCEL_INTERVAL   := 30.0         # seconds between acceleration steps
const STARTUP_DURATION := 5.0

# ─── State ───────────────────────────────────────────────────────────────────
var current_state: GameState = GameState.STARTUP
var difficulty: String = "normal"

var power: float = 100.0
var max_power: float = 100.0
var blue_uses: int = MAX_BLUE_USES
var red_uses: int = MAX_RED_USES

var elapsed_time: float = 0.0
var accel_timer: float = 0.0
var halt_timer: float = 0.0
var startup_timer: float = 0.0

var is_halted: bool = false
var gui_visible: bool = true
var audio_muted: bool = false
var paused: bool = false

# Set by DistrictManager to track which district each dial is hovering
var active_dial_index: int = -1
# Index of the district currently selected for saving (during DECISION phase)
var pending_save_index: int = -1

# Score accumulators
var score_base: int = 100
var _no_halt_bonus: bool = true

# ─── Lifecycle ───────────────────────────────────────────────────────────────
func _ready() -> void:
	_apply_difficulty()

func _process(delta: float) -> void:
	if paused:
		return

	match current_state:
		GameState.STARTUP:
			_process_startup(delta)
		GameState.MONITORING:
			_process_monitoring(delta)
		GameState.DECISION:
			pass   # DecisionManager coroutine handles this
		GameState.ENDING:
			pass

# ─── Startup ─────────────────────────────────────────────────────────────────
func _process_startup(delta: float) -> void:
	startup_timer += delta
	if startup_timer >= STARTUP_DURATION:
		_change_state(GameState.MONITORING)

# ─── Monitoring ──────────────────────────────────────────────────────────────
func _process_monitoring(delta: float) -> void:
	elapsed_time += delta

	# Halt countdown
	if is_halted:
		halt_timer -= delta
		if halt_timer <= 0.0:
			is_halted = false

	# Acceleration tick
	if not is_halted:
		accel_timer += delta
		if accel_timer >= ACCEL_INTERVAL:
			accel_timer = 0.0
			DistrictManager.increase_decay_rate(DECAY_ACCEL_RATE)

	# Low power warning (every 10 units below 30)
	if power <= 30.0 and fmod(power, 10.0) < 0.5:
		AudioManager.play_sfx("low_power_warning")

	_check_end_conditions()

func _check_end_conditions() -> void:
	if power <= 0.0:
		power = 0.0
		emit_signal("power_changed", power)
		_trigger_ending()
		return
	# If both saves used, go straight to ending
	if blue_uses <= 0 and current_state == GameState.MONITORING:
		_trigger_ending()

# ─── Actions ─────────────────────────────────────────────────────────────────

## Called by InputHandler when player rotates a dial on district [index]
func stabilize_district(index: int) -> void:
	if current_state != GameState.MONITORING:
		return
	if not _spend_power(STABILIZE_COST):
		return
	DistrictManager.stabilize(index, STABILIZE_BONUS, STABILIZE_DUR)
	UIManager.show_power_deduction(STABILIZE_COST)
	AudioManager.play_sfx("dial_click")

## Called by InputHandler when player clicks the blue button
func request_save(index: int) -> void:
	if current_state != GameState.MONITORING:
		return
	if blue_uses <= 0:
		return
	if not _spend_power(SAVE_COST):
		return
	pending_save_index = index
	_change_state(GameState.DECISION)
	_execute_decision()

## Called by InputHandler when player clicks the red button
func emergency_halt() -> void:
	if current_state != GameState.MONITORING:
		return
	if red_uses <= 0:
		return
	if not _spend_power(HALT_COST):
		return
	red_uses -= 1
	_no_halt_bonus = false
	is_halted = true
	halt_timer = HALT_DURATION
	DistrictManager.set_halted(true)
	emit_signal("emergency_halt_used", red_uses)
	UIManager.show_power_deduction(HALT_COST)
	AudioManager.play_sfx("red_button")
	# Resume decay after duration
	get_tree().create_timer(HALT_DURATION).timeout.connect(_on_halt_expired)

func _on_halt_expired() -> void:
	is_halted = false
	DistrictManager.set_halted(false)

# ─── Decision Phase ───────────────────────────────────────────────────────────
func _execute_decision() -> void:
	UIManager.show_decision_lock(pending_save_index)
	AudioManager.play_sfx("blue_button")
	DistrictManager.lock_district(pending_save_index)
	blue_uses -= 1
	emit_signal("district_saved", pending_save_index)
	await get_tree().create_timer(2.0).timeout
	if blue_uses <= 0:
		_trigger_ending()
	else:
		_change_state(GameState.MONITORING)

# ─── Ending ───────────────────────────────────────────────────────────────────
func _trigger_ending() -> void:
	_change_state(GameState.ENDING)
	var ending := _determine_ending()
	var score := _calculate_score()
	emit_signal("game_ended", ending, score)
	AudioManager.play_ending_music(ending)

func _determine_ending() -> String:
	var saved_count := DistrictManager.get_saved_count()
	if saved_count >= 2:
		return "A"
	elif saved_count == 1:
		return "B"
	else:
		return "C"

func _calculate_score() -> int:
	var score: int = score_base
	var saved: Array = DistrictManager.get_saved_districts()
	# +10 per saved district per minute remaining (approx 3-min cap)
	var minutes_remaining: float = max(0.0, (180.0 - elapsed_time) / 60.0)
	score += int(saved.size() * 10 * minutes_remaining)
	# Low power bonus
	if power > 50.0:
		score += 20
	# No halt bonus
	if _no_halt_bonus:
		score += 30
	return min(score, 160)

# ─── Difficulty ───────────────────────────────────────────────────────────────
func set_difficulty(d: String) -> void:
	difficulty = d
	_apply_difficulty()

func _apply_difficulty() -> void:
	var s: Dictionary = DIFFICULTY_SETTINGS.get(difficulty, DIFFICULTY_SETTINGS["normal"])
	max_power = s["start_power"]
	power = max_power
	emit_signal("power_changed", power)
	DistrictManager.set_base_decay_rate(s["decay_rate"])

# ─── Helpers ─────────────────────────────────────────────────────────────────
func _spend_power(amount: float) -> bool:
	if power < amount:
		UIManager.show_message("INSUFFICIENT POWER")
		return false
	power -= amount
	emit_signal("power_changed", power)
	UIManager.show_power_deduction(amount)
	return true

func _change_state(new_state: GameState) -> void:
	current_state = new_state
	var name_map := {
		GameState.STARTUP: "STARTUP",
		GameState.MONITORING: "MONITORING",
		GameState.DECISION: "DECISION",
		GameState.ENDING: "ENDING",
	}
	emit_signal("state_changed", name_map[new_state])

# ─── Input passthrough ───────────────────────────────────────────────────────
func toggle_pause() -> void:
	if current_state != GameState.MONITORING:
		return
	paused = !paused
	DistrictManager.set_halted(paused)

func toggle_mute() -> void:
	audio_muted = !audio_muted
	AudioManager.set_muted(audio_muted)

func toggle_gui() -> void:
	gui_visible = !gui_visible
	UIManager.set_visible(gui_visible)

func restart() -> void:
	get_tree().reload_current_scene()
