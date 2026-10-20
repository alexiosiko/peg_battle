extends Node



@export var video_player: VideoStreamPlayer

func _ready() -> void:
	await video_player.finished
	SceneHandler.transition("res://scenes/main_menu.tscn", "", true)
