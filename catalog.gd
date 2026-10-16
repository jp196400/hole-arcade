extends RefCounted

static func maps() -> Array:
	return [
		_map("Downtown", 80, "grid", 11, "Grid streets", Color(0.36, 0.62, 0.90), Color(0.68, 0.82, 0.94), Color(0.34, 0.62, 0.32), Color(1.0, 0.97, 0.92), 28.0, 1.16, Color(1, 1, 1), [Color(0.76, 0.36, 0.36), Color(0.84, 0.70, 0.34), Color(0.36, 0.60, 0.64), Color(0.78, 0.48, 0.52), Color(0.40, 0.50, 0.72)]),
		_map("Suburbs", 130, "suburb", 27, "Yards and fences", Color(0.58, 0.78, 0.88), Color(0.74, 0.88, 0.72), Color(0.40, 0.68, 0.34), Color(1.0, 0.97, 0.90), 18.0, 1.12, Color(1.0, 1.0, 0.96), [Color(0.84, 0.76, 0.64), Color(0.55, 0.70, 0.76), Color(0.62, 0.74, 0.56), Color(0.86, 0.68, 0.56), Color(0.78, 0.76, 0.82)]),
		_map("Park", 180, "park", 63, "Paths and ponds", Color(0.42, 0.70, 0.86), Color(0.58, 0.84, 0.58), Color(0.24, 0.58, 0.26), Color(0.95, 0.98, 0.90), -12.0, 1.14, Color(0.96, 1.0, 0.94), [Color(0.55, 0.68, 0.48), Color(0.72, 0.62, 0.46)]),
		_map("Boardwalk", 240, "boardwalk", 41, "Sand and water", Color(0.42, 0.66, 0.88), Color(0.98, 0.74, 0.50), Color(0.84, 0.72, 0.46), Color(1.0, 0.94, 0.82), 48.0, 1.18, Color(1.0, 0.98, 0.92), [Color(0.86, 0.55, 0.42), Color(0.92, 0.78, 0.52), Color(0.45, 0.70, 0.74)]),
		_map("Farm", 300, "farm", 88, "Fields and barns", Color(0.64, 0.78, 0.90), Color(0.92, 0.84, 0.54), Color(0.55, 0.62, 0.26), Color(1.0, 0.96, 0.84), 70.0, 1.10, Color(1.0, 0.98, 0.90), [Color(0.70, 0.32, 0.28), Color(0.78, 0.68, 0.40), Color(0.55, 0.58, 0.36)]),
		_map("Harbor", 370, "harbor", 104, "Docks and crates", Color(0.34, 0.50, 0.64), Color(0.58, 0.70, 0.74), Color(0.30, 0.42, 0.48), Color(0.90, 0.94, 0.96), 8.0, 1.08, Color(0.90, 0.95, 0.98), [Color(0.38, 0.48, 0.58), Color(0.62, 0.40, 0.34), Color(0.42, 0.52, 0.48)]),
		_map("Campus", 450, "campus", 130, "Plaza and field", Color(0.36, 0.55, 0.84), Color(0.78, 0.82, 0.70), Color(0.36, 0.60, 0.34), Color(0.96, 0.96, 0.90), 40.0, 1.12, Color(0.98, 0.99, 0.96), [Color(0.62, 0.42, 0.36), Color(0.78, 0.74, 0.64), Color(0.36, 0.44, 0.62)]),
		_map("Fairground", 540, "fair", 156, "Rides and stalls", Color(0.40, 0.34, 0.68), Color(0.94, 0.50, 0.40), Color(0.42, 0.55, 0.34), Color(1.0, 0.86, 0.74), 55.0, 1.20, Color(1.0, 0.96, 0.92), [Color(0.78, 0.40, 0.48), Color(0.86, 0.62, 0.28), Color(0.48, 0.42, 0.70)]),
		_map("Industrial", 640, "industrial", 188, "Tanks and pipes", Color(0.58, 0.62, 0.60), Color(0.74, 0.70, 0.58), Color(0.42, 0.46, 0.38), Color(0.94, 0.94, 0.90), -28.0, 1.05, Color(0.92, 0.94, 0.90), [Color(0.55, 0.56, 0.54), Color(0.62, 0.48, 0.32), Color(0.48, 0.54, 0.40), Color(0.78, 0.66, 0.28)]),
		_map("Skyline", 760, "skyline", 214, "Dense towers", Color(0.12, 0.18, 0.38), Color(0.90, 0.50, 0.34), Color(0.20, 0.24, 0.34), Color(1.0, 0.90, 0.78), 24.0, 1.14, Color(1.0, 0.96, 0.92), [Color(0.45, 0.55, 0.68), Color(0.62, 0.50, 0.48), Color(0.40, 0.38, 0.55), Color(0.72, 0.62, 0.42)]),
	]

static func _map(map_name: String, target: int, layout: String, seed_n: int, blurb: String, sky_top: Color, horizon: Color, ground: Color, sun: Color, sun_yaw: float, sat: float, tint: Color, palette: Array) -> Dictionary:
	return {
		"name": map_name,
		"target": target,
		"layout": layout,
		"bias": layout,
		"seed": seed_n,
		"blurb": blurb,
		"sky_top": sky_top,
		"horizon": horizon,
		"ground": ground,
		"fog": horizon,
		"sun": sun,
		"sun_yaw": sun_yaw,
		"sat": sat,
		"tint": tint,
		"palette": palette,
	}

static func skins() -> Array:
	return [
		_skin("cyan", "Cyan", Color(0.05, 0.86, 1.0), Color(0.75, 0.98, 1.0), 0, 0.9, "free"),
		_skin("magenta", "Magenta", Color(1.0, 0.12, 0.55), Color(1.0, 0.7, 0.88), 0, 0.9, "rounds:3"),
		_skin("lime", "Lime", Color(0.45, 1.0, 0.15), Color(0.85, 1.0, 0.55), 0, 0.85, "coins:500"),
		_skin("gold", "Sun Gold", Color(1.0, 0.78, 0.12), Color(1.0, 0.96, 0.6), 0, 1.05, "stars:10"),
		_skin("orange", "Orange", Color(1.0, 0.4, 0.05), Color(1.0, 0.75, 0.35), 0, 0.9, "eat:450"),
		_skin("violet", "Violet", Color(0.58, 0.22, 1.0), Color(0.86, 0.7, 1.0), 0, 0.95, "level:3"),
		_skin("ice", "Ice", Color(0.72, 0.92, 1.0), Color(0.35, 0.65, 1.0), 0, 0.75, "rounds:14"),
		_skin("stripe", "Candy Stripe", Color(1.0, 0.18, 0.42), Color(1.0, 0.95, 0.35), 1, 0.95, "coins:1400"),
		_skin("ember", "Ember", Color(1.0, 0.22, 0.02), Color(1.0, 0.82, 0.15), 3, 1.4, "eat:1400"),
		_skin("ocean", "Ocean", Color(0.02, 0.4, 0.95), Color(0.15, 0.95, 0.85), 3, 1.0, "level:6"),
		_skin("rose", "Rose Gold", Color(0.93, 0.55, 0.5), Color(1.0, 0.9, 0.7), 4, 1.25, "stars:16"),
		_skin("toxic", "Toxic", Color(0.55, 1.0, 0.08), Color(0.08, 0.22, 0.05), 2, 1.1, "rounds:36"),
		_skin("royal", "Royal", Color(0.32, 0.08, 0.72), Color(1.0, 0.82, 0.28), 4, 1.3, "level:9"),
		_skin("checker", "Checker", Color(0.06, 0.06, 0.08), Color(0.95, 0.96, 1.0), 2, 0.6, "eat:2800"),
		_skin("prism", "Prism", Color(1.0, 0.2, 0.55), Color(0.25, 0.85, 1.0), 1, 1.45, "stars:28"),
	]

static func _skin(id: String, skin_name: String, a: Color, b: Color, pattern: int, glow: float, unlock: String) -> Dictionary:
	return {"id": id, "name": skin_name, "a": a, "b": b, "pattern": pattern, "glow": glow, "unlock": unlock}

static func skin_by_id(id: String) -> Dictionary:
	for s in skins():
		if str(s.id) == id:
			return s
	return skins()[0]
