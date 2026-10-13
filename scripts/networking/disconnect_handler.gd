extends Node

func _ready() -> void:
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	multiplayer.server_disconnected.connect(_on_server_disconnect)
func _on_peer_disconnected(_id: int) -> void:
	print("client has disconnected")
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
func _on_server_disconnect() -> void:
	print("disconnected to server")
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
