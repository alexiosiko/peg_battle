extends CanvasLayer

@export var anim_player: AnimationPlayer
@export var label: Label
 
func _ready() -> void:
	label.text = ""
	open_scene()
func transition(scene_path: String, msg: String = "") -> void:
	await close_scene(msg)
	get_tree().change_scene_to_file(scene_path)
	await get_tree().create_timer(1).timeout
	await open_scene()

func open_scene() -> void:
	anim_player.play("open")
	await anim_player.animation_finished
	hide()
	

func close_scene(msg: String = "") -> void:
	show()
	label.text = msg
	anim_player.play("close")
	await anim_player.animation_finished
