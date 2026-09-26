extends Node
## Desktop input bindings, fullscreen toggle, and window defaults.

const MIN_WINDOW_SIZE := Vector2i(640, 360)

const BINDINGS := {
	"move_left": [KEY_LEFT, KEY_A, KEY_H],
	"move_right": [KEY_RIGHT, KEY_D, KEY_L],
	"launch": [KEY_SPACE, KEY_UP, KEY_W, KEY_K],
	"pause": [KEY_ESCAPE, KEY_P],
	"toggle_fullscreen": [KEY_F11],
}


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for action: String in BINDINGS:
		if not InputMap.has_action(action):
			InputMap.add_action(action)
		for keycode: Key in BINDINGS[action]:
			var ev := InputEventKey.new()
			ev.physical_keycode = keycode
			InputMap.action_add_event(action, ev)
	if DisplayServer.get_name() != "headless":
		DisplayServer.window_set_min_size(MIN_WINDOW_SIZE)


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("toggle_fullscreen"):
		var fullscreen := DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN
		DisplayServer.window_set_mode(
			DisplayServer.WINDOW_MODE_WINDOWED if fullscreen else DisplayServer.WINDOW_MODE_FULLSCREEN
		)
		get_viewport().set_input_as_handled()


func set_cursor_hidden(hidden: bool) -> void:
	Input.mouse_mode = Input.MOUSE_MODE_HIDDEN if hidden else Input.MOUSE_MODE_VISIBLE
