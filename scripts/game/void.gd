extends Area2D

func _ready() -> void:
	if multiplayer.is_server():
		body_entered.connect(_on_body_entered)
func _on_body_entered(b: Node2D) -> void:
	# if it falls in the void, on not the shooters client, STOP
	if b.get_multiplayer_authority() != multiplayer.get_unique_id():
		return
	var ball: Ball = b
	ball.die.rpc()
