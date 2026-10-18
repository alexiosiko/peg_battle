class_name Board extends Node2D

@export var pegs_container: Node2D

signal round_over(points: int)
var pegs: Array[Peg]
var gun: Gun
var ball_count: int = 0

var popped_pegs: Array[Peg]

func _ready() -> void:
	for i in range(pegs_container.get_child_count()):
		var peg: Peg = pegs_container.get_child(i)
		peg.id = i
		if peg.data.type == PegData.Type.OBSTACLE:
			continue
		pegs.append(peg)
		peg.pop.connect(_on_peg_poppped)
	gun = get_tree().get_first_node_in_group("gun")
	gun.ball_spawned.connect(_on_ball_spawned)
	await get_tree().create_timer(1).timeout
	Signals.board_ready.emit(self)
func _on_peg_poppped(p: Peg) -> void:
	popped_pegs.append(p)
func _on_ball_spawned(b: Ball) -> void:
	if b.is_multiplayer_authority():
		print("im listening to ball")
		ball_count += 1
		b.tree_exiting.connect(_on_ball_exited.bind(b.get_multiplayer_authority()))
		b.ball_stuck.connect(_on_ball_stuck)
	else:
		print("im NOTTTT listening to ball")
func _on_ball_stuck() -> void:
	print("ball is stuck")
	if popped_pegs.is_empty():
		return
	for i in range(popped_pegs.size() - 1, -1 ,-1):
		var peg: Peg = popped_pegs[i]
		if peg.is_faded:
			continue
		peg.fade.rpc()
		return
	#popped_pegs.erase(peg)
func _on_ball_exited(client_id_that_shot_ball: int) -> void:
	ball_count -= 1
	if ball_count != 0:
		print("ball exited, still " , ball_count, " left in board")
		return
	var peg_ids: PackedInt32Array = _get_peg_ids()
	
	var round_points: int = 0
	var round_multi: int = 1
	for p: Peg in pegs:
		if peg_ids.has(p.id):
			round_points += p.data.points
			round_multi += p.data.multi
		
	var total_calculated_points = round_points * round_multi
	print("server is telling to clearn pegs with client id that shot the ball: ", client_id_that_shot_ball)
	await Synchronzier.call_and_wait_for_clients(_clear_pegs, peg_ids, client_id_that_shot_ball)
	print("round over")
	Synchronzier.emit_on_all(round_over, total_calculated_points)
func _get_peg_ids() -> PackedInt32Array:
	var ids: PackedInt32Array = []
	for peg in popped_pegs:
		if not is_instance_valid(peg):
			continue
		ids.append(peg.id)
	return ids
@rpc("call_local", "any_peer")
func _clear_pegs(ids: PackedInt32Array,  client_id_that_shot_the_ball: int) -> void:
	print("clearnig pegss")
	var copy_pegs: Array[Peg] = pegs.duplicate()
	for peg in copy_pegs:
		if ids.has(peg.id):
			peg.die(client_id_that_shot_the_ball)
			pegs.erase(peg)
			if is_inside_tree():
				await get_tree().create_timer(0.1).timeout
	if is_inside_tree():
		await get_tree().create_timer(1).timeout
	popped_pegs.clear()
func has_pegs() -> bool:
	return not pegs.is_empty()
