extends Node

@export var audio_player: AudioStreamPlayer
@export var music_player: AudioStreamPlayer
@export var ui_player: AudioStreamPlayer

func play_music(stream: AudioStream) -> void:
	music_player.stream = stream
	music_player.play()
func play_sound(stream: AudioStream) -> void:
	audio_player.stream = stream
	audio_player.play()
func play_ui(stream: AudioStream) -> void:
	ui_player.stream = stream
	ui_player.play()

@export var click_sound: AudioStream
@export var hover_sound: AudioStream

func _ready() -> void:
	get_tree().scene_changed.connect(_on_scene_changed)
	_on_scene_changed()
func _on_scene_changed() -> void:
	var all_buttons: Array[Node] = get_tree().current_scene.find_children("*", "Button", true, false)
	for button: Button in all_buttons:
		button.pressed.connect(_play_click)
		button.mouse_entered.connect(_play_hover)
func _play_click() -> void:
	ui_player.stream = click_sound
	ui_player.play()
func _play_hover() -> void:
	ui_player.stream = hover_sound
	ui_player.play()
