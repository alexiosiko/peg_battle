extends Line2D

# Ensure your Ball node script has 'class_name Ball' at the top, 
# or change this type to CharacterBody2D / RigidBody2D
@export var ball: Node2D 
@export var max_trail_points: int = 40
func _ready() -> void:
	await ball.ready
	var game: Game = get_tree().current_scene
	var player: Player = game.get_player(ball.get_multiplayer_authority())
	self_modulate = player.color
func _physics_process(_delta: float) -> void:
	# Make sure a ball was actually assigned in the Inspector
	if ball == null:
		return
		
	# 1. Use the ball's global position, not the line's position
	add_point(ball.global_position)
	
	# 2. Remove older points to maintain the length limit
	if points.size() > max_trail_points:
		remove_point(0)
