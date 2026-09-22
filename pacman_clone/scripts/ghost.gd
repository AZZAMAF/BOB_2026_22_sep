## ghost.gd
## Attach to: CharacterBody2D (Ghost)
## Simple AI: move straight, pick a random free direction on wall collision.
extends CharacterBody2D

const SPEED: float = 80.0

const DIRS: Array[Vector2] = [
	Vector2.UP, Vector2.DOWN, Vector2.LEFT, Vector2.RIGHT
]

var _direction: Vector2 = Vector2.RIGHT

func _ready() -> void:
	_direction = DIRS[randi() % DIRS.size()]

func _physics_process(_delta: float) -> void:
	if GameManager.game_over:
		velocity = Vector2.ZERO
		return

	# Bug fix: use move_and_slide() only (not move_and_collide + velocity together)
	velocity = _direction * SPEED
	move_and_slide()

	# Check if we hit something by seeing how much velocity was cancelled
	if get_slide_collision_count() > 0:
		_pick_new_direction()

func _pick_new_direction() -> void:
	var candidates: Array[Vector2] = DIRS.duplicate()
	var reverse: Vector2 = -_direction
	candidates.erase(reverse)
	candidates.shuffle()

	for dir in candidates:
		# test_only=true: probe without actually moving
		var probe: KinematicCollision2D = move_and_collide(dir * 4.0, true)
		if probe == null:
			_direction = dir
			return

	# Cornered — allow reverse as last resort
	_direction = reverse
