class_name Ball
extends CharacterBody2D
## CharacterBody2D ball using move_and_collide for controlled bounce response.

signal fell_below
signal hit_paddle
signal hit_block(block: Block)
signal hit_wall

const RADIUS := 7.0
const MIN_ANGLE_FROM_VERTICAL := deg_to_rad(18.0)
const MIN_ANGLE_FROM_HORIZONTAL := deg_to_rad(18.0)

var speed: float = 280.0
var direction: Vector2 = Vector2(0.4, -1.0).normalized()
var launched: bool = false
var _attached_paddle: Paddle = null


func _ready() -> void:
	var shape := CircleShape2D.new()
	shape.radius = RADIUS
	$CollisionShape2D.shape = shape
	collision_layer = 8  # ball
	collision_mask = 1 | 2 | 4  # walls, paddle, blocks
	GameTheme.palette_changed.connect(queue_redraw)
	queue_redraw()


func attach_to_paddle(paddle: Paddle) -> void:
	_attached_paddle = paddle
	launched = false
	direction = Vector2(0.25, -1.0).normalized()
	_snap_to_paddle()


func launch() -> void:
	if launched:
		return
	launched = true
	_attached_paddle = null
	direction = direction.normalized()
	# Prefer a slight upward angle if somehow flat
	if absf(direction.y) < 0.2:
		direction = Vector2(direction.x, -1.0).normalized()
	direction = _clamp_direction(direction)


func set_speed(value: float) -> void:
	speed = value


func _physics_process(delta: float) -> void:
	if not launched:
		_snap_to_paddle()
		return

	var remaining := speed * delta
	var safety := 0
	while remaining > 0.0001 and safety < 4:
		safety += 1
		var motion := direction * remaining
		var collision := move_and_collide(motion)
		if collision == null:
			break
		remaining -= collision.get_travel().length()
		_resolve_collision(collision)

	if global_position.y > GameTheme.VIEW_H + 40.0:
		fell_below.emit()


func _snap_to_paddle() -> void:
	if _attached_paddle == null:
		return
	global_position = _attached_paddle.global_position + Vector2(0, -Paddle.HEIGHT * 0.5 - RADIUS - 2.0)


func _resolve_collision(collision: KinematicCollision2D) -> void:
	var collider := collision.get_collider()
	var normal := collision.get_normal()

	if collider is Block:
		var block := collider as Block
		hit_block.emit(block)
		direction = direction.bounce(normal).normalized()
		direction = _clamp_direction(direction)
		return

	if collider is Paddle or (collider is Node and (collider as Node).is_in_group("paddle")):
		_bounce_off_paddle(collider as Node2D)
		hit_paddle.emit()
		return

	# Walls / generic
	direction = direction.bounce(normal).normalized()
	direction = _clamp_direction(direction)
	hit_wall.emit()


func _bounce_off_paddle(paddle: Node2D) -> void:
	# Vary horizontal direction based on hit offset along paddle width.
	var offset := (global_position.x - paddle.global_position.x) / (Paddle.WIDTH * 0.5)
	offset = clampf(offset, -1.0, 1.0)
	# Map offset to bounce angle: center = steep, edges = wider
	var max_angle := deg_to_rad(65.0)
	var angle := offset * max_angle
	direction = Vector2(sin(angle), -cos(angle)).normalized()
	direction = _clamp_direction(direction)
	# Nudge slightly above paddle to avoid re-collision
	global_position.y = minf(global_position.y, paddle.global_position.y - Paddle.HEIGHT * 0.5 - RADIUS - 1.0)


func _clamp_direction(dir: Vector2) -> Vector2:
	var d := dir.normalized()
	# Prevent nearly horizontal (frustrating stalls along walls)
	var abs_y := absf(d.y)
	var min_y := sin(MIN_ANGLE_FROM_HORIZONTAL)
	if abs_y < min_y:
		d.y = signf(d.y if d.y != 0.0 else -1.0) * min_y
		d.x = signf(d.x if d.x != 0.0 else 1.0) * cos(asin(min_y))
		d = d.normalized()
	# Prevent nearly vertical (slow horizontal progress)
	var abs_x := absf(d.x)
	var min_x := sin(MIN_ANGLE_FROM_VERTICAL)
	if abs_x < min_x:
		d.x = signf(d.x if d.x != 0.0 else 1.0) * min_x
		var rest := sqrt(maxf(0.0, 1.0 - d.x * d.x))
		d.y = signf(d.y if d.y != 0.0 else -1.0) * rest
		d = d.normalized()
	return d


func _draw() -> void:
	draw_circle(Vector2.ZERO, RADIUS, GameTheme.BALL)
	draw_arc(Vector2.ZERO, RADIUS, 0.0, TAU, 24, GameTheme.ACCENT.lightened(0.3), 1.5)
