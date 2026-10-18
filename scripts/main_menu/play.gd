extends Button

var searching: bool = false
var _search_id: int = 0

func _ready() -> void:
	pressed.connect(_on_pressed)
	multiplayer.peer_connected.connect(_on_peer_connected)

func _on_peer_connected(_id: int) -> void:
	if multiplayer.is_server():
		await Synchronzier.call_and_wait_for_clients(_transition_to_game)

func _on_pressed() -> void:
	if searching:
		_cancel_search()
	else:
		_start_search()

func _cancel_search() -> void:
	_reset()
	NetworkHandler.leave_lobby()

func _reset() -> void:
	searching = false
	_search_id += 1  # invalidates any loop still awaiting
	text = "Play"

func _is_current(id: int) -> bool:
	return searching and id == _search_id

func _start_search() -> void:
	searching = true
	_search_id += 1
	var my_id: int = _search_id
	text = "Searching ..."
	
	if not NetworkHandler.is_connected_to_eos():
		var error: Error = await NetworkHandler.connect_to_eos()
		if error != OK:
			await get_tree().create_timer(1).timeout
			
	print("connected from main menu!")

	while _is_current(my_id):
		if not NetworkHandler.is_connected_to_eos():
			var conn_error: Error = await NetworkHandler.connect_to_eos()
			if not _is_current(my_id):
				return
			if conn_error != OK:
				print("could not connect to eos")
				_reset()
				return

		var error: Error = await NetworkHandler.join_a_lobby()
		if not _is_current(my_id):
			if error == OK:
				NetworkHandler.leave_lobby()  # joined after cancel, undo it
			return

		if error == OK:
			print("Joined lobby")
			text = "Click to cancel search"
			return  # searching stays true so the button can still cancel

		if error == ERR_DOES_NOT_EXIST:
			error = await NetworkHandler.host()
			if not _is_current(my_id):
				if error == OK:
					NetworkHandler.leave_lobby()
				return
			if error == OK:
				print("hosted game")
				text = "Waiting for opponent..."
				return
			push_warning("host failed: %s" % error_string(error))
		elif error == ERR_CONNECTION_ERROR:
			print("not connected to eos")  # loop re-checks the connection next pass
		else:
			push_warning("join_a_lobby failed: %s" % error_string(error))

		# anything that falls through: back off before retrying
		await get_tree().create_timer(1.0).timeout

@rpc("call_local")
func _transition_to_game() -> void:
	get_tree().change_scene_to_file.call_deferred("res://scenes/game.tscn")
