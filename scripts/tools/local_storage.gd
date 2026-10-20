extends Node

const SAVE_PATH = "user://save_data.cfg"

# Adds or updates a parameter in the save data, then immediately saves it
func add_param(key: String, value: Variant) -> void:
	var current_data := load_game_data()
	current_data[key] = value
	save_game_data(current_data)

# Retrieves a parameter. Returns a default value if the key doesn't exist
func get_param(key: String, default_value: Variant = null) -> Variant:
	var current_data := load_game_data()
	if current_data.has(key):
		return current_data[key]
	return default_value

# Helper function to write the entire dictionary to disk
func save_game_data(data: Dictionary) -> void:
	var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		file.store_var(data) 
		file.close()

# Helper function to read the entire dictionary from disk
func load_game_data() -> Dictionary:
	if not FileAccess.file_exists(SAVE_PATH):
		return {}
		
	var file = FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file:
		var data = file.get_var()
		file.close()
		if data is Dictionary:
			return data
	return {}
