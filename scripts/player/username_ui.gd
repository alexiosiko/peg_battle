extends Label

var player: PlayerUI:
	get():
		return owner as PlayerUI
		
func _ready() -> void:
	player.player.player_info_changed.connect(_on_info_changed)
func _on_info_changed(pi: PlayerInfo) -> void:
	print("info changed" , pi)

	text = pi.display_name
