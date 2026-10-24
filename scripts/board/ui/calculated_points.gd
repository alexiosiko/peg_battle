extends CanvasLayer

@export var cash_in_stream: AudioStream
@export var client_player_ui: PlayerUI
@export var host_player_ui: PlayerUI
@export var points_ui_pop: PackedScene

var board: Board
var current_streak: int = 0
var current_multiplier: float = 1.0 # Tracks the rolling multiplier total

func _ready() -> void:
	Signals.board_ready.connect(_on_board_ready)

func _on_board_ready(b: Board) -> void:
	board = b
	board.round_over.connect(_on_round_over)
	
	for peg: Peg in board.pegs:
		peg.dying.connect(_on_dying.bind(peg))
func _on_dying(client_id: int, peg: Peg) -> void:
	# 1. Track cumulative numbers matching the server logic
	current_streak += 1 
	current_multiplier += peg.data.multi
	
	var individual_peg_points: int = peg.data.points + (current_streak)
	
	var pop: PointsPopUI = points_ui_pop.instantiate()
	var target_ui: PlayerUI = host_player_ui if client_id == 1 else client_player_ui
	
	var from_pos: Vector2 = peg.get_global_transform_with_canvas().origin
	var to_pos: Vector2 = target_ui.get_global_rect().get_center()
	
	# Pass a reference to target_ui, and pass along the multiplier data for step 2!
	pop.init_sequenced(
		individual_peg_points, 
		current_multiplier, 
		peg.data.multi, 
		from_pos, 
		to_pos, 
		1,
		target_ui
	)
	add_child(pop)


func _on_round_over(_total_points: int) -> void:
	# Reset both trackers when the board finishes scoring
	current_streak = 0
	current_multiplier = 1.0
