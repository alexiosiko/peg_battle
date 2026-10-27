extends AnimatedSprite2D

var peg: Peg:
	get(): 
		return owner as Peg
func _ready() -> void:
	peg.revived.connect(_on_revive)
	peg.peg_hit.connect(_on_peg_hit)
	peg.faded.connect(_on_faded)
func _on_revive() -> void:
	modulate = Color.WHITE
func _on_peg_hit(_b: Peg, _hit_by_player: Player, _lin_velo: Vector2) -> void:
	self_modulate = _hit_by_player.color
	position += _lin_velo / 100
	scale *= clamp(_lin_velo / 700, Vector2.ONE, Vector2.ONE * 15).length() / 1.2
			
func _physics_process(delta: float) -> void:
	if position.is_zero_approx():
		return
	position = position.lerp(Vector2.ZERO, delta * 5)
	scale = scale.lerp(Vector2.ONE, delta * 5)

func _on_faded() -> void:
	modulate = Color(1,1,1, 0.5)
