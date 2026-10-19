extends Control

@export var game: Game
func _ready() -> void:
	hide()
	#game.game_started.connect(_on_game_started)
	game.game_over.connect(_on_game_over)
#func _on_game_started() -> void:
	#hide()
func _on_game_over(host_player: Player, client_player: Player) -> void:
	var _winner: Player
	if host_player.points > client_player.points:
		_winner = host_player
	elif host_player.points < client_player.points:
		_winner = client_player
	else:
		_winner = null
	show()
	NetworkHandler.leave_lobby()
