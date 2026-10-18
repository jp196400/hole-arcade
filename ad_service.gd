extends Node

const MobileIds = preload("res://mobile_ids.gd")

## Web builds show a placeholder card. There is no ad SDK in the Pages test build.
## Android and iOS call an AdMob plugin singleton when one is installed.
## Test unit ids live in mobile_ids.gd. No banner API. Do not show a banner during gameplay.
## no_ads turns off interstitials only. Rewarded ads stay available.
## A store build with no plugin does not show the fake card and does not grant a reward.
## SKIP_AFTER_SECONDS is the placeholder interstitial skip delay.
## A real AdMob interstitial's skip timing is controlled by the ad network, not this constant.

signal interstitial_closed
signal rewarded_done(granted: bool)

const SKIP_AFTER_SECONDS := 5.0
const REWARD_PLAY_SECONDS := 5.0

var _layer: CanvasLayer
var _mode := ""
var _left := 0.0
var _finished := false
var _skip: Button
var _status: Label
var _plugin: Object = null

func _ready() -> void:
	_plugin = _ad_plugin()
	if _plugin == null:
		_request_att()
		return
	var app_id := MobileIds.app_id()
	if _plugin.has_method("initialize"):
		_plugin.initialize(app_id)
	elif _plugin.has_method("init"):
		_plugin.init(app_id)
	_request_att()

func _ad_plugin() -> Object:
	for name in ["AdMob", "PoingGodotAdMob"]:
		if Engine.has_singleton(name):
			return Engine.get_singleton(name)
	return null

func _request_att() -> void:
	if not OS.has_feature("ios"):
		return
	for name in ["AppTrackingTransparency", "ATT", "AdMob", "PoingGodotAdMob"]:
		if not Engine.has_singleton(name):
			continue
		var plugin := Engine.get_singleton(name)
		if plugin.has_method("request_tracking_authorization"):
			plugin.request_tracking_authorization()
			return
		if plugin.has_method("requestTrackingAuthorization"):
			plugin.requestTrackingAuthorization()
			return

func show_interstitial() -> void:
	if IapService.no_ads:
		call_deferred("_emit_interstitial")
		return
	if _show_native("interstitial", MobileIds.interstitial_id()):
		return
	if MobileIds.STORE_BUILD:
		call_deferred("_emit_interstitial")
		return
	_open("interstitial")

func show_rewarded() -> void:
	if _show_native("rewarded", MobileIds.rewarded_id()):
		return
	if MobileIds.STORE_BUILD:
		call_deferred("_deny_reward")
		return
	_open("rewarded")

func _show_native(kind: String, unit_id: String) -> bool:
	if _plugin == null:
		return false
	var pairs := []
	if kind == "interstitial":
		pairs = [["load_interstitial", "show_interstitial"], ["loadInterstitial", "showInterstitial"]]
	else:
		pairs = [["load_rewarded", "show_rewarded"], ["loadRewarded", "showRewarded"], ["load_rewarded_ad", "show_rewarded_ad"]]
	for pair in pairs:
		if _plugin.has_method(pair[0]):
			_plugin.call(pair[0], unit_id)
		if _plugin.has_method(pair[1]):
			_plugin.call(pair[1])
			return true
	return false

func _deny_reward() -> void:
	rewarded_done.emit(false)

func _emit_interstitial() -> void:
	interstitial_closed.emit()

func _process(delta: float) -> void:
	if _finished or _layer == null or _left <= 0.0:
		return
	_left = maxf(_left - delta, 0.0)
	if _left <= 0.001:
		_left = 0.0
	if _mode == "interstitial":
		_tick_skip()
	elif _mode == "rewarded":
		_tick_reward()

func _open(mode: String) -> void:
	_close()
	_finished = false
	_mode = mode
	_skip = null
	_status = null
	_left = SKIP_AFTER_SECONDS if mode == "interstitial" else REWARD_PLAY_SECONDS
	_layer = CanvasLayer.new()
	_layer.layer = 60
	var dim := ColorRect.new()
	dim.color = Color(0.06, 0.08, 0.12, 0.82)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	_layer.add_child(dim)
	var card := Panel.new()
	card.anchor_left = 0.5
	card.anchor_right = 0.5
	card.anchor_top = 0.5
	card.anchor_bottom = 0.5
	card.offset_left = -330
	card.offset_right = 330
	card.offset_top = -360
	card.offset_bottom = 360
	card.add_theme_stylebox_override("panel", _card_style())
	_layer.add_child(card)
	var title := Label.new()
	title.text = "Advertisement" if mode == "interstitial" else "Rewarded ad"
	title.position = Vector2(28, 96)
	title.size = Vector2(604, 64)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 40)
	title.add_theme_color_override("font_color", Color(0.11, 0.16, 0.29))
	card.add_child(title)
	var body := Label.new()
	if mode == "interstitial":
		body.text = "Test ad. This build has no ad SDK.\nWith AdMob, the network controls when Skip appears."
	else:
		body.text = "Test ad. Watch to the end to earn the reward.\nClosing early forfeits it."
	body.position = Vector2(36, 180)
	body.size = Vector2(588, 120)
	body.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body.add_theme_font_size_override("font_size", 28)
	body.add_theme_color_override("font_color", Color(0.11, 0.16, 0.29))
	card.add_child(body)
	if mode == "interstitial":
		var btn := Button.new()
		btn.text = "Skip in %d" % int(ceili(_left))
		btn.disabled = true
		btn.position = Vector2(40, 520)
		btn.size = Vector2(580, 88)
		btn.add_theme_font_size_override("font_size", 32)
		btn.pressed.connect(_on_skip)
		card.add_child(btn)
		_skip = btn
	else:
		_status = Label.new()
		_status.text = "Playing… %d" % int(ceili(_left))
		_status.position = Vector2(36, 320)
		_status.size = Vector2(588, 48)
		_status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_status.add_theme_font_size_override("font_size", 32)
		_status.add_theme_color_override("font_color", Color(0.11, 0.16, 0.29))
		card.add_child(_status)
		var close_x := Button.new()
		close_x.text = "X"
		close_x.position = Vector2(560, 16)
		close_x.size = Vector2(72, 72)
		close_x.add_theme_font_size_override("font_size", 32)
		close_x.pressed.connect(_on_forfeit)
		card.add_child(close_x)
	add_child(_layer)

func _card_style() -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = Color(0.99, 0.97, 0.94, 0.98)
	s.corner_radius_top_left = 28
	s.corner_radius_top_right = 28
	s.corner_radius_bottom_right = 28
	s.corner_radius_bottom_left = 28
	s.content_margin_left = 16
	s.content_margin_right = 16
	s.content_margin_top = 16
	s.content_margin_bottom = 16
	return s

func _tick_skip() -> void:
	if _skip == null:
		return
	if _left <= 0.0:
		_skip.disabled = false
		_skip.text = "Skip"
	else:
		_skip.disabled = true
		_skip.text = "Skip in %d" % int(ceili(_left))

func _tick_reward() -> void:
	if _left <= 0.0:
		_grant_reward()
		return
	if _status:
		_status.text = "Playing… %d" % int(ceili(_left))

func _on_skip() -> void:
	if _finished or _mode != "interstitial" or _left > 0.0:
		return
	_finished = true
	_close()
	interstitial_closed.emit()

func _on_forfeit() -> void:
	if _finished or _mode != "rewarded":
		return
	_finished = true
	_close()
	rewarded_done.emit(false)

func _grant_reward() -> void:
	if _finished or _mode != "rewarded":
		return
	_finished = true
	_close()
	rewarded_done.emit(true)

func _close() -> void:
	if _layer != null and is_instance_valid(_layer):
		_layer.queue_free()
	_layer = null
	_skip = null
	_status = null
	_mode = ""
	_left = 0.0
