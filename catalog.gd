extends RefCounted

static func maps() -> Array:
	return [
		_map("Downtown", 80, "downtown", 3, 0, 11, 18, 12, 6, 22, 14, 14, Color(0.22, 0.48, 0.98), Color(1.0, 0.72, 0.48), Color(0.42, 0.62, 0.38), Color(0.72, 0.82, 1.0), Color(1.0, 0.78, 0.48), 32.0, 1.16),
		_map("Suburbs", 130, "suburb", 2, 1, 27, 12, 26, 3, 16, 10, 8, Color(0.42, 0.7, 1.0), Color(0.95, 0.9, 0.62), Color(0.45, 0.72, 0.34), Color(0.78, 0.9, 0.7), Color(1.0, 0.9, 0.62), 18.0, 1.12),
		_map("Crosswalk", 180, "traffic", 4, 2, 41, 14, 8, 5, 28, 12, 20, Color(0.2, 0.42, 0.95), Color(1.0, 0.62, 0.42), Color(0.38, 0.55, 0.4), Color(0.85, 0.78, 0.7), Color(1.0, 0.7, 0.42), 48.0, 1.2),
		_map("Park Rows", 240, "park", 2, 3, 63, 10, 30, 2, 18, 8, 8, Color(0.35, 0.62, 0.95), Color(0.75, 0.95, 0.7), Color(0.32, 0.62, 0.3), Color(0.7, 0.88, 0.72), Color(0.95, 0.95, 0.7), -12.0, 1.18),
		_map("Yards", 300, "industrial", 5, 4, 88, 26, 6, 16, 12, 18, 12, Color(0.35, 0.42, 0.55), Color(0.85, 0.7, 0.55), Color(0.4, 0.45, 0.38), Color(0.7, 0.72, 0.75), Color(1.0, 0.72, 0.45), 70.0, 1.05),
		_map("Lamp Mile", 370, "dusk", 3, 2, 104, 16, 14, 6, 20, 28, 12, Color(0.18, 0.22, 0.48), Color(1.0, 0.48, 0.32), Color(0.28, 0.32, 0.38), Color(0.95, 0.55, 0.4), Color(1.0, 0.55, 0.32), 8.0, 1.22),
		_map("High Rise", 450, "towers", 4, 1, 130, 12, 8, 6, 18, 16, 14, Color(0.15, 0.32, 0.72), Color(0.95, 0.78, 0.62), Color(0.3, 0.4, 0.45), Color(0.65, 0.75, 0.95), Color(1.0, 0.84, 0.62), 40.0, 1.14),
		_map("Market", 540, "market", 3, 5, 156, 28, 10, 8, 28, 14, 10, Color(0.25, 0.5, 0.9), Color(1.0, 0.66, 0.4), Color(0.5, 0.62, 0.32), Color(1.0, 0.8, 0.55), Color(1.0, 0.68, 0.35), 55.0, 1.28),
		_map("Festival", 640, "festival", 2, 4, 188, 22, 18, 4, 26, 16, 16, Color(0.32, 0.28, 0.85), Color(1.0, 0.45, 0.55), Color(0.35, 0.55, 0.4), Color(1.0, 0.55, 0.7), Color(1.0, 0.5, 0.62), -28.0, 1.35),
		_map("Skyline", 760, "skyline", 3, 6, 214, 14, 10, 8, 20, 18, 16, Color(0.08, 0.16, 0.38), Color(0.95, 0.55, 0.35), Color(0.15, 0.22, 0.28), Color(0.55, 0.45, 0.6), Color(1.0, 0.62, 0.38), 24.0, 1.18),
	]

static func _map(map_name: String, target: int, bias: String, plaza: int, shift: int, seed_n: int, small_n: int, trees_n: int, dumps_n: int, people_n: int, lamps_n: int, cars_n: int, sky_top: Color, horizon: Color, ground: Color, fog: Color, sun: Color, sun_yaw: float, sat: float) -> Dictionary:
	return {
		"name": map_name,
		"target": target,
		"bias": bias,
		"plaza": plaza,
		"shift": shift,
		"seed": seed_n,
		"small": small_n,
		"trees": trees_n,
		"dumpsters": dumps_n,
		"people": people_n,
		"lamps": lamps_n,
		"cars": cars_n,
		"sky_top": sky_top,
		"horizon": horizon,
		"ground": ground,
		"fog": fog,
		"sun": sun,
		"sun_yaw": sun_yaw,
		"sat": sat,
	}

static func skins() -> Array:
	return [
		_skin("cyan", "Cyan", Color(0.05, 0.86, 1.0), Color(0.75, 0.98, 1.0), 0, 0.9, "free"),
		_skin("magenta", "Magenta", Color(1.0, 0.12, 0.55), Color(1.0, 0.7, 0.88), 0, 0.9, "free"),
		_skin("lime", "Lime", Color(0.45, 1.0, 0.15), Color(0.85, 1.0, 0.55), 0, 0.85, "coins:30"),
		_skin("gold", "Sun Gold", Color(1.0, 0.78, 0.12), Color(1.0, 0.96, 0.6), 0, 1.05, "coins:50"),
		_skin("orange", "Orange", Color(1.0, 0.4, 0.05), Color(1.0, 0.75, 0.35), 0, 0.9, "coins:40"),
		_skin("violet", "Violet", Color(0.58, 0.22, 1.0), Color(0.86, 0.7, 1.0), 0, 0.95, "level:2"),
		_skin("ice", "Ice", Color(0.72, 0.92, 1.0), Color(0.35, 0.65, 1.0), 0, 0.75, "coins:70"),
		_skin("stripe", "Candy Stripe", Color(1.0, 0.18, 0.42), Color(1.0, 0.95, 0.35), 1, 0.95, "coins:90"),
		_skin("ember", "Ember", Color(1.0, 0.22, 0.02), Color(1.0, 0.82, 0.15), 3, 1.4, "coins:120"),
		_skin("ocean", "Ocean", Color(0.02, 0.4, 0.95), Color(0.15, 0.95, 0.85), 3, 1.0, "level:4"),
		_skin("rose", "Rose Gold", Color(0.93, 0.55, 0.5), Color(1.0, 0.9, 0.7), 4, 1.25, "coins:180"),
		_skin("toxic", "Toxic", Color(0.55, 1.0, 0.08), Color(0.08, 0.22, 0.05), 2, 1.1, "level:6"),
		_skin("royal", "Royal", Color(0.32, 0.08, 0.72), Color(1.0, 0.82, 0.28), 4, 1.3, "level:8"),
		_skin("checker", "Checker", Color(0.06, 0.06, 0.08), Color(0.95, 0.96, 1.0), 2, 0.6, "coins:150"),
		_skin("prism", "Prism", Color(1.0, 0.2, 0.55), Color(0.25, 0.85, 1.0), 1, 1.45, "level:10"),
	]

static func _skin(id: String, skin_name: String, a: Color, b: Color, pattern: int, glow: float, unlock: String) -> Dictionary:
	return {"id": id, "name": skin_name, "a": a, "b": b, "pattern": pattern, "glow": glow, "unlock": unlock}

static func skin_by_id(id: String) -> Dictionary:
	for s in skins():
		if str(s.id) == id:
			return s
	return skins()[0]
