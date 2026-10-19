extends Node

# Define the target folder inside your project resources
const SCREENSHOT_DIR = "res://screenshots/"

func _unhandled_input(event: InputEvent) -> void:
	# Trigger the screenshot when pressing the F12 key
	if event.is_action_pressed("screenshot"):
		take_screenshot()

func take_screenshot() -> void:
	# 1. Ensure the target directory exists
	if not DirAccess.dir_exists_absolute(SCREENSHOT_DIR):
		DirAccess.make_dir_absolute(SCREENSHOT_DIR)
	
	# 2. Get the current viewport image data
	var viewport = get_viewport()
	var image = viewport.get_texture().get_image()
	
	# 2b. Ensure RGBA8 format, then correct linear->sRGB so the saved PNG matches what's on screen
	image.convert(Image.FORMAT_RGBA8)
	image.linear_to_srgb()
	
	# 3. Generate a unique filename using the current timestamp
	var time = Time.get_datetime_dict_from_system()
	var filename = "screenshot_%04d%02d%02d_%02d%02d%02d.png" % [
		time.year, time.month, time.day,
		time.hour, time.minute, time.second
	]
	
	var full_path = SCREENSHOT_DIR + filename
	
	# 4. Save the image as a PNG file
	var error = image.save_png(full_path)
	
	if error == OK:
		print("Screenshot saved successfully to: ", full_path)
	else:
		push_error("Failed to save screenshot. Error code: ", error)
