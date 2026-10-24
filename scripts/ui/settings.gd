extends Control

@export var button_close: Button
@export var button_toggle: Button

func _ready() -> void:
	hide()
	button_close.pressed.connect(_on_close)
	button_toggle.pressed.connect(_on_toggle)

func _on_toggle() -> void:
	visible = !visible

func _on_close() -> void:
	close()
func close() -> void:
	hide()
