extends Node
## Automated gameplay checks. Run: godot --path . res://scenes/auto_playtest.tscn

const GAME_SCENE := preload("res://scenes/game.tscn")

var _failures: PackedStringArray = []


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	await get_tree().process_frame

	var game := GAME_SCENE.instantiate() as GameManager
	add_child(game)
	await get_tree().process_frame
	await get_tree().process_frame

	_check("starts waiting launch", game.state == GameManager.State.WAITING_LAUNCH)
	_check("3 lives", game.lives == 3)
	_check("level 1", game.level == 1)
	_check("has blocks", game._block_count > 0)

	game._on_launch_requested()
	await get_tree().process_frame
	_check("playing after launch", game.state == GameManager.State.PLAYING)
	_check("ball launched", game.ball.launched)

	var before: int = game.score
	var blocks: Array = game.blocks_root.get_children()
	if blocks.size() > 0:
		var b := blocks[0] as Block
		b.hit()
		await get_tree().process_frame
		_check("score increased", game.score > before)
		_check("block count decreased", game._block_count == blocks.size() - 1)

	var lives_before: int = game.lives
	game._on_ball_fell()
	await get_tree().process_frame
	_check("life lost", game.lives == lives_before - 1)
	_check("waiting after fall", game.state == GameManager.State.WAITING_LAUNCH)

	game.toggle_pause()
	await get_tree().process_frame
	_check("paused", game.state == GameManager.State.PAUSED)
	# Resume without leaving tree paused stuck
	game._on_resume()
	await get_tree().process_frame
	_check("resumed", game.state != GameManager.State.PAUSED)
	_check("tree not paused", get_tree().paused == false)

	_check("speed capped", is_equal_approx(LevelGenerator.ball_speed_for_level(999), LevelGenerator.MAX_SPEED))
	_check("complexity capped", LevelGenerator.complexity_for_level(999) == LevelGenerator.MAX_COMPLEXITY)

	# Force game over
	game.lives = 1
	game._on_ball_fell()
	await get_tree().process_frame
	_check("game over", game.state == GameManager.State.GAME_OVER)
	_check("game over visible", game.game_over_overlay.visible)

	# Replay path: start_run again
	game.start_run()
	await get_tree().process_frame
	_check("replay level 1", game.level == 1)
	_check("replay lives 3", game.lives == 3)

	if _failures.is_empty():
		print("AUTO_OK")
		get_tree().quit(0)
	else:
		print("AUTO_FAIL")
		for f in _failures:
			print(" - ", f)
		get_tree().quit(1)


func _check(label: String, ok: bool) -> void:
	if not ok:
		_failures.append(label)
	else:
		print("ok: ", label)
