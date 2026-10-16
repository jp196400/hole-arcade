extends Node

const LIGHT_MS := 10
const HEAVY_MS := 28
const MIN_GAP_MS := 66

var _last_ms := -1000

func pulse(heavy: bool) -> void:
	if not Save.haptics_on:
		return
	var now := Time.get_ticks_msec()
	if now - _last_ms < MIN_GAP_MS:
		return
	_last_ms = now
	var ms := HEAVY_MS if heavy else LIGHT_MS
	if OS.has_feature("web"):
		JavaScriptBridge.eval("if(window.__holeHaptic)window.__holeHaptic(%d);" % ms, true)
		return
	_native_pulse(heavy, ms)

func _native_pulse(heavy: bool, ms: int) -> void:
	var os_name := OS.get_name()
	if os_name == "iOS":
		# UIImpactFeedbackGenerator light / medium. Godot 4.3 has no built-in
		# impact generator; a native export registers this singleton.
		if Engine.has_singleton("ImpactHaptics"):
			var plugin: Object = Engine.get_singleton("ImpactHaptics")
			plugin.impact("medium" if heavy else "light")
		return
	if os_name == "Android":
		Input.vibrate_handheld(ms)
