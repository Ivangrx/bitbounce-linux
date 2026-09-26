extends Node
## Forwards the pause key (Esc / P) to GameManager even while the scene tree is paused.

func _unhandled_input(event: InputEvent) -> void:
	if not event.is_action_pressed("pause"):
		return
	var game := get_tree().get_first_node_in_group("game_manager") as GameManager
	if game:
		game.toggle_pause()
		get_viewport().set_input_as_handled()
