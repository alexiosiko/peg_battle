extends CheckBox

func _ready() -> void:
	toggled.connect(_on_toggled)
func _on_toggled(on: bool) -> void:
	Settings.skip_ads = on
	LocalStorage.add_param("skip_ads", on)
	if Settings.skip_ads:
		Toast.success("Ads disabled")
	else:
		Toast.error("Ads enabled")
		
