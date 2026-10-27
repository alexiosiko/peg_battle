extends Label

var player: PlayerUI:
	get():
		return owner as PlayerUI
		
func _ready() -> void:
	player.player.player_info_changed.connect(_on_info_changed)
func _on_info_changed(pi: PlayerInfo) -> void:
	if pi.display_name.is_empty():
		text = "Tutorial"
	else:
		text = pi.display_name
