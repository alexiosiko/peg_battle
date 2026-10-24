extends Label

var peg: Peg:
	get(): 
		return owner as Peg
func _ready() -> void:
	if peg.data.type == PegData.Type.MULTIPLIER:
		show()
	text = str(peg.data.multi) + "X"
