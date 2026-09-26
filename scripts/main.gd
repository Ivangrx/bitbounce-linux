extends Node
## Root scene: boots into the main menu.

func _ready() -> void:
	RenderingServer.set_default_clear_color(GameTheme.BG)
	get_tree().change_scene_to_file.call_deferred("res://scenes/menu.tscn")
