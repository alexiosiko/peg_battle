extends Node

static var is_debug: bool = false
static var skip_ads: bool = false
static var test_ads: bool = false

func _ready() -> void:
	skip_ads = LocalStorage.get_param("skip_ads", false)
	var refresh_rate = DisplayServer.screen_get_refresh_rate()
	ProjectSettings.set("physics/common/physics_ticks_per_second", min(refresh_rate, 75))
