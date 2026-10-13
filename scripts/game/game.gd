class_name Game extends Node

@export var boards_paths: Array[String]
@export var gun: Gun
@export var client_player: Player
@export var host_player: Player
signal client_can_shoot(id: int)

var current_player: Player

signal game_started
signal game_over(host_player: Player, client_player: Player)
signal everyone_is_in_game

var board: Board
var is_solo: bool = false


func _ready() -> void:
	current_player = host_player
	if multiplayer.is_server():
		everyone_is_in_game.connect(_start_game)
		if multiplayer.multiplayer_peer is OfflineMultiplayerPeer:
			is_solo = true
			everyone_is_in_game.emit()
	else:
		_tell_server_client_joined_scene.rpc_id(1)
func _start_game() -> void:
	var bp := _get_next_board_path()
	if board:
		await Synchronzier.call_and_wait_for_clients(_destroy_board)
	await Synchronzier.call_and_wait_for_clients(_load_next_board, bp)
	
	await Synchronzier.call_and_wait_for_clients(host_player.reset)
	await Synchronzier.call_and_wait_for_clients(client_player.reset)
	await Synchronzier.call_and_wait_for_clients(gun.stop)
		
	board.round_over.connect(_on_round_over)
	board.ball_ready.connect(_on_ball_ready)
	board.game_over.connect(_game_over)
	Synchronzier.emit_on_all(game_started)
	_on_ball_ready()
func _on_round_over(points: int) -> void:
	current_player.points += points
func _on_ball_ready() -> void:
	flip_player_turn()
	if not current_player.has_balls():
		flip_player_turn()
	if not current_player.has_balls():
		_game_over()
		return
	_tell_client_he_can_shoot.rpc(current_player.client_id)
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("debug_o"):
		_game_over()
func _game_over() -> void:
	print("game over")
	await Synchronzier.call_and_wait_for_clients(host_player.cash_in_balls)
	await get_tree().create_timer(1).timeout
	await Synchronzier.call_and_wait_for_clients(client_player.cash_in_balls)
	Synchronzier.emit_on_all(game_over, host_player, client_player)
	await get_tree().create_timer(3).timeout
	
	_start_game()
	
@rpc("call_local")
func _tell_client_he_can_shoot(id: int) -> void:
	client_can_shoot.emit(id)
@rpc("any_peer")
func _tell_server_client_joined_scene() -> void:
	everyone_is_in_game.emit()
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
