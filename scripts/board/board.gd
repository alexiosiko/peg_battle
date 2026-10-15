class_name Board extends Node2D

@export var pegs_container: Node2D

signal round_over(points: int)

var _pegs: Array[Peg]
var gun: Gun

var round_points: int = 0
var round_multi: int = 1 # Start at 1 so multiplication math works on first hits
var highlighted_pegs: Array[Peg]

func _ready() -> void:
	for i in range(pegs_container.get_child_count()):
		var peg: Peg = pegs_container.get_child(i)
		peg.id = i
		if peg.type == Peg.Type.OBSTACLE:
			continue
		_pegs.append(peg)
		peg.peg_hit.connect(_on_peg_hit)
	
	gun = get_tree().get_first_node_in_group("gun")
	gun.ball_spawned.connect(_on_ball_spawned)
	Signals.board_ready.emit(self)
func _on_peg_hit(p: Peg) -> void:
	if p.has_hit == true:
		return
	if p.type == Peg.Type.MULTIPLIER:
		round_multi += p.multi
	else:
		round_points += p.points
	
	highlighted_pegs.append(p)
func _on_ball_spawned(b: Ball) -> void:
	if b.is_multiplayer_authority():
		print("im listening to ball")
		b.tree_exiting.connect(_on_ball_exited)
		b.ball_stuck.connect(_on_ball_stuck)
	else:
		print("im NOTTTT listening to ball")
func _on_ball_stuck() -> void:
	print("ball is stuck")
	if highlighted_pegs.is_empty():
		return
	for i in range(highlighted_pegs.size(), -1 ,-1):
		var peg: Peg = highlighted_pegs[i]
		if peg.is_faded:
			continue
		peg.fade()
		return
	#highlighted_pegs.erase(peg)
func _on_ball_exited() -> void:
	print("ball exited")
	var total_calculated_points = round_points * round_multi
	round_points = 0
	round_multi = 1
	var peg_ids: PackedInt32Array = _get_peg_ids()
	print(peg_ids)
	await Synchronzier.call_and_wait_for_clients(_clear_pegs, peg_ids)
	print("got here")
	Synchronzier.emit_on_all(round_over, total_calculated_points)
func _get_peg_ids() -> PackedInt32Array:
	var ids: PackedInt32Array = []
	for peg in highlighted_pegs:
		if not is_instance_valid(peg):
			continue
		ids.append(peg.id)
	return ids
@rpc("call_local", "any_peer")
func _clear_pegs(ids: PackedInt32Array) -> void:
	print("clearnig pegss")
	var copy_pegs: Array[Peg] = _pegs.duplicate()
	for peg in copy_pegs:
		if ids.has(peg.id):
			peg.die()
			_pegs.erase(peg)
			await get_tree().create_timer(0.1).timeout
	highlighted_pegs.clear()
func has_pegs() -> bool:
	return not _pegs.is_empty()
