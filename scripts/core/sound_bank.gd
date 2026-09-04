class_name SoundBank
extends Node
## Small reusable randomized sound bank (Phase 3 audio).
## Register one or more banks (named lists of AudioStream); play(name) plays exactly one
## randomly selected variation and avoids immediately repeating the same one when the bank
## has more than one entry. Built entirely on the engine's AudioStreamPlayer.

## Default shoot bank (one-shot weapon sound variations).
const SHOOT_STREAMS := [
	preload("res://assets/audio/shoot/shoot1.mp3"),
	preload("res://assets/audio/shoot/shoot2.mp3"),
]

## Default impact bank (surface-impact sound variations).
const IMPACT_STREAMS := [
	preload("res://assets/audio/impact/impact.mp3"),
	preload("res://assets/audio/impact/heavy-impact.mp3"),
	preload("res://assets/audio/impact/deep-heavy-impact.mp3"),
]

var _banks : Dictionary = {} ## bank_name -> Array[AudioStream]
var _players : Dictionary = {} ## bank_name -> AudioStreamPlayer
var _last_index : Dictionary = {} ## bank_name -> int (last played variation, -1 = none)


func _ready() -> void:
	# Register the Phase 3 banks. Future weapons can call register_bank() to add their own.
	register_bank("shoot", SHOOT_STREAMS)
	register_bank("impact", IMPACT_STREAMS)


## Registers (or replaces) a named bank. Reusable so future weapons/weapons own variations.
func register_bank(bank_name : String, streams : Array) -> void:
	_banks[bank_name] = streams
	_last_index[bank_name] = -1
	var player := AudioStreamPlayer.new()
	player.name = "SoundPlayer_%s" % bank_name
	add_child(player)
	_players[bank_name] = player


## Plays exactly one random variation from the named bank. Does nothing if the bank is
## missing or empty. Returns true if a sound started playing.
func play(bank_name : String) -> bool:
	if not _banks.has(bank_name):
		return false
	var streams : Array = _banks[bank_name]
	if streams.is_empty():
		return false
	var index := _pick_index(bank_name, streams.size())
	var player : AudioStreamPlayer = _players[bank_name]
	player.stream = streams[index]
	player.play()
	return true


## Last played variation index for the named bank (-1 if none yet). Used for tests.
func get_last_index(bank_name : String) -> int:
	return _last_index.get(bank_name, -1)


func _pick_index(bank_name : String, count : int) -> int:
	if count <= 1:
		_last_index[bank_name] = 0
		return 0
	var last : int = _last_index.get(bank_name, -1)
	var index := randi() % count
	if index == last:
		index = (index + 1) % count
	_last_index[bank_name] = index
	return index