extends Sprite2D

@export var frown: Texture2D
@export var dieing: Texture2D

var peg: Peg:
	get(): 
		return owner as Peg
func _ready() -> void:
	peg.peg_hit.connect(_on_hit)
	peg.dying.connect(_on_dying)
func _on_dying() -> void:
	texture = dieing
func _on_hit(_p: Peg) -> void:
	print("hit")
	texture = frown
