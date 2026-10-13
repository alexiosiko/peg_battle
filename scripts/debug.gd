extends Node


# Called when the node enters the scene tree for the first time.
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("debug_increase_speed"):
		Engine.time_scale += 1
	elif event.is_action_pressed("debug_speed_reset"):
		Engine.time_scale = 1
