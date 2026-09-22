## main.gd
## Root scene script. Builds maze procedurally from ASCII data.
extends Node2D

const TILE: int = 28

# All rows MUST be the same length (20 chars wide).
# '#' = wall  '.' = pellet  ' ' = empty  'P' = player  'G' = ghost
const MAZE_DATA: Array[String] = [
	"####################",
	"#........#.........#",
	"#.###.##.#.##.###..#",
	"#..................#",
	"#.###.#.#####.#.###.",
	"#.....#...#...#....#",
	"######.##.#.##.#####",
	"#....#....G....#...#",
	"#.##.#.#######.#.#.#",
	"#..................#",
	"#.##.#.#######.#.#.#",
	"#....#.........#...#",
	"######.##.#.##.#####",
	"#.....#...#...#....#",
	"#.###.##.###.###.#.#",
	"#..#........P...#..#",
	"#.###.#.#####.#.###.",
	"#.....#...#...#....#",
	"#.##################",
	"#..................#",
	"####################",
]

@onready var _score_label: Label   = $UI/ScoreLabel
@onready var _gameover_panel: ColorRect = $UI/GameOverPanel
@onready var _pellets_node: Node2D = $Pellets

# ── Lifecycle ──────────────────────────────────────────────────────────────────
func _ready() -> void:
	GameManager.reset()
	GameManager.score_changed.connect(_on_score_changed)
	GameManager.game_over_triggered.connect(_on_game_over)
	_build_maze()
	_score_label.text = "SCORE: 0"
	_gameover_panel.visible = false

func _unhandled_input(event: InputEvent) -> void:
	if GameManager.game_over and event is InputEventKey and event.pressed:
		get_tree().reload_current_scene()

# ── Maze builder ───────────────────────────────────────────────────────────────
func _build_maze() -> void:
	for row in MAZE_DATA.size():
		var row_str: String = MAZE_DATA[row]
		for col in row_str.length():
			var ch: String = row_str[col]
			# Centre of this tile in world space
			var pos: Vector2 = Vector2(col * TILE + TILE / 2, row * TILE + TILE / 2)
			match ch:
				"#": _spawn_wall(pos)
				".": _spawn_pellet(pos)
				"P": _spawn_player(pos)
				"G": _spawn_ghost(pos)

# ── Wall ───────────────────────────────────────────────────────────────────────
func _spawn_wall(pos: Vector2) -> void:
	var body := StaticBody2D.new()
	body.position = pos
	# Layer 1 = walls
	body.collision_layer = 1
	body.collision_mask  = 0

	var shape := CollisionShape2D.new()
	var rect  := RectangleShape2D.new()
	rect.size  = Vector2(TILE, TILE)
	shape.shape = rect
	body.add_child(shape)

	var vis := ColorRect.new()
	vis.size     = Vector2(TILE, TILE)
	vis.position = Vector2(-TILE / 2.0, -TILE / 2.0)
	vis.color    = Color(0.05, 0.1, 0.7)   # Pac-Man blue wall
	body.add_child(vis)

	add_child(body)

# ── Pellet ─────────────────────────────────────────────────────────────────────
func _spawn_pellet(pos: Vector2) -> void:
	var area := Area2D.new()
	area.position = pos
	area.add_to_group("pellet")
	# Layer 2 = collectibles; mask 4 = player layer
	area.collision_layer = 2
	area.collision_mask  = 4
	area.monitoring      = true
	area.monitorable     = false

	var shape  := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 5.0
	shape.shape   = circle
	area.add_child(shape)

	var dot := ColorRect.new()
	dot.size     = Vector2(6, 6)
	dot.position = Vector2(-3, -3)
	dot.color    = Color(1.0, 0.95, 0.8)   # warm white dot
	area.add_child(dot)

	# Bug fix: set_script BEFORE add_child so _ready() fires with shape already present
	area.set_script(load("res://scripts/pellet.gd"))
	_pellets_node.add_child(area)

# ── Player ─────────────────────────────────────────────────────────────────────
func _spawn_player(pos: Vector2) -> void:
	var body := CharacterBody2D.new()
	body.position = pos
	body.add_to_group("player")
	# Layer 4 = player; mask 1 = walls
	body.collision_layer = 4
	body.collision_mask  = 1

	var shape  := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = TILE * 0.42
	shape.shape   = circle
	body.add_child(shape)

	var vis := ColorRect.new()
	vis.size     = Vector2(TILE - 4, TILE - 4)
	vis.position = Vector2(-(TILE - 4) / 2.0, -(TILE - 4) / 2.0)
	vis.color    = Color.YELLOW
	body.add_child(vis)

	# Bug fix: set_script BEFORE add_child
	body.set_script(load("res://scripts/player.gd"))
	add_child(body)

# ── Ghost ──────────────────────────────────────────────────────────────────────
func _spawn_ghost(pos: Vector2) -> void:
	var body := CharacterBody2D.new()
	body.position = pos
	# Layer 8 = ghost; mask 1 = walls
	body.collision_layer = 8
	body.collision_mask  = 1

	var shape  := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = TILE * 0.42
	shape.shape   = circle
	body.add_child(shape)

	var vis := ColorRect.new()
	vis.size     = Vector2(TILE - 4, TILE - 4)
	vis.position = Vector2(-(TILE - 4) / 2.0, -(TILE - 4) / 2.0)
	vis.color    = Color(1.0, 0.3, 0.3)   # red ghost
	body.add_child(vis)

	# Ghost hitbox Area2D (detects player layer 4)
	var detector       := Area2D.new()
	detector.collision_layer = 0
	detector.collision_mask  = 4
	detector.monitoring      = true
	detector.monitorable     = false

	var det_shape  := CollisionShape2D.new()
	var det_circle := CircleShape2D.new()
	det_circle.radius  = TILE * 0.42
	det_shape.shape    = det_circle
	detector.add_child(det_shape)

	# Bug fix: set_script BEFORE add_child
	detector.set_script(load("res://scripts/ghost_detector.gd"))
	body.add_child(detector)

	body.set_script(load("res://scripts/ghost.gd"))
	add_child(body)

# ── Signals ────────────────────────────────────────────────────────────────────
func _on_score_changed(new_score: int) -> void:
	_score_label.text = "SCORE: %d" % new_score

func _on_game_over() -> void:
	_gameover_panel.visible = true
