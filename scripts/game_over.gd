extends Control
## Game Over overlay: final score, personal best, and Play Again.

@onready var dim: ColorRect = $Dim
@onready var title: Label = $Center/VBox/Title
@onready var score_label: Label = $Center/VBox/ScoreLabel
@onready var best_label: Label = $Center/VBox/BestLabel
@onready var record_label: Label = $Center/VBox/RecordLabel
@onready var again_btn: Button = $Center/VBox/AgainButton
@onready var menu_btn: Button = $Center/VBox/MenuButton

var final_score: int = 0
var best_score: int = 0
var is_new_record: bool = false


func setup(score: int, best: int, new_record: bool) -> void:
	final_score = score
	best_score = best
	is_new_record = new_record
	if is_node_ready():
		_refresh()
		again_btn.grab_focus()


func _ready() -> void:
	again_btn.pressed.connect(_on_again)
	menu_btn.pressed.connect(_on_menu)
	GameTheme.palette_changed.connect(_restyle)
	_restyle()
	_refresh()


func _restyle() -> void:
	dim.color = Color(GameTheme.BG, 0.9)
	GameTheme.apply_label(title, false, true)
	title.add_theme_font_size_override("font_size", 36)
	title.add_theme_color_override("font_color", GameTheme.DANGER)
	GameTheme.apply_label(score_label)
	GameTheme.apply_label(best_label, true)
	GameTheme.apply_label(record_label)
	record_label.add_theme_color_override("font_color", GameTheme.ACCENT)
	GameTheme.apply_button(again_btn)
	GameTheme.apply_button(menu_btn)


func _refresh() -> void:
	score_label.text = "SCORE  %d" % final_score
	best_label.text = "PERSONAL BEST  %d" % best_score
	record_label.visible = is_new_record
	record_label.text = "NEW PERSONAL BEST"


func _on_again() -> void:
	AudioManager.play_ui()
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/game.tscn")


func _on_menu() -> void:
	AudioManager.play_ui()
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/menu.tscn")
