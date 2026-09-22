## game_manager.gd
## Autoload singleton. Tracks score and game-over state.
extends Node

# ── Signals ───────────────────────────────────────────────────────────────────
signal score_changed(new_score: int)
signal game_over_triggered

# ── State ─────────────────────────────────────────────────────────────────────
var score: int = 0
var game_over: bool = false

# ── API ───────────────────────────────────────────────────────────────────────
func add_score(amount: int) -> void:
	if game_over:
		return
	score += amount
	emit_signal("score_changed", score)

func trigger_game_over() -> void:
	if game_over:
		return
	game_over = true
	emit_signal("game_over_triggered")

func reset() -> void:
	score = 0
	game_over = false
