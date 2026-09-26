extends Node
## Shared palette and visual settings.
## On Omarchy the palette follows the active theme's colors.toml and reloads live
## when the user switches themes. Elsewhere the built-in palette is used.

signal palette_changed

const OMARCHY_THEME_DIR := "~/.local/state/omarchy/current"
const THEME_POLL_SECONDS := 1.5

const FONT_PATH := "res://assets/fonts/JetBrainsMono-Regular.ttf"
const FONT_BOLD_PATH := "res://assets/fonts/JetBrainsMono-Bold.ttf"

## Playfield layout (reference 960×540)
const VIEW_W := 960.0
const VIEW_H := 540.0
const HUD_HEIGHT := 48.0
const WALL_THICKNESS := 8.0
const PLAY_MARGIN := 12.0
const PADDLE_Y := 500.0
const BLOCK_TOP := 72.0
const BLOCK_BOTTOM_MAX := 360.0
const BLOCK_SIZE := Vector2(48, 20)
const BLOCK_GAP := Vector2(4, 4)

var BG := Color("121416")
var SURFACE := Color("1a1d21")
var SURFACE_ALT := Color("22262b")
var BORDER := Color("2e343c")
var TEXT := Color("e6e8eb")
var TEXT_DIM := Color("8b929a")
var ACCENT := Color("7dba6a")
var ACCENT_DIM := Color("4a7a3f")
var DANGER := Color("c45c5c")
var PADDLE := Color("e6e8eb")
var BALL := Color("7dba6a")
var BLOCKS: Array[Color] = [Color("7dba6a"), Color("5b9bd5"), Color("d4a017"), Color("c47a5c")]

## "omarchy:<name>", "file:<path>" or "builtin"
var source: String = "builtin"

var _font: FontFile
var _font_bold: FontFile
var _theme_file: String = ""
var _theme_mtime: int = -1


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_font = load(FONT_PATH) as FontFile
	_font_bold = load(FONT_BOLD_PATH) as FontFile
	_theme_file = _resolve_theme_file()
	_reload_palette()
	if _theme_file != "":
		var timer := Timer.new()
		timer.wait_time = THEME_POLL_SECONDS
		timer.timeout.connect(_poll_theme_file)
		add_child(timer)
		timer.start()


func _resolve_theme_file() -> String:
	var override := OS.get_environment("BITBOUNCE_THEME_FILE")
	if override != "":
		return override
	if OS.get_environment("BITBOUNCE_NO_OMARCHY") != "":
		return ""
	var path := OMARCHY_THEME_DIR.replace("~", OS.get_environment("HOME")) + "/theme/colors.toml"
	return path if FileAccess.file_exists(path) else ""


func _poll_theme_file() -> void:
	if not FileAccess.file_exists(_theme_file):
		return
	if FileAccess.get_modified_time(_theme_file) != _theme_mtime:
		_reload_palette()


func _reload_palette() -> void:
	var colors := {}
	if _theme_file != "" and FileAccess.file_exists(_theme_file):
		_theme_mtime = FileAccess.get_modified_time(_theme_file)
		colors = _parse_colors_toml(FileAccess.get_file_as_string(_theme_file))
	if colors.has("background") and colors.has("foreground") and colors.has("accent"):
		_apply_theme_colors(colors)
		source = "omarchy:%s" % _omarchy_theme_name() if OS.get_environment("BITBOUNCE_THEME_FILE") == "" else "file:%s" % _theme_file
	else:
		source = "builtin"
	RenderingServer.set_default_clear_color(BG)
	palette_changed.emit()


func _apply_theme_colors(c: Dictionary) -> void:
	BG = c["background"]
	var fg: Color = c.get("bright_foreground", c["foreground"])
	SURFACE = c.get("dark_background", BG.darkened(0.15))
	SURFACE_ALT = c.get("lighter_background", BG.lightened(0.08))
	BORDER = c.get("muted", c.get("selection", BG.lerp(fg, 0.2)))
	TEXT = fg
	TEXT_DIM = fg.lerp(BG, 0.42)
	ACCENT = c["accent"]
	ACCENT_DIM = ACCENT.lerp(BG, 0.4)
	DANGER = c.get("red", Color("c45c5c"))
	PADDLE = fg
	BALL = ACCENT
	BLOCKS = [
		c.get("green", ACCENT),
		c.get("blue", ACCENT.lerp(fg, 0.3)),
		c.get("yellow", ACCENT.lerp(BG, 0.2)),
		c.get("magenta", c.get("red", fg)),
	]


func _omarchy_theme_name() -> String:
	var path := OMARCHY_THEME_DIR.replace("~", OS.get_environment("HOME")) + "/theme.name"
	if not FileAccess.file_exists(path):
		return "custom"
	return FileAccess.get_file_as_string(path).strip_edges()


static func _parse_colors_toml(text: String) -> Dictionary:
	## Minimal parser for Omarchy's flat `key = "#rrggbb"` colors.toml.
	var result := {}
	for raw_line in text.split("\n"):
		var line := raw_line.strip_edges()
		if line.begins_with("#") or not line.contains("="):
			continue
		var key := line.get_slice("=", 0).strip_edges()
		var value := line.get_slice("=", 1).strip_edges().trim_prefix("\"").trim_suffix("\"")
		if value.begins_with("#") and Color.html_is_valid(value):
			result[key] = Color.html(value)
	return result


func get_font() -> Font:
	return _font


func get_font_bold() -> Font:
	return _font_bold


func theme_label() -> String:
	if source.begins_with("omarchy:"):
		return "theme://" + source.trim_prefix("omarchy:")
	if source.begins_with("file:"):
		return "theme://custom"
	return "theme://bitbounce"


func apply_label(label: Label, dim: bool = false, large: bool = false) -> void:
	if _font:
		label.add_theme_font_override("font", _font_bold if large else _font)
	label.add_theme_font_size_override("font_size", 28 if large else 18)
	label.add_theme_color_override("font_color", TEXT_DIM if dim else TEXT)


func apply_button(btn: Button) -> void:
	if _font_bold:
		btn.add_theme_font_override("font", _font_bold)
	btn.add_theme_font_size_override("font_size", 22)
	btn.add_theme_color_override("font_color", TEXT)
	btn.add_theme_color_override("font_hover_color", ACCENT)
	btn.add_theme_color_override("font_focus_color", ACCENT)
	btn.add_theme_color_override("font_pressed_color", ACCENT_DIM)
	btn.add_theme_stylebox_override("normal", _button_box(SURFACE_ALT, BORDER))
	btn.add_theme_stylebox_override("hover", _button_box(SURFACE_ALT, ACCENT))
	btn.add_theme_stylebox_override("focus", _button_box(Color.TRANSPARENT, ACCENT))
	btn.add_theme_stylebox_override("pressed", _button_box(SURFACE, ACCENT_DIM))
	btn.custom_minimum_size = Vector2(220, 56)


func _button_box(bg: Color, border: Color) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = bg
	box.border_color = border
	box.set_border_width_all(1)
	box.set_content_margin_all(8)
	return box


func block_color_for_index(i: int) -> Color:
	return BLOCKS[posmod(i, BLOCKS.size())]
