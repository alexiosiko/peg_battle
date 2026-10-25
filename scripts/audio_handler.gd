extends Node

@export var sound_player: AudioStreamPlayer
@export var music_player: AudioStreamPlayer
@export var ui_player: AudioStreamPlayer

func play_music(stream: AudioStream) -> void:
	music_player.stream = stream
	music_player.play()
# Changed the 3rd parameter name to 'speed' for clarity, defaulting to a standard full-volume speed value
func play_sound(stream: AudioStream, separate_thread: bool = false, speed: float = -1) -> void:
	if separate_thread:
		var s: AudioStreamPlayer = sound_player.duplicate()
		s.stream = stream
		add_child(s)
		s.play()
		await s.finished
		s.queue_free()
		return
	
	# 1. Define your speed bounds (Adjust 50.0 and 800.0 depending on how fast your ball moves)
	# 2. Map those speeds to a good decibel range (e.g., -20 dB for soft hits, 2 dB for maximum impact hits)
	if speed != -1:
		var target_db: float = remap(speed, 50.0, 800.0, -5.0, 10.0)
		# Clamp the final decibels to prevent it from going completely silent or dangerously loud
		sound_player.volume_db = clampf(target_db, -24.0, 3.0)
	
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
