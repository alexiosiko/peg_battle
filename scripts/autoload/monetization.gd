extends Node
## Autoload: add as "Monetization" in Project Settings > Globals.
## One-time non-consumable "remove ads" purchase via godot-iap.
##
## Setup:
##  1. Create a NON-CONSUMABLE product with ID REMOVE_ADS_SKU in both
##     Play Console and App Store Connect (same ID on both).
##  2. Enable the godot-iap plugin. It adds a "GodotIapPlugin" autoload;
##     this script creates its own wrapper node instead (see _ready), so
##     do NOT also connect signals on that autoload (purchases would finish twice).
##  3. Gate every ad call with `if Monetization.ads_removed: return`.

signal ads_removed_changed(removed: bool)
signal price_loaded(price: String)
signal purchase_failed(message: String)

const Types = preload("res://addons/godot-iap/types.gd")

const REMOVE_ADS_SKU := "removeads"

var ads_removed := false:
	set(value):
		if ads_removed == value:
			return
		ads_removed = value
		_save_flag()
		ads_removed_changed.emit(value)

var price := ""  # localized price string for your button, e.g. "$2.99"

var _iap
var _connected := false


func _ready() -> void:
	_load_flag()

	# Only mobile has a real store; editor/desktop calls no-op safely.
	var wrapper = preload("res://addons/godot-iap/godot_iap.gd").new()
	wrapper.name = "GodotIapWrapper"
	add_child(wrapper)
	_iap = wrapper

	_iap.purchase_updated.connect(_on_purchase_updated)
	_iap.purchase_error.connect(_on_purchase_error)

	_connected = await _iap.init_connection()
	if not _connected:
		push_warning("Monetization: store connection failed (normal in editor).")
		return

	await _load_product()
	await restore()  # silently re-check ownership on every launch


## Call from your "Remove Ads" button.
func purchase_remove_ads() -> void:
	if ads_removed:
		return
	if not _connected:
		purchase_failed.emit("Store not available.")
		return

	var platforms = Types.RequestPurchasePropsByPlatforms.new()
	platforms.apple = Types.RequestPurchaseIosProps.new()
	platforms.apple.sku = REMOVE_ADS_SKU
	platforms.google = Types.RequestPurchaseAndroidProps.new()
	var skus: Array[String] = [REMOVE_ADS_SKU]
	platforms.google.skus = skus
	var props = Types.RequestPurchaseProps.in_app(platforms)

	# Result arrives through purchase_updated / purchase_error.
	await _iap.request_purchase(props)


## Call from a "Restore Purchases" button (Apple requires one).
func restore() -> void:
	if not _connected:
		return
	var owned: Array = await _iap.get_available_purchases()
	for purchase in owned:
		if purchase.product_id == REMOVE_ADS_SKU:
			ads_removed = true
			await _iap.finish_transaction(purchase, false)
			return


func _load_product() -> void:
	var request = Types.ProductRequest.new()
	request.skus.assign([REMOVE_ADS_SKU])
	request.type = Types.ProductQueryType.IN_APP

	var products: Array = await _iap.fetch_products(request)
	for product in products:
		if product.id == REMOVE_ADS_SKU:
			price = product.display_price
			price_loaded.emit(price)


func _on_purchase_updated(purchase) -> void:
	if purchase.product_id != REMOVE_ADS_SKU:
		return
	# For a cheap indie game, trusting the store result is common.
	# Add server-side verification here if piracy matters to you.
	ads_removed = true
	# false = non-consumable. On Android, unfinished purchases are
	# refunded automatically after 3 days, so always finish.
	await _iap.finish_transaction(purchase, false)


func _on_purchase_error(error) -> void:
	# User cancelling is not worth showing an error for.
	var code := str(error.code).to_lower()
	if code.contains("cancel"):
		return
	purchase_failed.emit(str(error.message))


func _save_flag() -> void:
	LocalStorage.add_param(REMOVE_ADS_SKU, ads_removed)

func _load_flag() -> void:
	ads_removed = LocalStorage.get_param(REMOVE_ADS_SKU, false)
