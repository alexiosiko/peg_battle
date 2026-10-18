extends Node2D

@export var speed := 500.0
@export var left_limit := 80.0
@export var right_limit := 720.0

var _start_msec: int = 0

func _ready() -> void:
	_start_msec = Time.get_ticks_msec()
	if multiplayer.is_server():
		Signals.board_ready.connect(_on_board_ready)
func _on_board_ready(_b: Board) -> void:
	_broadcast_clock()

func _broadcast_clock() -> void:
	_sync_clock.rpc(Time.get_ticks_msec() - _start_msec)

@rpc("authority", "call_remote", "unreliable_ordered")
func _sync_clock(host_elapsed_msec: int) -> void:
	_start_msec = Time.get_ticks_msec() - host_elapsed_msec

func _physics_process(_delta: float) -> void:
	var t: float = (Time.get_ticks_msec() - _start_msec) / 1000.0
	var span: float = right_limit - left_limit
	var dist: float = fposmod(t * speed, span * 2.0)
	position.x = left_limit + (span - absf(dist - span))
