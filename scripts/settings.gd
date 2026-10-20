extends Node

static var is_debug: bool = false

func _ready() -> void:
	var refresh_rate = DisplayServer.screen_get_refresh_rate()
	ProjectSettings.set("physics/common/physics_ticks_per_second", min(refresh_rate, 75))
