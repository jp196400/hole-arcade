extends Node

const CatalogSafe = preload("res://catalog.gd")
const PATH := "user://hole_save.cfg"
# v1 was the unversioned [player] file. v2 adds [meta] saved_at so the web
# IndexedDB file and the localStorage mirror can be compared.
const SAVE_VERSION := 2
const SIZE_RADIUS := [0.50, 0.62, 0.74, 0.88, 1.02]
const SPEED_MUL := [1.0, 1.08, 1.16, 1.25, 1.34]
const EXTRA_TIME := [0.0, 15.0, 30.0, 45.0, 60.0]
const UPGRADE_COST := [450, 1080, 2100, 3600]
const DAILY_COINS := 100

var coins := 0
var size_rank := 0
var speed_rank := 0
var time_rank := 0
var skin_id := "cyan"
var unlocked_skins: Array = ["cyan"]
var best: Array = []
var unlocked_level := 0
var no_ads := false
var eaten := 0
var max_size := 1
var rounds := 0
var clears := 0
var clean_clears := 0
var sweeps := 0
var rival_eats := 0
var streak := 0
var tallies := {}
var maps_cleared: Array = []
var stars: Array = []
const TALLY_KEYS := ["cars", "trees", "buildings", "people", "props", "boats", "lamps", "animals"]
var music_on := true
var sfx_on := true
var play_time := 0.0
var first_ad_shown := false
var last_ad_play := 0.0
var next_interstitial_round := 2
var interstitial_gap_two := false
var trial_skin := ""
var last_daily := ""
var daily_doubled := false
var _play_save_wait := 0.0
var _disk_text := ""
var _rev := 0
var _flush_cb: JavaScriptObject

func _ready() -> void:
	best.resize(10)
	stars.resize(10)
	maps_cleared.resize(10)
	for i in best.size():
		best[i] = 0
		stars[i] = 0
		maps_cleared[i] = 0
	for k in TALLY_KEYS:
		tallies[k] = 0
	_install_web_hooks()
	load_game()
	grant_play_skins()

func _install_web_hooks() -> void:
	if not OS.has_feature("web"):
		return
	# Keep the callback on this node. Godot drops it if nothing references it.
	_flush_cb = JavaScriptBridge.create_callback(_on_page_hide)
	var window := JavaScriptBridge.get_interface("window")
	if window:
		window.__holeSetFlush(_flush_cb)

func _on_page_hide(_args: Array) -> void:
	save_game()

# [rev, saved_at]. Missing text is [-1, -1]. A legacy file with no [meta] is [0, 0].
# rev wins over the clock, so a later save is kept even if the device clock jumps back.
func _rank_of(text: String) -> Array:
	if text.strip_edges() == "":
		return [-1, -1]
	var cf := ConfigFile.new()
	if cf.parse(text) != OK:
		return [-1, -1]
	if not cf.has_section("player") and not cf.has_section("meta"):
		return [-1, -1]
	return [int(cf.get_value("meta", "rev", 0)), int(cf.get_value("meta", "saved_at", 0))]

func _beats(a: Array, b: Array) -> bool:
	if int(a[0]) != int(b[0]):
		return int(a[0]) > int(b[0])
	return int(a[1]) > int(b[1])

func _pick_text(file_text: String, mirror_text: String) -> String:
	var file_rank := _rank_of(file_text)
	var mirror_rank := _rank_of(mirror_text)
	# The mirror is written synchronously on every save. On a tie it is the
	# copy most likely to have survived a tab close before IndexedDB finished.
	if _beats(mirror_rank, file_rank):
		return mirror_text
	if _beats(file_rank, mirror_rank):
		return file_text
	if int(mirror_rank[0]) >= 0:
		return mirror_text
	if int(file_rank[0]) >= 0:
		return file_text
	return ""

func _read_user() -> String:
	if not FileAccess.file_exists(PATH):
		return ""
	return FileAccess.get_file_as_string(PATH)

func _write_user(text: String) -> void:
	var f := FileAccess.open(PATH, FileAccess.WRITE)
	if f == null:
		return
	f.store_string(text)
	f.close()

func _mirror_get() -> String:
	if not OS.has_feature("web"):
		return ""
	var raw = JavaScriptBridge.eval("(window.__holeLoadMirror?window.__holeLoadMirror():'')", true)
	if raw == null:
		return ""
	return str(raw)

func _mirror_put(text: String) -> void:
	if not OS.has_feature("web"):
		return
	var payload := JSON.stringify(text)
	JavaScriptBridge.eval("if(window.__holeSaveMirror)window.__holeSaveMirror(" + payload + ");", true)

func _sync_fs() -> void:
	if not OS.has_feature("web"):
		return
	JavaScriptBridge.eval("if(window.__holeSyncFS)window.__holeSyncFS();", true)

func load_game() -> void:
	var file_text := _read_user()
	var mirror_text := _mirror_get()
	var chosen := _pick_text(file_text, mirror_text)
	if chosen == "":
		return
	var cf := ConfigFile.new()
	if cf.parse(chosen) != OK:
		var other := file_text if chosen == mirror_text else mirror_text
		cf = ConfigFile.new()
		if other == "" or other == chosen or cf.parse(other) != OK:
			return
		chosen = other
	_disk_text = chosen
	_migrate(cf)
	_apply(cf)
	if not OS.has_feature("web"):
		return
	if chosen != file_text:
		_write_user(chosen)
		_sync_fs()
	if chosen != mirror_text:
		_mirror_put(chosen)

# Older files have no [meta]. Keep every player key. Missing "clears" is seeded
# in _apply from unlocked_level so an update does not lock maps the player had.
func _migrate(cf: ConfigFile) -> void:
	var v := int(cf.get_value("meta", "version", 0))
	if v < 1:
		pass
	if v < 2:
		pass
	if v > SAVE_VERSION:
		pass

func _apply(cf: ConfigFile) -> void:
	_rev = maxi(0, int(cf.get_value("meta", "rev", 0)))
	coins = int(cf.get_value("player", "coins", 0))
	size_rank = clampi(int(cf.get_value("player", "size_rank", 0)), 0, 4)
	speed_rank = clampi(int(cf.get_value("player", "speed_rank", 0)), 0, 4)
	time_rank = clampi(int(cf.get_value("player", "time_rank", 0)), 0, 4)
	skin_id = str(cf.get_value("player", "skin", "cyan"))
	no_ads = bool(cf.get_value("player", "no_ads", false))
	unlocked_level = clampi(int(cf.get_value("player", "unlocked_level", 0)), 0, 10)
	eaten = maxi(0, int(cf.get_value("player", "eaten", 0)))
	max_size = clampi(int(cf.get_value("player", "max_size", 1)), 1, 6)
	rounds = maxi(0, int(cf.get_value("player", "rounds", 0)))
	if cf.has_section_key("player", "clears"):
		clears = maxi(0, int(cf.get_value("player", "clears", 0)))
	else:
		clears = unlocked_level * 3
	clean_clears = maxi(0, int(cf.get_value("player", "clean", 0)))
	sweeps = maxi(0, int(cf.get_value("player", "sweeps", 0)))
	rival_eats = maxi(0, int(cf.get_value("player", "rival_eats", 0)))
	streak = maxi(0, int(cf.get_value("player", "streak", 0)))
	var tally_csv := str(cf.get_value("player", "tallies", ""))
	if tally_csv != "":
		for part in tally_csv.split(",", false):
			var bits := part.split(":", false)
			if bits.size() == 2 and tallies.has(str(bits[0])):
				tallies[str(bits[0])] = maxi(0, int(bits[1]))
	var map_csv := str(cf.get_value("player", "maps", ""))
	if map_csv != "":
		var mp := map_csv.split(",", false)
		for i in mini(mp.size(), maps_cleared.size()):
			maps_cleared[i] = 1 if int(mp[i]) > 0 else 0
	music_on = bool(cf.get_value("player", "music_on", true))
	sfx_on = bool(cf.get_value("player", "sfx_on", true))
	play_time = maxf(0.0, float(cf.get_value("player", "play_time", 0.0)))
	first_ad_shown = bool(cf.get_value("player", "first_ad_shown", false))
	last_ad_play = maxf(0.0, float(cf.get_value("player", "last_ad_play", 0.0)))
	next_interstitial_round = maxi(2, int(cf.get_value("player", "next_interstitial_round", 2)))
	interstitial_gap_two = bool(cf.get_value("player", "interstitial_gap_two", false))
	trial_skin = str(cf.get_value("player", "trial_skin", ""))
	last_daily = str(cf.get_value("player", "last_daily", ""))
	daily_doubled = bool(cf.get_value("player", "daily_doubled", false))
	var skin_csv := str(cf.get_value("player", "skins", "cyan"))
	unlocked_skins = skin_csv.split(",", false)
	if unlocked_skins.is_empty() or not unlocked_skins.has("cyan"):
		unlocked_skins.append("cyan")
	var best_csv := str(cf.get_value("player", "best", ""))
	if best_csv != "":
		var parts := best_csv.split(",", false)
		for i in mini(parts.size(), best.size()):
			best[i] = int(parts[i])
	var star_csv := str(cf.get_value("player", "stars", ""))
	if star_csv != "":
		var sparts := star_csv.split(",", false)
		for i in mini(sparts.size(), stars.size()):
			stars[i] = clampi(int(sparts[i]), 0, 3)

func save_game() -> void:
	var cf := ConfigFile.new()
	if _disk_text != "" and cf.parse(_disk_text) != OK:
		cf = ConfigFile.new()
	var version := int(cf.get_value("meta", "version", 0))
	if version < SAVE_VERSION:
		version = SAVE_VERSION
	_rev += 1
	cf.set_value("meta", "version", version)
	cf.set_value("meta", "rev", _rev)
	cf.set_value("meta", "saved_at", int(Time.get_unix_time_from_system() * 1000.0))
	cf.set_value("player", "coins", coins)
	cf.set_value("player", "size_rank", size_rank)
	cf.set_value("player", "speed_rank", speed_rank)
	cf.set_value("player", "time_rank", time_rank)
	cf.set_value("player", "skin", skin_id)
	cf.set_value("player", "no_ads", no_ads)
	cf.set_value("player", "unlocked_level", unlocked_level)
	cf.set_value("player", "eaten", eaten)
	cf.set_value("player", "max_size", max_size)
	cf.set_value("player", "rounds", rounds)
	cf.set_value("player", "clears", clears)
	cf.set_value("player", "clean", clean_clears)
	cf.set_value("player", "sweeps", sweeps)
	cf.set_value("player", "rival_eats", rival_eats)
	cf.set_value("player", "streak", streak)
	var tally_bits: PackedStringArray = []
	for k in TALLY_KEYS:
		tally_bits.append("%s:%d" % [str(k), int(tallies.get(k, 0))])
	cf.set_value("player", "tallies", ",".join(tally_bits))
	var map_bits: PackedStringArray = []
	for i in maps_cleared.size():
		map_bits.append(str(int(maps_cleared[i])))
	cf.set_value("player", "maps", ",".join(map_bits))
	cf.set_value("player", "music_on", music_on)
	cf.set_value("player", "sfx_on", sfx_on)
	cf.set_value("player", "play_time", play_time)
	cf.set_value("player", "first_ad_shown", first_ad_shown)
	cf.set_value("player", "last_ad_play", last_ad_play)
	cf.set_value("player", "next_interstitial_round", next_interstitial_round)
	cf.set_value("player", "interstitial_gap_two", interstitial_gap_two)
	cf.set_value("player", "trial_skin", trial_skin)
	cf.set_value("player", "last_daily", last_daily)
	cf.set_value("player", "daily_doubled", daily_doubled)
	var star_bits: PackedStringArray = []
	for i in stars.size():
		star_bits.append(str(int(stars[i])))
	cf.set_value("player", "stars", ",".join(star_bits))
	cf.set_value("player", "skins", ",".join(unlocked_skins))
	var bits: PackedStringArray = []
	for i in best.size():
		bits.append(str(int(best[i])))
	cf.set_value("player", "best", ",".join(bits))
	var text := cf.encode_to_text()
	_write_user(text)
	_disk_text = text
	_mirror_put(text)
	_sync_fs()

func wipe() -> void:
	coins = 0
	size_rank = 0
	speed_rank = 0
	time_rank = 0
	skin_id = "cyan"
	unlocked_skins = ["cyan"]
	unlocked_level = 0
	no_ads = false
	eaten = 0
	max_size = 1
	rounds = 0
	clears = 0
	clean_clears = 0
	sweeps = 0
	rival_eats = 0
	streak = 0
	for k in TALLY_KEYS:
		tallies[k] = 0
	for i in maps_cleared.size():
		maps_cleared[i] = 0
	music_on = true
	sfx_on = true
	play_time = 0.0
	first_ad_shown = false
	last_ad_play = 0.0
	next_interstitial_round = 2
	interstitial_gap_two = false
	trial_skin = ""
	last_daily = ""
	daily_doubled = false
	for i in best.size():
		best[i] = 0
		stars[i] = 0
	save_game()

func add_play_time(dt: float) -> void:
	if dt <= 0.0:
		return
	play_time += dt

func note_ad(at: float) -> void:
	last_ad_play = at
	save_game()

func mark_interstitial(at: float) -> void:
	first_ad_shown = true
	last_ad_play = at
	save_game()

func advance_interstitial_schedule() -> void:
	var gap := 2 if interstitial_gap_two else 3
	interstitial_gap_two = not interstitial_gap_two
	next_interstitial_round = rounds + gap
	save_game()

func today_key() -> String:
	var d := Time.get_date_dict_from_system()
	return "%04d-%02d-%02d" % [int(d.year), int(d.month), int(d.day)]

func daily_claimed() -> bool:
	return last_daily == today_key()

func claim_daily() -> int:
	if daily_claimed():
		return 0
	last_daily = today_key()
	daily_doubled = false
	coins += DAILY_COINS
	save_game()
	return DAILY_COINS

func grant_daily_double() -> bool:
	if not daily_claimed() or daily_doubled:
		return false
	daily_doubled = true
	coins += DAILY_COINS
	save_game()
	return true

func set_trial(id: String) -> void:
	trial_skin = id
	save_game()

func clear_trial() -> void:
	if trial_skin == "":
		return
	trial_skin = ""
	save_game()

func set_music(on: bool) -> void:
	music_on = on
	save_game()

func set_sfx(on: bool) -> void:
	sfx_on = on
	save_game()

func start_radius() -> float:
	return float(SIZE_RADIUS[size_rank])

func speed_mul() -> float:
	return float(SPEED_MUL[speed_rank])

func extra_time() -> float:
	return float(EXTRA_TIME[time_rank])

func next_cost(rank: int) -> int:
	if rank < 0 or rank >= UPGRADE_COST.size():
		return -1
	return int(UPGRADE_COST[rank])

func add_coins(n: int) -> void:
	coins += n
	save_game()

func has_skin(id: String) -> bool:
	return unlocked_skins.has(id)

func grant_skin(id: String) -> void:
	if not has_skin(id):
		unlocked_skins.append(id)
		save_game()

func total_stars() -> int:
	var n := 0
	for s in stars:
		n += int(s)
	return n

func _maps_done() -> int:
	var n := 0
	for v in maps_cleared:
		if int(v) > 0:
			n += 1
	return n

func _stars3() -> int:
	var n := 0
	for s in stars:
		if int(s) >= 3:
			n += 1
	return n

func progress_for(unlock: String) -> Dictionary:
	var key := ""
	var need := 1
	var cut := unlock.find(":")
	if cut >= 0:
		key = unlock.substr(0, cut)
		need = int(unlock.substr(cut + 1))
	need = maxi(need, 1)
	var cur := 0
	var label := "Challenge"
	match key:
		"cars", "trees", "buildings", "people", "props", "boats", "lamps", "animals":
			cur = int(tallies.get(key, 0))
		"rivals":
			cur = rival_eats
		"clean":
			cur = clean_clears
		"streak":
			cur = streak
		"sweeps":
			cur = sweeps
		"maps":
			cur = _maps_done()
		"stars3":
			cur = _stars3()
		_:
			key = ""
	match key:
		"cars":
			label = "Cars eaten"
		"trees":
			label = "Trees eaten"
		"buildings":
			label = "Buildings eaten"
		"people":
			label = "People eaten"
		"props":
			label = "Props eaten"
		"boats":
			label = "Boats eaten"
		"lamps":
			label = "Lamps eaten"
		"animals":
			label = "Animals eaten"
		"rivals":
			label = "Rival holes eaten"
		"clean":
			label = "Clear without being eaten"
		"streak":
			label = "Clears in a row"
		"sweeps":
			label = "Full rival sweeps"
		"maps":
			label = "Levels fully cleared"
		"stars3":
			label = "3-star levels"
		_:
			label = "Challenge"
	return {
		"cur": cur,
		"need": need,
		"unit": key,
		"label": label,
		"ratio": clampf(float(cur) / float(need), 0.0, 1.0),
	}

func next_skin() -> Dictionary:
	var best_ratio := -1.0
	var picked: Dictionary = {}
	var prog: Dictionary = {}
	for s in CatalogSafe.skins():
		if has_skin(str(s.id)):
			continue
		var p := progress_for(str(s.unlock))
		if float(p.ratio) > best_ratio:
			best_ratio = float(p.ratio)
			picked = s
			prog = p
	if picked.is_empty():
		return {}
	return {"skin": picked, "progress": prog}

func next_purchase() -> Dictionary:
	var need := -1
	var label := ""
	for s in CatalogSafe.skins():
		var unlock := str(s.unlock)
		if has_skin(str(s.id)) or not unlock.begins_with("coins:"):
			continue
		var cost := int(unlock.substr(6))
		if need < 0 or cost < need:
			need = cost
			label = str(s.name)
	var upgrade := next_cost(mini(size_rank, mini(speed_rank, time_rank)))
	if upgrade > 0 and (need < 0 or upgrade < need):
		need = upgrade
		label = "Upgrade"
	if need < 0:
		return {}
	return {
		"label": label,
		"cur": coins,
		"need": need,
		"ratio": clampf(float(coins) / float(need), 0.0, 1.0),
	}

func _skin_earned(unlock: String) -> bool:
	if unlock == "free":
		return true
	if unlock.begins_with("coins:"):
		return false
	var p := progress_for(unlock)
	if str(p.unit) == "":
		return false
	return int(p.cur) >= int(p.need)

func grant_play_skins() -> Array:
	var fresh: Array = []
	for s in CatalogSafe.skins():
		var id := str(s.id)
		if has_skin(id):
			continue
		if _skin_earned(str(s.unlock)):
			unlocked_skins.append(id)
			fresh.append(s)
	if not has_skin(skin_id):
		skin_id = "cyan"
	if not fresh.is_empty():
		save_game()
	return fresh

func note_swallow(bucket: String) -> Array:
	eaten += 1
	if tallies.has(bucket):
		tallies[bucket] = int(tallies[bucket]) + 1
	var fresh := grant_play_skins()
	save_game()
	return fresh

func note_eaten(n: int) -> Array:
	eaten += n
	var fresh := grant_play_skins()
	save_game()
	return fresh

func note_size(size_n: int) -> Array:
	if size_n <= max_size:
		return []
	max_size = size_n
	var fresh := grant_play_skins()
	save_game()
	return fresh

func note_round() -> Array:
	rounds += 1
	var fresh := grant_play_skins()
	save_game()
	return fresh

func note_stars(index: int, count: int) -> Array:
	if index < 0 or index >= stars.size():
		return []
	var n := clampi(count, 0, 3)
	if n <= int(stars[index]):
		return []
	stars[index] = n
	_refresh_unlocks()
	var fresh := grant_play_skins()
	save_game()
	return fresh

func note_rival_eat() -> Array:
	rival_eats += 1
	var fresh := grant_play_skins()
	save_game()
	return fresh

func note_fail() -> void:
	if streak == 0:
		return
	streak = 0
	save_game()

func note_clear(index: int, clean: bool, sweep: bool) -> Array:
	clears += 1
	streak += 1
	if clean:
		clean_clears += 1
	if sweep:
		sweeps += 1
	if index >= 0 and index < maps_cleared.size():
		maps_cleared[index] = 1
	_refresh_unlocks()
	var fresh := grant_play_skins()
	save_game()
	return fresh

func _refresh_unlocks() -> void:
	var earned := unlocked_level
	var i := unlocked_level + 1
	while i <= 10:
		var prev := i - 1
		var prev_stars := int(stars[prev]) if prev >= 0 and prev < stars.size() else 0
		if prev_stars >= 3 and clears >= i * 3:
			earned = i
			i += 1
		else:
			break
	unlocked_level = mini(earned, 10)

func unlock_all() -> void:
	unlocked_level = 10
	eaten = maxi(eaten, 20000)
	max_size = maxi(max_size, 6)
	rounds = maxi(rounds, 40)
	clears = maxi(clears, 40)
	clean_clears = maxi(clean_clears, 20)
	sweeps = maxi(sweeps, 20)
	rival_eats = maxi(rival_eats, 80)
	streak = maxi(streak, 10)
	for k in TALLY_KEYS:
		tallies[k] = maxi(int(tallies.get(k, 0)), 5000)
	for i in maps_cleared.size():
		maps_cleared[i] = 1
	for i in stars.size():
		stars[i] = 3
	for s in CatalogSafe.skins():
		var id := str(s.id)
		if not has_skin(id):
			unlocked_skins.append(id)
	save_game()

func mark_cleared(index: int, score: int) -> Array:
	if index >= 0 and index < best.size() and score > int(best[index]):
		best[index] = score
	var fresh := grant_play_skins()
	save_game()
	return fresh

func try_buy_upgrade(which: String) -> bool:
	var rank := size_rank
	if which == "speed":
		rank = speed_rank
	elif which == "time":
		rank = time_rank
	var cost := next_cost(rank)
	if cost < 0 or coins < cost:
		return false
	coins -= cost
	if which == "size":
		size_rank += 1
	elif which == "speed":
		speed_rank += 1
	else:
		time_rank += 1
	save_game()
	return true

func try_buy_skin(skin: Dictionary) -> bool:
	var id := str(skin.id)
	if has_skin(id):
		return false
	var unlock := str(skin.unlock)
	if not unlock.begins_with("coins:"):
		return false
	var cost := int(unlock.substr(6))
	if coins < cost:
		return false
	coins -= cost
	unlocked_skins.append(id)
	save_game()
	return true

func equip(id: String) -> void:
	if has_skin(id):
		skin_id = id
		save_game()

func set_no_ads(on: bool) -> void:
	no_ads = on
	save_game()
