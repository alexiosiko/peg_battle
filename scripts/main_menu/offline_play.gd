extends Button

func _ready() -> void:
	pressed.connect(_on_pressed)
func _on_pressed() -> void:
	NetworkHandler.user_info = PlayerInfo.new()
	await NetworkHandler.leave_lobby()
	multiplayer.multiplayer_peer = OfflineMultiplayerPeer.new()
	SceneHandler.transition("res://scenes/game.tscn", "Loading local game")
