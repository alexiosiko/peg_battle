extends Line2D

@export var gun: Gun
@export var ball_speed: float = 800.0  
@export var max_simulation_steps: int = 300 
@export var step_time: float = 0.02    

## Explicitly drag your ball's real collision shape resource here for maximum accuracy
@export var ball_collision_shape: Shape2D

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

	# Fallback if no specific shape resource is assigned in the Inspector
	var shape = ball_collision_shape
	if not shape:
		var circle = CircleShape2D.new()
		circle.radius = 12.0
		shape = circle

	# Start drawing at local origin (0, 0) where this Line2D is attached
	add_point(Vector2.ZERO)
	
	var simulated_global_pos: Vector2 = global_position
	var initial_direction: Vector2 = Vector2.DOWN.rotated(gun.global_rotation)
	var current_velocity: Vector2 = initial_direction * ball_speed
	
	var space_state = get_world_2d().direct_space_state
	
	# Prepare shape casting parameters
	var query = PhysicsShapeQueryParameters2D.new()
	query.shape = shape
	query.collision_mask = 1 + 4

	for step in range(max_simulation_steps):
		current_velocity.y += gravity * step_time
		var displacement: Vector2 = current_velocity * step_time
		
		# Sub-stepping loop: processes the entire displacement even if multiple bounces happen inside this step_time
		var distance_left_fraction: float = 1.0
		var max_bounces_per_step: int = 4 # Safety cap to prevent infinite bounce loops in tight corners
		
		while distance_left_fraction > 0.001 and max_bounces_per_step > 0:
			var segment_displacement: Vector2 = displacement * distance_left_fraction
			
			query.transform = Transform2D(0.0, simulated_global_pos)
			query.motion = segment_displacement
			
			var results = space_state.cast_motion(query)
			
			if results.size() > 0 and results[0] < 1.0:
				var safe_fraction = results[0]
				
				# Move up to the point of impact
				simulated_global_pos += segment_displacement * safe_fraction
				
				# Find collision normal vector using a rest query slightly pushed forward into the surface
				var rest_query = PhysicsShapeQueryParameters2D.new()
				rest_query.shape = shape
				rest_query.collision_mask = 1 + 4
				rest_query.transform = Transform2D(0.0, simulated_global_pos + (segment_displacement.normalized() * 0.1))
				
				var rest_info = space_state.get_rest_info(rest_query)
				var hit_normal: Vector2 = segment_displacement.normalized() * -1.0
				
				if rest_info.has("normal"):
					hit_normal = rest_info["normal"]
				
				# Bounce the remaining velocity vectors
				current_velocity = current_velocity.bounce(hit_normal)
				displacement = displacement.bounce(hit_normal)
				
				# Slightly back off the surface along the normal vector to prevent getting stuck inside geometry
				simulated_global_pos += hit_normal * 0.1
				
				# Deduct the fraction of distance we already traveled
				distance_left_fraction *= (1.0 - safe_fraction)
				max_bounces_per_step -= 1
			else:
				# No collision, complete the full movement segment
				simulated_global_pos += segment_displacement
				distance_left_fraction = 0.0
				
		add_point(to_local(simulated_global_pos))
