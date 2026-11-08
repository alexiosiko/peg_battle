extends Node	

var _is_hosting: bool = false

@export var anim_player: AnimationPlayer
@export var video_stream: VideoStreamPlayer
@export var play_timeout_to_offline: Timer
@export var cancel_search_button: Button
@export var hosted_check_for_game: Timer  # set One Shot = true in the inspector
func _ready() -> void:
	cancel_search_button.pressed.connect(_cancel_search.bind(true))
	hosted_check_for_game.timeout.connect(_on_hosted_check_for_game)
	play_timeout_to_offline.timeout.connect(_on_play_search_timeout)
	NetworkHandler.failed_connecting_eos.connect(_cancel_search.bind(true))
	multiplayer.peer_connected.connect(_on_peer_connected)
	_start_search()
	await get_tree().create_timer(10).timeout
	Toast.info("Trying to connect to players...")
	
func _on_play_search_timeout() -> void:
	await _cancel_search(false)
	multiplayer.multiplayer_peer = OfflineMultiplayerPeer.new()
	SceneHandler.transition("res://scenes/game.tscn", "Found opponent!")

func _on_hosted_check_for_game() -> void:
	var lobby: HLobby = await NetworkHandler.get_open_lobby()
	if lobby == null:
		return
	await NetworkHandler.leave_lobby()
	var error: Error = await NetworkHandler.join_lobby(lobby)
	if error != OK:
		_reset() # error connecting to the found lobby
		_start_search()
func _on_peer_connected(_id: int) -> void:
	if multiplayer.is_server():
		NetworkHandler.lobby.add_attribute("IS_OPEN", false)
		await NetworkHandler.lobby.update_async()
		# opponent found: stop the fallback timers so they can't fire mid-transition
		play_timeout_to_offline.stop()
		hosted_check_for_game.stop()
		await Synchronzier.call_and_wait_for_clients(_transition_to_game)


func _cancel_search(go_home: bool) -> void:
	_reset()
	await NetworkHandler.leave_lobby()
	if go_home:
		anim_player.play("close")
		await anim_player.animation_finished
		video_stream.hide()
		SceneHandler.transition("res://scenes/main_menu.tscn", "Failed to find opponent")


func _reset() -> void:
	play_timeout_to_offline.stop()
	hosted_check_for_game.stop()
	_is_hosting = false
	await NetworkHandler.leave_lobby()


func _start_search() -> void:
	anim_player.play("open")
	await NetworkHandler.leave_lobby()

	Toast.info("Finding opponent")
	if not NetworkHandler.is_logged_in():
		var conn_error: Error = await NetworkHandler.login_as_guest()
		if conn_error != OK:
			Toast.error("Could not connect to servers")
			print("could not connect to eos")
			_reset()
			return

	var error: Error = await NetworkHandler.join_a_lobby()
	if error == ERR_DOES_NOT_EXIST:
		error = await NetworkHandler.host()
		if error == OK:
			print("hosted")
			hosted_check_for_game.start(randf_range(7, 13))
		else:
			print("failed to host")
			Toast.error("Search failed")
			_reset()
			
	elif error == OK:
		print("Joined lobby")
		Toast.info("Connecting...")
		return
	else:
		print("failed host")
		Toast.error("Search failed")
		_reset()

@rpc("call_local")
func _transition_to_game() -> void:
	await SceneHandler.transition("res://scenes/game.tscn", "Found opponent!")
