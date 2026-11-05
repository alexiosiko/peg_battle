extends Node

# Define the target folder inside your project resources
const SCREENSHOT_DIR = "res://screenshots/"

func _unhandled_input(event: InputEvent) -> void:
	# Trigger the screenshot when pressing the F12 key
	if event.is_action_pressed("screenshot"):
		take_screenshot()

func take_screenshot() -> void:
	# 1. Ensure directory exists
	if not DirAccess.dir_exists_absolute(SCREENSHOT_DIR):
		DirAccess.make_dir_absolute(SCREENSHOT_DIR)
	
	# 2. Wait for the frame to finish rendering so post-processing is fully applied
	await RenderingServer.frame_post_draw
	
	# 3. Get the fully rendered image directly from the root viewport
	var image = get_tree().get_root().get_texture().get_image()
	
	# 4. Create the filename
	var time = Time.get_datetime_dict_from_system()
	var filename = "screenshot_%04d%02d%02d_%02d%02d%02d.png" % [
		time.year, time.month, time.day,
		time.hour, time.minute, time.second
	]
	var full_path = SCREENSHOT_DIR + filename
	
	# 5. Save the file (No color conversion needed here!)
	var error = image.save_png(full_path)
	if error == OK:
		print("Screenshot saved to: ", ProjectSettings.globalize_path(full_path))
	else:
		push_error("Failed to save screenshot. Error: ", error)
