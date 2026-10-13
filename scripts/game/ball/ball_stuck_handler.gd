class_name StuckHandler extends Node


@export var timer: Timer     # wait_time = how long before it counts as stuck (e.g. 1.2), autostart on

@onready var ball: Ball = owner as Ball


func _ready() -> void:
	if not multiplayer.is_server():
		timer.stop()
		return
	timer.timeout.connect(_on_timeout)
