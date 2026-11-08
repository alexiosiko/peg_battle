class_name PlayerUI extends Control

@export var player: Player
@export var points: Label
@export var username: Label
@export var game: Game
@export var is_client: bool
@export var emoji_button: bool

func _ready() -> void:
	if game.is_offline() && is_client:
		modulate = Color(0,0,0,0)
	else:
		Signals.board_ready.connect(_on_board_ready)
func _on_board_ready(_b: Board) -> void:
	show()
