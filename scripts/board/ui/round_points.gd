extends Label

@export var board: Board

func _ready() -> void:
	board.round_points_changed.connect(_on_round_points_changed)
func _on_round_points_changed(p: int) -> void:
	text = str(p)
