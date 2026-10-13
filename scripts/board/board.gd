class_name Board extends Node2D


@export var pegs_container: Node2D

var _pegs: Array[Peg]
signal game_over
signal round_over(points: int)
signal ball_ready

var gun: Gun

var round_points: int = 0
var round_multi: int = 1 # Start at 1 so multiplication math works on first hits
var highlighted_pegs: Array[Peg]

func _ready() -> void:
	if not multiplayer.is_server():
		return
	gun = get_tree().get_first_node_in_group("gun")
	gun.ball_spawned.connect(_on_ball_spawned)
	for peg: Peg in pegs_container.get_children():
		if peg.type == Peg.Type.OBSTACLE:
			continue
		_pegs.append(peg)
		peg.peg_hit.connect(_on_peg_hit)
	Signals.board_ready.emit(self)
func _on_peg_hit(p: Peg) -> void:
	if p.has_hit:
		return
	p.has_hit = true # Prevent hitting a single peg multiple times per shot
	
	if p.type == Peg.Type.MULTIPLIER:
		round_multi += p.multi
	else:
		round_points += p.points
	
	highlighted_pegs.append(p)
func _on_ball_spawned(b: Ball) -> void:
	b.tree_exiting.connect(_on_ball_exited)
	b.ball_stuck.connect(_on_ball_stuck)
func _on_ball_stuck() -> void:
	#highlighted_pegs[highlighted_pegs.size() - 1]
	#for i in range(highlighted_pegs.size() - 1, -1, -1):
	if highlighted_pegs.is_empty():
		return
	var peg := highlighted_pegs[highlighted_pegs.size() - 1]
	peg.die.rpc()
	highlighted_pegs.erase(peg)
func _on_ball_exited() -> void:
	var total_calculated_points = round_points * round_multi
	round_over.emit(total_calculated_points)
	round_points = 0
	round_multi = 1
	await Synchronzier.call_and_wait_for_clients(_clear_pegs)
	if has_pegs():
		ball_ready.emit()
	else:
		game_over.emit()
func _clear_pegs() -> void:
	for p in highlighted_pegs:
		if is_instance_valid(p):
			p.die.rpc()
			await get_tree().create_timer(0.1).timeout
func has_pegs() -> bool:
	return not _pegs.is_empty()
