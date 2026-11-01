extends Label

@export var play_button: PlayButton


func _physics_process(delta: float) -> void:
	if play_button.is_searching:
		show()
	else:
		hide()
