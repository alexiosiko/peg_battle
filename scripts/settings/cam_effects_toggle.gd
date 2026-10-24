extends CheckBox

func _ready() -> void:
	# Load the true state: if enabled, check the box (true).
	button_pressed = not LocalStorage.get_param("cam_effects", true)
	toggled.connect(_on_toggled)

func _on_toggled(on: bool) -> void:
	# Save the actual state of the button directly
	LocalStorage.add_param("cam_effects", on)
	Juice.enabled = on
