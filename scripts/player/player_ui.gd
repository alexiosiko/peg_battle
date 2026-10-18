class_name PlayerUI extends Control

@export var player: Player
@export var points: Label
@export var username: Label
@export var ball_count: Label

func _ready() -> void:
	player.points_changed.connect(_on_points_changed)
	player.ball_count_changed.connect(_on_ball_count_changed)
	#player.player_info.display_name
func _on_points_changed(count: int) -> void:
	points.text = str(count)
func _on_ball_count_changed(count: int) -> void:
	ball_count.text = str(count)
