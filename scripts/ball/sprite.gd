extends Sprite2D

var ball: Ball:
	get():
		return owner as Ball
func _ready() -> void:
	await ball.ready
	var game: Game = get_tree().current_scene
	var player: Player = game.get_player(ball.get_multiplayer_authority())
	self_modulate = player.color
