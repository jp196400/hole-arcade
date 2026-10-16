extends Node

signal no_ads_changed(on: bool)

var no_ads := false

func _ready() -> void:
	no_ads = Save.no_ads

func purchase_remove_ads() -> void:
	# Stub IAP. The web build grants the flag without a payment provider.
	no_ads = true
	Save.set_no_ads(true)
	no_ads_changed.emit(true)
