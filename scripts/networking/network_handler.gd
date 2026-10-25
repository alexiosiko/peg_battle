extends Node

signal failed_connecting_eos(msg: String)

signal logged_in(pi: PlayerInfo)
signal game_found

const SOCKET_ID: String = "pegbattle"
const BUCKET_ID: String = "birdboxgames_pegbattle"
var user_info: PlayerInfo:
	set(val):
		user_info = val
		logged_in.emit(user_info)
var lobby: HLobby

var is_logging_in: bool = false
func _ready() -> void:
	user_info = PlayerInfo.new()
	get_tree().set_auto_accept_quit(false)
	HAuth.logged_in.connect(_on_logged_in)
	is_logging_in = true
	var error: Error = await connect_to_eos()
	is_logging_in = false
	if error == OK:
		Toast.success("Connected to servers")
	else:
		failed_connecting_eos.emit("Server error")
		print("Error: ", error)
		Toast.error("No connection ...")
func connect_to_eos() -> Error:
	var credentials: HCredentials = HCredentials.new()
	credentials.product_name = "birdboxgames_pegbattle"
	credentials.product_version = ProjectSettings.get("application/config/version")
	credentials.product_id = "7113d087c5fb42ee8142e17da3cb7615"
	credentials.sandbox_id = "f6f7caaa75424fce8519bc0e16432e18"
	credentials.deployment_id = "f6784bea03884bd9849c6faba3927a1d"
	credentials.client_id = "xyza7891HlTHCzv6g1sLVsdxFBFbLtsX"
	credentials.client_secret = "i4JAeELoZUXLGzk2B4e4g1Z+kOxkbipccT1W6RsNzQo"
	#credentials.encryption_key = "5f10af06412d17b3889345887f64ebac39e8e1dfb52183d3ec8bb7a447b6b954"

	var setup_success: bool = await HPlatform.setup_eos_async(credentials)
	if not setup_success:
		return ERR_UNAUTHORIZED
	var log_res: EOS.Result = HPlatform.set_eos_log_level(EOS.Logging.LogCategory.AllCategories, EOS.Logging.LogLevel.Info)
	if not EOS.is_success(log_res):
		return FAILED
	var login_success: bool = await HAuth.login_persistent_auth_async()
	if login_success:
		return OK
	if await login_as_guest() == OK:
		return OK
	return FAILED
func login_as_guest() -> Error:
	var display_name: String = "user#" + str(randi_range(0, 100000))
	is_logging_in = true
	var login_success: bool = await HAuth.login_anonymous_async(display_name)
	is_logging_in = false
	if login_success:
		user_info = PlayerInfo.new()
		user_info.display_name = display_name
		print("annonymous login as ", user_info)
		return OK
	print("failed to login persistence and THEN annonymous")
	failed_connecting_eos.emit()
	return FAILED
func login(persistent: bool = true) -> Error:
	is_logging_in = true
	var login_success: bool = false
	if persistent:
		login_success = await HAuth.login_persistent_auth_async()
		if login_success:
			print("logged in with persistence auth")
		else:
			print("could not loginwin with persistent auth login")
	# 2. Only show the portal if there was no usable token
	if not login_success:
		login_success = await HAuth.login_account_portal_async()

	is_logging_in = false
	return OK if login_success else ERR_UNAUTHORIZED
func logout() -> Error:
	var error: EOS.Result = await HAuth.logout_async()
	print("logout error code: ", error)
	user_info = null
	return error as Error
func _on_logged_in() -> void:
	var user_dict: Dictionary = await get_user_info(HAuth.epic_account_id, HAuth.epic_account_id)
	user_info = PlayerInfo.from_dict(user_dict.user_info)
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
		var error = peer.create_client(SOCKET_ID, host_id)
		if error != OK:
			printerr("Failed to establish P2P connection to host: ", error)
			return error
		
		# Assign it to Godot's global multiplayer system
		multiplayer.multiplayer_peer = peer
		print("P2P Client initialized. Connected to Godot network via Socket: ", SOCKET_ID)
			
		return OK
	return ERR_CANT_CONNECT
func join_a_lobby() -> Error:
	if not is_logged_in():
		print("not connected to eos")
		return ERR_CONNECTION_ERROR
	var lobbies = await HLobbies.search_by_bucket_id_async(BUCKET_ID)
	print(lobbies)
	if lobbies and lobbies.size() > 0:
		lobbies = lobbies as Array[HLobby]
		game_found.emit()
		return await join_lobby(lobbies[0])
	return ERR_DOES_NOT_EXIST
func get_lobbies() -> Array[HLobby]:
	var lobbies = await HLobbies.search_by_bucket_id_async(BUCKET_ID)
	if lobbies:
		return lobbies as Array[HLobby]
	return []
func is_logged_in() -> bool:
	return HAuth.product_user_id != ""	
func host() -> Error:
	var opts := EOS.Lobby.CreateLobbyOptions.new()
	opts.max_lobby_members = 2
	opts.disable_host_migration = true
	opts.permission_level = EOS.Lobby.LobbyPermissionLevel.PublicAdvertised
	opts.bucket_id = BUCKET_ID

	lobby = await HLobbies.create_lobby_async(opts)
	lobby.add_attribute("IS_OPEN", true)
	await lobby.update_async()
	if not lobby:
		printerr("Failed to create lobby")
		return ERR_BUG
	print("Lobby created: ", lobby.lobby_id)

	var peer: EOSGMultiplayerPeer = EOSGMultiplayerPeer.new()
	var err = peer.create_server(SOCKET_ID)
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
