extends AnimatedSprite2D

var peg: Peg:
	get(): 
		return owner as Peg
func _ready() -> void:
	peg.revived.connect(_on_revived)
	play("idle")
	if Engine.is_editor_hint():
		return
	peg.pop.connect(_on_pop)
	if peg.data.type == PegData.Type.MULTIPLIER:
		hide()
	
func _on_revived() -> void:
	play("idle")
func _on_pop(_p: Peg) -> void:
	play("pop")
