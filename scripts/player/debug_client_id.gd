extends Label

var player: PlayerUI:
	get():
		return owner as PlayerUI
func _physics_process(_delta: float) -> void:
	text = str(player.player.client_id)
