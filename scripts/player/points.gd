extends Label

var player: Player:
	get():
		return owner as Player
func _ready() -> void:
	player.points_changed.connect(_on_points_updated)
func _on_points_updated(points: int) -> void:
	text = str(points)
	if multiplayer.is_server():
		_sync.rpc(points)

@rpc
func _sync(points: int) -> void:
	text = str(points)
