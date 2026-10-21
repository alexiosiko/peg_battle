extends Button

func _ready() -> void:
	pressed.connect(_on_pressed)
func _on_pressed() -> void:
	await NetworkHandler.logout()
	Toast.info("Signing in ...")
	var error: Error = await NetworkHandler.login(false)
	if error != OK:
		Toast.error("Failed signin")
	else:
		Toast.success("Signed in!")
