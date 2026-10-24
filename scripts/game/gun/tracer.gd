extends Line2D

@export var gun: Gun
@export var ball_speed: float = 800.0  
@export var max_simulation_steps: int = 300 
@export var step_time: float = 0.02    

# Drag your ball's CircleShape2D resource here in the Inspector
@export var ball_collision_circle: CircleShape2D

@onready var gravity: float = ProjectSettings.get_setting("physics/2d/default_gravity")

func _process(_delta: float) -> void:
	if gun.waiting:
		clear_points()
		return
			
	_update_gravity_tracer()

func _update_gravity_tracer() -> void:
	clear_points()
	
	if not gun:
		return

	# Fallback if no CircleShape2D is assigned in the Inspector
	var circle_shape = ball_collision_circle
	if not circle_shape:
		circle_shape = CircleShape2D.new()
		circle_shape.radius = 12.0

	# Start drawing at local origin (0, 0) which is where this Line2D sits
	add_point(Vector2.ZERO)
	
	var simulated_global_pos: Vector2 = global_position
	var initial_direction: Vector2 = Vector2.DOWN.rotated(gun.global_rotation)
	var current_velocity: Vector2 = initial_direction * ball_speed
	
	var space_state = get_world_2d().direct_space_state
	
	# Prepare shape casting parameters
	var query = PhysicsShapeQueryParameters2D.new()
	query.shape = circle_shape
	query.collision_mask = 1 + 4

	for step in range(max_simulation_steps):
		current_velocity.y += gravity * step_time
		var displacement: Vector2 = current_velocity * step_time
		var target_global_pos: Vector2 = simulated_global_pos + displacement
		
		query.transform = Transform2D(0.0, simulated_global_pos)
		query.motion = displacement
		
		var results = space_state.cast_motion(query)
		
		# If results Array has fractions where the first value is less than 1.0, a collision occurred
		if results.size() > 0 and results[0] < 1.0:
			var safe_fraction = results[0]
			
			var collision_global_pos: Vector2 = simulated_global_pos + (displacement * safe_fraction)
			add_point(to_local(collision_global_pos))
			
			# Find collision normal vector
			var rest_query = PhysicsShapeQueryParameters2D.new()
			rest_query.shape = circle_shape
			rest_query.collision_mask = 1 + 4
			rest_query.transform = Transform2D(0.0, collision_global_pos + (displacement.normalized() * 0.1))
			
			var rest_info = space_state.get_rest_info(rest_query)
			var hit_normal: Vector2 = displacement.normalized() * -1.0
			
			if rest_info.has("normal"):
				hit_normal = rest_info["normal"]
			
			current_velocity = current_velocity.bounce(hit_normal)
			simulated_global_pos = collision_global_pos + (hit_normal * 0.1)
		else:
			add_point(to_local(target_global_pos))
			simulated_global_pos = target_global_pos
