extends Button

func _ready() -> void:
	pressed.connect(_on_pressed)
func _on_pressed() -> void:
	NetworkHandler.leave_lobby()
	SceneHandler.transition("res://scenes/dev_options.tscn", "Entering dev mode ...")
