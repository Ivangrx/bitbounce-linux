extends Control
## Main menu: terminal-style title screen.

const LOGO_GLYPHS := {
	"B": ["██████╗ ", "██╔══██╗", "██████╔╝", "██╔══██╗", "██████╔╝", "╚═════╝ "],
	"I": ["██╗", "██║", "██║", "██║", "██║", "╚═╝"],
	"T": ["████████╗", "╚══██╔══╝", "   ██║   ", "   ██║   ", "   ██║   ", "   ╚═╝   "],
	"O": [" ██████╗ ", "██╔═══██╗", "██║   ██║", "██║   ██║", "╚██████╔╝", " ╚═════╝ "],
	"U": ["██╗   ██╗", "██║   ██║", "██║   ██║", "██║   ██║", "╚██████╔╝", " ╚═════╝ "],
	"N": ["███╗   ██╗", "████╗  ██║", "██╔██╗ ██║", "██║╚██╗██║", "██║ ╚████║", "╚═╝  ╚═══╝"],
	"C": [" ██████╗", "██╔════╝", "██║     ", "██║     ", "╚██████╗", " ╚═════╝"],
	"E": ["███████╗", "██╔════╝", "█████╗  ", "██╔══╝  ", "███████╗", "╚══════╝"],
}

@onready var background: ColorRect = $Background
@onready var ascii_art: Label = $Center/VBox/AsciiArt
@onready var title: Label = $Center/VBox/Title
@onready var status_line: Label = $Center/VBox/StatusLine
@onready var subtitle: Label = $Center/VBox/Subtitle
@onready var best_label: Label = $Center/VBox/BestLabel
@onready var play_btn: Button = $Center/VBox/PlayButton
@onready var quit_btn: Button = $Center/VBox/QuitButton
@onready var accent_line: ColorRect = $AccentLine
@onready var accent_line_bottom: ColorRect = $AccentLineBottom
@onready var scanline: ColorRect = $Scanline
@onready var corner_tl: Label = $CornerTL
@onready var corner_br: Label = $CornerBR

var _blink_on: bool = true
var _boot_done: bool = false
var _blink_timer: Timer


func _ready() -> void:
	Desktop.set_cursor_hidden(false)
	ascii_art.text = _build_logo("BITBOUNCE")
	title.text = "// bitbounce — endless arcade shell for linux"
	subtitle.text = "survive · score · root your personal best"
	best_label.text = "best_score=%d" % SaveManager.best_score
	play_btn.text = "> ./play"
	quit_btn.text = "> ./quit"
	corner_tl.text = "┌─ mouse/←→ move · space launch · esc pause · f11 fullscreen"

	play_btn.pressed.connect(_on_play)
	quit_btn.pressed.connect(_on_quit)
	GameTheme.palette_changed.connect(_restyle)
	_restyle()
	play_btn.grab_focus()

	_blink_timer = Timer.new()
	_blink_timer.wait_time = 0.55
	_blink_timer.timeout.connect(_on_blink)
	add_child(_blink_timer)
	_boot_status()


func _restyle() -> void:
	background.color = GameTheme.BG
	accent_line.color = GameTheme.ACCENT
	accent_line_bottom.color = Color(GameTheme.ACCENT, 0.45)
	scanline.color = Color(GameTheme.ACCENT, 0.035)
	corner_br.text = GameTheme.theme_label() + " ─┘"

	if GameTheme.get_font():
		ascii_art.add_theme_font_override("font", GameTheme.get_font())
	ascii_art.add_theme_font_size_override("font_size", 12)
	ascii_art.add_theme_constant_override("line_spacing", -2)
	ascii_art.add_theme_color_override("font_color", GameTheme.ACCENT)

	GameTheme.apply_label(title, false, true)
	title.add_theme_font_size_override("font_size", 13)
	title.add_theme_color_override("font_color", GameTheme.ACCENT)
	GameTheme.apply_label(status_line, true)
	status_line.add_theme_font_size_override("font_size", 14)
	status_line.add_theme_color_override("font_color", GameTheme.ACCENT)
	GameTheme.apply_label(subtitle, true)
	GameTheme.apply_label(best_label, true)

	for label: Label in [corner_tl, corner_br]:
		if GameTheme.get_font():
			label.add_theme_font_override("font", GameTheme.get_font())
		label.add_theme_font_size_override("font_size", 12)
		label.add_theme_color_override("font_color", Color(GameTheme.ACCENT, 0.75))

	GameTheme.apply_button(play_btn)
	GameTheme.apply_button(quit_btn)


func _build_logo(word: String) -> String:
	var rows := PackedStringArray(["", "", "", "", "", ""])
	for letter in word:
		var glyph: Array = LOGO_GLYPHS[letter]
		for r in rows.size():
			rows[r] += glyph[r]
	return "\n".join(rows)


func _boot_status() -> void:
	status_line.text = "> init playfield………… ok"
	await get_tree().create_timer(0.2).timeout
	if not is_inside_tree():
		return
	status_line.text = "> load highscore………… ok"
	await get_tree().create_timer(0.2).timeout
	if not is_inside_tree():
		return
	_boot_done = true
	status_line.text = "> await operator input█"
	_blink_timer.start()


func _on_blink() -> void:
	if not _boot_done:
		return
	_blink_on = not _blink_on
	status_line.text = "> await operator input" + ("█" if _blink_on else " ")


func _on_play() -> void:
	AudioManager.play_ui()
	get_tree().change_scene_to_file("res://scenes/game.tscn")


func _on_quit() -> void:
	AudioManager.play_ui()
	get_tree().quit()
