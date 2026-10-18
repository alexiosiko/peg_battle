extends Label

var peg: Peg:
	get():
		return owner as Peg
func _ready() -> void:
	text = str(peg.data.points)
	
