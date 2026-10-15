class_name PlayerInfo extends RefCounted

var country: String
var display_name: String
var user_id: String
var preferred_language: String
var nickname: String

static func from_dict(dict: Dictionary) -> PlayerInfo:
	var info = PlayerInfo.new()
	info.user_id = dict.get("user_id", "")
	info.country = dict.get("country", "")
	info.display_name = dict.get("display_name", "")
	info.preferred_language = dict.get("preferred_language", "")
	info.nickname = dict.get("nickname", "")
	
	return info

## Converts the PlayerInfo instance back into a clean JSON string structure
func _to_string() -> String:
	var dict: Dictionary = {
		"user_id": user_id,
		"country": country,
		"display_name": display_name,
		"display_name_sanitized": display_name, # Mirroring your EOS data dump
		"preferred_language": preferred_language,
		"nickname": nickname
	}
	return JSON.stringify(dict)
