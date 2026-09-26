class_name LevelGenerator
extends RefCounted
## Seeded endless level generation from reusable block patterns.

const BASE_SPEED := 280.0
const SPEED_INCREMENT := 12.0
const MAX_SPEED := 520.0
const BASE_COMPLEXITY := 1
const COMPLEXITY_INCREMENT := 1
const MAX_COMPLEXITY := 8
const POINTS_PER_BLOCK := 10

## Layout mirrors GameTheme playfield constants (kept local for tool/smoke use).
const BLOCK_SIZE := Vector2(48, 20)
const BLOCK_GAP := Vector2(4, 4)
const PLAY_MARGIN := 12.0
const WALL_THICKNESS := 8.0
const BLOCK_TOP := 72.0
const BLOCK_BOTTOM_MAX := 360.0
const VIEW_W := 960.0
const VIEW_H := 540.0

## Official-style wordmark bitmaps (Omarchy logo.txt / Salduu web logo).
const PATTERN_OMARCHY: Array = [
	[0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
	[1, 1, 1, 1, 0, 0, 1, 1, 1, 1, 1, 1, 0, 0, 1, 1, 1, 1, 0, 1, 1, 1, 1, 0, 1, 1, 1, 1, 0, 1, 1, 1, 1, 0, 1, 1, 0, 1],
	[1, 1, 0, 1, 1, 1, 1, 0, 1, 1, 0, 1, 1, 1, 1, 0, 1, 1, 1, 1, 0, 1, 1, 1, 1, 0, 1, 1, 0, 1, 1, 1, 1, 0, 1, 1, 0, 1],
	[1, 1, 0, 1, 1, 1, 1, 0, 1, 1, 0, 1, 1, 1, 1, 0, 1, 1, 1, 1, 0, 1, 1, 1, 1, 0, 1, 1, 0, 1, 1, 1, 1, 0, 1, 1, 0, 1],
	[1, 1, 0, 1, 1, 1, 1, 0, 1, 1, 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1],
	[1, 1, 0, 1, 1, 1, 1, 0, 1, 1, 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0, 1, 1, 0, 0, 0, 1, 1, 1, 1, 1, 0, 1, 1, 1, 1],
	[1, 1, 0, 1, 1, 1, 1, 0, 1, 1, 0, 1, 1, 1, 1, 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0, 1, 1, 0, 1, 1, 1, 1, 0, 1, 1, 0, 1],
	[1, 1, 0, 1, 1, 1, 1, 0, 1, 1, 0, 1, 1, 1, 1, 0, 1, 1, 1, 1, 0, 1, 1, 1, 1, 0, 1, 1, 0, 1, 1, 1, 1, 0, 1, 1, 0, 1],
	[1, 1, 1, 1, 0, 0, 1, 0, 1, 1, 0, 1, 0, 1, 1, 0, 1, 0, 1, 1, 0, 1, 1, 1, 1, 1, 1, 1, 0, 1, 0, 1, 1, 0, 1, 1, 1, 1],
]

const PATTERN_SALDUU: Array = [
	[0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 0, 0, 0, 0, 0, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
	[0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 0, 0, 0, 0, 0, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
	[0, 1, 1, 1, 0, 0, 0, 1, 1, 1, 0, 0, 1, 1, 0, 0, 1, 1, 0, 1, 1, 0, 0, 0, 0, 0, 1, 0, 1, 0, 0, 0, 0, 1],
	[1, 1, 1, 1, 1, 0, 0, 1, 1, 1, 1, 0, 1, 1, 0, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0, 0, 1, 1, 1, 0, 0, 0, 1, 1],
	[1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 1, 1, 1, 0, 0, 0, 1, 1, 1, 1, 0, 0, 0, 1, 1, 1, 0, 0, 0, 1, 1],
	[1, 1, 1, 1, 0, 0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0, 0, 1, 1, 1, 1, 0, 0, 0, 1, 1, 1, 0, 0, 0, 1, 1],
	[0, 0, 1, 1, 1, 0, 1, 1, 0, 0, 1, 1, 1, 1, 1, 1, 0, 0, 0, 1, 1, 1, 1, 0, 0, 0, 1, 1, 1, 0, 0, 0, 1, 1],
	[1, 1, 1, 1, 1, 0, 1, 1, 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1],
	[1, 1, 1, 1, 0, 0, 1, 1, 1, 1, 1, 0, 1, 0, 0, 1, 1, 1, 1, 1, 0, 0, 1, 1, 1, 1, 1, 0, 0, 1, 1, 1, 1, 1],
]

const EASTER_MIN_LEVEL := 3
const EASTER_CHANCE := 0.14
## Guaranteed OMARCHY word level: 4, 14, 24, ...
const OMARCHY_LEVEL := 4
const OMARCHY_LEVEL_EVERY := 10
const WORD_BLOCK_SIZE := Vector2(19, 22)
const WORD_BLOCK_GAP := Vector2(2, 2)
const WORD_LETTERS := {
	"O": [".###.", "#...#", "#...#", "#...#", "#...#", "#...#", ".###."],
	"M": ["#...#", "##.##", "#.#.#", "#.#.#", "#...#", "#...#", "#...#"],
	"A": [".###.", "#...#", "#...#", "#####", "#...#", "#...#", "#...#"],
	"R": ["####.", "#...#", "#...#", "####.", "#.#..", "#..#.", "#...#"],
	"C": [".####", "#....", "#....", "#....", "#....", "#....", ".####"],
	"H": ["#...#", "#...#", "#...#", "#####", "#...#", "#...#", "#...#"],
	"Y": ["#...#", "#...#", ".#.#.", "..#..", "..#..", "..#..", "..#.."],
}
const EASTER_BLOCK_SIZE := Vector2(20, 14)
const EASTER_BLOCK_GAP := Vector2(2, 2)

## Cell grid for patterns (relative). 1 = block, 0 = empty.
## Patterns are placed within the safe block region.

static func ball_speed_for_level(level: int) -> float:
	return minf(MAX_SPEED, BASE_SPEED + float(level - 1) * SPEED_INCREMENT)


static func is_omarchy_level(level: int) -> bool:
	return level >= OMARCHY_LEVEL and (level - OMARCHY_LEVEL) % OMARCHY_LEVEL_EVERY == 0


static func complexity_for_level(level: int) -> int:
	return mini(MAX_COMPLEXITY, BASE_COMPLEXITY + (level - 1) / 2 * COMPLEXITY_INCREMENT)


func generate(level: int, seed_value: int = -1) -> Dictionary:
	## Returns { positions, color_ids, easter, easter_id, seed, complexity, block_size, block_gap }
	var rng := RandomNumberGenerator.new()
	var used_seed := seed_value
	if used_seed < 0:
		used_seed = hash(level) ^ int(Time.get_ticks_msec())
	rng.seed = used_seed as int

	var complexity := complexity_for_level(level)
	var easter_id := ""
	var cells: Dictionary = {}  # Vector2i -> Color index
	var block_size := BLOCK_SIZE
	var block_gap := BLOCK_GAP

	if is_omarchy_level(level):
		block_size = WORD_BLOCK_SIZE
		block_gap = WORD_BLOCK_GAP
		_stamp_word(cells, "OMARCHY", Vector2i(0, 1))
		easter_id = "omarchy"
	# Rare logo easter eggs from level 3+ (no score/rule changes)
	elif level >= EASTER_MIN_LEVEL and rng.randf() < EASTER_CHANCE:
		block_size = EASTER_BLOCK_SIZE
		block_gap = EASTER_BLOCK_GAP
		if rng.randf() < 0.5:
			_stamp_logo(cells, PATTERN_SALDUU)
			easter_id = "salduu"
		else:
			_stamp_logo(cells, PATTERN_OMARCHY)
			easter_id = "omarchy"
	else:
		var pattern_count := mini(3, 1 + complexity / 2)
		for i in pattern_count:
			var pattern := _pick_pattern(rng, complexity)
			var ox := rng.randi_range(0, 14)
			var oy := rng.randi_range(0, maxi(0, 6 + complexity))
			_stamp(cells, pattern, Vector2i(ox, oy), i)

		if cells.is_empty():
			_stamp(cells, _pattern_row(10), Vector2i(2, 1), 0)

	var layout := _cells_to_world(cells, block_size, block_gap)
	layout["easter"] = easter_id != ""
	layout["easter_id"] = easter_id
	layout["seed"] = used_seed
	layout["complexity"] = complexity
	layout["block_size"] = block_size
	layout["block_gap"] = block_gap
	return layout



func _cells_to_world(cells: Dictionary, size: Vector2 = BLOCK_SIZE, gap: Vector2 = BLOCK_GAP) -> Dictionary:
	var positions: Array[Vector2] = []
	var color_ids: Array[int] = []
	var origin_x := PLAY_MARGIN + WALL_THICKNESS + 12.0
	var origin_y := BLOCK_TOP

	# Clamp so blocks stay above paddle / launch area
	var max_row := int((BLOCK_BOTTOM_MAX - origin_y) / (size.y + gap.y))
	var max_col := int(
		(VIEW_W - 2.0 * (PLAY_MARGIN + WALL_THICKNESS) - 24.0)
		/ (size.x + gap.x)
	)

	# Center the pattern's actual bounding box horizontally
	var min_x := 1 << 30
	var max_x := -(1 << 30)
	for key in cells.keys():
		min_x = mini(min_x, (key as Vector2i).x)
		max_x = maxi(max_x, (key as Vector2i).x)
	var x_offset := 0
	if not cells.is_empty():
		var span := max_x - min_x + 1
		x_offset = maxi(0, int((max_col - span) * 0.5)) - min_x

	for key in cells.keys():
		var cell: Vector2i = key
		var cx := cell.x + x_offset
		if cx < 0 or cell.y < 0 or cx > max_col or cell.y > max_row:
			continue
		var pos := Vector2(
			origin_x + float(cx) * (size.x + gap.x) + size.x * 0.5,
			origin_y + float(cell.y) * (size.y + gap.y) + size.y * 0.5
		)
		positions.append(pos)
		color_ids.append(int(cells[key]))

	return {"positions": positions, "color_ids": color_ids}


func _stamp(cells: Dictionary, pattern: Array, origin: Vector2i, color_base: int) -> void:
	for y in pattern.size():
		var row: Array = pattern[y]
		for x in row.size():
			if int(row[x]) == 0:
				continue
			var key := Vector2i(origin.x + x, origin.y + y)
			cells[key] = color_base + x + y


func _pick_pattern(rng: RandomNumberGenerator, complexity: int) -> Array:
	var pool: Array = [
		_pattern_row(8 + complexity),
		_pattern_grid(6 + complexity / 2, 2 + complexity / 3),
		_pattern_diamond(2 + complexity / 3),
		_pattern_staggered(7 + complexity / 2, 2 + complexity / 3),
		_pattern_pyramid(4 + complexity / 2),
		_pattern_checker(6, 3),
	]
	if complexity >= 4:
		pool.append(_pattern_hollow_box(5 + complexity / 2, 3))
	if complexity >= 6:
		pool.append(_pattern_zigzag(8, 3))
	return pool[rng.randi_range(0, pool.size() - 1)]


func _pattern_row(width: int) -> Array:
	var row: Array = []
	for i in width:
		row.append(1)
	return [row]


func _pattern_grid(w: int, h: int) -> Array:
	var rows: Array = []
	for _y in h:
		var row: Array = []
		for _x in w:
			row.append(1)
		rows.append(row)
	return rows


func _pattern_diamond(radius: int) -> Array:
	var size := radius * 2 + 1
	var rows: Array = []
	for y in size:
		var row: Array = []
		for x in size:
			var d := absi(x - radius) + absi(y - radius)
			row.append(1 if d <= radius else 0)
		rows.append(row)
	return rows


func _pattern_staggered(w: int, h: int) -> Array:
	var rows: Array = []
	for y in h:
		var row: Array = []
		for x in w:
			row.append(1 if (x + y) % 2 == 0 else 0)
		rows.append(row)
	return rows


func _pattern_pyramid(height: int) -> Array:
	var rows: Array = []
	var width := height * 2 - 1
	for y in height:
		var row: Array = []
		var fill_start := height - 1 - y
		var fill_end := height - 1 + y
		for x in width:
			row.append(1 if x >= fill_start and x <= fill_end else 0)
		rows.append(row)
	return rows


func _pattern_checker(w: int, h: int) -> Array:
	return _pattern_staggered(w, h)


func _pattern_hollow_box(w: int, h: int) -> Array:
	var rows: Array = []
	for y in h:
		var row: Array = []
		for x in w:
			var edge := y == 0 or y == h - 1 or x == 0 or x == w - 1
			row.append(1 if edge else 0)
		rows.append(row)
	return rows


func _pattern_zigzag(w: int, h: int) -> Array:
	var rows: Array = []
	for y in h:
		var row: Array = []
		for x in w:
			row.append(1 if (x + (0 if y % 2 == 0 else 1)) % 3 != 0 else 0)
		rows.append(row)
	return rows


func _stamp_word(cells: Dictionary, word: String, origin: Vector2i) -> void:
	## Block letters from WORD_LETTERS, one column apart, one color per letter.
	var x := origin.x
	for i in word.length():
		var glyph: Array = WORD_LETTERS[word[i]]
		for y in glyph.size():
			var row: String = glyph[y]
			for gx in row.length():
				if row[gx] == "#":
					cells[Vector2i(x + gx, origin.y + y)] = i
		x += (glyph[0] as String).length() + 1


func _stamp_logo(cells: Dictionary, pattern: Array) -> void:
	## Stamp a logo bitmap using existing block graphics (no external assets).
	_stamp(cells, pattern, Vector2i.ZERO, 0)


