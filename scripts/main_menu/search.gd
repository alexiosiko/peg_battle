extends Button


func _ready() -> void:
	pressed.connect(_on_pressed)
func _on_pressed() -> void:
	var lobbies = await NetworkHandler.get_lobbies()
	print(lobbies)
	for lobby in lobbies:
		var error: Error = await NetworkHandler.join_lobby(lobby)
		if error != OK:
			print("error joining lobby")
		else:
			# server tells client to join
			#get_tree().change_scene_to_file("res://scenes/game.tscn")
			return
		
