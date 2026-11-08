extends CanvasLayer

@export var anim_player: AnimationPlayer
@export var label: Label

var is_closed: bool = false

func _ready() -> void:
	open_scene()

@rpc("call_local")
func transition(scene_path: String, msg: String = "", dont_open: bool = false) -> void:
	if not is_closed:
		await close_scene(msg)
	# already covered: skip the close animation, just update the message
	if msg != "":
		label.text = msg

	if not Settings.is_debug:
		await get_tree().create_timer(0.5).timeout
	get_tree().change_scene_to_file(scene_path)

	if dont_open:
		return
	await open_scene()

@rpc("call_local")
func open_scene() -> void:
	is_closed = false
	anim_player.play("open")
	if not Settings.is_debug:
		await anim_player.animation_finished
	hide()

func close_scene(msg: String = "") -> void:
	is_closed = true
	show()
	label.text = msg
	anim_player.play("close")
	if not Settings.is_debug:
		await anim_player.animation_finished
