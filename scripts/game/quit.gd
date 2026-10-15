extends Button

func _ready() -> void:
	pressed.connect(_on_pressed)
func _on_pressed() -> void:
	await NetworkHandler.leave_lobby()
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
