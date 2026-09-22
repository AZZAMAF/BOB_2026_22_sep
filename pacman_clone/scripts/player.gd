## player.gd
## Attach to: CharacterBody2D (Player)
## Controls Pac-Man movement in 4 directions on a tile grid.
extends CharacterBody2D

# ── Tuning ────────────────────────────────────────────────────────────────────
const SPEED: float = 120.0   # pixels per second

# Current direction the player is heading
var _direction: Vector2 = Vector2.RIGHT
# Queued next direction (buffered one frame so corners feel responsive)
var _queued_dir: Vector2 = Vector2.RIGHT

# ── Per-frame ─────────────────────────────────────────────────────────────────
func _physics_process(delta: float) -> void:
	if GameManager.game_over:
		return

	_read_input()
	_try_turn()

	velocity = _direction * SPEED
	move_and_slide()

# ── Input ─────────────────────────────────────────────────────────────────────
func _read_input() -> void:
	if Input.is_action_pressed("move_up"):
		_queued_dir = Vector2.UP
	elif Input.is_action_pressed("move_down"):
		_queued_dir = Vector2.DOWN
	elif Input.is_action_pressed("move_left"):
		_queued_dir = Vector2.LEFT
	elif Input.is_action_pressed("move_right"):
		_queued_dir = Vector2.RIGHT

# Try to apply the queued turn. Only switch direction when the player
# is roughly aligned to the tile grid so movement stays smooth.
func _try_turn() -> void:
	if _queued_dir == _direction:
		return

	# Snap test: attempt a 1-pixel probe in the queued direction.
	# If move_and_collide returns null the path is clear → turn.
	var probe: KinematicCollision2D = move_and_collide(
		_queued_dir * 1.0, true   # test_only = true
	)
	if probe == null:
		_direction = _queued_dir
