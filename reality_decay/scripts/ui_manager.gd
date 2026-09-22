## ui_manager.gd
## Controls all HUD labels, overlays, glitch effects. Autoload: "UIManager"
extends Node

# ─── Node References (set by ConsoleUI._ready) ───────────────────────────────
var power_label: Label           = null
var power_bar: ProgressBar       = null
var time_label: Label            = null
var saved_label: Label           = null
var reality_decay_label: Label   = null

# Per-district nodes (set as arrays)
var district_panels: Array       = []   # Array[PanelContainer]
var stability_bars: Array        = []   # Array[ProgressBar]
var stability_labels: Array      = []   # Array[Label]
var district_name_labels: Array  = []   # Array[Label]
var glitch_overlays: Array       = []   # Array[ColorRect] (tinted)

var blue_button: Control         = null
var red_button: Control          = null
var red_uses_label: Label        = null
var central_screen: Control      = null
var gui_root: Control            = null

# Startup / Ending overlays
var startup_overlay: Control     = null
var ending_overlay: Control      = null
var ending_label: Label          = null
var score_label: Label           = null

# Flash timer
var _flash_timers: Array[float]  = [0.0, 0.0, 0.0, 0.0]
var _time_elapsed: float         = 0.0

# ─── Lifecycle ────────────────────────────────────────────────────────────────
func _ready() -> void:
	# Connect to all relevant signals once references are set in _late_ready
	pass

## Call this from ConsoleUI after all node refs are assigned
func late_ready() -> void:
	GameManager.power_changed.connect(_on_power_changed)
	GameManager.state_changed.connect(_on_state_changed)
	GameManager.district_saved.connect(_on_district_saved)
	GameManager.game_ended.connect(_on_game_ended)
	GameManager.emergency_halt_used.connect(_on_halt_used)
	DistrictManager.district_stability_changed.connect(_on_stability_changed)
	DistrictManager.reality_decay_updated.connect(_on_reality_decay_updated)

func _process(delta: float) -> void:
	_time_elapsed += delta
	_update_time_label()
	_update_flash_timers(delta)

# ─── Signal Handlers ──────────────────────────────────────────────────────────
func _on_power_changed(new_power: float) -> void:
	if power_label:
		power_label.text = "POWER: %d/%d" % [int(new_power), int(GameManager.max_power)]
	if power_bar:
		power_bar.max_value = GameManager.max_power
		power_bar.value = new_power

func _on_stability_changed(index: int, stability: float) -> void:
	if index >= stability_bars.size():
		return
	if stability_bars[index]:
		stability_bars[index].value = stability
	if stability_labels[index]:
		stability_labels[index].text = "%d%%" % int(stability)
	_update_glitch(index, stability)

func _on_reality_decay_updated(pct: float) -> void:
	if reality_decay_label:
		reality_decay_label.text = "REALITY DECAY: %d%%" % int(pct)

func _on_state_changed(state: String) -> void:
	match state:
		"STARTUP":
			if startup_overlay:
				startup_overlay.visible = true
		"MONITORING":
			if startup_overlay:
				startup_overlay.visible = false
		"ENDING":
			pass  # handled by _on_game_ended

func _on_district_saved(index: int) -> void:
	_update_saved_label()
	if index < district_panels.size() and district_panels[index]:
		district_panels[index].modulate = Color(0.2, 1.0, 0.4)   # Green lock

func _on_game_ended(ending: String, score: int) -> void:
	if ending_overlay:
		ending_overlay.visible = true
	if ending_label:
		var texts: Dictionary = {
			"A": "TWO REALITIES PRESERVED",
			"B": "ONE REALITY PRESERVED, ONE LOST",
			"C": "REALITY FULLY DECAYED",
		}
		ending_label.text = texts.get(ending, "SIMULATION ENDED")
	if score_label:
		score_label.text = "SCORE: %d / 160" % score
	# Mark unsaved districts red
	for i in DistrictManager.districts.size():
		if not DistrictManager.is_district_locked(i):
			if i < district_panels.size() and district_panels[i]:
				district_panels[i].modulate = Color(1.0, 0.15, 0.15)

func _on_halt_used(uses_remaining: int) -> void:
	if red_uses_label:
		red_uses_label.text = "HALT: %d/%d" % [uses_remaining, GameManager.MAX_RED_USES]
	if red_button:
		if uses_remaining <= 0:
			red_button.modulate = Color(0.3, 0.3, 0.3)

# ─── Glitch Effects ───────────────────────────────────────────────────────────
func _update_glitch(index: int, stability: float) -> void:
	if index >= glitch_overlays.size() or glitch_overlays[index] == null:
		return
	var overlay: ColorRect = glitch_overlays[index]
	var decay: float = 100.0 - stability

	# Visibility + alpha
	if decay < 25.0:
		overlay.visible = false
	else:
		overlay.visible = true
		var alpha: float = clamp((decay - 25.0) / 75.0, 0.0, 0.85)
		if decay >= 75.0:
			# Red flash pulse
			_flash_timers[index] = 0.3
			overlay.color = Color(1.0, 0.0, 0.0, alpha)
		elif decay >= 50.0:
			overlay.color = Color(1.0, 0.5, 0.0, alpha * 0.6)
		else:
			overlay.color = Color(0.8, 0.8, 0.0, alpha * 0.3)

func _update_flash_timers(delta: float) -> void:
	for i in _flash_timers.size():
		if _flash_timers[i] > 0.0:
			_flash_timers[i] -= delta
			if _flash_timers[i] <= 0.0:
				# Reset overlay alpha to non-flash value
				if i < glitch_overlays.size() and glitch_overlays[i]:
					glitch_overlays[i].modulate.a = 0.5

# ─── Helper Methods ───────────────────────────────────────────────────────────
func _update_time_label() -> void:
	if time_label:
		var mins: int = int(_time_elapsed) / 60
		var secs: int = int(_time_elapsed) % 60
		time_label.text = "TIME: %02d:%02d" % [mins, secs]

func _update_saved_label() -> void:
	var saved: int = DistrictManager.get_saved_count()
	if saved_label:
		saved_label.text = "SAVED: %d/2" % saved
	if blue_button:
		if GameManager.blue_uses <= 0:
			blue_button.modulate = Color(0.3, 0.3, 0.5)
		else:
			blue_button.modulate = Color.WHITE

func show_power_deduction(amount: float) -> void:
	# A simple one-shot label flash; real impl uses a tween
	pass

func show_decision_lock(index: int) -> void:
	if index >= district_name_labels.size():
		return
	var name_str: String = DistrictManager.DISTRICT_NAMES[index]
	show_message("[%s] LOCKED FOR PRESERVATION" % name_str)

func show_message(msg: String) -> void:
	# Prints to Godot output for now; replace with on-screen popup label
	print("[UIManager] ", msg)

func set_visible(v: bool) -> void:
	if gui_root:
		gui_root.visible = v

# ─── Waveform Monitor ────────────────────────────────────────────────────────
## Called every frame from ConsoleUI to update a waveform line
func get_waveform_points(num_points: int, decay_pct: float) -> PackedVector2Array:
	var pts := PackedVector2Array()
	pts.resize(num_points)
	var amplitude: float = lerpf(4.0, 24.0, decay_pct / 100.0)
	for i in num_points:
		var x: float = float(i) / float(num_points - 1)
		var y: float = sin(x * TAU * 3.0 + Time.get_ticks_msec() * 0.003) * amplitude
		pts[i] = Vector2(x * 120.0, 40.0 + y)
	return pts
