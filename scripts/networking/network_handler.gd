extends Node

signal error_connecting_eos(msg: String)
signal player_info_retrieved(pi: PlayerInfo)
signal logged_in
const bucket_id: String = "birdboxgames_pegbattle"
var player_info: PlayerInfo:
	set(val):
		player_info = val
		if player_info:
			player_info_retrieved.emit(player_info)
var lobby: HLobby
var debug: bool = true

func _ready() -> void:
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

func leave_lobby() -> void:
	multiplayer.multiplayer_peer = null

func join_a_lobby() -> Error:
	# 1. Search for available lobbies matching the bucket ID
	var lobbies = await HLobbies.search_by_bucket_id_async(bucket_id)
	
	# 2. Check if the search returned a valid, non-empty array
	if lobbies and lobbies.size() > 0:
		lobbies = lobbies as Array[HLobby]
		
		var joined_lobby = await HLobbies.join_async(lobbies[0])
		
		if joined_lobby != null:
			lobby = joined_lobby 
			return OK
			
	# If the array was empty or join_async returned null
	return ERR_DOES_NOT_EXIST

func get_lobbies() -> Array[HLobby]:
	var lobbies = await HLobbies.search_by_bucket_id_async(bucket_id)
	if lobbies:
		return lobbies as Array[HLobby]
	return []

func host() -> Error:
	var opts := EOS.Lobby.CreateLobbyOptions.new()
	opts.max_lobby_members = 2
	opts.permission_level = EOS.Lobby.LobbyPermissionLevel.PublicAdvertised
	opts.bucket_id = bucket_id

	lobby = await HLobbies.create_lobby_async(opts)
	if not lobby:
		printerr("Failed to create lobby")
		return ERR_BUG
	print("Lobby created: ", lobby.lobby_id)

	var peer: EOSGMultiplayerPeer = EOSGMultiplayerPeer.new()
	var err = peer.create_server("pegbattle")
	if err != OK:
		printerr("create_server failed: ", err)
		return err
	peer.set_auto_accept_connection_requests(true)
	multiplayer.multiplayer_peer = peer

	return OK
