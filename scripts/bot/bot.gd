class_name Bot

static func create_bot_info() -> PlayerInfo:
	var pi: PlayerInfo = PlayerInfo.new()
	pi.display_name = "Bot 1"
	pi.avatar_index = randi_range(0, Database.avatars.size() - 1)
	pi.country = "n/a"
	return pi
