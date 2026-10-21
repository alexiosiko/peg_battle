extends Button

@export var scene_path: String
@export var loading_msg: String

func _ready() -> void:
	pressed.connect(_on_pressed)
func _on_pressed() -> void:
	SceneHandler.transition(scene_path, loading_msg)
