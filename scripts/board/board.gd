class_name Board extends Node2D

@export var pegs_container: Node2D
@export var wall_hit_stream: AudioStream
@export var num_starting_balls: int = 5
signal round_over(points: int)
var pegs: Array[Peg]
var gun: Gun
var ball_count: int = 0

var popped_pegs: Array[Peg]

@rpc("call_local", "any_peer")
func hit() -> void:
	AudioHandler.play_sound(wall_hit_stream)
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
		b.ball_stuck.connect(_on_ball_stuck.bind(b))
	else:
		print("im NOTTTT listening to ball")
func _on_ball_stuck(b: Ball) -> void:
	print("ball is stuck")
	if popped_pegs.is_empty():
		return
	var q: PhysicsShapeQueryParameters2D = PhysicsShapeQueryParameters2D.new()
	q.transform = Transform2D(0, b.global_position)
	q.collision_mask = 4 # for pegs
	q.collide_with_bodies = true
	
	var shape: CircleShape2D = CircleShape2D.new()
	shape.radius = 30
	q.shape = shape
	
	var space = get_world_2d().direct_space_state
	var results: Array = space.intersect_shape(q)
	var closest_peg: Peg = null
	var closest_peg_distance_sqrd = INT32_MAX
	for r: Dictionary in results:
		var peg: Peg = r.collider
		print(peg)
		var d: float = b.global_position.distance_squared_to(peg.global_position)
		if d < closest_peg_distance_sqrd:
			closest_peg = peg
			closest_peg_distance_sqrd = d
	if closest_peg:
		closest_peg.fade.rpc()
	#popped_pegs.erase(peg)
func _on_ball_exited(client_id_that_shot_ball: int) -> void:
	ball_count -= 1
	if ball_count != 0:
		return
		
	var peg_ids: PackedInt32Array = _get_peg_ids()
	var round_points: int = 0
	var index: int = 1
	var multiplier: float = 1
	
	# Ensures order of execution matches exactly how they are processed
	for p: Peg in pegs:
		if peg_ids.has(p.id):
			round_points += p.data.points + index
			index += 1
			multiplier += p.data.multi
			
	var total_calculated_points = round_points * multiplier

	await Synchronzier.call_and_wait_for_clients(_clear_pegs, peg_ids, client_id_that_shot_ball)
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
