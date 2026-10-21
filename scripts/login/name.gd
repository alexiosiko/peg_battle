extends Label

func _ready() -> void:
	if NetworkHandler.user_info:
		text = NetworkHandler.user_info.display_name
	else:
		text = "n/a"
	NetworkHandler.logged_in.connect(_on_user_info_changed)
func _on_user_info_changed(pi: PlayerInfo) -> void:
	if pi:
		text = pi.display_name
	else:
		text = "n/a"
