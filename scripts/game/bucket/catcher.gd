class_name Catcher extends Area2D

@export var anim_player: AnimationPlayer

signal ball_caught(ball: Ball)

func _ready() -> void:
	body_entered.connect(_on_body_entered)
func _on_body_entered(body: Node2D) -> void:
	var ball: Ball = body
	if ball.get_multiplayer_authority() != multiplayer.get_unique_id():
		return
	_ball_count.rpc(ball.get_path())
	ball.die.rpc()
@rpc("any_peer", "call_local")
func _ball_count(ball_path: String) -> void:
	var ball: Ball = get_node(ball_path)
	ball_caught.emit(ball)
	anim_player.play("ball_caught")
	
