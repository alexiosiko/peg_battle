extends Node

signal error_connecting_eos(msg: String)
signal logged_in(pi: PlayerInfo)
signal game_found

const socket_id: String = "pegbattle"
const bucket_id: String = "birdboxgames_pegbattle"
var user_info: PlayerInfo
var lobby: HLobby
var debug: bool = true
func _ready() -> void:
	get_tree().set_auto_accept_quit(false)
	HAuth.logged_in.connect(_on_logged_in)
	var error: Error = await connect_to_eos()
	if error == OK:
		Toast.success("Connected to servers")
	else:
		Toast.error("Failed to connect to servers")
func connect_to_eos() -> Error:
	Toast.info("Connecting to servers...")
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
		return ERR_UNAUTHORIZED

	var log_res := HPlatform.set_eos_log_level(EOS.Logging.LogCategory.AllCategories, EOS.Logging.LogLevel.Info)
	if not EOS.is_success(log_res):
		error_connecting_eos.emit("Error credentials to EOS")
		return FAILED

	# This will trigger both the 'await' resolution AND the 'HAuth.logged_in' signal
	var login_success: bool
	if debug:
		login_success = await HAuth.login_anonymous_async("alexi" + str(randi()))
	else:
		login_success = await HAuth.login_account_portal_async()
	if not login_success:
		error_connecting_eos.emit("Authentication error")
		return ERR_UNAUTHORIZED
	return OK
func _on_logged_in() -> void:
	var user_dict: Dictionary = await get_user_info(HAuth.epic_account_id, HAuth.epic_account_id)
	user_info = PlayerInfo.from_dict(user_dict.user_info)
	logged_in.emit(user_info)
func get_user_info(local_id: String, target_id: String) -> Dictionary:
	var query_opts := EOS.UserInfo.QueryUserInfoOptions.new()
	query_opts.local_user_id = local_id
	query_opts.target_user_id = target_id
	IEOS.user_info_interface_query_user_info(query_opts)

	var data: Dictionary = await IEOS.user_info_interface_query_user_info_callback
	if not EOS.is_success(data):  # or: data.result_code == EOS.Result.Success
		push_warning("query_user_info failed")
		return {}

	var copy_opts := EOS.UserInfo.CopyUserInfoOptions.new()
	copy_opts.local_user_id = local_id
	copy_opts.target_user_id = target_id
	var result: Dictionary = IEOS.user_info_interface_copy_user_info(copy_opts)
	return {"user_info": result.user_info}
func update_lobby(lobby_modification: EOSGLobbyModification) -> void:
	var options: EOS.Lobby.UpdateLobbyOptions = EOS.Lobby.UpdateLobbyOptions.new()
	options.lobby_modification = lobby_modification
	EOS.Lobby.LobbyInterface.update_lobby(options)
func leave_lobby() -> Error:
	
	if not lobby:
		print("left lobby. but wanst in one anyways")
		
		multiplayer.multiplayer_peer = null
		return OK

	var success: bool = false
	
	if multiplayer.multiplayer_peer && multiplayer.is_server():
		success = await lobby.destroy_async()
	else:
		success = await lobby.leave_async()

	multiplayer.multiplayer_peer = null
	print("left lobby")
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
func join_a_lobby() -> Error:
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
