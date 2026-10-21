extends Label

var player: PlayerUI:
	get():
		return owner as PlayerUI
		
func _ready() -> void:
	player.player.player_info_changed.connect(_on_info_changed)
func _on_info_changed(pi: PlayerInfo) -> void:
	text = pi.country
	if text.is_empty():
		hide()
	else:
		show()
