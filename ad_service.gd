extends Node

## Placeholder ads only. There is no ad SDK and no ad account in this build.
## Swap point for a later AdMob build: replace show_interstitial and show_rewarded.
## No banner API. Do not show a banner during gameplay.
## no_ads turns off interstitials only. Rewarded ads stay available.
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

func show_interstitial() -> void:
	if IapService.no_ads:
		call_deferred("_emit_interstitial")
		return
	_open("interstitial")

func show_rewarded() -> void:
	_open("rewarded")

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
	dim.color = Color(0.04, 0.05, 0.09, 0.94)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	_layer.add_child(dim)
	var title := Label.new()
	title.text = "Advertisement" if mode == "interstitial" else "Rewarded ad"
	title.position = Vector2(70, 340)
	title.size = Vector2(580, 60)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 56)
	title.add_theme_color_override("font_color", Color.WHITE)
	_layer.add_child(title)
	var body := Label.new()
	if mode == "interstitial":
		body.text = "Placeholder. This build has no ad SDK.\nWith AdMob, the network controls when Skip appears."
	else:
		body.text = "Placeholder. Watch to the end to earn the reward.\nClosing early forfeits it."
	body.position = Vector2(70, 430)
	body.size = Vector2(580, 120)
	body.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body.add_theme_font_size_override("font_size", 36)
	body.add_theme_color_override("font_color", Color(0.82, 0.86, 0.95))
	_layer.add_child(body)
	if mode == "interstitial":
		var btn := Button.new()
		btn.text = "Skip in %d" % int(ceili(_left))
		btn.disabled = true
		btn.position = Vector2(80, 640)
		btn.size = Vector2(560, 96)
		btn.add_theme_font_size_override("font_size", 40)
		btn.pressed.connect(_on_skip)
		_layer.add_child(btn)
		_skip = btn
	else:
		_status = Label.new()
		_status.text = "Playing… %d" % int(ceili(_left))
		_status.position = Vector2(70, 580)
		_status.size = Vector2(580, 50)
		_status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_status.add_theme_font_size_override("font_size", 40)
		_status.add_theme_color_override("font_color", Color.WHITE)
		_layer.add_child(_status)
		var close_x := Button.new()
		close_x.text = "X"
		close_x.position = Vector2(600, 48)
		close_x.size = Vector2(88, 88)
		close_x.add_theme_font_size_override("font_size", 44)
		close_x.pressed.connect(_on_forfeit)
		_layer.add_child(close_x)
	add_child(_layer)

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
