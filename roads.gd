extends RefCounted

# One street plan for every theme. The map is about ±78.
# Lines sit off the hole so the opening ground stays the theme's own floor.

const LINES: Array = [-54, -36, -18, 18, 36, 54]

static func cell(x: int, z: int) -> int:
	if absi(x) < 7 and absi(z) < 7:
		return 0
	if _island(x, z):
		return 0
	if _road(x, z):
		return 1
	if _shoulder(x, z):
		return 2
	return 0

static func routes() -> Array:
	var out: Array = []
	out.append(_pack(_outer_loop(), true))
	for line in [-54, -36, -18, 18, 54]:
		out.append(_pack(_vertical(line), false))
	out.append(_pack(_vertical_dead(), false))
	for line in [-54, -36, 18, 36, 54]:
		out.append(_pack(_horizontal(line), false))
	out.append(_pack(_horizontal_dead(), false))
	out.append(_pack(_stub(), false))
	out.append(_pack(_circle(Vector3(18, 0, -36), 6.3), true))
	return out

static func _road(x: int, z: int) -> bool:
	if _ring(x, z):
		return true
	if absi(x) >= 50 and absi(z) >= 50 and _corner_square(x, z):
		return false
	if _on_vertical(x, z) or _on_horizontal(x, z) or _on_stub(x, z):
		return true
	return _fillet(x, z)

static func _on_vertical(x: int, z: int) -> bool:
	for line in LINES:
		if absi(x - int(line)) > 1:
			continue
		if int(line) == 36:
			return z >= -58 and z <= 12
		return z >= -58 and z <= 58
	return false

static func _on_horizontal(x: int, z: int) -> bool:
	for line in LINES:
		if absi(z - int(line)) > 1:
			continue
		if int(line) == -18:
			return x >= -58 and x <= -6
		return x >= -58 and x <= 58
	return false

static func _on_stub(x: int, z: int) -> bool:
	return absi(z) <= 1 and x <= -18 and x >= -42

static func _corner_square(x: int, z: int) -> bool:
	return absi(x) >= 50 and absi(z) >= 50

static func _fillet(x: int, z: int) -> bool:
	if absi(x) < 40 or absi(z) < 40:
		return false
	var sx := 1 if x > 0 else -1
	var sz := 1 if z > 0 else -1
	var cx := sx * 44
	var cz := sz * 44
	var dx := float(x - cx)
	var dz := float(z - cz)
	var dist := sqrt(dx * dx + dz * dz)
	if dist < 8.5 or dist > 11.4:
		return false
	return x * sx > 40 and z * sz > 40

static func _ring(x: int, z: int) -> bool:
	var dx := float(x - 18)
	var dz := float(z + 36)
	var dist := sqrt(dx * dx + dz * dz)
	return dist >= 5.0 and dist <= 7.6

static func _island(x: int, z: int) -> bool:
	var dx := float(x - 18)
	var dz := float(z + 36)
	return sqrt(dx * dx + dz * dz) < 4.7

static func _shoulder(x: int, z: int) -> bool:
	if _road(x, z) or _island(x, z):
		return false
	for dz in range(-2, 3):
		for dx in range(-2, 3):
			if dx == 0 and dz == 0:
				continue
			if maxi(absi(dx), absi(dz)) > 2:
				continue
			if _road(x + dx, z + dz):
				return true
	return false

static func _outer_loop() -> PackedVector3Array:
	var pts := PackedVector3Array()
	_line(pts, Vector3(-44, 0, -54), Vector3(44, 0, -54))
	_arc(pts, Vector3(44, 0, -44), 10.0, -PI * 0.5, 0.0)
	_line(pts, Vector3(54, 0, -44), Vector3(54, 0, 44))
	_arc(pts, Vector3(44, 0, 44), 10.0, 0.0, PI * 0.5)
	_line(pts, Vector3(44, 0, 54), Vector3(-44, 0, 54))
	_arc(pts, Vector3(-44, 0, 44), 10.0, PI * 0.5, PI)
	_line(pts, Vector3(-54, 0, 44), Vector3(-54, 0, -44))
	_arc(pts, Vector3(-44, 0, -44), 10.0, PI, PI * 1.5)
	return pts

static func _vertical(line: int) -> PackedVector3Array:
	var pts := PackedVector3Array()
	if line == 18:
		_line(pts, Vector3(18, 0, -54), Vector3(18, 0, -43))
		_arc(pts, Vector3(18, 0, -36), 7.0, -PI * 0.5, PI * 0.5)
		_line(pts, Vector3(18, 0, -29), Vector3(18, 0, 54))
		return pts
	_line(pts, Vector3(float(line), 0, -54), Vector3(float(line), 0, 54))
	return pts

static func _vertical_dead() -> PackedVector3Array:
	var pts := PackedVector3Array()
	_line(pts, Vector3(36, 0, -54), Vector3(36, 0, 12))
	return pts

static func _horizontal(line: int) -> PackedVector3Array:
	var pts := PackedVector3Array()
	if line == -36:
		_line(pts, Vector3(-54, 0, -36), Vector3(11, 0, -36))
		_arc(pts, Vector3(18, 0, -36), 7.0, PI, 0.0)
		_line(pts, Vector3(25, 0, -36), Vector3(54, 0, -36))
		return pts
	_line(pts, Vector3(-54, 0, float(line)), Vector3(54, 0, float(line)))
	return pts

static func _horizontal_dead() -> PackedVector3Array:
	var pts := PackedVector3Array()
	_line(pts, Vector3(-54, 0, -18), Vector3(-6, 0, -18))
	return pts

static func _stub() -> PackedVector3Array:
	var pts := PackedVector3Array()
	_line(pts, Vector3(-18, 0, 0), Vector3(-42, 0, 0))
	return pts

static func _circle(center: Vector3, radius: float) -> PackedVector3Array:
	var pts := PackedVector3Array()
	_arc(pts, center, radius, 0.0, TAU - 0.2)
	return pts

static func _line(pts: PackedVector3Array, a: Vector3, b: Vector3) -> void:
	var span := b - a
	var steps := maxi(int(span.length() / 2.0), 1)
	for i in range(steps + 1):
		var p := a.lerp(b, float(i) / float(steps))
		if pts.is_empty() or pts[pts.size() - 1].distance_to(p) > 0.4:
			pts.append(p)

static func _arc(pts: PackedVector3Array, center: Vector3, radius: float, a0: float, a1: float) -> void:
	var sweep := a1 - a0
	var steps := maxi(int(absf(sweep) * radius / 2.0), 2)
	for i in range(steps + 1):
		var a := a0 + sweep * float(i) / float(steps)
		var p := center + Vector3(cos(a) * radius, 0.0, sin(a) * radius)
		if pts.is_empty() or pts[pts.size() - 1].distance_to(p) > 0.4:
			pts.append(p)

static func _pack(pts: PackedVector3Array, closed: bool) -> Dictionary:
	var cum := PackedFloat32Array()
	cum.resize(pts.size())
	var length := 0.0
	for i in pts.size():
		if i > 0:
			length += pts[i].distance_to(pts[i - 1])
		cum[i] = length
	var stops := PackedFloat32Array()
	for i in range(1, pts.size() - 1):
		var prev := pts[i] - pts[i - 1]
		var nxt := pts[i + 1] - pts[i]
		if prev.length_squared() < 0.01 or nxt.length_squared() < 0.01:
			continue
		var turn := prev.normalized().dot(nxt.normalized())
		if turn < 0.65:
			stops.append(cum[i])
	return {"pts": pts, "cum": cum, "len": maxf(length, 0.1), "closed": closed, "stops": stops}
