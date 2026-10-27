extends AnimatedSprite2D

var peg: Peg:
	get(): 
		return owner as Peg
func _ready() -> void:
	peg.revived.connect(_on_revived)
	peg.dying.connect(_on_dying)
	play("idle")
	if Engine.is_editor_hint():
		return
	peg.pop.connect(_on_pop)
	if peg.data.type == PegData.Type.MULTIPLIER:
		hide()
func _on_dying(_from_client_id: int) -> void:
	self_modulate = Color(1, 1, 1, 0)
func _on_revived() -> void:
	play("idle")
	self_modulate = Color(1, 1, 1, 1)
	
func _on_pop(_p: Peg) -> void:
	play("pop")
