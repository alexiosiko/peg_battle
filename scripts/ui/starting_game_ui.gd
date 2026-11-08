extends Control

@export var game: Game
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if game.is_offline():
		hide()
