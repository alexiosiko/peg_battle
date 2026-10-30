extends Node

@export var disable_ads_buy_button: Button
@export var restore_purchases_button: Button
func _ready() -> void:
	disable_ads_buy_button.pressed.connect(Monetization.purchase_remove_ads)
	restore_purchases_button.pressed.connect(Monetization.restore)
	Monetization.price_loaded.connect(func(p): disable_ads_buy_button.text = "Remove Ads – " + p)
	Monetization.ads_removed_changed.connect(func(r): disable_ads_buy_button.visible = not r)
	disable_ads_buy_button.visible = not Monetization.ads_removed

# Anywhere you show ads
func show_interstitial():
	if Monetization.ads_removed:
		return
	# admob.show_interstitial_ad()
