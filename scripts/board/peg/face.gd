@tool
extends AnimatedSprite2D

var peg: Peg:
	get(): 
		return owner as Peg
func _ready() -> void:
	sprite_frames = peg.data.sprite_frames
	play("idle")
	if Engine.is_editor_hint():
		return
	peg.peg_hit.connect(_on_hit)
	
func _on_hit(_p: Peg, _hit_by_player: Player, _linear_velocity: Vector2) -> void:
	if _p.hit_by_player == _hit_by_player:
		play("hit")
