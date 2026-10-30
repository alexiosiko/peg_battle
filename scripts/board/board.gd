class_name Board extends Node2D

@export var pegs_container: Node2D
@export var wall_hit_stream: AudioStream
@export var num_starting_balls: int = 5
@export var voids: Array[Void]
@export var ball_catcher: Catcher
@export var background_color: Color = Color("#fae6d6")
signal round_over(points: int)
var pegs: Array[Peg]
var gun: Gun
var ball_count: int = 0
var popped_pegs: Array[Peg]

@rpc("call_local", "any_peer")
func hit() -> void:
	AudioHandler.play_sound(wall_hit_stream)
func _ready() -> void:
	RenderingServer.set_default_clear_color(background_color)
	for i in range(pegs_container.get_child_count()):
		var peg: Peg = pegs_container.get_child(i)
		peg.id = i
		if peg.data.type == PegData.Type.OBSTACLE:
			continue
		pegs.append(peg)
		peg.pop.connect(_on_peg_poppped)
	for v: Void in voids:
		v.voided_ball.connect(_on_voided_ball)
	ball_catcher.ball_caught.connect(_on_ball_caught)
	gun = get_tree().get_first_node_in_group("gun")
	gun.ball_spawned.connect(_on_ball_spawned)
	await get_tree().create_timer(1).timeout
	Signals.board_ready.emit(self)
func _on_ball_caught(_ball: Ball) -> void:
	_on_voided_ball(Void.Type.HALF, _ball)
func _on_voided_ball(_type: Void.Type, ball: Ball) -> void:
	print("board void handling")
	ball_count -= 1
	print("ball count: ", ball_count)
	if ball_count != 0:
		return
		
	var destroy_peg_ids: PackedInt32Array = _get_peg_ids()
	var round_points: int = 0
	var index: int = 1
	var multiplier: int = 1
	
	# Ensures order of execution matches exactly how they are processed
	for p: Peg in pegs:
		if destroy_peg_ids.has(p.id):
			round_points += p.data.points + index
			index += 1
			multiplier += p.data.multi
	var total_calculated_points = round_points * multiplier
	var temp_array = Array(destroy_peg_ids)
	temp_array.shuffle()
	match _type:
		Void.Type.HALF:
			temp_array = temp_array.slice(0, (int)(temp_array.size() * 0.5))
		Void.Type.THREE_QUARTER:
			temp_array = temp_array.slice(0, (int)(temp_array.size() * 0.75))
	var respawn_peg_ids = PackedInt32Array(temp_array)

	await Synchronzier.call_and_wait_for_clients(_clear_and_respawn_pegs, destroy_peg_ids, respawn_peg_ids, ball.get_multiplayer_authority())
	Synchronzier.emit_on_all(round_over, total_calculated_points)
func _on_peg_poppped(p: Peg) -> void:
	popped_pegs.append(p)
func _on_ball_spawned(b: Ball) -> void:
	if b.is_multiplayer_authority():
		print("im listening to ball")
		ball_count += 1
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
func _get_peg_ids() -> PackedInt32Array:
	var ids: PackedInt32Array = []
	for peg in popped_pegs:
		if not is_instance_valid(peg):
			continue
		ids.append(peg.id)
	return ids
@rpc("call_local", "any_peer")
func _clear_and_respawn_pegs(destroy_peg_ids: PackedInt32Array, respawn_peg_ids: PackedInt32Array, client_id_that_shot_the_ball: int) -> void:
	print("clearnig pegss")
	var copy_pegs: Array[Peg] = pegs.duplicate()
	var revive_pegs: Array[Peg]
	for peg in copy_pegs:
		if destroy_peg_ids.has(peg.id):
			if respawn_peg_ids.has(peg.id):
				revive_pegs.append(peg)
				peg.die(client_id_that_shot_the_ball, true)
			else:
				pegs.erase(peg)
				peg.die(client_id_that_shot_the_ball)
			if is_inside_tree():
				await get_tree().create_timer(0.1).timeout
	if not destroy_peg_ids.is_empty() && is_inside_tree():
		await get_tree().create_timer(1.5).timeout
	for peg in revive_pegs:
		peg.revive()
		if is_inside_tree():
			await get_tree().create_timer(0.1).timeout
	if is_inside_tree():
		await get_tree().create_timer(1).timeout
	popped_pegs.clear()
func has_pegs() -> bool:
	return not pegs.is_empty()
