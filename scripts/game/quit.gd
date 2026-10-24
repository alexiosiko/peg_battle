extends Button

var show_ad: bool = true
func _ready() -> void:
	pressed.connect(_on_pressed)
func _on_pressed() -> void:
	if show_ad:
		show_ad = false
		AdHandler.show_interstitial_ad()
		return
	SceneHandler.transition("res://scenes/main_menu.tscn", "Leaving lobby ...")
	
