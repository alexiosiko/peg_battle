extends Label

var player_ui: PlayerUI:
	get():
		return owner as PlayerUI
func _ready() -> void:
	text = player_ui.player.player_info.display_name
