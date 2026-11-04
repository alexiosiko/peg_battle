extends Node

signal failed_connecting_eos(msg: String)

signal logged_in(pi: PlayerInfo)
signal game_found

const SOCKET_ID: String = "pegbattle"
const BUCKET_PREFIX: String = "pegbattle"
var BUCKET_ID: String = _make_bucket_id()
func _make_bucket_id() -> String:
	var version: String = str(ProjectSettings.get("application/config/version"))
	return "%s_%s" % [BUCKET_PREFIX, version.replace(".", "_")]
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
	credentials.client_secret = "60MF3vXXVygvI9LnPM/fyAtHTV9m8hg6T4M1zf25Ux0"

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
		print("anonymous login as ", user_info)
		
		return OK
	print("failed to login with persistence and THEN anonymous")
	failed_connecting_eos.emit("Guest login failed")  # signal takes a msg arg
	return FAILED


func login(persistent: bool = true) -> Error:
	if is_logging_in:
		return ERR_BUSY  # prevent overlapping logins from resetting the flag
	is_logging_in = true
	var login_success: bool = false
	if persistent:
		login_success = await HAuth.login_persistent_auth_async()
		print("persistent auth: ", "ok" if login_success else "no usable token")

	if not login_success:
		login_success = await HAuth.login_account_portal_async()

	is_logging_in = false
	if not login_success:
		push_warning("Epic login failed")
		return ERR_UNAUTHORIZED
	return OK


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
	if not EOS.is_success(data):
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
		print("left lobby, but wasn't in one anyway")
		multiplayer.multiplayer_peer = null
		return OK

	var old_lobby: HLobby = lobby
	var was_host: bool = multiplayer.multiplayer_peer != null and multiplayer.is_server()
	lobby = null  # clear first so concurrent calls don't double-leave
	multiplayer.multiplayer_peer = null

	var success: bool
	if was_host:
		success = await old_lobby.destroy_async()
	else:
		success = await old_lobby.leave_async()
	print("left lobby")
	return OK if success else FAILED


func join_lobby(_lobby: HLobby) -> Error:
	var joined_lobby: HLobby = await HLobbies.join_async(_lobby)
	if joined_lobby == null:
		return ERR_CANT_CONNECT

	var host_id: String = joined_lobby.get_owner().product_user_id
	var peer: EOSGMultiplayerPeer = EOSGMultiplayerPeer.new()
	var error: int = peer.create_client(SOCKET_ID, host_id)
	if error != OK:
		printerr("Failed to establish P2P connection to host: ", error)
		await joined_lobby.leave_async()
		return error as Error

	lobby = joined_lobby
	multiplayer.multiplayer_peer = peer
	print("P2P client initialized via socket: ", SOCKET_ID)
	return OK


func join_a_lobby() -> Error:
	if not is_logged_in():
		print("not connected to eos")
		return ERR_CONNECTION_ERROR
	for l: HLobby in await get_open_lobbies():
		if await join_lobby(l) == OK:
			game_found.emit()
			return OK
	return ERR_DOES_NOT_EXIST


func get_lobbies() -> Array[HLobby]:
	var lobbies = await HLobbies.search_by_bucket_id_async(BUCKET_ID)
	if lobbies:
		return lobbies as Array[HLobby]
	return []


func get_open_lobbies() -> Array[HLobby]:
	var result: Array[HLobby] = []
	var lobbies = await HLobbies.search_by_bucket_id_async(BUCKET_ID)
	if not lobbies:
		return result
	for _l: HLobby in lobbies:
		if lobby != null and _l.lobby_id == lobby.lobby_id:
			continue  # don't join self
		if _l.get_attribute("IS_OPEN"):
			result.append(_l)
	return result


func get_open_lobby() -> HLobby:
	var open: Array[HLobby] = await get_open_lobbies()
	return open[0] if not open.is_empty() else null


func is_logged_in() -> bool:
	return HAuth.product_user_id != ""


func host() -> Error:
	var opts := EOS.Lobby.CreateLobbyOptions.new()
	opts.max_lobby_members = 2
	opts.permission_level = EOS.Lobby.LobbyPermissionLevel.PublicAdvertised
	opts.bucket_id = BUCKET_ID

	var new_lobby: HLobby = await HLobbies.create_lobby_async(opts)
	if new_lobby == null:
		printerr("Failed to create lobby")
		return ERR_BUG
	lobby = new_lobby
	lobby.add_attribute("IS_OPEN", true)
	await lobby.update_async()
	print("Lobby created: ", lobby.lobby_id)

	var peer: EOSGMultiplayerPeer = EOSGMultiplayerPeer.new()
	var err: int = peer.create_server(SOCKET_ID)
	if err != OK:
		printerr("create_server failed: ", err)
		await leave_lobby()  # don't leave an advertised lobby with no server
		return err as Error
	peer.set_auto_accept_connection_requests(true)
	multiplayer.multiplayer_peer = peer
	return OK


func close_lobby() -> void:
	if lobby == null:
		return
	lobby.add_attribute("IS_OPEN", false)
	await lobby.update_async()


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		await leave_lobby()
		get_tree().quit()
