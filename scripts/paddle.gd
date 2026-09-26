class_name Paddle
extends CharacterBody2D
## Paddle driven by mouse, keyboard, or touch. Stays inside the playfield.

signal launch_requested

const WIDTH := 96.0
const HEIGHT := 14.0
const SPEED := 1400.0
const KEY_SPEED := 620.0

var _target_x: float = GameTheme.VIEW_W * 0.5
var _play_left: float = 20.0
var _play_right: float = GameTheme.VIEW_W - 20.0
var enabled: bool = true


func _ready() -> void:
	var shape := RectangleShape2D.new()
	shape.size = Vector2(WIDTH, HEIGHT)
	$CollisionShape2D.shape = shape
	collision_layer = 2
	collision_mask = 0
	_target_x = position.x
	GameTheme.palette_changed.connect(queue_redraw)
	queue_redraw()


func set_bounds(left: float, right: float) -> void:
	_play_left = left + WIDTH * 0.5
	_play_right = right - WIDTH * 0.5
	position.x = clampf(position.x, _play_left, _play_right)
	_target_x = position.x


func _unhandled_input(event: InputEvent) -> void:
	if not enabled:
		return
	if event.is_action_pressed("launch"):
		launch_requested.emit()
	elif event is InputEventScreenTouch:
		var touch := event as InputEventScreenTouch
		if touch.pressed:
			_target_x = touch.position.x
			launch_requested.emit()
	elif event is InputEventScreenDrag:
		_target_x = (event as InputEventScreenDrag).position.x
	elif event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_LEFT and mb.pressed:
			_target_x = mb.position.x
			launch_requested.emit()
	elif event is InputEventMouseMotion:
		_target_x = (event as InputEventMouseMotion).position.x


func _physics_process(delta: float) -> void:
	if not enabled:
		return
	var axis := Input.get_axis("move_left", "move_right")
	if axis != 0.0:
		position.x = clampf(position.x + axis * KEY_SPEED * delta, _play_left, _play_right)
		_target_x = position.x
	_target_x = clampf(_target_x, _play_left, _play_right)
	var dx := _target_x - position.x
	var max_step := SPEED * delta
	if absf(dx) <= max_step:
		position.x = _target_x
	else:
		position.x += signf(dx) * max_step
	position.x = clampf(position.x, _play_left, _play_right)
	velocity = Vector2.ZERO


func _draw() -> void:
	var half := Vector2(WIDTH, HEIGHT) * 0.5
	var rect := Rect2(-half, Vector2(WIDTH, HEIGHT))
	draw_rect(rect, GameTheme.PADDLE)
	draw_line(Vector2(-half.x, -half.y), Vector2(half.x, -half.y), GameTheme.ACCENT, 2.0)
