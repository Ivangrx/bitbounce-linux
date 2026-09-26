class_name GameManager
extends Node2D
## Run state: score, lives, levels, pause, game over, and endless generation.

enum State { PLAYING, WAITING_LAUNCH, LEVEL_CLEAR, PAUSED, GAME_OVER }

signal score_changed(score: int)
signal lives_changed(lives: int)
signal level_changed(level: int)
signal state_changed(state: State)
signal personal_best_updated(best: int)
signal easter_triggered
signal run_ended(final_score: int, best: int, is_new_record: bool)

const START_LIVES := 3

@onready var paddle: Paddle = $Paddle
@onready var ball: Ball = $Ball
@onready var blocks_root: Node2D = $Blocks
@onready var walls: Node2D = $Walls
@onready var hud: CanvasLayer = $HUD
@onready var pause_overlay: Control = $HUD/PauseOverlay
@onready var level_banner: Label = $HUD/LevelBanner
@onready var easter_banner: Label = $HUD/EasterBanner
@onready var score_label: Label = $HUD/TopBar/ScoreLabel
@onready var level_label: Label = $HUD/TopBar/LevelLabel
@onready var lives_label: Label = $HUD/TopBar/LivesLabel
@onready var pause_button: Button = $HUD/TopBar/PauseButton
@onready var game_over_overlay: Control = $HUD/GameOverOverlay

var state: State = State.WAITING_LAUNCH
var score: int = 0
var lives: int = START_LIVES
var level: int = 1
var _generator := LevelGenerator.new()
var _block_count: int = 0
var _level_had_easter: bool = false
var _easter_cleared: bool = false
var _level_easter_id: String = ""
var _last_seed: int = 0
var _record_announced: bool = false


func _ready() -> void:
	add_to_group("game_manager")
	_build_walls()
	_style_hud()
	paddle.launch_requested.connect(_on_launch_requested)
	paddle.set_bounds(
		GameTheme.PLAY_MARGIN + GameTheme.WALL_THICKNESS,
		GameTheme.VIEW_W - GameTheme.PLAY_MARGIN - GameTheme.WALL_THICKNESS
	)
	ball.fell_below.connect(_on_ball_fell)
	ball.hit_paddle.connect(_on_ball_hit_paddle)
	ball.hit_block.connect(_on_ball_hit_block)
	ball.hit_wall.connect(_on_ball_hit_wall)
	pause_button.pressed.connect(toggle_pause)
	pause_button.focus_mode = Control.FOCUS_NONE
	$HUD/PauseOverlay/ResumeButton.pressed.connect(_on_resume)
	$HUD/PauseOverlay/MenuButton.pressed.connect(_on_main_menu)
	GameTheme.palette_changed.connect(_on_palette_changed)
	pause_overlay.visible = false
	game_over_overlay.visible = false
	level_banner.visible = false
	easter_banner.visible = false
	start_run()


func start_run() -> void:
	score = 0
	lives = START_LIVES
	level = 1
	_record_announced = false
	game_over_overlay.visible = false
	_emit_hud()
	_set_state(State.WAITING_LAUNCH)
	_spawn_level(level)
	_reset_ball_on_paddle()
	get_tree().paused = false


func _style_hud() -> void:
	GameTheme.apply_label(score_label)
	GameTheme.apply_label(level_label)
	GameTheme.apply_label(lives_label)
	GameTheme.apply_label(level_banner, false, true)
	GameTheme.apply_label(easter_banner, false, true)
	level_banner.add_theme_color_override("font_color", GameTheme.ACCENT)
	easter_banner.add_theme_color_override("font_color", GameTheme.ACCENT)
	GameTheme.apply_button(pause_button)
	pause_button.custom_minimum_size = Vector2(100, 44)
	pause_button.text = "❚❚"
	for child in pause_overlay.get_children():
		if child is Label:
			GameTheme.apply_label(child as Label, false, true)
		elif child is Button:
			GameTheme.apply_button(child as Button)
		elif child is ColorRect:
			(child as ColorRect).color = Color(GameTheme.BG, 0.85)


func _on_palette_changed() -> void:
	_style_hud()
	queue_redraw()
	for block in blocks_root.get_children():
		(block as Node2D).queue_redraw()


func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT and (state == State.PLAYING or state == State.WAITING_LAUNCH):
		toggle_pause()


func _build_walls() -> void:
	# Clear any editor placeholders
	for c in walls.get_children():
		c.queue_free()
	var t := GameTheme.WALL_THICKNESS
	var top := GameTheme.HUD_HEIGHT
	_add_wall(Vector2(GameTheme.VIEW_W * 0.5, top + t * 0.5), Vector2(GameTheme.VIEW_W, t))
	_add_wall(Vector2(t * 0.5, top + (GameTheme.VIEW_H - top) * 0.5), Vector2(t, GameTheme.VIEW_H - top))
	_add_wall(
		Vector2(GameTheme.VIEW_W - t * 0.5, top + (GameTheme.VIEW_H - top) * 0.5),
		Vector2(t, GameTheme.VIEW_H - top)
	)
	# Decorative border
	queue_redraw()


func _add_wall(pos: Vector2, size: Vector2) -> void:
	var body := StaticBody2D.new()
	body.position = pos
	body.collision_layer = 1
	body.collision_mask = 0
	var shape := RectangleShape2D.new()
	shape.size = size
	var col := CollisionShape2D.new()
	col.shape = shape
	body.add_child(col)
	walls.add_child(body)


func _draw() -> void:
	# Playfield frame
	var r := Rect2(4, GameTheme.HUD_HEIGHT + 2, GameTheme.VIEW_W - 8, GameTheme.VIEW_H - GameTheme.HUD_HEIGHT - 6)
	draw_rect(r, GameTheme.BORDER, false, 1.0)
	draw_rect(Rect2(0, 0, GameTheme.VIEW_W, GameTheme.HUD_HEIGHT), GameTheme.SURFACE)


func _spawn_level(lvl: int) -> void:
	for c in blocks_root.get_children():
		c.queue_free()
	_block_count = 0
	_easter_cleared = false

	var layout := _generator.generate(lvl)
	_last_seed = int(layout["seed"])
	_level_easter_id = str(layout.get("easter_id", ""))
	_level_had_easter = _level_easter_id != ""
	var positions: Array = layout["positions"]
	var color_ids: Array = layout["color_ids"]
	var block_size: Vector2 = layout.get("block_size", LevelGenerator.BLOCK_SIZE)
	print("Level %d seed=%d blocks=%d easter=%s" % [lvl, _last_seed, positions.size(), _level_easter_id])

	for i in positions.size():
		var block := Block.new()
		block.name = "Block_%d" % i
		block.position = positions[i]
		block.setup(block_size, color_ids[i], LevelGenerator.POINTS_PER_BLOCK, _level_had_easter)
		block.destroyed.connect(_on_block_destroyed)
		blocks_root.add_child(block)
		_block_count += 1

	ball.set_speed(LevelGenerator.ball_speed_for_level(lvl))


func _reset_ball_on_paddle() -> void:
	ball.attach_to_paddle(paddle)
	_set_state(State.WAITING_LAUNCH)


func _set_state(s: State) -> void:
	state = s
	state_changed.emit(s)
	paddle.enabled = s == State.PLAYING or s == State.WAITING_LAUNCH
	Desktop.set_cursor_hidden(paddle.enabled or s == State.LEVEL_CLEAR)


func _emit_hud() -> void:
	score_label.text = "SCORE %d" % score
	level_label.text = "LVL %d" % level
	lives_label.text = "LIVE %d" % lives
	score_changed.emit(score)
	lives_changed.emit(lives)
	level_changed.emit(level)


func _on_launch_requested() -> void:
	if state == State.WAITING_LAUNCH:
		ball.launch()
		_set_state(State.PLAYING)


func _on_ball_fell() -> void:
	if state != State.PLAYING and state != State.WAITING_LAUNCH:
		return
	lives -= 1
	_emit_hud()
	AudioManager.play_life()
	if lives <= 0:
		_game_over()
	else:
		_reset_ball_on_paddle()


func _on_ball_hit_paddle() -> void:
	AudioManager.play_hit()


func _on_ball_hit_wall() -> void:
	AudioManager.play_hit()


func _on_ball_hit_block(block: Block) -> void:
	if not is_instance_valid(block):
		return
	block.hit()


func _on_block_destroyed(block: Block, points: int) -> void:
	score += points
	_block_count = maxi(0, _block_count - 1)
	_emit_hud()
	AudioManager.play_block()
	# Update personal best live during the run
	if SaveManager.try_update_best(score, level):
		personal_best_updated.emit(SaveManager.best_score)
		if not _record_announced:
			_record_announced = true
			AudioManager.play_record()

	if _block_count <= 0 and state == State.PLAYING:
		_on_level_cleared()


func _on_level_cleared() -> void:
	_set_state(State.LEVEL_CLEAR)
	ball.launched = false
	AudioManager.play_level()

	if _level_had_easter:
		easter_banner.text = _level_easter_id.to_upper()
		easter_banner.visible = true
		easter_triggered.emit()
		await get_tree().create_timer(1.2).timeout
		easter_banner.visible = false

	level_banner.text = "LEVEL %d CLEAR" % level
	level_banner.visible = true
	await get_tree().create_timer(1.0).timeout
	level_banner.visible = false

	level += 1
	_emit_hud()
	_spawn_level(level)
	_reset_ball_on_paddle()


func _game_over() -> void:
	_set_state(State.GAME_OVER)
	ball.launched = false
	paddle.enabled = false
	var is_new := SaveManager.try_update_best(score, level)
	run_ended.emit(score, SaveManager.best_score, is_new)
	if game_over_overlay.has_method("setup"):
		game_over_overlay.setup(score, SaveManager.best_score, is_new)
	game_over_overlay.visible = true


func toggle_pause() -> void:
	if state == State.GAME_OVER or state == State.LEVEL_CLEAR:
		return
	if state == State.PAUSED:
		_on_resume()
	else:
		_set_state(State.PAUSED)
		pause_overlay.visible = true
		$HUD/PauseOverlay/ResumeButton.grab_focus()
		get_tree().paused = true
		AudioManager.play_ui()


func _on_resume() -> void:
	pause_overlay.visible = false
	get_tree().paused = false
	_set_state(State.PLAYING if ball.launched else State.WAITING_LAUNCH)
	AudioManager.play_ui()


func _on_main_menu() -> void:
	get_tree().paused = false
	Desktop.set_cursor_hidden(false)
	AudioManager.play_ui()
	get_tree().change_scene_to_file("res://scenes/menu.tscn")
