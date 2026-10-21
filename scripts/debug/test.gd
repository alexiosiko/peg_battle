extends Button

func _ready() -> void:
	pressed.connect(_on_button)
func _on_button() -> void:
	SceneHandler.transition("res://scenes/account_settings.tscn", "Loading account settings ...")

	
