class_name Gun extends Node2D

signal ball_spawned(b: Ball)

@export var ball_prefab: PackedScene
@export var release_point: Node2D
@export var ball_speed: float = 700
@export var ballls_container: Node
@export var game: Game
@export var shoot_stream: AudioStream

var rotation_speed: float = 50
var waiting: bool = true:
	set(val):
		waiting = val
func _ready() -> void:
	game.can_shoot.connect(_on_can_shoot)
func _on_can_shoot() -> void:
	waiting = false
func request_shot() -> void:
	if waiting:
		return
	waiting = true
	var dir := Vector2.from_angle(rotation + PI / 2)
	shoot.rpc(release_point.global_position, dir, multiplayer.get_unique_id(), randi())

@rpc("call_local", "any_peer", "reliable")
func shoot(pos: Vector2, dir: Vector2, shooter_id: int, rand_i: int) -> void:
	print("shooting ball with shooterid: ", shooter_id)
	AudioHandler.play_sound(shoot_stream)
	var ball: Ball = ball_prefab.instantiate()
	ball.name = "Ball_" + str(rand_i)
	ball.init(pos, dir * ball_speed, shooter_id)
	ballls_container.add_child(ball)
	ball_spawned.emit(ball)
