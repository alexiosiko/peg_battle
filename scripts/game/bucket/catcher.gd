class_name Catcher extends Area2D

@export var anim_player: AnimationPlayer

signal ball_caught(ball: Ball)


func _ready() -> void:
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node2D) -> void:
	var ball: Ball = body as Ball
	if ball == null or not ball.is_multiplayer_authority():
		return  # only the shooter's peer handles it
	ball_caught.emit(ball)
	_play_catch_anim.rpc()
	ball.die.rpc()


@rpc("any_peer", "call_local")
func _play_catch_anim() -> void:
	anim_player.play("ball_caught")
