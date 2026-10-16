extends Node

signal interstitial_closed
signal rewarded_done(granted: bool)

var _layer: CanvasLayer
var _mode := ""

func show_interstitial() -> void:
	if IapService.no_ads:
		call_deferred("_emit_interstitial")
		return
	_open("interstitial")

func show_rewarded() -> void:
	_open("rewarded")

func _emit_interstitial() -> void:
	interstitial_closed.emit()

func _open(mode: String) -> void:
	_close()
	_mode = mode
	_layer = CanvasLayer.new()
	_layer.layer = 60
	var dim := ColorRect.new()
	dim.color = Color(0.04, 0.05, 0.09, 0.94)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	_layer.add_child(dim)
	var title := Label.new()
	title.text = "Advertisement" if mode == "interstitial" else "Rewarded ad"
	title.position = Vector2(70, 380)
	title.size = Vector2(580, 60)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 40)
	title.add_theme_color_override("font_color", Color.WHITE)
	_layer.add_child(title)
	var body := Label.new()
	body.text = "Placeholder. This build has no ad SDK."
	body.position = Vector2(70, 470)
	body.size = Vector2(580, 80)
	body.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body.add_theme_font_size_override("font_size", 24)
	body.add_theme_color_override("font_color", Color(0.82, 0.86, 0.95))
	_layer.add_child(body)
	var btn := Button.new()
	btn.text = "Close" if mode == "interstitial" else "Claim reward"
	btn.position = Vector2(160, 620)
	btn.size = Vector2(400, 78)
	btn.add_theme_font_size_override("font_size", 28)
	btn.pressed.connect(_on_press)
	_layer.add_child(btn)
	if mode == "rewarded":
		var skip := Button.new()
		skip.text = "No thanks"
		skip.position = Vector2(160, 720)
		skip.size = Vector2(400, 64)
		skip.add_theme_font_size_override("font_size", 24)
		skip.pressed.connect(_on_skip)
		_layer.add_child(skip)
	add_child(_layer)

func _on_press() -> void:
	var mode := _mode
	_close()
	if mode == "interstitial":
		interstitial_closed.emit()
	else:
		rewarded_done.emit(true)

func _on_skip() -> void:
	_close()
	rewarded_done.emit(false)

func _close() -> void:
	if _layer != null and is_instance_valid(_layer):
		_layer.queue_free()
	_layer = null
	_mode = ""
