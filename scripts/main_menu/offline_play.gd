extends Button

func _ready() -> void:
	pressed.connect(_on_pressed)
func _on_pressed() -> void:
	multiplayer.multiplayer_peer = OfflineMultiplayerPeer.new()
	SceneHandler.transition("res://scenes/game.tscn")
