extends Control

@export var ball_sprite: Texture2D

var player: PlayerUI:
	get():
		return owner as PlayerUI
func _ready() -> void:
	player.player.ball_count_changed.connect(_on_ball_count_changed)
func _on_ball_count_changed(count: int) -> void:
	for child in get_children():
		child.free()
	for i in range(count):
		var sprite: TextureRect = TextureRect.new()
		sprite.texture = ball_sprite
		add_child(sprite)
		
