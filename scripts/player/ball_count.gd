extends Label

@export var player: Player

func _ready() -> void:
	player.ball_count_changed.connect(_on_ball_count)
func _on_ball_count(count: int) -> void:
	text = str(count)
	if multiplayer.is_server():
		_sync.rpc(count)

@rpc
func _sync(count: int) -> void:
	text = str(count)
