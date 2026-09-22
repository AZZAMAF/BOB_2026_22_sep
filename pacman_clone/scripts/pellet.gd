## pellet.gd
## Attach to: Area2D (Pellet)
## Disappears when the player walks over it and adds 10 to the score.
extends Area2D

func _ready() -> void:
	# Connect the body_entered signal to our handler
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node2D) -> void:
	# Only react when Pac-Man touches the pellet
	if body.is_in_group("player"):
		GameManager.add_score(10)
		queue_free()
