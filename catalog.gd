extends RefCounted

static func maps() -> Array:
	return [
		_map("Downtown", 80, "downtown", 3, 0, 11, 18, 12, 6, 22, 14, 14, Color(0.45, 0.74, 1.0), Color(0.86, 0.94, 1.0), Color(0.56, 0.82, 0.48), Color(0.92, 0.96, 1.0), Color(1.0, 0.98, 0.94), 32.0, 1.06),
		_map("Suburbs", 130, "suburb", 2, 1, 27, 12, 26, 3, 16, 10, 8, Color(0.55, 0.82, 1.0), Color(0.9, 0.97, 0.82), Color(0.5, 0.84, 0.42), Color(0.92, 0.98, 0.88), Color(1.0, 0.98, 0.94), 18.0, 1.05),
		_map("Crosswalk", 180, "traffic", 4, 2, 41, 14, 8, 5, 28, 12, 20, Color(0.42, 0.7, 1.0), Color(0.95, 0.9, 0.78), Color(0.58, 0.78, 0.5), Color(0.95, 0.94, 0.9), Color(1.0, 0.98, 0.94), 48.0, 1.06),
		_map("Park Rows", 240, "park", 2, 3, 63, 10, 30, 2, 18, 8, 8, Color(0.5, 0.8, 1.0), Color(0.82, 0.96, 0.78), Color(0.42, 0.78, 0.38), Color(0.86, 0.96, 0.82), Color(1.0, 0.98, 0.94), -12.0, 1.06),
		_map("Yards", 300, "industrial", 5, 4, 88, 26, 6, 16, 12, 18, 12, Color(0.62, 0.78, 0.92), Color(0.9, 0.92, 0.94), Color(0.62, 0.7, 0.58), Color(0.9, 0.92, 0.94), Color(1.0, 0.98, 0.94), 70.0, 1.02),
		_map("Lamp Mile", 370, "dusk", 3, 2, 104, 16, 14, 6, 20, 28, 12, Color(0.55, 0.72, 1.0), Color(1.0, 0.86, 0.72), Color(0.55, 0.72, 0.48), Color(1.0, 0.9, 0.8), Color(1.0, 0.97, 0.9), 8.0, 1.08),
		_map("High Rise", 450, "towers", 4, 1, 130, 12, 8, 6, 18, 16, 14, Color(0.4, 0.68, 0.98), Color(0.82, 0.9, 1.0), Color(0.5, 0.68, 0.62), Color(0.86, 0.92, 1.0), Color(1.0, 0.98, 0.94), 40.0, 1.05),
		_map("Market", 540, "market", 3, 5, 156, 28, 10, 8, 28, 14, 10, Color(0.48, 0.74, 1.0), Color(1.0, 0.9, 0.72), Color(0.62, 0.78, 0.42), Color(1.0, 0.94, 0.8), Color(1.0, 0.98, 0.92), 55.0, 1.1),
		_map("Festival", 640, "festival", 2, 4, 188, 22, 18, 4, 26, 16, 16, Color(0.55, 0.7, 1.0), Color(1.0, 0.82, 0.88), Color(0.5, 0.78, 0.5), Color(1.0, 0.86, 0.92), Color(1.0, 0.97, 0.94), -28.0, 1.1),
		_map("Skyline", 760, "skyline", 3, 6, 214, 14, 10, 8, 20, 18, 16, Color(0.38, 0.62, 0.98), Color(0.78, 0.88, 1.0), Color(0.48, 0.66, 0.62), Color(0.82, 0.9, 1.0), Color(1.0, 0.98, 0.94), 24.0, 1.05),
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
		_skin("magenta", "Magenta", Color(1.0, 0.12, 0.55), Color(1.0, 0.7, 0.88), 0, 0.9, "eat:15"),
		_skin("lime", "Lime", Color(0.45, 1.0, 0.15), Color(0.85, 1.0, 0.55), 0, 0.85, "coins:30"),
		_skin("gold", "Sun Gold", Color(1.0, 0.78, 0.12), Color(1.0, 0.96, 0.6), 0, 1.05, "coins:50"),
		_skin("orange", "Orange", Color(1.0, 0.4, 0.05), Color(1.0, 0.75, 0.35), 0, 0.9, "size:3"),
		_skin("violet", "Violet", Color(0.58, 0.22, 1.0), Color(0.86, 0.7, 1.0), 0, 0.95, "level:2"),
		_skin("ice", "Ice", Color(0.72, 0.92, 1.0), Color(0.35, 0.65, 1.0), 0, 0.75, "eat:40"),
		_skin("stripe", "Candy Stripe", Color(1.0, 0.18, 0.42), Color(1.0, 0.95, 0.35), 1, 0.95, "coins:90"),
		_skin("ember", "Ember", Color(1.0, 0.22, 0.02), Color(1.0, 0.82, 0.15), 3, 1.4, "size:5"),
		_skin("ocean", "Ocean", Color(0.02, 0.4, 0.95), Color(0.15, 0.95, 0.85), 3, 1.0, "level:4"),
		_skin("rose", "Rose Gold", Color(0.93, 0.55, 0.5), Color(1.0, 0.9, 0.7), 4, 1.25, "coins:180"),
		_skin("toxic", "Toxic", Color(0.55, 1.0, 0.08), Color(0.08, 0.22, 0.05), 2, 1.1, "level:6"),
		_skin("royal", "Royal", Color(0.32, 0.08, 0.72), Color(1.0, 0.82, 0.28), 4, 1.3, "level:8"),
		_skin("checker", "Checker", Color(0.06, 0.06, 0.08), Color(0.95, 0.96, 1.0), 2, 0.6, "eat:100"),
		_skin("prism", "Prism", Color(1.0, 0.2, 0.55), Color(0.25, 0.85, 1.0), 1, 1.45, "level:10"),
	]

static func _skin(id: String, skin_name: String, a: Color, b: Color, pattern: int, glow: float, unlock: String) -> Dictionary:
	return {"id": id, "name": skin_name, "a": a, "b": b, "pattern": pattern, "glow": glow, "unlock": unlock}

static func skin_by_id(id: String) -> Dictionary:
	for s in skins():
		if str(s.id) == id:
			return s
	return skins()[0]
