extends Node

const CatalogSafe = preload("res://catalog.gd")
const PATH := "user://hole_save.cfg"
const SIZE_RADIUS := [0.50, 0.62, 0.74, 0.88, 1.02]
const SPEED_MUL := [1.0, 1.08, 1.16, 1.25, 1.34]
const EXTRA_TIME := [0.0, 15.0, 30.0, 45.0, 60.0]
const UPGRADE_COST := [150, 360, 700, 1200]

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
var stars: Array = []

func _ready() -> void:
	best.resize(10)
	stars.resize(10)
	for i in best.size():
		best[i] = 0
		stars[i] = 0
	load_game()
	grant_play_skins()

func load_game() -> void:
	var cf := ConfigFile.new()
	if cf.load(PATH) != OK:
		return
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
	var star_bits: PackedStringArray = []
	for i in stars.size():
		star_bits.append(str(int(stars[i])))
	cf.set_value("player", "stars", ",".join(star_bits))
	cf.set_value("player", "skins", ",".join(unlocked_skins))
	var bits: PackedStringArray = []
	for i in best.size():
		bits.append(str(int(best[i])))
	cf.set_value("player", "best", ",".join(bits))
	cf.save(PATH)

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
	for i in best.size():
		best[i] = 0
		stars[i] = 0
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

func progress_for(unlock: String) -> Dictionary:
	var cur := 0
	var need := 1
	var unit := ""
	if unlock.begins_with("rounds:"):
		need = int(unlock.substr(7))
		cur = rounds
		unit = "rounds"
	elif unlock.begins_with("eat:"):
		need = int(unlock.substr(4))
		cur = eaten
		unit = "eaten"
	elif unlock.begins_with("level:"):
		need = int(unlock.substr(6))
		cur = unlocked_level
		unit = "levels"
	elif unlock.begins_with("stars:"):
		need = int(unlock.substr(6))
		cur = total_stars()
		unit = "stars"
	elif unlock.begins_with("coins:"):
		need = int(unlock.substr(6))
		cur = coins
		unit = "coins"
	elif unlock.begins_with("size:"):
		need = int(unlock.substr(5))
		cur = max_size
		unit = "size"
	need = maxi(need, 1)
	return {
		"cur": cur,
		"need": need,
		"unit": unit,
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
	var fresh := grant_play_skins()
	save_game()
	return fresh

func unlock_all() -> void:
	unlocked_level = 10
	eaten = maxi(eaten, 3000)
	max_size = maxi(max_size, 6)
	rounds = maxi(rounds, 40)
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
	if index + 1 > unlocked_level:
		unlocked_level = mini(index + 1, 10)
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
