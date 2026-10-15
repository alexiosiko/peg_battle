extends Control

@export var label: Label
@export var reconnect: Button

func _ready() -> void:
	NetworkHandler.error_connecting_eos.connect(_on_fail)
	NetworkHandler.logged_in.connect(_on_eos_connected)
	reconnect.pressed.connect(_on_pressed)
func _on_fail(msg: String) -> void:
	show()
	label.text = msg
func _on_eos_connected() -> void:
	label.text = "Connected"
	
func _on_pressed() -> void:
	reconnect.text = "Connecting ..."
	NetworkHandler.connect_to_eos()
