extends Button

func _ready() -> void:
	pressed.connect(_on_pressed)
func _on_pressed() -> void:
	if not NetworkHandler.is_logged_in():
		await NetworkHandler.login_as_guest()
	await NetworkHandler.leave_lobby()
	multiplayer.multiplayer_peer = OfflineMultiplayerPeer.new()
	SceneHandler.transition("res://scenes/game.tscn", "Loading local game")
