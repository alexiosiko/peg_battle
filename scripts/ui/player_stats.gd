extends Control

@export var player: Player
@export var username_label: Label
@export var pegs_popped_label: Label
@export var balls_caught_label: Label
@export var total_points_label: Label

func init(username: String, pegs_popped: int, ball_caught: int, total_points: int) -> void:
	username_label.text = username
	pegs_popped_label.text = str(pegs_popped)
	balls_caught_label.text = str(ball_caught)
	total_points_label.text = str(total_points)
