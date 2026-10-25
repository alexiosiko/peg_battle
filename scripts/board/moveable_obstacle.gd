class_name Obstacle extends AnimatableBody2D

@export var point_a: Node2D
@export var point_b: Node2D
@export var speed: float = 300.0       # pixels per second
@export var resync_interval: float = 2.0
@export var hit_sound: AudioStream
var pos_a: Vector2
var pos_b: Vector2
var _start_msec: int = 0

@rpc("call_local", "any_peer")
func hit() -> void:
	AudioHandler.play_sound(hit_sound)
	
func _ready() -> void:
	pos_a = point_a.global_position
	pos_b = point_b.global_position
	_start_msec = Time.get_ticks_msec()

	if multiplayer.is_server():
		Signals.board_ready.connect(_on_board_ready)
func _on_board_ready(_b: Board) -> void:
	_broadcast_clock()

func _broadcast_clock() -> void:
	_sync_clock.rpc(Time.get_ticks_msec() - _start_msec)

@rpc("authority", "call_remote", "unreliable")
func _sync_clock(host_elapsed_msec: int) -> void:
	_start_msec = Time.get_ticks_msec() - host_elapsed_msec

func _process(_delta: float) -> void:
	var length: float = pos_a.distance_to(pos_b)
	if length < 0.001:
		return
	var t: float = (Time.get_ticks_msec() - _start_msec) / 1000.0
	var weight: float = pingpong(t * speed, length) / length
	global_position = pos_a.lerp(pos_b, weight)
