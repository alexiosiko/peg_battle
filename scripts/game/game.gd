class_name Game extends Node

@export var debug_override_board: String
@export var boards_paths: Array[String]
@export var gun: Gun
@export var client_player: Player
@export var host_player: Player
@export var its_your_turn: AudioStream
signal can_shoot
var current_player: Player

signal game_over(host_player: Player, client_player: Player)

var board: Board
var is_solo: bool = false


func _ready() -> void:
	#AdHandler.show_banner()
	multiplayer.server_disconnected.connect(_on_server_disconnected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	current_player = host_player
	if multiplayer.is_server():
		if NetworkHandler.lobby:
			NetworkHandler.lobby.permission_level = EOS.Lobby.LobbyPermissionLevel.InviteOnly
			NetworkHandler.lobby.update_async()
		if multiplayer.multiplayer_peer is OfflineMultiplayerPeer:
			is_solo = true
			_start_game()
	else:
		_tell_server_client_joined_scene.rpc_id(1)
func _init_game(client_id: int) -> void:
	host_player.client_id = 1
	client_player.client_id = client_id
	_start_game()
func _start_game() -> void:
	#if multiplayer.is_server():
		#await NetworkHandler.lobby.update_async()
	var bp: String = _get_next_board_path()
	if not debug_override_board.is_empty():
		bp = debug_override_board
	if board:
		await Synchronzier.call_and_wait_for_clients(_destroy_board)
	print("loading ", bp)
	await Synchronzier.call_and_wait_for_clients(_load_next_board, bp)
	var ball_count: int = board.num_starting_balls
	await Synchronzier.call_and_wait_for_clients(host_player.reset, ball_count)
	await Synchronzier.call_and_wait_for_clients(client_player.reset, ball_count)
	#AdHandler1.hide_banner.rpc()
	if not Settings.is_debug:
		await get_tree().create_timer(2).timeout
	board.round_over.connect(_on_round_over)
	_on_round_over(0)

@rpc("call_local")
func _tell_client_enemy_is_shooting() -> void:
	Toast.info("Enemy is shooting!")
@rpc("call_local")
func _tell_client_to_shoot() -> void:
	Toast.success("Your turn!")
	AudioHandler.play_sound(its_your_turn, true)
	can_shoot.emit()
func _on_round_over(points: int) -> void:
	print("round over with points :", points)
	await Synchronzier.call_and_wait_for_clients(current_player.add_points, points)
	if board.has_pegs():
		flip_player_turn()
		if not current_player.has_balls():
			flip_player_turn()
		if not current_player.has_balls():
			_game_over()
			return
		print("telling client its his turn : ", current_player.client_id)
		_tell_client_to_shoot.rpc_id(current_player.client_id)
		var other_id: int = client_player.client_id if current_player.client_id == 1 else host_player.client_id
		if not is_solo:
			_tell_client_enemy_is_shooting.rpc_id(other_id)
	else:
		_game_over()
func _input(event: InputEvent) -> void:
	if not multiplayer.is_server():
		return
	if event.is_action_pressed("debug_o"):
		_game_over()
func _game_over() -> void:
	print("game over")
	await Synchronzier.call_and_wait_for_clients(host_player.cash_in_balls)
	await get_tree().create_timer(1).timeout
	await Synchronzier.call_and_wait_for_clients(client_player.cash_in_balls)
	Toast.info("Game over")
	#AdHandler.show_interstitial_ad()
	#AdHandler.show_banner(AdPosition.TOP)
	_emit_game_over.rpc()
@rpc("call_local")
func _emit_game_over() -> void:
	game_over.emit(host_player, client_player)
@rpc("any_peer")
func _tell_server_client_joined_scene() -> void:
	if not multiplayer.is_server():
		return
	_init_game(multiplayer.get_remote_sender_id())
func flip_player_turn() -> void:
	if is_solo:
		return
	if current_player == host_player:
		current_player = client_player
	else:
		current_player = host_player
func _get_next_board_path() -> String:
	var n: int = randi() % boards_paths.size()
	return boards_paths[n]
func _load_next_board(path: String) -> void:
	board = load(path).instantiate()
	add_child(board)
@rpc("call_local")
func _destroy_board() -> void:
	board.free()
	await get_tree().create_timer(0.5).timeout
func _on_server_disconnected(_id: int) -> void:
	print("user has left!")
	await NetworkHandler.leave_lobby()		
	SceneHandler.transition("res://scenes/main_menu.tscn", "Disconnected from server")
func _on_peer_disconnected(_id: int) -> void:
	print("user has left!")
	await NetworkHandler.leave_lobby()
	SceneHandler.transition("res://scenes/main_menu.tscn", "Your opponent rage quit!")
func get_player(client_id: int) -> Player:
	if client_id == 1:
		return host_player
	else:
		return client_player
