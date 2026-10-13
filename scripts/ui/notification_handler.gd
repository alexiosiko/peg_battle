extends Node

@export var label: Label
@export var timer: Timer

func _ready() -> void:
	label.hide()
	timer.timeout.connect(func(): label.hide())
	
func error(msg: String) -> void:
	label.show()
	timer.start(3)
	label.add_theme_color_override("font_color", Color.RED)
	label.text = msg
	

func notify(msg: String) -> void:
	label.show()
	timer.start(3)
	label.remove_theme_color_override("font_color")
	label.text = msg
