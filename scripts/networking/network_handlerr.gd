extends Node

signal connected_to_eos
signal error_connecting_eos(msg: String)
var address: String = "5.55.153.59"
var port: String = "8080"
var room: RoomMetaData

func connect_to_eos() -> void:
	var credentials = HCredentials.new()
	credentials.product_name = Env.get_var("PRODUCT_NAME")
	credentials.product_version = Env.get_var("PRODUCT_VERSION")
	credentials.product_id = Env.get_var("PRODUCT_ID")
	credentials.sandbox_id = Env.get_var("SANDBOX_ID")
	credentials.deployment_id = Env.get_var("DEPLOYMENT_ID")
	credentials.client_id = Env.get_var("CLIENT_ID")
	credentials.client_secret = Env.get_var("CLIENT_SECRET")
	# optional
	#credentials.encryption_key = "ENCRYPTION_KEY_HERE"

	var setup_success: bool = await HPlatform.setup_eos_async(credentials)
	
	if not setup_success:
		push_error("Failed to setup EOS. See logs for more details")
		error_connecting_eos.emit("Erroring getting EOS credentials")
		return

	
	var login_success: bool = await HAuth.login_anonymous_async("alexii")
	if not login_success:
		error_connecting_eos.emit("Erroring logging int")
		push_error("Failed to log in via Epic Account Portal")
		return	
	print("EMITTING SIGNLDS")
	connected_to_eos.emit()
func _ready() -> void:
	# Setup HEOS Logs
	HLog.log_level = HLog.LogLevel.INFO
	HAuth.logged_in.connect(_on_logged_in)
	HPlatform.log_msg.connect(_on_eos_log_msg)
	EosHandler.connect_to_eos()
	
func _on_logged_in():
	print("Logged in successfully: product_user_id=%s" % HAuth.product_user_id)
func _on_eos_log_msg(msg: EOS.Logging.LogMessage) -> void:
	print("SDK %s | %s" % [msg.category, msg.message])

func host_offline_room(md: RoomMetaData) -> Error:
	room = md
	multiplayer.multiplayer_peer = OfflineMultiplayerPeer.new()
	return OK
func leave_lobby() -> void:
	multiplayer.multiplayer_peer = null
func connect_to_servers() -> void:
	_connect_to_relay()
func host(md: RoomMetaData) -> Error:
	return OK
func join_a_lobby() -> Error:
	return OK
func _connect_to_relay() -> Error:
	return OK
func _join_validation(_client_metadata: String) -> bool:
	if not room.is_open:
		return false
	return true
func set_is_open(val: bool) -> void:
	return
