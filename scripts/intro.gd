extends Node

@export var video_player: VideoStreamPlayer

func _ready() -> void:
	await video_player.finished
	var finished_tut: bool = LocalStorage.get_param("finished_tutorial", false)
	if finished_tut:
		SceneHandler.transition("res://scenes/main_menu.tscn", "Loading menu")
	else:
		SceneHandler.transition("res://scenes/tutorial.tscn", "Loading tutorial")
		
