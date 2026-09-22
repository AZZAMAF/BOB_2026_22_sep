## console_ui.gd
## Root scene script. Builds all runtime UI nodes procedurally and wires them.
extends Control

# ─── Constants ───────────────────────────────────────────────────────────────
const PANEL_BG         := Color(0.05, 0.05, 0.12)
const TEAL             := Color(0.2, 0.9, 0.8)
const BLUE_BTN_COLOR   := Color(0.15, 0.4, 0.9)
const RED_BTN_COLOR    := Color(0.9, 0.15, 0.15)
const SCANLINE_ALPHA   := 0.08

var _waveform_line: Line2D = null
var _waveform_decay: float = 0.0

# ─── Lifecycle ───────────────────────────────────────────────────────────────
func _ready() -> void:
	_build_ui()
	UIManager.late_ready()
	_connect_district_signals()

func _process(_delta: float) -> void:
	_update_waveform()

# ─── UI Construction ─────────────────────────────────────────────────────────

func _build_ui() -> void:
	# Full-screen dark background
	var bg := ColorRect.new()
	bg.color = PANEL_BG
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	UIManager.gui_root = self

	# CRT scanline overlay
	_add_scanlines()

	# Central screen (4 district quads)
	var central := _build_central_screen()
	add_child(central)

	# Left side monitor (waveform)
	var left_mon := _build_side_monitor_left()
	left_mon.position = Vector2(20, 160)
	add_child(left_mon)

	# Right side monitor (power graph placeholder)
	var right_mon := _build_side_monitor_right()
	right_mon.position = Vector2(660, 160)
	add_child(right_mon)

	# Dials row (below central screen)
	var dials_container := _build_dials()
	dials_container.position = Vector2(175, 390)
	add_child(dials_container)

	# Buttons (right side)
	var buttons_container := _build_buttons()
	buttons_container.position = Vector2(620, 260)
	add_child(buttons_container)

	# HUD labels
	_build_hud_labels()

	# Startup overlay
	_build_startup_overlay()

	# Ending overlay
	_build_ending_overlay()

# ─── Central Screen ───────────────────────────────────────────────────────────
func _build_central_screen() -> Control:
	var screen := PanelContainer.new()
	screen.position = Vector2(160, 60)
	screen.custom_minimum_size = Vector2(480, 300)

	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.02, 0.02, 0.08)
	style.border_color = TEAL
	style.set_border_width_all(2)
	screen.add_theme_stylebox_override("panel", style)

	var grid := GridContainer.new()
	grid.columns = 2
	grid.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	screen.add_child(grid)

	UIManager.central_screen = screen

	var panels: Array = []
	var stab_bars: Array = []
	var stab_labels: Array = []
	var name_labels: Array = []
	var glitch_overlays: Array = []

	for i in 4:
		var quad := _build_district_quad(i)
		grid.add_child(quad["root"])
		panels.append(quad["root"])
		stab_bars.append(quad["bar"])
		stab_labels.append(quad["pct_label"])
		name_labels.append(quad["name_label"])
		glitch_overlays.append(quad["glitch"])

	UIManager.district_panels    = panels
	UIManager.stability_bars     = stab_bars
	UIManager.stability_labels   = stab_labels
	UIManager.district_name_labels = name_labels
	UIManager.glitch_overlays    = glitch_overlays

	return screen

func _build_district_quad(index: int) -> Dictionary:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(238, 148)

	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.04, 0.04, 0.1)
	style.border_color = DistrictManager.DISTRICT_COLORS[index]
	style.set_border_width_all(1)
	panel.add_theme_stylebox_override("panel", style)

	# Overlay (glitch effect)
	var glitch := ColorRect.new()
	glitch.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	glitch.color = Color(1.0, 0.0, 0.0, 0.0)
	glitch.visible = false
	glitch.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var vbox := VBoxContainer.new()
	vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	panel.add_child(vbox)
	panel.add_child(glitch)

	# District name
	var name_lbl := Label.new()
	name_lbl.text = DistrictManager.DISTRICT_NAMES[index]
	name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_lbl.add_theme_color_override("font_color", DistrictManager.DISTRICT_COLORS[index])
	vbox.add_child(name_lbl)

	# Stability bar
	var bar := ProgressBar.new()
	bar.min_value = 0
	bar.max_value = 100
	bar.value = 100
	bar.custom_minimum_size = Vector2(200, 14)
	bar.add_theme_color_override("font_color", Color.WHITE)
	vbox.add_child(bar)

	# Stability % label
	var pct_lbl := Label.new()
	pct_lbl.text = "100%"
	pct_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	pct_lbl.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))
	vbox.add_child(pct_lbl)

	# Scrolling city placeholder (Label with district flavor text)
	var city_lbl := Label.new()
	city_lbl.text = _get_city_flavor(index)
	city_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	city_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	city_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD
	city_lbl.add_theme_color_override("font_color", DistrictManager.DISTRICT_COLORS[index].lerp(Color.WHITE, 0.3))
	city_lbl.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(city_lbl)

	return {
		"root": panel,
		"bar": bar,
		"pct_label": pct_lbl,
		"name_label": name_lbl,
		"glitch": glitch,
	}

func _get_city_flavor(index: int) -> String:
	var flavors := [
		"Crystalline spires\npulse with fading light",
		"Glacial towers crack\nas warmth returns",
		"Neural networks\nflicker and dim",
		"Bio-structures\ndissolve into void",
	]
	return flavors[index]

# ─── Dials ───────────────────────────────────────────────────────────────────
func _build_dials() -> HBoxContainer:
	var hbox := HBoxContainer.new()
	hbox.custom_minimum_size = Vector2(480, 80)
	var dial_controls: Array = []

	for i in 4:
		var dial := _build_dial(i)
		hbox.add_child(dial["root"])
		dial_controls.append(dial["root"])

	InputHandler.register_dials(dial_controls)
	return hbox

func _build_dial(index: int) -> Dictionary:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(110, 80)

	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.08, 0.08, 0.15)
	style.border_color = TEAL
	style.set_border_width_all(1)
	style.corner_radius_top_left    = 8
	style.corner_radius_top_right   = 8
	style.corner_radius_bottom_left = 8
	style.corner_radius_bottom_right = 8
	panel.add_theme_stylebox_override("panel", style)

	var vbox := VBoxContainer.new()
	vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	panel.add_child(vbox)

	var name_lbl := Label.new()
	name_lbl.text = DistrictManager.DISTRICT_NAMES[index]
	name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_lbl.add_theme_font_size_override("font_size", 10)
	name_lbl.add_theme_color_override("font_color", TEAL)
	vbox.add_child(name_lbl)

	var dial_lbl := Label.new()
	dial_lbl.text = "◉ DIAL"
	dial_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	dial_lbl.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))
	vbox.add_child(dial_lbl)

	var hint := Label.new()
	hint.text = "drag ←→"
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.add_theme_font_size_override("font_size", 9)
	hint.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
	vbox.add_child(hint)

	return { "root": panel }

# ─── Buttons ─────────────────────────────────────────────────────────────────
func _build_buttons() -> VBoxContainer:
	var vbox := VBoxContainer.new()
	vbox.custom_minimum_size = Vector2(120, 200)

	# BLUE button
	var blue := Button.new()
	blue.text = "SAVE\nDISTRICT"
	blue.custom_minimum_size = Vector2(110, 60)
	blue.add_theme_color_override("font_color", Color.WHITE)
	var blue_style := StyleBoxFlat.new()
	blue_style.bg_color = BLUE_BTN_COLOR
	blue_style.set_border_width_all(2)
	blue_style.border_color = Color(0.5, 0.7, 1.0)
	blue_style.corner_radius_top_left    = 6
	blue_style.corner_radius_top_right   = 6
	blue_style.corner_radius_bottom_left = 6
	blue_style.corner_radius_bottom_right = 6
	blue.add_theme_stylebox_override("normal", blue_style)
	blue.tooltip_text = "SAVE DISTRICT  (Cost: -30 power)"
	vbox.add_child(blue)

	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(0, 12)
	vbox.add_child(spacer)

	# RED button
	var red := Button.new()
	red.text = "EMERGENCY\nHALT"
	red.custom_minimum_size = Vector2(110, 60)
	red.add_theme_color_override("font_color", Color.WHITE)
	var red_style := StyleBoxFlat.new()
	red_style.bg_color = RED_BTN_COLOR
	red_style.set_border_width_all(2)
	red_style.border_color = Color(1.0, 0.5, 0.5)
	red_style.corner_radius_top_left    = 6
	red_style.corner_radius_top_right   = 6
	red_style.corner_radius_bottom_left = 6
	red_style.corner_radius_bottom_right = 6
	red.add_theme_stylebox_override("normal", red_style)
	red.tooltip_text = "EMERGENCY HALT — pause all decay 3s  (Cost: -50 power)"
	vbox.add_child(red)

	# Uses label below red button
	var uses_lbl := Label.new()
	uses_lbl.text = "HALT: 5/5"
	uses_lbl.add_theme_font_size_override("font_size", 10)
	uses_lbl.add_theme_color_override("font_color", Color(1.0, 0.6, 0.6))
	uses_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(uses_lbl)

	UIManager.blue_button   = blue
	UIManager.red_button    = red
	UIManager.red_uses_label = uses_lbl
	InputHandler.register_buttons(blue, red)

	return vbox

# ─── Side Monitors ────────────────────────────────────────────────────────────
func _build_side_monitor_left() -> PanelContainer:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(130, 200)
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.03, 0.03, 0.1)
	style.border_color = Color(0.3, 0.1, 0.6)
	style.set_border_width_all(2)
	panel.add_theme_stylebox_override("panel", style)

	var vbox := VBoxContainer.new()
	vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	panel.add_child(vbox)

	var title := Label.new()
	title.text = "WAVEFORM"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 9)
	title.add_theme_color_override("font_color", Color(0.6, 0.3, 1.0))
	vbox.add_child(title)

	# Line2D waveform
	var line := Line2D.new()
	line.default_color = Color(0.5, 0.3, 1.0)
	line.width = 1.5
	line.position = Vector2(5, 20)
	panel.add_child(line)
	_waveform_line = line

	return panel

func _build_side_monitor_right() -> PanelContainer:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(130, 200)
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.03, 0.03, 0.1)
	style.border_color = Color(0.1, 0.4, 0.3)
	style.set_border_width_all(2)
	panel.add_theme_stylebox_override("panel", style)

	var vbox := VBoxContainer.new()
	vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	panel.add_child(vbox)

	var title := Label.new()
	title.text = "POWER DIST."
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 9)
	title.add_theme_color_override("font_color", Color(0.2, 0.8, 0.6))
	vbox.add_child(title)

	var body := Label.new()
	body.text = "Monitor\ndata\nstream"
	body.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	body.add_theme_font_size_override("font_size", 9)
	body.add_theme_color_override("font_color", Color(0.3, 0.6, 0.5))
	vbox.add_child(body)

	return panel

# ─── HUD Labels ───────────────────────────────────────────────────────────────
func _build_hud_labels() -> void:
	# Bottom bar
	var hud := HBoxContainer.new()
	hud.position = Vector2(0, 550)
	hud.custom_minimum_size = Vector2(800, 40)
	add_child(hud)

	var power_lbl := Label.new()
	power_lbl.text = "POWER: 100/100"
	power_lbl.custom_minimum_size = Vector2(200, 0)
	power_lbl.add_theme_color_override("font_color", TEAL)
	hud.add_child(power_lbl)

	var power_bar := ProgressBar.new()
	power_bar.min_value = 0
	power_bar.max_value = 100
	power_bar.value = 100
	power_bar.custom_minimum_size = Vector2(160, 16)
	power_bar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	hud.add_child(power_bar)

	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hud.add_child(spacer)

	var time_lbl := Label.new()
	time_lbl.text = "TIME: 00:00"
	time_lbl.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	hud.add_child(time_lbl)

	var spacer2 := Control.new()
	spacer2.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hud.add_child(spacer2)

	var saved_lbl := Label.new()
	saved_lbl.text = "SAVED: 0/2"
	saved_lbl.custom_minimum_size = Vector2(160, 0)
	saved_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	saved_lbl.add_theme_color_override("font_color", TEAL)
	hud.add_child(saved_lbl)

	# Top-center: REALITY DECAY meter
	var decay_lbl := Label.new()
	decay_lbl.text = "REALITY DECAY: 0%"
	decay_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	# Use anchor offsets only — avoids the "size overridden after _ready" warning
	decay_lbl.set_anchor_and_offset(SIDE_LEFT,   0.0,   0.0)
	decay_lbl.set_anchor_and_offset(SIDE_RIGHT,  1.0,   0.0)
	decay_lbl.set_anchor_and_offset(SIDE_TOP,    0.0,   6.0)
	decay_lbl.set_anchor_and_offset(SIDE_BOTTOM, 0.0,  38.0)
	decay_lbl.add_theme_color_override("font_color", Color(1.0, 0.3, 0.3))
	decay_lbl.add_theme_font_size_override("font_size", 16)
	add_child(decay_lbl)

	UIManager.power_label        = power_lbl
	UIManager.power_bar          = power_bar
	UIManager.time_label         = time_lbl
	UIManager.saved_label        = saved_lbl
	UIManager.reality_decay_label = decay_lbl

# ─── Startup Overlay ─────────────────────────────────────────────────────────
func _build_startup_overlay() -> void:
	var overlay := ColorRect.new()
	overlay.color = Color(0.0, 0.0, 0.0, 0.92)
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(overlay)

	var vbox := VBoxContainer.new()
	vbox.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	overlay.add_child(vbox)

	var title := Label.new()
	title.text = "REALITY DECAY"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 32)
	title.add_theme_color_override("font_color", Color(1.0, 0.3, 0.3))
	vbox.add_child(title)

	var subtitle := Label.new()
	subtitle.text = "INITIALIZING... MONITORING REALITY DECAY..."
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.add_theme_color_override("font_color", TEAL)
	vbox.add_child(subtitle)

	UIManager.startup_overlay = overlay

# ─── Ending Overlay ───────────────────────────────────────────────────────────
func _build_ending_overlay() -> void:
	var overlay := ColorRect.new()
	overlay.color = Color(0.0, 0.0, 0.0, 0.88)
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.visible = false
	add_child(overlay)

	var vbox := VBoxContainer.new()
	vbox.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	overlay.add_child(vbox)

	var ending_lbl := Label.new()
	ending_lbl.text = ""
	ending_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ending_lbl.add_theme_font_size_override("font_size", 24)
	ending_lbl.add_theme_color_override("font_color", Color.WHITE)
	vbox.add_child(ending_lbl)

	var score_lbl := Label.new()
	score_lbl.text = "SCORE: 0 / 160"
	score_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	score_lbl.add_theme_font_size_override("font_size", 18)
	score_lbl.add_theme_color_override("font_color", TEAL)
	vbox.add_child(score_lbl)

	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(0, 20)
	vbox.add_child(spacer)

	var restart_btn := Button.new()
	restart_btn.text = "[ RESTART ]"
	restart_btn.pressed.connect(GameManager.restart)
	vbox.add_child(restart_btn)

	# Difficulty selector
	var diff_label := Label.new()
	diff_label.text = "DIFFICULTY:"
	diff_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	diff_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	vbox.add_child(diff_label)

	var diff_hbox := HBoxContainer.new()
	diff_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_child(diff_hbox)

	for d in ["easy", "normal", "hard"]:
		var btn := Button.new()
		btn.text = d.to_upper()
		btn.pressed.connect(GameManager.set_difficulty.bind(d))
		diff_hbox.add_child(btn)

	UIManager.ending_overlay = overlay
	UIManager.ending_label   = ending_lbl
	UIManager.score_label    = score_lbl

# ─── CRT Scanlines ────────────────────────────────────────────────────────────
func _add_scanlines() -> void:
	var scanlines := ColorRect.new()
	scanlines.color = Color(0.0, 0.0, 0.0, SCANLINE_ALPHA)
	scanlines.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	scanlines.mouse_filter = Control.MOUSE_FILTER_IGNORE
	# Scanline effect via shader (or simple dark overlay — real shader in ext. resource)
	add_child(scanlines)
	move_child(scanlines, get_child_count() - 1)

# ─── Waveform Update ─────────────────────────────────────────────────────────
func _connect_district_signals() -> void:
	DistrictManager.reality_decay_updated.connect(_on_reality_decay_for_waveform)

func _on_reality_decay_for_waveform(pct: float) -> void:
	_waveform_decay = pct

func _update_waveform() -> void:
	if _waveform_line == null:
		return
	var pts := UIManager.get_waveform_points(40, _waveform_decay)
	_waveform_line.points = pts
