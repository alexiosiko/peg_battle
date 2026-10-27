class_name Player extends Node

signal ball_count_changed(count: int)
signal points_changed(points: int) # New signal for UI updates
signal player_info_changed(pi: PlayerInfo)

var ball_catcher: Catcher
@export var gun: Gun
@export var color: Color

var player_info: PlayerInfo:
	set(val):
		player_info = val
		player_info_changed.emit(val)
var client_id: int = 1
var ball_count: int = 7:
	set(val):
		ball_count = val
		ball_count_changed.emit(ball_count)
		if multiplayer.is_server():
			_sync_ball_count.rpc(ball_count)
var points: int = 0:
	set(val):
		points = val
		points_changed.emit(points)
var winner: bool = false
var pegs_popped: int = 0
var balls_caught: int = 0

func has_balls() -> bool:
	return ball_count > 0
func _ready() -> void:
	if not multiplayer.is_server():
		return
	gun.ball_spawned.connect(_on_ball_spawned)
	Signals.board_ready.connect(_on_board_ready)
func _on_board_ready(b: Board) -> void:
	b.ball_catcher.ball_caught.connect(_on_ball_catched)
func _on_client_joined_scene(id :int) -> void:
	client_id = id
func _on_ball_spawned(_b: Ball) -> void:
	if _b.get_multiplayer_authority() != client_id: return
	ball_count -= 1
func _on_ball_catched(ball: Ball) -> void:
	if client_id != ball.get_multiplayer_authority():
		return
	balls_caught += 1
	ball_count += 1
@rpc
func _sync_ball_count(count: int) -> void:
	ball_count = count
func cash_in_balls() -> void:
	while ball_count > 0:
		ball_count -= 1
		points += 40
		await get_tree().create_timer(0.2).timeout
func flip_labels_in_children() -> void:
	for label: Label in get_all_labels(self):
		label.offset_transform_enabled = true
		label.offset_transform_scale.x = -1
@rpc("call_local")
func add_points(_points: int) -> void:
	points += _points
func get_all_labels(node: Node) -> Array[Label]:
	var labels: Array[Label] = []
	
	for child in node.get_children():
		if child is Label:
			labels.append(child)
		if child.get_child_count() > 0:
			labels.append_array(get_all_labels(child))
			
	return labels
@rpc("call_local")
func reset(_ball_count: int) -> void:
	ball_count = _ball_count
	points = 0
	balls_caught = 0
	pegs_popped = 0
@rpc("call_local", "any_peer")
func set_info(_player_info_string: String) -> void:
	var pi: PlayerInfo = PlayerInfo.from_string(_player_info_string)
	player_info = pi
