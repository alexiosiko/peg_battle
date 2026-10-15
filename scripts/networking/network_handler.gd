extends Node

signal error_connecting_eos(msg: String)
signal player_info_retrieved(pi: PlayerInfo)
signal logged_in
signal joining_or_hosting_lobby
signal game_found
signal failed_to_join_a_game

const socket_id: String = "pegbattle"
const bucket_id: String = "birdboxgames_pegbattle"
var player_info: PlayerInfo:
	set(val):
		player_info = val
		if player_info:
			player_info_retrieved.emit(player_info)
var lobby: HLobby
var debug: bool = true

func _ready() -> void:
	get_tree().set_auto_accept_quit(false)
	IEOS.user_info_interface_query_user_info_callback.connect(_on_user_info_completed)
	HAuth.logged_in.connect(_on_logged_in)
	HAuth.logged_in.connect(func(): logged_in.emit())
	HLog.log_level = HLog.LogLevel.INFO
	connect_to_eos()
func connect_to_eos() -> void:
	var credentials = HCredentials.new()
	credentials.product_name = Env.get_var("PRODUCT_NAME")
	credentials.product_version = Env.get_var("PRODUCT_VERSION")
	credentials.product_id = Env.get_var("PRODUCT_ID")
	credentials.sandbox_id = Env.get_var("SANDBOX_ID")
	credentials.deployment_id = Env.get_var("DEPLOYMENT_ID")
	credentials.client_id = Env.get_var("CLIENT_ID")
	credentials.client_secret = Env.get_var("CLIENT_SECRET")

	var setup_success: bool = await HPlatform.setup_eos_async(credentials)
	if not setup_success:
		error_connecting_eos.emit("Error credentials to EOS")
		return

	var log_res := HPlatform.set_eos_log_level(EOS.Logging.LogCategory.AllCategories, EOS.Logging.LogLevel.Info)
	if not EOS.is_success(log_res):
		error_connecting_eos.emit("Error credentials to EOS")
		return

	# This will trigger both the 'await' resolution AND the 'HAuth.logged_in' signal
	var login_success: bool
	if debug:
		login_success = await HAuth.login_anonymous_async("alexi" + str(randi()))
	else:
		login_success = await HAuth.login_account_portal_async()
	if not login_success:
		error_connecting_eos.emit("Authentication error")
		return	
func _on_logged_in() -> void:
	var query_opts: EOS.UserInfo.QueryUserInfoOptions = EOS.UserInfo.QueryUserInfoOptions.new()
	query_opts.local_user_id = HAuth.epic_account_id
	query_opts.target_user_id = HAuth.epic_account_id
	
	IEOS.user_info_interface_query_user_info(query_opts)
func _on_user_info_completed(callback_data: Dictionary) -> void:
	print("UserInfo server request finished: ", callback_data)
	if callback_data.result_code != 0:
		return

	var copy_opts: EOS.UserInfo.CopyUserInfoOptions = EOS.UserInfo.CopyUserInfoOptions.new()
	copy_opts.local_user_id = callback_data.local_user_id
	copy_opts.target_user_id = callback_data.target_user_id

	var result_dict = IEOS.user_info_interface_copy_user_info(copy_opts)
	if result_dict.result_code == 0 and result_dict.has("user_info"):
		player_info = PlayerInfo.from_dict(result_dict.user_info)
func update_lobby(lobby_modification: EOSGLobbyModification) -> void:
	var options: EOS.Lobby.UpdateLobbyOptions = EOS.Lobby.UpdateLobbyOptions.new()
	options.lobby_modification = lobby_modification
	EOS.Lobby.LobbyInterface.update_lobby(options)
func leave_lobby() -> Error:
	if not lobby:
		multiplayer.multiplayer_peer = null
		return OK

	var success: bool = false
	
	if multiplayer.is_server():
		success = await lobby.destroy_async()
	else:
		success = await lobby.leave_async()

	multiplayer.multiplayer_peer = null
	if success:
		return OK
	else:
		return FAILED

		
func join_lobby(_lobby: HLobby) -> Error:
	var joined_lobby = await HLobbies.join_async(_lobby)
	if joined_lobby != null:
		lobby = joined_lobby 
		
		var host_id: String = lobby.get_owner().product_user_id
		
		var peer: EOSGMultiplayerPeer = EOSGMultiplayerPeer.new()
		
		# Call the specific 2-argument signature
		var error = peer.create_client(socket_id, host_id)
		if error != OK:
			printerr("Failed to establish P2P connection to host: ", error)
			return error
		
		# Assign it to Godot's global multiplayer system
		multiplayer.multiplayer_peer = peer
		print("P2P Client initialized. Connected to Godot network via Socket: ", socket_id)
			
		return OK
	return ERR_CANT_CONNECT
func _join_a_lobby() -> Error:
	if not is_connected_to_eos():
		print("not connected to eos")
		return ERR_CONNECTION_ERROR
	var lobbies = await HLobbies.search_by_bucket_id_async(bucket_id)
	if lobbies and lobbies.size() > 0:
		lobbies = lobbies as Array[HLobby]
		game_found.emit()
		return await join_lobby(lobbies[0])
		
	return ERR_DOES_NOT_EXIST
func get_lobbies() -> Array[HLobby]:
	var lobbies = await HLobbies.search_by_bucket_id_async(bucket_id)
	if lobbies:
		return lobbies as Array[HLobby]
	return []
func join_or_host_lobby() -> Error:
	joining_or_hosting_lobby.emit()
	var join_error := await _join_a_lobby()
	if join_error == ERR_DOES_NOT_EXIST:
		print("no lobbies exist, making one ...")
		var host_error: Error = await NetworkHandler.host()
		if host_error != OK:
			push_error("Error hosting lobby: %d" % host_error)
			failed_to_join_a_game.emit()
			return host_error
		print("lobby made")
		return host_error
	if join_error == OK:
		game_found.emit()
		print("game found")
		return join_error
	elif join_error == ERR_CONNECTION_ERROR:
		print("not connected to servers")
		failed_to_join_a_game.emit()
		return ERR_CONNECTION_ERROR
	else: # error joining lobby, try again
		print("Error joining someones lobby, trying again error code: ", join_error)
		failed_to_join_a_game.emit()
		return await join_or_host_lobby()
func is_connected_to_eos() -> bool:
	return HAuth.product_user_id != ""	
func host() -> Error:
	var opts := EOS.Lobby.CreateLobbyOptions.new()
	opts.max_lobby_members = 2
	opts.disable_host_migration = true
	opts.permission_level = EOS.Lobby.LobbyPermissionLevel.PublicAdvertised
	opts.bucket_id = bucket_id

	lobby = await HLobbies.create_lobby_async(opts)
	if not lobby:
		printerr("Failed to create lobby")
		return ERR_BUG
	print("Lobby created: ", lobby.lobby_id)

	var peer: EOSGMultiplayerPeer = EOSGMultiplayerPeer.new()
	var err = peer.create_server(socket_id)
	if err != OK:
		printerr("create_server failed: ", err)
		return err
	peer.set_auto_accept_connection_requests(true)
	multiplayer.multiplayer_peer = peer

	return OK


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		await leave_lobby()
		get_tree().quit()
