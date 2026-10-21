class_name PlayerStats extends Control

@export var username_label: Label
@export var pegs_popped_label: Label
@export var balls_caught_label: Label
@export var total_points_label: Label

# only server calls this
func init(_player: Player) -> void:
	if _player == null:
		return
	var display_name: String
	if _player.player_info:
		display_name = _player.player_info.display_name
	else:
		display_name = "Empty"
	_sync.rpc(display_name, _player.pegs_popped, _player.balls_caught, _player.points)
@rpc("call_local")
func _sync(username: String, pegs_popped: int, ball_caught: int, total_points: int) -> void:
	username_label.text = username
	pegs_popped_label.text = str(pegs_popped)
	balls_caught_label.text = str(ball_caught)
	total_points_label.text = str(total_points)
