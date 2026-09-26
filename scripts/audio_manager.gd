extends Node
## Simple SFX player. Game stays fully playable if streams fail to load.

var muted: bool = false

var _hit: AudioStream
var _block: AudioStream
var _life: AudioStream
var _level: AudioStream
var _record: AudioStream
var _ui: AudioStream
var _players: Array[AudioStreamPlayer] = []


func _ready() -> void:
	_hit = load("res://assets/audio/hit.wav") as AudioStream
	_block = load("res://assets/audio/block.wav") as AudioStream
	_life = load("res://assets/audio/life.wav") as AudioStream
	_level = load("res://assets/audio/level.wav") as AudioStream
	_record = load("res://assets/audio/record.wav") as AudioStream
	_ui = load("res://assets/audio/ui.wav") as AudioStream
	for i in 6:
		var p := AudioStreamPlayer.new()
		p.bus = "Master"
		add_child(p)
		_players.append(p)


func play_hit() -> void:
	_play(_hit)


func play_block() -> void:
	_play(_block)


func play_life() -> void:
	_play(_life)


func play_level() -> void:
	_play(_level)


func play_record() -> void:
	_play(_record)


func play_ui() -> void:
	_play(_ui)


func _play(stream: AudioStream) -> void:
	if muted or stream == null:
		return
	for p in _players:
		if not p.playing:
			p.stream = stream
			p.play()
			return
	# All busy — reuse first
	_players[0].stream = stream
	_players[0].play()
