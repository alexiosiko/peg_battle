extends Node

const ANDROID_INTERSTITIAL_UNIT_ID: String = "ca-app-pub-9154579237929047/5638403627"
const IOS_INTERSTITIAL_UNIT_ID: String = "ca-app-pub-9154579237929047/8760225134"

const ANDROID_BANNER_UNIT_ID: String = "ca-app-pub-9154579237929047/6149092404"
const IOS_BANNER_UNIT_ID: String = "ca-app-pub-9154579237929047/2421600383"

const ANDROID_APP_OPEN_UNIT_ID: String = "ca-app-pub-9154579237929047~7693721326"
const IOS_APP_OPEN_UNIT_ID: String = "ca-app-pub-9154579237929047~7693721326"

const TEST_BANNER: String = "ca-app-pub-3940256099942544/6300978111"
const TEST_INTERSTITUAL: String = "ca-app-pub-3940256099942544/1033173712"

var is_initialized: bool = false
func _ready() -> void:
	var listener = OnInitializationCompleteListener.new()
	listener.on_initialization_complete = _on_admob_initialized
	MobileAds.initialize(listener)

func _on_admob_initialized(_status: InitializationStatus) -> void:
	print("admob initialized")
	is_initialized = true
	_load_interstitial()

func _get_unit_id(test_id: String, android_id: String, ios_id: String) -> String:
	if Settings.test_ads:
		return test_id
	match OS.get_name():
		"Android": return android_id
		"iOS": return ios_id
	return test_id

func _fullscreen_callback(on_closed: Callable) -> FullScreenContentCallback:
	var fsc := FullScreenContentCallback.new()
	fsc.on_ad_dismissed_full_screen_content = func():
		on_closed.call()
	fsc.on_ad_failed_to_show_full_screen_content = func(_e):
		on_closed.call()
	return fsc

# ---------- Interstitial ----------
var interstitial_ad: InterstitialAd
var _interstitial_loading: bool = false

func show_interstitial_ad() -> bool:
	if not is_initialized:
		return false
	if interstitial_ad == null:
		_load_interstitial()
		return false
	interstitial_ad.full_screen_content_callback = _fullscreen_callback(_on_interstitial_closed)
	interstitial_ad.show()
	return true

func _on_interstitial_closed() -> void:
	if interstitial_ad:
		interstitial_ad.destroy()
		interstitial_ad = null
	_load_interstitial()

func _load_interstitial() -> void:

	if _interstitial_loading or interstitial_ad != null:
		return
	_interstitial_loading = true
	var cb := InterstitialAdLoadCallback.new()
	cb.on_ad_loaded = func(ad: InterstitialAd):
		_interstitial_loading = false
		interstitial_ad = ad
	cb.on_ad_failed_to_load = func(e: LoadAdError):
		_interstitial_loading = false
		print("interstitial failed: ", e.message)
	InterstitialAdLoader.new().load(
		_get_unit_id(TEST_INTERSTITUAL, ANDROID_INTERSTITIAL_UNIT_ID, IOS_INTERSTITIAL_UNIT_ID),
		AdRequest.new(), cb)


var banner_ad: AdView

func load_banner(position: AdPosition = AdPosition.BOTTOM) -> void:
	if not is_initialized:
		return
	if banner_ad != null:
		return
	var id := _get_unit_id(TEST_BANNER, ANDROID_BANNER_UNIT_ID, IOS_BANNER_UNIT_ID)
	banner_ad = AdView.new(id, AdSize.BANNER, position)
	var listener := AdListener.new()
	listener.on_ad_failed_to_load = func(e: LoadAdError):
		print("banner failed: ", e.message)
		banner_ad.destroy()
		banner_ad = null
	banner_ad.ad_listener = listener
	banner_ad.load_ad(AdRequest.new())

func show_banner(position: AdPosition = AdPosition.BOTTOM) -> void:
	if not is_initialized:
		return
	if banner_ad:
		banner_ad.show()
	else:
		load_banner(position)

@rpc("call_local")
func hide_banner() -> void:
	if banner_ad:
		banner_ad.hide()
