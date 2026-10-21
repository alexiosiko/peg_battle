extends Button

func _ready() -> void:
	pressed.connect(_on_pressed)
func _on_pressed() -> void:
	if not NetworkHandler.is_connected_to_eos():
		Toast.info("Not logged in")
		return
	var error: Error
	error = await NetworkHandler.logout()
	if error != OK:
		Toast.error("Failed logout")
	else:
		Toast.success("Signed out")
