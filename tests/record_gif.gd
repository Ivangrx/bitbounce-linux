extends Node
## Records a short gameplay + live theme-change GIF sequence as PNG frames.
## Run (not headless):
##   GIF_FRAME_DIR=/tmp/bitbounce-gif godot --path . res://tests/record_gif.tscn
## Then:
##   ffmpeg -y -framerate 12 -i $GIF_FRAME_DIR/frame_%04d.png docs/gameplay.gif

const THEME_DIR := "/usr/share/omarchy/themes"
const FPS := 12
const TICKS_PER_FRAME := 5
const VIEW := Vector2i(960, 540)

var _vp: SubViewport
var _scene: Node
var _game: GameManager
var _frame: int = 0
var _out_dir: String = "/tmp/bitbounce-gif"


func _ready() -> void:
	AudioManager.muted = true
	GameTheme._theme_file = ""
	var env_dir := OS.get_environment("GIF_FRAME_DIR")
	if env_dir != "":
		_out_dir = env_dir
	DirAccess.make_dir_recursive_absolute(_out_dir)
	_clear_frames()

	_vp = SubViewport.new()
	_vp.size = VIEW
	_vp.transparent_bg = false
	_vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	_vp.disable_3d = true
	add_child(_vp)
	_run.call_deferred()


func _run() -> void:
	_apply_theme("hackerman")
	await _show_menu()
	await _record_for(2.0)

	_apply_theme("tokyo-night")
	await _record_for(1.5)

	await _show_game(LevelGenerator.OMARCHY_LEVEL)
	await _record_for(0.9)
	_launch()
	await _record_for(3.4)

	_apply_theme("catppuccin-latte")
	await _record_for(3.0)

	_apply_theme("rose-pine")
	await _record_for(2.2)

	print("GIF_FRAMES ", _frame, " dir=", _out_dir)
	get_tree().quit()


func _record_for(seconds: float) -> void:
	var n := maxi(1, int(round(seconds * float(FPS))))
	for _i in n:
		for _tick in TICKS_PER_FRAME:
			_steer()
			await get_tree().physics_frame
		_capture()


func _steer() -> void:
	if _game == null or not is_instance_valid(_game):
		return
	if _game.state == GameManager.State.PAUSED:
		_game._on_resume()
	if _game.state == GameManager.State.GAME_OVER:
		_game.start_run()
		_game.level = LevelGenerator.OMARCHY_LEVEL
		_game._spawn_level(_game.level)
		_game._emit_hud()
		_game._reset_ball_on_paddle()
		return
	if is_instance_valid(_game.ball) and is_instance_valid(_game.paddle):
		_game.paddle._target_x = _game.ball.global_position.x
	if _game.state == GameManager.State.WAITING_LAUNCH and _game.ball.launched == false:
		# Relaunch quickly after a drop so the GIF stays in motion.
		if _frame > 40:
			_launch()


func _launch() -> void:
	if _game and is_instance_valid(_game):
		_game._on_launch_requested()


func _capture() -> void:
	var img := _vp.get_texture().get_image()
	var path := "%s/frame_%04d.png" % [_out_dir, _frame]
	img.save_png(path)
	_frame += 1


func _apply_theme(theme_name: String) -> void:
	var path := "%s/%s/colors.toml" % [THEME_DIR, theme_name]
	var colors: Dictionary = GameTheme._parse_colors_toml(FileAccess.get_file_as_string(path))
	if colors.is_empty():
		push_error("Failed to parse %s" % path)
		return
	GameTheme._apply_theme_colors(colors)
	GameTheme.source = "omarchy:%s" % theme_name
	RenderingServer.set_default_clear_color(GameTheme.BG)
	GameTheme.palette_changed.emit()
	print("THEME ", theme_name)


func _show_menu() -> void:
	await _swap(load("res://scenes/menu.tscn") as PackedScene)
	_game = null


func _show_game(level: int) -> void:
	await _swap(load("res://scenes/game.tscn") as PackedScene)
	_game = _scene as GameManager
	await get_tree().physics_frame
	await get_tree().physics_frame
	_game.level = level
	_game._spawn_level(level)
	_game._emit_hud()
	_game._reset_ball_on_paddle()


func _swap(packed: PackedScene) -> void:
	if _scene:
		_scene.queue_free()
		_scene = null
		_game = null
		await get_tree().process_frame
	_scene = packed.instantiate()
	_vp.add_child(_scene)
	await get_tree().process_frame
	await get_tree().process_frame


func _clear_frames() -> void:
	var dir := DirAccess.open(_out_dir)
	if dir == null:
		return
	dir.list_dir_begin()
	var name := dir.get_next()
	while name != "":
		if name.begins_with("frame_") and name.ends_with(".png"):
			dir.remove(name)
		name = dir.get_next()
