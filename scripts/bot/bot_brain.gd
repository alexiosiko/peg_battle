class_name BotBrain

static func pick_angle(board: Board, gun: Gun, skill: float = 0.7) -> float:
	if board.pegs.is_empty():
		return 0.0 # straight down

	var angle := 0.0

	for i in randi_range(2, 4):
		var pegs := board.pegs.filter(func(p): return is_instance_valid(p))
		if pegs.is_empty():
			break

		var target: Node2D = pegs.pick_random()
		angle = _angle_to(gun, target, skill)

		# Gun._process smoothly lerps toward this while waiting
		gun.target_rotation = angle

		await board.get_tree().create_timer(randf_range(0.25, 0.6)).timeout

	return angle


static func _angle_to(gun: Gun, target: Node2D, skill: float) -> float:
	var dir := (target.global_position - gun.global_position).angle()
	var ideal := wrapf(dir + deg_to_rad(gun.aim_offset_degrees), -PI, PI)
	var noise := randfn(0.0, (1.0 - skill) * 0.25)
	return clampf(ideal + noise, deg_to_rad(gun.min_angle), deg_to_rad(gun.max_angle))
