extends CanvasLayer  # was: extends Node

@export var cash_in_stream: AudioStream
@export var client_player_ui: PlayerUI
@export var host_player_ui: PlayerUI
@export var points_ui_pop: PackedScene

var board: Board


func _ready() -> void:
	layer = 10  # above the rest of your UI
	Signals.board_ready.connect(_on_board_ready)

func _on_board_ready(b: Board) -> void:
	board = b
	for peg: Peg in board.pegs:
		peg.dying.connect(_on_dying.bind(peg))

func _on_dying(client_id: int, peg: Peg) -> void:
	if peg.hit_by_player == null:
		return
	var pop: PointsPopUI = points_ui_pop.instantiate()
	var target_ui: PlayerUI = host_player_ui if client_id == 1 else client_player_ui
	var from_pos: Vector2 = peg.get_global_transform_with_canvas().origin
	var to_pos: Vector2 = target_ui.get_global_rect().get_center()
	pop.init(peg.data.points, from_pos, to_pos)
	add_child(pop)
