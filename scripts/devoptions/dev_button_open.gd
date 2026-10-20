extends Button

func _ready() -> void:
	pressed.connect(_on_pressed)
func _on_pressed() -> void:
	SceneHandler.transition("res://scenes/dev_options.tscn", "Entering dev mode ...")
