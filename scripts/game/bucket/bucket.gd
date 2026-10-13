extends Node2D

@export var speed := 500.0
@export var left_limit := 80.0
@export var right_limit := 720.0
@export var sync_timer: Timer
var direction: int = 1
func _ready() -> void:
	if not multiplayer.is_server():
		return
	
	sync_timer.timeout.connect(_on_timeout)
func _on_timeout() -> void:
	_sync_pos_and_dir.rpc(position, direction)
func _physics_process(delta: float) -> void:
	position.x += speed * direction * delta
	
	if position.x >= right_limit - 1:
		direction = -1
	elif position.x <= left_limit:
		direction = 1
@rpc
func _sync_pos_and_dir(pos: Vector2, dire: int) -> void:
	position = pos
	direction = dire
