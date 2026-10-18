class_name PointsPopUI extends Control

@export var label: Label
@export var anim_player: AnimationPlayer

var moving: bool = false
var start_pos: Vector2
var to_pos: Vector2

func init(points: int, from_pos: Vector2, to: Vector2) -> void:
	label.text = str(points)
	start_pos = from_pos
	to_pos = to

func _ready() -> void:
	global_position = start_pos
	anim_player.play("open")
	await get_tree().create_timer(1.0).timeout
	moving = true

func _process(delta: float) -> void:
	if not moving:
		return
	global_position = global_position.lerp(to_pos, 1.0 - exp(-delta * 8.0))
	if global_position.distance_to(to_pos) < 4.0:
		queue_free()
