class_name Catcher extends Area2D

@export var caught_sound: AudioStream

signal ball_caught(ball: Ball)

func _ready() -> void:
	if multiplayer.is_server():
		body_entered.connect(_on_body_entered)
func _on_body_entered(body: Node2D) -> void:
	var ball: Ball = body
	ball_caught.emit(ball)
	ball.die.rpc()
	AudioHandler.play_sound(caught_sound, true)
