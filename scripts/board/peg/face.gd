extends AnimatedSprite2D

var peg: Peg:
	get(): 
		return owner as Peg
func _ready() -> void:
	play("idle")
	if Engine.is_editor_hint():
		return
	peg.peg_hit.connect(_on_hit)
	if peg.data.type == PegData.Type.MULTIPLIER:
		hide()
	
func _on_hit(_p: Peg, _hit_by_player: Player, _linear_velocity: Vector2) -> void:
	if _p.hit_by_player == _hit_by_player:
		play("hit")
