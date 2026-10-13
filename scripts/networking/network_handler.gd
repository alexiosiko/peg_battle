extends Node

var address: String = "5.55.153.59"
var port: String = "8080"
var peer: NodeTunnelPeer = NodeTunnelPeer.new()
var room: RoomMetaData

func set_is_open(val: bool) -> void:
	room.is_open = val
	var error: Error = peer.update_room(room.to_string())
	print("updated room error code with :", error)
func _ready() -> void:
	peer.error.connect(func(error_msg: String):
		push_error(error_msg)
	)
	# Safely start connection in background
	_connect_to_relay()
func host_offline_room(md: RoomMetaData) -> Error:
	room = md
	multiplayer.multiplayer_peer = OfflineMultiplayerPeer.new()
	return OK
func leave_lobby() -> void:
	peer.close()
	multiplayer.multiplayer_peer = null
func connect_to_servers() -> void:
	_connect_to_relay()
func host(md: RoomMetaData) -> Error:
	var error: Error = peer.host_room(true, md.to_string())
	print("hosting room error code: ", error)
	if error == OK:
		await peer.room_connected
		room = md
	else:
		peer.join_validation = _join_validation
	return error
func join_a_lobby() -> Error:
	peer.get_rooms()
	var array: Array = await peer.rooms_received
	
	for ar: Dictionary in array:
		var md: RoomMetaData = RoomMetaData.from_dict(ar)
		if md.is_open:
			peer.join_room(md.id)
			await peer.room_connected
			return OK # Only return OK if we actually joined a room!
			
	print("No open lobbies found.")
	return ERR_DOES_NOT_EXIST
func _connect_to_relay() -> Error:
	print("connecting to relay ...")
	var uri: String = address + ":" + port
	var error: Error = peer.connect_to_relay(uri, "birdboxgames_deckofempires")
	if error != OK:
		push_error("Relay connection error code: %d" % error)
		return error
	multiplayer.multiplayer_peer = peer 
	await peer.authenticated
	print("auth")
	
	print("Connected to servers and authenticated")
	return error
func _join_validation(_client_metadata: String) -> bool:
	if not room.is_open:
		return false
	return true
