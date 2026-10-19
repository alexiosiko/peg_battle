extends Node

@export var anim_player: AnimationPlayer
 
func transition(scene_path: String) -> void:
	await close_scene()
	get_tree().change_scene_to_file(scene_path)
	await open_scene()

func open_scene() -> void:
	anim_player.play("open")
	await anim_player.animation_finished

func close_scene() -> void:
	anim_player.play("close")
	await anim_player.animation_finished
