extends Control

@export var toggle_button: Button
@export var close_button: Button

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("toggle_menu"):
		_toggle()
func _ready() -> void:
	hide()
	close_button.pressed.connect(hide)
	toggle_button.pressed.connect(_toggle)

func _toggle() -> void:
	visible = !visible
	
