class_name RoomMetaData extends RefCounted

var is_open: bool = true
var id: String 

func _to_string() -> String:
	var dict: Dictionary = {
		"is_open": is_open
	}
	return JSON.stringify(dict)

static func from_dict(room: Dictionary) -> RoomMetaData:
	var json = JSON.parse_string(room.metadata)
	var md: RoomMetaData = RoomMetaData.new()
	md.is_open = json["is_open"]
	md.id = room.id
	return md
