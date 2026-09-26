extends Node
## Saves clean README screenshots from an offscreen 1920×1080 viewport.
## Run (not headless): godot --path . res://tests/capture_screenshots.tscn
## Output: docs/menu<suffix>.png, docs/gameplay<suffix>.png (suffix from $SHOT_SUFFIX)

const SHOTS := {
	"menu": "res://scenes/menu.tscn",
	"gameplay": "res://scenes/game.tscn",
}
const OUT_SIZE := Vector2i(1920, 1080)


func _ready() -> void:
	_run.call_deferred()


func _run() -> void:
	var suffix := OS.get_environment("SHOT_SUFFIX")
	for shot_name: String in SHOTS:
		var vp := SubViewport.new()
		vp.size = OUT_SIZE
		vp.size_2d_override = Vector2i(int(GameTheme.VIEW_W), int(GameTheme.VIEW_H))
		vp.size_2d_override_stretch = true
		vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
		add_child(vp)
		vp.add_child((load(SHOTS[shot_name]) as PackedScene).instantiate())
		for i in 45:
			await get_tree().process_frame
		var img := vp.get_texture().get_image()
		var out := ProjectSettings.globalize_path("res://docs/%s%s.png" % [shot_name, suffix])
		img.save_png(out)
		print("CAPTURED ", out, " ", img.get_size())
		vp.queue_free()
		await get_tree().process_frame
	get_tree().quit()
