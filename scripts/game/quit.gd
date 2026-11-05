extends Button

@export var show_ad: bool = true
func _ready() -> void:
	pressed.connect(_on_pressed)
func _on_pressed() -> void:
	print("Monetization.ads_removed: ", Monetization.ads_removed)
	print("Settings.skip_ads: ", Settings.skip_ads)
	if not Monetization.ads_removed:
		if not Settings.skip_ads:
			if show_ad:
				show_ad = false
				AdHandler.show_interstitial_ad()
	SceneHandler.transition("res://scenes/main_menu.tscn", "Leaving lobby ...")
	
