extends Button

func _ready() -> void:
	pressed.connect(_on_pressed)
func _on_pressed() -> void:
	SceneHandler.transition("res://scenes/main_menu.tscn", "Leaving lobby ...")
	NetworkHandler.leave_lobby()
