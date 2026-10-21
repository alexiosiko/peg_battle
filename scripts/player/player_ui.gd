class_name PlayerUI extends Control

@export var player: Player
@export var points: Label
@export var username: Label
@export var game: Game
@export var is_client: bool
func _ready() -> void:
	Signals.board_ready.connect(_on_board_ready)
func _on_board_ready(_b: Board) -> void:
	if game.is_solo:
		if is_client:
			hide()
