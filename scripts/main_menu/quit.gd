extends Button



func _ready() -> void:
	if OS.get_name() == "iOS":
		hide()
		return
	show()
	pressed.connect(_on_pressed)
func _on_pressed() -> void:
	await NetworkHandler.leave_lobby()
	get_tree().quit()
