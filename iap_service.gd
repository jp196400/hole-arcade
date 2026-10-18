extends Node

const MobileIds = preload("res://mobile_ids.gd")

signal no_ads_changed(on: bool)

var no_ads := false
var _billing: Object = null
var _billing_ready := false
var _want_purchase := false

func price_text() -> String:
	return "$" + String.num(MobileIds.REMOVE_ADS_PRICE, 2)

func _ready() -> void:
	no_ads = Save.no_ads
	_billing = _billing_plugin()
	if _billing == null:
		return
	if _billing.has_signal("connected"):
		_billing.connected.connect(_on_billing_connected)
	if _billing.has_signal("purchases_updated"):
		_billing.purchases_updated.connect(_on_purchases)
	if _billing.has_signal("query_purchases_response"):
		_billing.query_purchases_response.connect(_on_query)
	if _billing.has_method("startConnection"):
		_billing.startConnection()

func _billing_plugin() -> Object:
	if Engine.has_singleton("GodotGooglePlayBilling"):
		return Engine.get_singleton("GodotGooglePlayBilling")
	return null

func purchase_remove_ads() -> void:
	if _billing != null and _billing.has_method("purchase"):
		_want_purchase = true
		if _billing_ready:
			_billing.purchase(MobileIds.PRODUCT_REMOVE_ADS)
		elif _billing.has_method("startConnection"):
			_billing.startConnection()
		return
	# Pages test build only. A store build never grants Remove Ads for free.
	if MobileIds.STORE_BUILD:
		return
	_grant()

func _on_billing_connected() -> void:
	_billing_ready = true
	if _billing.has_method("queryPurchases"):
		_billing.queryPurchases("inapp")
	if _want_purchase and _billing.has_method("purchase"):
		_want_purchase = false
		_billing.purchase(MobileIds.PRODUCT_REMOVE_ADS)

func _on_query(result: Dictionary) -> void:
	var rows = result.get("purchases", [])
	if rows is Array:
		_apply_rows(rows)

func _on_purchases(rows: Array) -> void:
	_apply_rows(rows)

func _apply_rows(rows: Array) -> void:
	for row in rows:
		if typeof(row) != TYPE_DICTIONARY:
			continue
		if str(row.get("productId", "")) != MobileIds.PRODUCT_REMOVE_ADS:
			continue
		# Purchase state 1 is purchased in Play Billing.
		if int(row.get("purchaseState", 1)) != 1:
			continue
		_grant()
		var token := str(row.get("purchaseToken", ""))
		var acked := bool(row.get("isAcknowledged", false))
		if token != "" and not acked and _billing != null and _billing.has_method("acknowledgePurchase"):
			_billing.acknowledgePurchase(token)
		return

func _grant() -> void:
	if no_ads and Save.no_ads:
		return
	no_ads = true
	Save.set_no_ads(true)
	no_ads_changed.emit(true)
