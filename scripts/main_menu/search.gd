extends Button


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pressed.connect(_on_pressed)
func _on_pressed() -> void:
	var lobbies = await NetworkHandler.get_lobbies()
	print(lobbies)
