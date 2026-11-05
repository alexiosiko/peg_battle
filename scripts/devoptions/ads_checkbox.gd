extends CheckBox

func _ready() -> void:
	toggled.connect(_on_toggled)
func _on_toggled(on: bool) -> void:
	Settings.skip_ads = on
	LocalStorage.add_param("skip_ads", on)
	if Settings.skip_ads:
		Toast.info("Ads disabled")
	else:
		Toast.info("Ads enabled")
	print("Skips ads: ", LocalStorage.get_param("skip_ads"))
