extends Button

@export var play_button: PlayButton
func _ready() -> void:
	pressed.connect(_on_pressed)
func _on_pressed() -> void:
	if play_button.is_searching:
		Toast.info("Busy searching....")
	await NetworkHandler.leave_lobby()
	multiplayer.multiplayer_peer = OfflineMultiplayerPeer.new()
	SceneHandler.transition("res://scenes/game.tscn", "Loading local game")
