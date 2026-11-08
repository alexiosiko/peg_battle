extends Button

@export var offline_button: Button

func _ready() -> void:
	offline_button.pressed.connect(_start_offline)
	pressed.connect(_on_play)
	multiplayer.peer_connected.connect(_on_peer_connected)
# --- Buttons ---
func _on_play() -> void:
	SceneHandler.transition("res://scenes/connecting.tscn", "Searching for opponent", true)
func _start_offline() -> void:
	multiplayer.multiplayer_peer = OfflineMultiplayerPeer.new()
	SceneHandler.transition.rpc("res://scenes/game.tscn", "Offline game started!")

# --- Matchmaking ---
func _on_peer_connected(_id: int) -> void:
	if not multiplayer.is_server():
		return
	SceneHandler.transition.rpc("res://scenes/game.tscn", "Opponent found!", true)

func _exit_tree() -> void:
	if multiplayer.peer_connected.is_connected(_on_peer_connected):
		multiplayer.peer_connected.disconnect(_on_peer_connected)
