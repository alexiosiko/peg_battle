class_name PlayButton extends Button

var is_searching: bool = false
var _search_id: int = 0
@export var anim_player: AnimationPlayer
@export var connecting_banner: Control
@export var connected_sound: AudioStream
func _ready() -> void:
	if not NetworkHandler.is_logged_in():
		connecting_banner.show()
		disabled = true
	else:
		disabled = false
		connecting_banner.hide()
	NetworkHandler.logged_in.connect(_on_logged_in)
	NetworkHandler.failed_connecting_eos.connect(func(): disabled = false)
	pressed.connect(_on_pressed)
	multiplayer.peer_connected.connect(_on_peer_connected)

func _on_logged_in(pi: PlayerInfo) -> void:
	disabled = false
	connecting_banner.hide()
	AudioHandler.play_sound(connected_sound)
func _on_peer_connected(_id: int) -> void:
	if multiplayer.is_server():
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

func _reset() -> void:
	anim_player.play("idle")
	is_searching = false
	_search_id += 1  # invalidates any loop still awaiting
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
			if not _is_current(my_id):
				return
			if conn_error != OK:
				Toast.error("Could not connect to servers")
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
			return  # is_searching stays true so the button can still cancel

		if error == ERR_DOES_NOT_EXIST:
			error = await NetworkHandler.host()
			if not _is_current(my_id):
				if error == OK:
					NetworkHandler.leave_lobby()
				return
			if error == OK:
				print("hosted game")
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
	await SceneHandler.transition("res://scenes/game.tscn", "Game found!")
