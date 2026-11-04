class_name Game extends Node

@export var debug_override_board: String
@export var boards_paths: Array[String]
@export var gun: Gun
@export var client_player: Player
@export var host_player: Player
@export var its_your_turn: AudioStream
signal can_shoot(client_id: int)
var current_player: Player
signal game_over(host_player: Player, client_player: Player)

var is_game_over: bool = false
var board: Board
const BOT_ID: int = -1
var awaiting_shot: bool = false


func _ready() -> void:
	multiplayer.server_disconnected.connect(_on_server_disconnected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	current_player = host_player
	gun.shot.connect(func() -> void: awaiting_shot = false)
	if multiplayer.is_server():
		if NetworkHandler.lobby:
			NetworkHandler.lobby.add_attribute("is_open", false)
			NetworkHandler.lobby.update_async()
		if multiplayer.multiplayer_peer is OfflineMultiplayerPeer:
			host_player.client_id = 1
			client_player.client_id = BOT_ID
			client_player.is_bot = true
			client_player.set_info(Bot.create_bot_info().to_string())  # needs a non-null player_info (avatar_index is read)
			_start_game()
	else:
		_tell_server_client_joined_scene.rpc_id(1)
func _init_game(client_id: int) -> void:
	host_player.client_id = 1
	client_player.client_id = client_id
	_start_game()
func _start_game() -> void:
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
	if not Settings.is_debug:
		await get_tree().create_timer(2).timeout
	board.round_over.connect(_on_round_over)
	_on_round_over(0)

@rpc("call_local")
func _tell_client_enemy_is_shooting() -> void:
	Toast.info("Enemy is shooting!")
@rpc("call_local")
func _tell_client_to_shoot(client_id: int) -> void:
	if multiplayer.get_unique_id() == client_id:
		Toast.success("Your turn!")
	print(multiplayer.get_peers())
	#if multiplayer.get_peers().size() == 1:
		
	AudioHandler.play_sound(its_your_turn, true)
	can_shoot.emit(client_id)
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
		awaiting_shot = true
		_tell_client_to_shoot.rpc(current_player.client_id)
		if current_player.is_bot:
			_bot_take_turn(current_player)
	else:
		_game_over()

func _game_over() -> void:
	is_game_over = true
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
func _on_server_disconnected() -> void:
	await NetworkHandler.leave_lobby()		
	SceneHandler.transition("res://scenes/main_menu.tscn", "Disconnected from server")
func _on_peer_disconnected(id: int) -> void:
	if not multiplayer.is_server():
		return
	if is_game_over or id != client_player.client_id:
		# Game already finished, so the old behavior is fine
		await NetworkHandler.leave_lobby()
		SceneHandler.transition("res://scenes/main_menu.tscn", "Your opponent rage quit!")
		return
	_replace_with_bot(client_player, id)

func _replace_with_bot(p: Player, old_id: int) -> void:
	Toast.info("Opponent left, a bot took over")
	p.is_bot = true
	p.client_id = BOT_ID

	for ball: Ball in gun.ballls_container.get_children():
		if ball.owner_id == old_id:
			ball.take_over(BOT_ID)
			board.adopt_ball(ball)
	if awaiting_shot and current_player == p:
		_bot_take_turn(p)

func _bot_take_turn(bot: Player) -> void:
	print("bot turn: waiting")
	await get_tree().create_timer(randf_range(0.8, 1.6)).timeout
	print("bot turn: guards ", is_game_over, awaiting_shot, current_player == bot)
	if is_game_over or not awaiting_shot or current_player != bot:
		return
	var angle: float = await BotBrain.pick_angle(board, gun)
	print("bot turn: shooting at ", angle)
	gun.bot_shoot(angle, bot.client_id)
func _ball_in_play() -> bool:
	return board.ball_count == 0
func get_player(client_id: int) -> Player:
	if client_id == 1:
		return host_player
	else:
		return client_player
