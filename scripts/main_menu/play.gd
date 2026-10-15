extends Button

func _ready() -> void:
	pressed.connect(_on_pressed)
	multiplayer.peer_connected.connect(_on_peer_connected)
func _on_peer_connected(_id: int) -> void:
	if multiplayer.is_server():
		await Synchronzier.call_and_wait_for_clients(_transition_to_game)
func _on_pressed() -> void:
	print("searching for lobby ...")
	disabled = true
	var error: Error = await NetworkHandler.host()
	if error != OK:
		disabled = false

@rpc("call_local")
func _transition_to_game() -> void:
	get_tree().change_scene_to_file.call_deferred("res://scenes/game.tscn")
