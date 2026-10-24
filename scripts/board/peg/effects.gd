@tool
extends AnimatedSprite2D

var peg: Peg:
	get(): 
		return owner as Peg
func _ready() -> void:
	speed_scale = randf_range(0.9, 1.1)
	
	sprite_frames = peg.data.effects_sprite_frames
	if sprite_frames:
		play("idle")
