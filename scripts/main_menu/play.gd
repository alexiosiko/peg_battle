extends Button


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pressed.connect(_on_pressed)
func _on_pressed() -> void:
	print("searching for lobby ...")
	
	var join_error := await NetworkHandler.join_a_lobby()
	if join_error == OK:
		_transition_to_game()
		return
	print("no lobbies existing")
		
	if join_error == ERR_DOES_NOT_EXIST:
		var host_error: Error = await NetworkHandler.host(RoomMetaData.new())
		if host_error == OK:
			_transition_to_game()
		else:
			push_error("Error hosting lobby: %d" % host_error)
	
func _transition_to_game() -> void:
	get_tree().change_scene_to_file.call_deferred("res://scenes/game.tscn")
