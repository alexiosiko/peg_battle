extends Control

@export var label: Label

func _ready() -> void:
	hide()
	NetworkHandler.failed_to_join_a_game.connect(_on_failed_to_join_game)
	NetworkHandler.joining_or_hosting_lobby.connect(_on_searching_for_game)
	NetworkHandler.game_found.connect(_on_game_found)
func _on_searching_for_game() -> void:
	show()
	label.text = "Searching for game..."
func _on_game_found() -> void:
	label.text = "Game found!"
func _on_failed_to_join_game() -> void:
	hide()
