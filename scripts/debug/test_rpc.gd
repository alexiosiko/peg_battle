extends Button

func _ready() -> void:
	pressed.connect(_on_button)
func _on_button() -> void:
	test.rpc_id(1)
@rpc("any_peer", "call_local")
func test() -> void:
	print("message from ", multiplayer.get_remote_sender_id())
