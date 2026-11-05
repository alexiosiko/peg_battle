class_name PlayButton extends Button

var is_searching: bool = false
var _is_hosting: bool = false

@export var anim_player: AnimationPlayer
@export var connecting_banner: Control
@export var banner_message: Label
@export var connected_sound: AudioStream
@export var play_timeout_to_offline: Timer
@export var hosted_check_for_game: Timer  # set One Shot = true in the inspector
var busy: bool:
	set(val):
		busy = val
		disabled = busy
		if busy:
			connecting_banner.show()
			banner_message.text = "Searching ..."
		else:
			connecting_banner.hide()
			

func _ready() -> void:
	hosted_check_for_game.timeout.connect(_on_hosted_check_for_game)
	play_timeout_to_offline.timeout.connect(_on_play_search_timeout)
	print("is logging in : ", NetworkHandler.is_logging_in)
	if NetworkHandler.is_logging_in:
		connecting_banner.show()
		banner_message.text = "Connecting ..."
		disabled = true
	else:
		disabled = false
		connecting_banner.hide()
	NetworkHandler.logged_in.connect(_on_logged_in)
	NetworkHandler.failed_connecting_eos.connect(func(): disabled = false)
	pressed.connect(_on_pressed)
	multiplayer.peer_connected.connect(_on_peer_connected)


func _on_play_search_timeout() -> void:
	await cancel_search()
	multiplayer.multiplayer_peer = OfflineMultiplayerPeer.new()
	SceneHandler.transition("res://scenes/game.tscn", "Found opponent!")

func _on_hosted_check_for_game() -> void:
	if not is_searching:
		return
	var lobby: HLobby = await NetworkHandler.get_open_lobby()
	if lobby == null:
		return
	await NetworkHandler.leave_lobby()
	var error: Error = await NetworkHandler.join_lobby(lobby)
	if error != OK:
		_reset() # error connecting to the found lobby
		_start_search()
	# connected
func _on_logged_in(_pi: PlayerInfo) -> void:
	disabled = false
	connecting_banner.hide()
	AudioHandler.play_sound(connected_sound)


func _on_peer_connected(_id: int) -> void:
	if multiplayer.is_server():
		NetworkHandler.lobby.add_attribute("IS_OPEN", false)
		await NetworkHandler.lobby.update_async()
		# opponent found: stop the fallback timers so they can't fire mid-transition
		play_timeout_to_offline.stop()
		hosted_check_for_game.stop()
		await Synchronzier.call_and_wait_for_clients(_transition_to_game)


func _on_pressed() -> void:
	if not NetworkHandler.is_logged_in():
		var error: Error = await NetworkHandler.login_as_guest()
		print("trying to login with error code: ", error)
		return
	print("is logged in")
	if is_searching:
		cancel_search()
	else:
		_start_search()


func cancel_search() -> void:
	_reset()
	await NetworkHandler.leave_lobby()


func _reset() -> void:
	play_timeout_to_offline.stop()
	hosted_check_for_game.stop()
	_is_hosting = false
	anim_player.play("idle")
	is_searching = false
	text = "Play"
	await NetworkHandler.leave_lobby()



func _start_search() -> void:
	busy = true
	anim_player.play("spinning")
	is_searching = true
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
	busy = false

@rpc("call_local")
func _transition_to_game() -> void:
	await SceneHandler.transition("res://scenes/game.tscn", "Found opponent!")
