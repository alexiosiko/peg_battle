extends CheckBox

func _ready() -> void:
	button_pressed = not LocalStorage.get_param("sounds_enabled", true)
	toggled.connect(_on_toggled)
func _on_toggled(on: bool) -> void:
	LocalStorage.add_param("sounds_enabled", not on)
	AudioHandler.init()
