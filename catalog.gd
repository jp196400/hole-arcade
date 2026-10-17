extends RefCounted

static func maps() -> Array:
	return [
		_map("Farm Valley", 80, "farm", 11, "Lanes, ponds, and wheat", Color(0.46, 0.74, 0.95), Color(0.78, 0.90, 0.62), Color(0.40, 0.62, 0.26), Color(1.0, 0.96, 0.84), 36.0, 1.08, 1.00, 0.0035, _paints(Color(0.55, 0.40, 0.22), Color(0.24, 0.58, 0.20), Color(0.78, 0.68, 0.34), Color(0.46, 0.32, 0.16), Color(0.22, 0.52, 0.66), Color(0.62, 0.58, 0.48), Color(0.58, 0.40, 0.22), Color(0.74, 0.70, 0.18), Color(0.66, 0.42, 0.28), Color(0.50, 0.36, 0.20))),
		_map("Candy Town", 130, "candy", 27, "Spiral streets of sweets", Color(0.62, 0.42, 0.92), Color(1.0, 0.70, 0.82), Color(0.95, 0.55, 0.72), Color(1.0, 0.92, 0.96), 18.0, 1.16, 1.08, 0.0032, _paints(Color(0.95, 0.45, 0.62), Color(0.55, 0.90, 0.74), Color(0.98, 0.86, 0.42), Color(0.52, 0.28, 0.20), Color(0.38, 0.58, 0.96), Color(0.98, 0.90, 0.96), Color(0.86, 0.62, 0.40), Color(0.96, 0.55, 0.74), Color(0.95, 0.32, 0.52), Color(0.92, 0.70, 0.78))),
		_map("Dino Jungle", 180, "jungle", 63, "A river through the ferns", Color(0.16, 0.40, 0.36), Color(0.52, 0.74, 0.40), Color(0.12, 0.36, 0.18), Color(0.85, 0.92, 0.70), -24.0, 1.05, 0.92, 0.0060, _paints(Color(0.28, 0.22, 0.12), Color(0.10, 0.40, 0.16), Color(0.36, 0.42, 0.18), Color(0.32, 0.22, 0.12), Color(0.08, 0.38, 0.42), Color(0.34, 0.40, 0.28), Color(0.36, 0.26, 0.14), Color(0.10, 0.28, 0.12), Color(0.24, 0.32, 0.16), Color(0.20, 0.28, 0.14))),
		_map("Pirate Harbor", 240, "pirate", 41, "Curved coast and wooden piers", Color(0.22, 0.38, 0.62), Color(0.96, 0.55, 0.32), Color(0.16, 0.42, 0.28), Color(1.0, 0.86, 0.70), 52.0, 1.10, 0.96, 0.0040, _paints(Color(0.45, 0.36, 0.24), Color(0.20, 0.52, 0.26), Color(0.90, 0.76, 0.46), Color(0.48, 0.34, 0.20), Color(0.06, 0.24, 0.44), Color(0.55, 0.54, 0.50), Color(0.50, 0.32, 0.16), Color(0.34, 0.48, 0.26), Color(0.62, 0.40, 0.24), Color(0.42, 0.28, 0.16))),
		_map("Snowy Village", 300, "snow", 88, "A winding path and a frozen pond", Color(0.55, 0.70, 0.90), Color(0.86, 0.92, 0.96), Color(0.78, 0.86, 0.92), Color(0.92, 0.96, 1.0), -8.0, 0.96, 0.88, 0.0048, _paints(Color(0.70, 0.78, 0.86), Color(0.70, 0.82, 0.88), Color(0.92, 0.95, 0.98), Color(0.74, 0.82, 0.90), Color(0.62, 0.84, 0.94), Color(0.72, 0.76, 0.84), Color(0.55, 0.40, 0.30), Color(0.80, 0.88, 0.92), Color(0.68, 0.74, 0.82), Color(0.60, 0.68, 0.76))),
		_map("Desert Oasis", 370, "desert", 104, "Dunes around a green pool", Color(0.52, 0.74, 0.95), Color(0.98, 0.74, 0.42), Color(0.86, 0.64, 0.32), Color(1.0, 0.92, 0.74), 70.0, 1.12, 1.04, 0.0030, _paints(Color(0.72, 0.52, 0.30), Color(0.18, 0.55, 0.26), Color(0.88, 0.70, 0.36), Color(0.62, 0.42, 0.22), Color(0.12, 0.55, 0.62), Color(0.78, 0.62, 0.40), Color(0.62, 0.44, 0.26), Color(0.70, 0.58, 0.28), Color(0.74, 0.48, 0.28), Color(0.58, 0.40, 0.24))),
		_map("Toy Room", 450, "toy", 130, "A rug on giant building blocks", Color(0.70, 0.58, 0.90), Color(0.98, 0.88, 0.74), Color(0.55, 0.36, 0.22), Color(1.0, 0.96, 0.90), 12.0, 1.14, 1.12, 0.0028, _paints(Color(0.85, 0.28, 0.26), Color(0.22, 0.62, 0.36), Color(0.95, 0.78, 0.28), Color(0.30, 0.48, 0.82), Color(0.35, 0.62, 0.90), Color(0.28, 0.48, 0.86), Color(0.62, 0.42, 0.24), Color(0.92, 0.76, 0.18), Color(0.82, 0.22, 0.24), Color(0.55, 0.36, 0.22))),
		_map("Space Colony", 540, "space", 156, "Crater pads on the moon", Color(0.03, 0.05, 0.12), Color(0.16, 0.20, 0.32), Color(0.34, 0.36, 0.40), Color(0.82, 0.88, 0.98), -40.0, 0.92, 0.90, 0.0022, _paints(Color(0.40, 0.44, 0.50), Color(0.16, 0.24, 0.30), Color(0.46, 0.48, 0.52), Color(0.28, 0.30, 0.36), Color(0.16, 0.55, 0.86), Color(0.72, 0.76, 0.80), Color(0.42, 0.46, 0.52), Color(0.22, 0.28, 0.36), Color(0.55, 0.60, 0.68), Color(0.36, 0.40, 0.48))),
		_map("Haunted Hollow", 640, "haunt", 188, "A crooked path and a swamp", Color(0.16, 0.10, 0.30), Color(0.55, 0.26, 0.34), Color(0.18, 0.22, 0.16), Color(0.85, 0.70, 0.62), 8.0, 0.90, 0.86, 0.0055, _paints(Color(0.32, 0.26, 0.28), Color(0.22, 0.28, 0.16), Color(0.40, 0.36, 0.30), Color(0.28, 0.22, 0.20), Color(0.10, 0.20, 0.16), Color(0.40, 0.40, 0.44), Color(0.32, 0.24, 0.22), Color(0.28, 0.16, 0.32), Color(0.36, 0.28, 0.32), Color(0.26, 0.22, 0.28))),
		_map("Theme Park", 760, "fair", 214, "A midway loop and a coaster", Color(0.26, 0.20, 0.55), Color(0.96, 0.46, 0.36), Color(0.24, 0.58, 0.30), Color(1.0, 0.90, 0.74), 58.0, 1.14, 1.06, 0.0036, _paints(Color(0.70, 0.36, 0.24), Color(0.22, 0.64, 0.28), Color(0.90, 0.74, 0.40), Color(0.72, 0.46, 0.30), Color(0.14, 0.46, 0.72), Color(0.78, 0.76, 0.82), Color(0.62, 0.40, 0.24), Color(0.40, 0.70, 0.32), Color(0.78, 0.20, 0.26), Color(0.55, 0.32, 0.22))),
	]

static func _band(c: Color) -> Array:
	return [c, c.lightened(0.24)]

static func _paints(road: Color, grass: Color, sand: Color, dirt: Color, water: Color, stone: Color, wood: Color, field: Color, brick: Color, dock: Color) -> Array:
	return [_band(road), _band(grass), _band(sand), _band(dirt), _band(water), _band(stone), _band(wood), _band(field), _band(brick), _band(dock)]

static func _map(map_name: String, target: int, layout: String, seed_n: int, blurb: String, sky_top: Color, horizon: Color, ground: Color, sun: Color, sun_yaw: float, sat: float, rate: float, fog_density: float, paints: Array) -> Dictionary:
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
		"tint": Color.WHITE,
		"palette": [],
		"paints": paints,
		"rate": rate,
		"fog_density": fog_density,
	}

static func skins() -> Array:
	return [
		_skin("cyan", "Cyan", Color(0.05, 0.86, 1.0), Color(0.75, 0.98, 1.0), 0, 0.9, "free"),
		_skin("magenta", "Magenta", Color(1.0, 0.12, 0.55), Color(1.0, 0.7, 0.88), 0, 0.9, "clean:1"),
		_skin("lime", "Lime", Color(0.45, 1.0, 0.15), Color(0.85, 1.0, 0.55), 0, 0.85, "streak:3"),
		_skin("gold", "Sun Gold", Color(1.0, 0.78, 0.12), Color(1.0, 0.96, 0.6), 0, 1.05, "trees:3500"),
		_skin("orange", "Orange", Color(1.0, 0.4, 0.05), Color(1.0, 0.75, 0.35), 0, 0.9, "buildings:1400"),
		_skin("violet", "Violet", Color(0.58, 0.22, 1.0), Color(0.86, 0.7, 1.0), 0, 0.95, "rivals:120"),
		_skin("ice", "Ice", Color(0.72, 0.92, 1.0), Color(0.35, 0.65, 1.0), 0, 0.75, "people:5000"),
		_skin("stripe", "Candy Stripe", Color(1.0, 0.18, 0.42), Color(1.0, 0.95, 0.35), 1, 0.95, "cars:7000"),
		_skin("ember", "Ember", Color(1.0, 0.22, 0.02), Color(1.0, 0.82, 0.15), 3, 1.4, "props:20000"),
		_skin("ocean", "Ocean", Color(0.02, 0.4, 0.95), Color(0.15, 0.95, 0.85), 3, 1.0, "lamps:2800"),
		_skin("rose", "Rose Gold", Color(0.93, 0.55, 0.5), Color(1.0, 0.9, 0.7), 4, 1.25, "boats:800"),
		_skin("toxic", "Toxic", Color(0.55, 1.0, 0.08), Color(0.08, 0.22, 0.05), 2, 1.1, "sweeps:6"),
		_skin("royal", "Royal", Color(0.32, 0.08, 0.72), Color(1.0, 0.82, 0.28), 4, 1.3, "stars3:8"),
		_skin("checker", "Checker", Color(0.06, 0.06, 0.08), Color(0.95, 0.96, 1.0), 2, 0.6, "animals:3500"),
		_skin("prism", "Prism", Color(1.0, 0.2, 0.55), Color(0.25, 0.85, 1.0), 1, 1.45, "maps:10"),
	]

static func _skin(id: String, skin_name: String, a: Color, b: Color, pattern: int, glow: float, unlock: String) -> Dictionary:
	return {"id": id, "name": skin_name, "a": a, "b": b, "pattern": pattern, "glow": glow, "unlock": unlock}

static func skin_by_id(id: String) -> Dictionary:
	for s in skins():
		if str(s.id) == id:
			return s
	return skins()[0]
