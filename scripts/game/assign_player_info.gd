extends Node

@export var host_player: Player
@export var client_player: Player

func _ready() -> void:
	Signals.board_ready.connect(_on_board_ready)
func _on_board_ready(_b: Board) -> void:
	if multiplayer.is_server():
		host_player.set_info.rpc(NetworkHandler.user_info)
	else:
		client_player.set_info.rpc(NetworkHandler.user_info)
