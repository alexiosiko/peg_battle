extends LineEdit

@export var enter: Button
@export var dev_options: Control
func _ready() -> void:
	dev_options.hide()
	enter.pressed.connect(_on_enter)
func _on_enter() -> void:
	# hey you're not supposed to be here
	if text == "watermelon":
		Toast.success("Code successful")
		dev_options.show()
	else:
		Toast.error("Code is wrooooong")
