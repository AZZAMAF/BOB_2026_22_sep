## ghost_detector.gd
## Attach to: Area2D child of Ghost node.
## Triggers Game Over when the ghost touches the player.
extends Area2D

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		GameManager.trigger_game_over()
