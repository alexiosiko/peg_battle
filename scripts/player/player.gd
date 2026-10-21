class_name Player extends Node

signal ball_count_changed(count: int)
signal points_changed(points: int) # New signal for UI updates
signal player_info_changed(pi: PlayerInfo)

@export var ball_catcher: Catcher
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
var points: int = 0:
	set(val):
		points = val
		points_changed.emit(points)

func has_balls() -> bool:
	return ball_count > 0
func _ready() -> void:
	if not multiplayer.is_server():
		return
	gun.ball_spawned.connect(_on_ball_spawned)
	ball_catcher.ball_caught.connect(_on_ball_catched)
func _on_client_joined_scene(id :int) -> void:
	print("whattt it called?" , id)
	client_id = id
func _on_ball_spawned(_b: Ball) -> void:
	if _b.get_multiplayer_authority() != client_id: return
	#if _b.type == Ball.Type.EXTRA: # cause i plus one in peg if its an extra
		#return
	ball_count -= 1
func _on_ball_catched(_b: Ball) -> void:
	if _b.get_multiplayer_authority() != client_id:
		return
	ball_count += 1
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
@rpc("call_local", "any_peer")
func set_info(_player_info: PlayerInfo) -> void:
	player_info = _player_info
