class_name SoundBank
extends Node
## Reusable randomized sound bank (Phase 3 revision).
## Plays ONE random variation per event through a small pool of players, so
## repeated events overlap naturally instead of cutting each other off.
## Immediate repetition of the same variation is avoided when the bank holds
## more than one stream. Future weapons can simply add another bank node.

@export var streams : Array[AudioStream] = []
@export var pool_size : int = 4
@export var volume_db : float = 0.0

var _players : Array[AudioStreamPlayer] = []
var _last_index : int = -1


func _ready() -> void:
	pool_size = maxi(pool_size, 1)
	for _i in pool_size:
		var player := AudioStreamPlayer.new()
		player.bus = "Master"
		player.volume_db = volume_db
		add_child(player)
		_players.append(player)


## Public: play exactly one randomly selected variation per event.
func play_random() -> void:
	if streams.is_empty():
		DebugLog.warn("SoundBank '%s' has no streams assigned" % name)
		return
	var index := _pick_index()
	_last_index = index
	var player := _acquire_player()
	player.stream = streams[index]
	player.play()


func _pick_index() -> int:
	if streams.size() == 1:
		return 0
	var index := randi_range(0, streams.size() - 1)
	while index == _last_index:
		index = randi_range(0, streams.size() - 1)
	return index


## Returns a free player; if the whole pool is busy, steals the player closest
## to finishing so the pool stays bounded and the oldest sound is interrupted
## as late as possible.
func _acquire_player() -> AudioStreamPlayer:
	for player in _players:
		if not player.playing:
			return player
	var victim : AudioStreamPlayer = _players[0]
	for player in _players:
		if player.get_playback_position() > victim.get_playback_position():
			victim = player
	return victim