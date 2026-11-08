extends CheckBox

func _ready() -> void:
	button_pressed = LocalStorage.get_param("cam_effects", true)
	Juice.enabled = button_pressed
	toggled.connect(_on_toggled)

func _on_toggled(on: bool) -> void:
	LocalStorage.add_param("cam_effects", on)
	Juice.enabled = on
