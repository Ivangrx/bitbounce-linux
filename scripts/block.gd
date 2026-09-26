class_name Block
extends StaticBody2D
## A single breakable block. Notifies GameManager on destruction.

signal destroyed(block: Block, points: int)

@export var points: int = 10
@export var is_easter: bool = false

var _color_id: int = 0
var _flash: float = 0.0


func setup(size: Vector2, color_id: int, score_value: int = 10, easter: bool = false) -> void:
	points = score_value
	is_easter = easter
	_color_id = color_id
	var shape := RectangleShape2D.new()
	shape.size = size
	var col := CollisionShape2D.new()
	col.shape = shape
	col.name = "CollisionShape2D"
	add_child(col)
	collision_layer = 4  # blocks
	collision_mask = 0
	queue_redraw()


func _draw() -> void:
	var shape_node := get_node_or_null("CollisionShape2D") as CollisionShape2D
	if shape_node == null or shape_node.shape == null:
		return
	var rect_shape := shape_node.shape as RectangleShape2D
	var half := rect_shape.size * 0.5
	var rect := Rect2(-half, rect_shape.size)
	var c := GameTheme.block_color_for_index(_color_id).lightened(_flash * 0.4)
	draw_rect(rect, c)
	draw_rect(rect, GameTheme.BORDER, false, 1.0)


func hit() -> void:
	collision_layer = 0
	collision_mask = 0
	_flash = 1.0
	queue_redraw()
	destroyed.emit(self, points)
	var tw := create_tween()
	tw.tween_property(self, "_flash", 0.0, 0.08)
	tw.tween_callback(queue_free)


func _process(delta: float) -> void:
	if _flash > 0.0:
		_flash = maxf(0.0, _flash - delta * 8.0)
		queue_redraw()
