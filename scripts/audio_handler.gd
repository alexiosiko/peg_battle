extends Node

@export var sound_player: AudioStreamPlayer
@export var music_player: AudioStreamPlayer
@export var ui_player: AudioStreamPlayer

func play_music(stream: AudioStream) -> void:
	music_player.stream = stream
	music_player.play()
func play_sound(stream: AudioStream, separate_thread: bool = false) -> void:
	if separate_thread:
		var s: AudioStreamPlayer = sound_player.duplicate()
		s.stream = stream
		add_child(s)
		s.play()
		await s.finished
		s.queue_free()
		return
	sound_player.stream = stream
	sound_player.play()
func play_ui(stream: AudioStream) -> void:
	ui_player.stream = stream
	ui_player.play()
@export var click_sound: AudioStream
@export var hover_sound: AudioStream

func _ready() -> void:
	get_tree().scene_changed.connect(_on_scene_changed)
	_on_scene_changed()
	init()
func init() -> void:
	set_bus_mute_state("Sounds", LocalStorage.get_param("sounds_enabled", false))
	set_bus_mute_state("UI", LocalStorage.get_param("sounds_enabled", false))
	set_bus_mute_state("Music", LocalStorage.get_param("music_enabled", false))
func set_bus_mute_state(bus_name: String, should_mute: bool) -> void:
	# Find the internal ID of the bus by its name
	var bus_index = AudioServer.get_bus_index(bus_name)
	
	# If the bus exists, mute or unmute it
	if bus_index != -1:
		AudioServer.set_bus_mute(bus_index, should_mute)
	else:
		push_error("Audio bus not found: " + bus_name)
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
