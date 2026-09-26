extends Node
## Persists personal best score via ConfigFile at user://savegame.cfg.

const SAVE_PATH := "user://savegame.cfg"
const SECTION := "progress"
const KEY_BEST_SCORE := "best_score"
const KEY_BEST_LEVEL := "best_level"

var best_score: int = 0
var best_level: int = 1


func _ready() -> void:
	load_save()


func load_save() -> void:
	var cfg := ConfigFile.new()
	var err := cfg.load(SAVE_PATH)
	if err != OK:
		best_score = 0
		best_level = 1
		return
	best_score = int(cfg.get_value(SECTION, KEY_BEST_SCORE, 0))
	best_level = int(cfg.get_value(SECTION, KEY_BEST_LEVEL, 1))


func save() -> void:
	var cfg := ConfigFile.new()
	cfg.load(SAVE_PATH)  # preserve other keys if any
	cfg.set_value(SECTION, KEY_BEST_SCORE, best_score)
	cfg.set_value(SECTION, KEY_BEST_LEVEL, best_level)
	cfg.save(SAVE_PATH)


## Returns true if a new personal best was set.
func try_update_best(score: int, level: int) -> bool:
	var is_new := score > best_score
	var level_up := level > best_level
	if is_new:
		best_score = score
	if level_up:
		best_level = level
	if is_new or level_up:
		save()
	return is_new
