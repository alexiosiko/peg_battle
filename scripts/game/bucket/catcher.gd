class_name Catcher extends Area2D

@export var caught_sound: AudioStream

signal ball_caught(owner_id: int)

func _ready() -> void:
	if multiplayer.is_server():
		body_entered.connect(_on_body_entered)
func _on_body_entered(body: Node2D) -> void:
	var ball: Ball = body
	if ball.get_multiplayer_authority() != multiplayer.get_unique_id():
		return
	_ball_count.rpc(ball.get_multiplayer_authority())
	ball.die.rpc()
	AudioHandler.play_sound(caught_sound, true)
@rpc("any_peer", "call_local")
func _ball_count(owner_id: int) -> void:
	ball_caught.emit(owner_id)
