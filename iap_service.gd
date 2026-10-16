extends Node

signal no_ads_changed(on: bool)

const REMOVE_ADS_PRICE := 2.99

var no_ads := false

func price_text() -> String:
	return "$" + String.num(REMOVE_ADS_PRICE, 2)

func _ready() -> void:
	no_ads = Save.no_ads

func purchase_remove_ads() -> void:
	# Stub IAP. The web build grants the flag without a payment provider.
	no_ads = true
	Save.set_no_ads(true)
	no_ads_changed.emit(true)
