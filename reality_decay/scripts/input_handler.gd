## input_handler.gd
## Handles all mouse and keyboard input. Autoload singleton: "InputHandler"
extends Node

# ─── Constants ───────────────────────────────────────────────────────────────
const DIAL_DRAG_THRESHOLD := 4.0    # px before a drag registers
const TICK_DRAG_PIXELS    := 20.0   # px of horizontal drag per stability tick

# ─── State ───────────────────────────────────────────────────────────────────
var _dragging_dial: int = -1        # index of dial being dragged (-1 = none)
var _drag_start_x: float = 0.0
var _drag_accumulated: float = 0.0
var _selected_district: int = 0     # which district is targeted for blue button

# References set by console_ui.gd after scene is ready
var dial_areas: Array = []          # Array[Area2D or Control]
var blue_button: Control = null
var red_button: Control  = null

# ─── Lifecycle ───────────────────────────────────────────────────────────────
func _unhandled_input(event: InputEvent) -> void:
	_handle_keyboard(event)
	_handle_mouse_button(event)
	_handle_mouse_motion(event)

# ─── Keyboard ────────────────────────────────────────────────────────────────
func _handle_keyboard(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed:
		return
	if event.is_action_pressed("pause_game"):
		GameManager.toggle_pause()
	elif event.is_action_pressed("restart_game"):
		GameManager.restart()
	elif event.is_action_pressed("mute_audio"):
		GameManager.toggle_mute()
	elif event.is_action_pressed("toggle_gui"):
		GameManager.toggle_gui()

# ─── Mouse Buttons ────────────────────────────────────────────────────────────
func _handle_mouse_button(event: InputEvent) -> void:
	if not event is InputEventMouseButton:
		return

	var mb := event as InputEventMouseButton

	if mb.button_index == MOUSE_BUTTON_LEFT:
		if mb.pressed:
			_check_dial_press(mb.position)
		else:
			_end_dial_drag()
			_check_button_release(mb.position)

func _check_dial_press(pos: Vector2) -> void:
	for i in dial_areas.size():
		var area = dial_areas[i]
		if area == null:
			continue
		if _point_in_control(area, pos):
			_dragging_dial = i
			_drag_start_x = pos.x
			_drag_accumulated = 0.0
			_selected_district = i
			return

func _end_dial_drag() -> void:
	_dragging_dial = -1
	_drag_accumulated = 0.0

func _check_button_release(pos: Vector2) -> void:
	if blue_button != null and _point_in_control(blue_button, pos):
		if GameManager.blue_uses > 0:
			GameManager.request_save(_selected_district)
	elif red_button != null and _point_in_control(red_button, pos):
		if GameManager.red_uses > 0:
			GameManager.emergency_halt()

# ─── Mouse Motion ────────────────────────────────────────────────────────────
func _handle_mouse_motion(event: InputEvent) -> void:
	if not event is InputEventMouseMotion:
		return
	if _dragging_dial < 0:
		return
	var mm := event as InputEventMouseMotion
	_drag_accumulated += mm.relative.x

	# Every TICK_DRAG_PIXELS of horizontal movement = one stabilize tick
	while abs(_drag_accumulated) >= TICK_DRAG_PIXELS:
		GameManager.stabilize_district(_dragging_dial)
		if _drag_accumulated > 0:
			_drag_accumulated -= TICK_DRAG_PIXELS
		else:
			_drag_accumulated += TICK_DRAG_PIXELS

# ─── Helpers ─────────────────────────────────────────────────────────────────
func _point_in_control(ctrl: Control, pos: Vector2) -> bool:
	var rect := Rect2(ctrl.global_position, ctrl.size)
	return rect.has_point(pos)

## Called by ConsoleUI after scene ready to register interactive elements
func register_dials(dials: Array) -> void:
	dial_areas = dials

func register_buttons(blue: Control, red: Control) -> void:
	blue_button = blue
	red_button  = red

func get_selected_district() -> int:
	return _selected_district
