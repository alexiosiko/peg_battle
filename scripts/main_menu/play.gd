class_name PlayButton extends Button

var is_searching: bool = false
var _search_id: int = 0

@export var anim_player: AnimationPlayer
@export var connecting_banner: Control
@export var connected_sound: AudioStream

var is_hosted: bool = false

func _ready() -> void:
	print("is logging in : ", NetworkHandler.is_logging_in)
	if NetworkHandler.is_logging_in:
		connecting_banner.show()
		disabled = true
	else:
		disabled = false
		connecting_banner.hide()
		
	NetworkHandler.logged_in.connect(_on_logged_in)
	NetworkHandler.failed_connecting_eos.connect(func(): disabled = false)
	pressed.connect(_on_pressed)
	multiplayer.peer_connected.connect(_on_peer_connected)


func _on_logged_in(_pi: PlayerInfo) -> void:
	disabled = false
	connecting_banner.hide()
	AudioHandler.play_sound(connected_sound)


func _on_peer_connected(_id: int) -> void:
	if multiplayer.is_server():
		# Match found! Stop host scanning loops instantly
		_search_id += 1 
		await Synchronzier.call_and_wait_for_clients(_transition_to_game)


func _on_pressed() -> void:
	if not NetworkHandler.is_logged_in():
		var error: Error = await NetworkHandler.login_as_guest()
		print("trying to login with error code: ", error)
		return
		
	print("is logged in")
	if is_searching:
		_cancel_search()
	else:
		_start_search()


func _cancel_search() -> void:
	_reset()
	NetworkHandler.leave_lobby()
	is_hosted = false


func _reset() -> void:
	anim_player.play("idle")
	is_searching = false
	_search_id += 1  # Invalidates any async loop still running
	text = "Play"


func _is_current(id: int) -> bool:
	return is_searching and id == _search_id


func _start_search() -> void:
	anim_player.play("spinning")
	is_searching = true
	_search_id += 1
	var my_id: int = _search_id
	
	while _is_current(my_id):
		Toast.info("Finding opponent")
		if not NetworkHandler.is_logged_in():
			var conn_error: Error = await NetworkHandler.connect_to_eos()
			if not _is_current(my_id): return
			if conn_error != OK:
				Toast.error("Could not connect to servers")
				_reset()
				return

		# 1. Attempt to join an existing lobby
		var error: Error = await NetworkHandler.join_a_lobby()
		if not _is_current(my_id):
			if error == OK: NetworkHandler.leave_lobby()
			return

		if error == OK:
			print("Joined lobby successfully as client")
			return  # Successfully matched!

		# 2. If no lobby exists, attempt to Host
		if error == ERR_DOES_NOT_EXIST:
			await host(my_id)
			return # Exit standard search loop because 'host' starts its own monitoring loop
		elif error == ERR_CONNECTION_ERROR:
			print("not connected to eos")
		else:
			push_warning("join_a_lobby failed: %s" % error_string(error))

		await get_tree().create_timer(1.0).timeout


func host(my_id: int) -> void:
	var error: Error = await NetworkHandler.host()
	if not _is_current(my_id):
		if error == OK: NetworkHandler.leave_lobby()
		return
		
	if error != OK:
		push_warning("host failed: %s" % error_string(error))
		await get_tree().create_timer(1.0).timeout
		return

	print("Hosted game successfully. Starting simultaneous host-collision loop...")
	is_hosted = true
	
	# --- Dynamic Host Scan Loop ---
	# Every 5 seconds, check if someone else also hosted a lobby
	while _is_current(my_id) and is_hosted:
		await get_tree().create_timer(5.0).timeout
		if not _is_current(my_id) or not is_hosted: 
			return

		print("Scanning for alternative lobbies while hosting...")
		var lobbies: Array = await NetworkHandler.get_lobbies()
		if not _is_current(my_id): return

		for l in lobbies:
			# Skip checking our own hosted lobby id
			# (Assuming your NetworkHandler keeps track of your current local lobby script or ID)
			if NetworkHandler.lobby and l.lobby_id == NetworkHandler.lobby.lobby_id:
				continue
				
			# Check if the other lobby is open/valid
			if l.get_attribute("IS_OPEN").get("value", false) == true:
				print("Found another host! Abandoning my lobby to merge into theirs.")
				
				# Abandon our own room
				is_hosted = false
				await NetworkHandler.leave_lobby() 
				if not _is_current(my_id): return
				
				# Try to merge into their lobby
				var join_error: Error = await NetworkHandler.join_lobby(l)
				if not _is_current(my_id):
					if join_error == OK: NetworkHandler.leave_lobby()
					return
					
				if join_error == OK:
					print("Successfully merged into the other player's lobby!")
					return # We are now successfully joined as a client
				else:
					# If joining failed (e.g. they left at the same frame), re-host and continue loop
					await host(my_id)
					return


@rpc("call_local")
func _transition_to_game() -> void:
	await SceneHandler.transition("res://scenes/game.tscn", "Game found!")
