extends AnimatedSprite2D

@export var jump_sound: AudioStream
@export var audio_player: AudioStreamPlayer
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	play("start")
	audio_player.stream = jump_sound
	audio_player.play()
	await animation_finished
	queue_free()
