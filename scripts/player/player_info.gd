class_name PlayerInfo extends RefCounted

var user_id: String
var country: String
var display_name: String
var display_name_sanitized: String
var preferred_language: String
var nickname: String
var avatar_index: int

static func from_dict(dict: Dictionary) -> PlayerInfo:
	var info = PlayerInfo.new()
	info.user_id = dict.get("user_id")
	info.country = dict.get("country")
	info.display_name = dict.get("display_name")
	info.display_name_sanitized = dict.get("display_name_sanitized")
	info.preferred_language = dict.get("preferred_language")
	info.nickname = dict.get("nickname")
	info.avatar_index = LocalStorage.get_param("avatar_index", randi_range(0, Database.avatars.size() - 1))
	return info

## Converts the PlayerInfo instance back into a clean JSON string structure
func _to_string() -> String:
	var dict: Dictionary = {
		"user_id": user_id,
		"country": country,
		"display_name": display_name,
		"display_name_sanitized": display_name, # Mirroring your EOS data dump
		"preferred_language": preferred_language,
		"nickname": nickname,
		"avatar_index": avatar_index
	}
	return JSON.stringify(dict)
## Creates and returns a new PlayerInfo instance populated from a JSON string
static func from_string(json_string: String) -> PlayerInfo:
	var player_info = PlayerInfo.new()
	
	var json = JSON.parse_string(json_string)
	player_info.avatar_index = json.get("avatar_index")
	player_info.user_id = json.get("user_id")
	player_info.country = json.get("country")
	player_info.display_name = json.get("display_name")
	player_info.preferred_language = json.get("preferred_language")
	player_info.nickname = json.get("nickname")
	return player_info
