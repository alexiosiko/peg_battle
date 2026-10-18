extends Control

@export var label: Label
@export var reconnect: Button

func _ready() -> void:
	if not NetworkHandler.is_connected_to_eos():
		reconnect.hide()
	else:
		reconnect.hide()
	NetworkHandler.error_connecting_eos.connect(_on_fail)
	NetworkHandler.logged_in.connect(_on_logged_in)
	reconnect.pressed.connect(_on_pressed)
func _on_fail(msg: String) -> void:
	show()
	label.text = msg
	reconnect.show()
func _on_logged_in(pi: PlayerInfo) -> void:
	label.text = "Connected as " + pi.display_name_sanitized
	
func _on_pressed() -> void:
	reconnect.text = "Connecting ..."
	NetworkHandler.connect_to_eos()
