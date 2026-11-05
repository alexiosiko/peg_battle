# In main script
extends Node

func connect_to_eos() -> void:
	var credentials = HCredentials.new()
	
	credentials.product_name = "doesntmatterbutitsunique"
	credentials.product_version = "1.0.1"
	credentials.product_id = "7113d087c5fb42ee8142e17da3cb7615"
	credentials.sandbox_id = "f6f7caaa75424fce8519bc0e16432e18"
	credentials.deployment_id = "f6784bea03884bd9849c6faba3927a1d"
	credentials.client_id = "xyza7891HlTHCzv6g1sLVsdxFBFbLtsX"
	credentials.client_secret = "i4JAeELoZUXLGzk2B4e4g1Z+kOxkbipccT1W6RsNzQo"
	# optional
	#credentials.encryption_key = "ENCRYPTION_KEY_HERE"
	print(credentials)

	var setup_success: bool = await HPlatform.setup_eos_async(credentials)
	print("setupsecucess bool" , setup_success)
	
	if not setup_success:
		push_error("Failed to setup EOS. See logs for more details")
		return

	# Setup Logs from EOS
	
	var log_res := HPlatform.set_eos_log_level(EOS.Logging.LogCategory.AllCategories, EOS.Logging.LogLevel.Info)
	if not EOS.is_success(log_res):
		push_error("Failed to set logging level")
		return

	
	var login_success := await HAuth.login_anonymous_async("alexii")
	if not login_success:
		printerr("Failed to log in via Epic Account Portal")
		return	
	else:
		print("logged into server")
	
		
	print("done")
func _ready() -> void:
	# Setup HEOS Logs
	HLog.log_level = HLog.LogLevel.INFO
	HAuth.logged_in.connect(_on_logged_in)
	HPlatform.log_msg.connect(_on_eos_log_msg)
	
	#connect_to_eos()
	
func _on_logged_in():
	print("Logged in successfully: product_user_id=%s" % HAuth.product_user_id)

	# Example: Get top records for a leaderboard
	var records := await HLeaderboards.get_leaderboard_records_async("LEADERBOARD_ID_HERE")
	print(records)
func _on_eos_log_msg(msg: EOS.Logging.LogMessage) -> void:
	print("SDK %s | %s" % [msg.category, msg.message])
