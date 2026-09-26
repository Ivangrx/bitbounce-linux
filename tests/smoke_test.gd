extends SceneTree
## Headless smoke test for level generation.

func _initialize() -> void:
	var gen := LevelGenerator.new()
	var errors: PackedStringArray = []
	const BLOCK_BOTTOM_MAX := 360.0
	const VIEW_W := 960.0

	for level in range(1, 21):
		var layout: Dictionary = gen.generate(level, 12345 + level)
		var positions: Array = layout["positions"]
		if positions.is_empty():
			errors.append("Level %d produced zero blocks" % level)
		var speed := LevelGenerator.ball_speed_for_level(level)
		if speed > LevelGenerator.MAX_SPEED + 0.01:
			errors.append("Speed exceeded max at level %d" % level)
		for pos in positions:
			var p: Vector2 = pos
			if p.y > BLOCK_BOTTOM_MAX + 20.0:
				errors.append("Block below safe area at level %d: %s" % [level, str(p)])
			if p.x < 0.0 or p.x > VIEW_W:
				errors.append("Block outside view X at level %d: %s" % [level, str(p)])

	var a: Dictionary = gen.generate(5, 999)
	var b: Dictionary = gen.generate(5, 999)
	if str(a["positions"]) != str(b["positions"]):
		errors.append("Seeded generation not deterministic")

	var logo_cells := 0
	for letter in "OMARCHY":
		for row: String in LevelGenerator.WORD_LETTERS[letter]:
			logo_cells += row.count("#")
	for level in [4, 14, 24]:
		var om: Dictionary = gen.generate(level, 7)
		if om["easter_id"] != "omarchy" or (om["positions"] as Array).size() != logo_cells:
			errors.append("Level %d is not the full OMARCHY level" % level)
	if LevelGenerator.is_omarchy_level(5) or LevelGenerator.is_omarchy_level(3):
		errors.append("OMARCHY level triggered on the wrong level")

	var capped := LevelGenerator.ball_speed_for_level(999)
	if not is_equal_approx(capped, LevelGenerator.MAX_SPEED):
		errors.append("Speed cap failed: %s" % str(capped))

	var theme_script := load("res://scripts/theme.gd")
	var parsed: Dictionary = theme_script._parse_colors_toml(
		"mode = \"dark\"\n# comment\naccent = \"#82FB9C\"\nbackground = \"#0B0C16\"\nforeground = \"#ddf7ff\"\nborder = \"rgba(1,2,3)\"\n"
	)
	if parsed.get("accent") != Color("82FB9C") or parsed.get("background") != Color("0B0C16") or parsed.has("mode") or parsed.has("border"):
		errors.append("colors.toml parsing failed: %s" % str(parsed))

	if errors.is_empty():
		print("SMOKE_OK levels=20 speed_cap=", capped, " sample_blocks=", (a["positions"] as Array).size())
	else:
		print("SMOKE_FAIL")
		for e in errors:
			print(" - ", e)

	quit()
