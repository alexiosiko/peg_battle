extends Label

var player: PlayerUI:
	get():
		return owner as PlayerUI
func _ready() -> void:
	player.player.points_changed.connect(_on_points_changed)
func _on_points_changed(val: int) -> void:
	text = str(val)
