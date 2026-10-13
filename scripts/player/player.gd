class_name Player extends Control

signal ball_count_changed(count: int)
signal points_changed(points: int) # New signal for UI updates

@export var ball_catcher: Catcher
@export var gun: Gun

@export var client_id: int = 1

var ball_count: int = 7:
	set(val):
		ball_count = val
		ball_count_changed.emit(ball_count)
var points: int = 0:
	set(val):
		points = val
		points_changed.emit(points)

func has_balls() -> bool:
	return ball_count > 0
func _ready() -> void:
	if multiplayer.is_server():
		ball_catcher.ball_caught.connect(_on_ball_catched)
		gun.ball_spawned.connect(_on_ball_spawned)
func _on_ball_spawned(_b: Ball) -> void:
	if _b.shooter_id != client_id: return
	ball_count -= 1
func _on_ball_catched(_b: Ball) -> void:
	if _b.shooter_id != client_id:
		return
	ball_count += 1
	points += 1
	_sync_player_stats.rpc(ball_count, points)
func cash_in_balls() -> void:
	while ball_count > 0:
		ball_count -= 1
		points += 40
		await get_tree().create_timer(0.2).timeout
@rpc("reliable")
func _sync_player_stats(server_balls: int, _points: int) -> void:
	ball_count = server_balls
	points = _points

@rpc("call_local")
func reset() -> void:
	ball_count = 6
	points = 0
