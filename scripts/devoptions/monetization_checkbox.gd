extends CheckBox

func _ready() -> void:
	toggled.connect(_on_toggled)
func _on_toggled(on: bool) -> void:
	Monetization.ads_removed = on
	print("Monetization.ads_removed: ", Monetization.ads_removed)
