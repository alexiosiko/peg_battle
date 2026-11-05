extends Button

var waiting: bool = false

func _ready() -> void:
	pressed.connect(_on_pressed)
func _on_pressed() -> void:
	if waiting:
		return
	waiting = true
	#if not NetworkHandler.is_logged_in():
		#NetworkHandler.login_as_guest()
	NetworkHandler.leave_lobby()
	multiplayer.multiplayer_peer = OfflineMultiplayerPeer.new()
	SceneHandler.transition("res://scenes/game.tscn", "Loading local game")
