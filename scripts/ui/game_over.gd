extends Control

@export var anim_player: AnimationPlayer
@export var game: Game
@export var host_stats: PlayerStats
@export var client_stats: PlayerStats
@export var win_sound: AudioStream
@export var lose_sound: AudioStream

func _ready() -> void:
	if not multiplayer.is_server():
		return
	game.game_over.connect(_on_game_over)

func _on_game_over(host_player: Player, client_player: Player) -> void:
	var _winner: Player
	if host_player.points > client_player.points:
		_winner = host_player
	else:
		_winner = client_player
	_winner.winner = true
	host_stats.init(host_player)
	client_stats.init(client_player)
	if _winner.client_id == multiplayer.get_unique_id():
		AudioHandler.play_sound(win_sound)
	else:
		AudioHandler.play_sound(lose_sound)
	anim_player.play("open")
	NetworkHandler.leave_lobby()
