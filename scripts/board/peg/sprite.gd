@tool
extends Sprite2D

var peg: Peg:
	get(): 
		return owner as Peg
func _ready() -> void:
	match owner.type:
		Peg.Type.MULTIPLIER: pass
		#_: self_modulate = peg.color
