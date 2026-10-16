extends RefCounted

# Original low-poly props. One mesh per kind so each kind is a single MultiMesh draw.
# `base` is the ground-contact half-width used for swallowing, not the canopy.

static func defs() -> Array:
	return [
		_def("hydrant", "small", 1, 0.11, _hydrant()),
		_def("mailbox", "small", 2, 0.07, _mailbox()),
		_def("sign", "small", 2, 0.06, _sign()),
		_def("crate", "small", 3, 0.22, _crate()),
		_def("bin", "small", 2, 0.16, _bin()),
		_def("bench", "small", 4, 0.58, _bench()),
		_def("picnic", "small", 8, 0.64, _picnic()),
		_def("umbrella", "umbrella", 3, 0.045, _umbrella()),
		_def("chair", "small", 2, 0.18, _chair()),
		_def("surf", "small", 2, 0.14, _surf()),
		_def("palm", "palm", 6, 0.10, _palm()),
		_def("stall", "stall", 12, 0.60, _stall()),
		_def("hay", "small", 5, 0.36, _hay()),
		_def("animal", "small", 4, 0.28, _animal()),
		_def("tractor", "car", 14, 0.58, _tractor()),
		_def("forklift", "car", 10, 0.50, _forklift()),
		_def("boat", "boat", 20, 1.05, _boat()),
		_def("bus", "bus", 22, 1.15, _bus()),
		_def("locker", "small", 3, 0.16, _locker()),
		_def("ride", "ride", 36, 1.45, _ride()),
		_def("tank", "tank", 26, 1.05, _tank()),
		_def("pipe", "small", 4, 0.62, _pipe()),
		_def("fence", "small", 2, 0.52, _fence()),
		_def("barn", "barn", 46, 1.60, _barn()),
		_def("truck", "truck", 18, 1.08, _truck()),
		_def("bike", "small", 3, 0.36, _bike()),
	]

static func _def(id: String, role: String, points: int, base: float, mesh: ArrayMesh) -> Dictionary:
	return {
		"id": id,
		"role": role,
		"points": points,
		"base": base,
		"mover": 0,
		"mesh": mesh,
		"size": mesh.get_aabb().size,
	}

static func _begin() -> SurfaceTool:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	return st

static func _commit(st: SurfaceTool) -> ArrayMesh:
	return st.commit()

static func _tri(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, col: Color) -> void:
	var n := (b - a).cross(c - a)
	n = Vector3.UP if n.length_squared() < 0.000001 else n.normalized()
	st.set_normal(n)
	st.set_color(col)
	st.add_vertex(a)
	st.set_normal(n)
	st.set_color(col)
	st.add_vertex(b)
	st.set_normal(n)
	st.set_color(col)
	st.add_vertex(c)

static func _quad(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, d: Vector3, col: Color) -> void:
	_tri(st, a, b, c, col)
	_tri(st, a, c, d, col)

static func _box(st: SurfaceTool, c: Vector3, s: Vector3, col: Color) -> void:
	var hx := s.x * 0.5
	var hy := s.y * 0.5
	var hz := s.z * 0.5
	var y0 := c.y - hy
	var y1 := c.y + hy
	_quad(st, Vector3(c.x - hx, y1, c.z + hz), Vector3(c.x + hx, y1, c.z + hz), Vector3(c.x + hx, y1, c.z - hz), Vector3(c.x - hx, y1, c.z - hz), col)
	_quad(st, Vector3(c.x - hx, y0, c.z - hz), Vector3(c.x + hx, y0, c.z - hz), Vector3(c.x + hx, y0, c.z + hz), Vector3(c.x - hx, y0, c.z + hz), col)
	_quad(st, Vector3(c.x - hx, y0, c.z + hz), Vector3(c.x + hx, y0, c.z + hz), Vector3(c.x + hx, y1, c.z + hz), Vector3(c.x - hx, y1, c.z + hz), col)
	_quad(st, Vector3(c.x + hx, y0, c.z - hz), Vector3(c.x - hx, y0, c.z - hz), Vector3(c.x - hx, y1, c.z - hz), Vector3(c.x + hx, y1, c.z - hz), col)
	_quad(st, Vector3(c.x + hx, y0, c.z + hz), Vector3(c.x + hx, y0, c.z - hz), Vector3(c.x + hx, y1, c.z - hz), Vector3(c.x + hx, y1, c.z + hz), col)
	_quad(st, Vector3(c.x - hx, y0, c.z - hz), Vector3(c.x - hx, y0, c.z + hz), Vector3(c.x - hx, y1, c.z + hz), Vector3(c.x - hx, y1, c.z - hz), col)

static func _cyl(st: SurfaceTool, base: Vector3, radius: float, height: float, col: Color, sides: int = 7) -> void:
	var top := base + Vector3(0, height, 0)
	for i in sides:
		var a0 := TAU * float(i) / float(sides)
		var a1 := TAU * float(i + 1) / float(sides)
		var b0 := base + Vector3(cos(a0) * radius, 0, sin(a0) * radius)
		var b1 := base + Vector3(cos(a1) * radius, 0, sin(a1) * radius)
		var t0 := b0 + Vector3(0, height, 0)
		var t1 := b1 + Vector3(0, height, 0)
		_quad(st, b0, t0, t1, b1, col)
		_tri(st, top, t1, t0, col)
		_tri(st, base, b0, b1, col)

static func _cone(st: SurfaceTool, base: Vector3, radius: float, height: float, col: Color, sides: int = 8) -> void:
	var apex := base + Vector3(0, height, 0)
	for i in sides:
		var a0 := TAU * float(i) / float(sides)
		var a1 := TAU * float(i + 1) / float(sides)
		var p0 := base + Vector3(cos(a0) * radius, 0, sin(a0) * radius)
		var p1 := base + Vector3(cos(a1) * radius, 0, sin(a1) * radius)
		_tri(st, apex, p1, p0, col)
		_tri(st, base, p0, p1, col)

static func _wheel(st: SurfaceTool, c: Vector3, radius: float, thick: float, col: Color, sides: int = 8) -> void:
	var x0 := c.x - thick * 0.5
	var x1 := c.x + thick * 0.5
	for i in sides:
		var a0 := TAU * float(i) / float(sides)
		var a1 := TAU * float(i + 1) / float(sides)
		var p0 := Vector2(cos(a0) * radius, sin(a0) * radius)
		var p1 := Vector2(cos(a1) * radius, sin(a1) * radius)
		var b0 := Vector3(x0, c.y + p0.x, c.z + p0.y)
		var b1 := Vector3(x0, c.y + p1.x, c.z + p1.y)
		var t0 := Vector3(x1, c.y + p0.x, c.z + p0.y)
		var t1 := Vector3(x1, c.y + p1.x, c.z + p1.y)
		_quad(st, b0, b1, t1, t0, col)

static func _hydrant() -> ArrayMesh:
	var st := _begin()
	var red := Color(0.72, 0.28, 0.28)
	var metal := Color(0.72, 0.74, 0.78)
	_cyl(st, Vector3.ZERO, 0.11, 0.42, red)
	_cyl(st, Vector3(0, 0.42, 0), 0.13, 0.08, metal)
	_box(st, Vector3(0.12, 0.28, 0), Vector3(0.14, 0.08, 0.08), metal)
	_cyl(st, Vector3(0, 0.50, 0), 0.04, 0.08, metal, 5)
	return _commit(st)

static func _mailbox() -> ArrayMesh:
	var st := _begin()
	_box(st, Vector3(0, 0.42, 0), Vector3(0.07, 0.84, 0.07), Color(0.45, 0.34, 0.24))
	_box(st, Vector3(0, 0.90, 0), Vector3(0.32, 0.20, 0.18), Color(0.32, 0.46, 0.70))
	_box(st, Vector3(0.18, 0.90, 0), Vector3(0.10, 0.08, 0.04), Color(0.85, 0.55, 0.22))
	return _commit(st)

static func _sign() -> ArrayMesh:
	var st := _begin()
	_box(st, Vector3(0, 0.62, 0), Vector3(0.06, 1.24, 0.06), Color(0.55, 0.58, 0.62))
	_box(st, Vector3(0, 1.15, 0), Vector3(0.70, 0.40, 0.05), Color(0.90, 0.82, 0.48))
	_box(st, Vector3(0, 1.15, 0.03), Vector3(0.50, 0.16, 0.02), Color(0.35, 0.55, 0.72))
	return _commit(st)

static func _crate() -> ArrayMesh:
	var st := _begin()
	var wood := Color(0.62, 0.44, 0.26)
	var band := Color(0.48, 0.32, 0.18)
	_box(st, Vector3(0, 0.22, 0), Vector3(0.44, 0.44, 0.44), wood)
	_box(st, Vector3(0, 0.36, 0), Vector3(0.46, 0.06, 0.46), band)
	_box(st, Vector3(0, 0.10, 0), Vector3(0.46, 0.06, 0.46), band)
	return _commit(st)

static func _bin() -> ArrayMesh:
	var st := _begin()
	_cyl(st, Vector3.ZERO, 0.16, 0.55, Color(0.32, 0.42, 0.38))
	_cyl(st, Vector3(0, 0.55, 0), 0.18, 0.06, Color(0.24, 0.30, 0.28))
	return _commit(st)

static func _bench() -> ArrayMesh:
	var st := _begin()
	var wood := Color(0.58, 0.40, 0.24)
	var iron := Color(0.35, 0.38, 0.42)
	_box(st, Vector3(0, 0.42, 0), Vector3(1.16, 0.06, 0.34), wood)
	_box(st, Vector3(0, 0.62, -0.14), Vector3(1.16, 0.32, 0.05), wood)
	_box(st, Vector3(-0.46, 0.22, 0), Vector3(0.06, 0.44, 0.30), iron)
	_box(st, Vector3(0.46, 0.22, 0), Vector3(0.06, 0.44, 0.30), iron)
	return _commit(st)

static func _picnic() -> ArrayMesh:
	var st := _begin()
	var wood := Color(0.55, 0.38, 0.22)
	_box(st, Vector3(0, 0.62, 0), Vector3(1.28, 0.07, 0.64), wood)
	_box(st, Vector3(0, 0.42, 0.48), Vector3(1.20, 0.06, 0.22), wood)
	_box(st, Vector3(0, 0.42, -0.48), Vector3(1.20, 0.06, 0.22), wood)
	_box(st, Vector3(-0.46, 0.32, 0), Vector3(0.08, 0.64, 0.56), Color(0.42, 0.30, 0.18))
	_box(st, Vector3(0.46, 0.32, 0), Vector3(0.08, 0.64, 0.56), Color(0.42, 0.30, 0.18))
	return _commit(st)

static func _umbrella() -> ArrayMesh:
	var st := _begin()
	_cyl(st, Vector3.ZERO, 0.035, 1.25, Color(0.85, 0.82, 0.74), 5)
	_cone(st, Vector3(0, 1.05, 0), 0.72, 0.22, Color(0.85, 0.40, 0.38))
	return _commit(st)

static func _chair() -> ArrayMesh:
	var st := _begin()
	var cloth := Color(0.86, 0.78, 0.62)
	var wood := Color(0.55, 0.40, 0.26)
	_box(st, Vector3(0, 0.40, 0), Vector3(0.36, 0.05, 0.36), cloth)
	_box(st, Vector3(0, 0.58, -0.15), Vector3(0.36, 0.32, 0.05), cloth)
	_box(st, Vector3(-0.14, 0.20, 0.12), Vector3(0.04, 0.40, 0.04), wood)
	_box(st, Vector3(0.14, 0.20, 0.12), Vector3(0.04, 0.40, 0.04), wood)
	_box(st, Vector3(-0.14, 0.20, -0.12), Vector3(0.04, 0.40, 0.04), wood)
	_box(st, Vector3(0.14, 0.20, -0.12), Vector3(0.04, 0.40, 0.04), wood)
	return _commit(st)

static func _surf() -> ArrayMesh:
	var st := _begin()
	_box(st, Vector3(0, 0.70, 0), Vector3(0.10, 1.35, 0.28), Color(0.90, 0.55, 0.32))
	_box(st, Vector3(0, 0.20, 0), Vector3(0.04, 0.16, 0.10), Color(0.85, 0.86, 0.88))
	return _commit(st)

static func _palm() -> ArrayMesh:
	var st := _begin()
	var trunk := Color(0.55, 0.40, 0.26)
	var leaf := Color(0.28, 0.58, 0.30)
	_cyl(st, Vector3.ZERO, 0.10, 0.55, trunk, 6)
	_cyl(st, Vector3(0.06, 0.50, 0), 0.09, 0.50, trunk, 6)
	_cyl(st, Vector3(0.14, 0.95, 0), 0.08, 0.48, trunk, 6)
	_box(st, Vector3(0.55, 1.55, 0), Vector3(0.85, 0.06, 0.16), leaf)
	_box(st, Vector3(-0.20, 1.58, 0.15), Vector3(0.70, 0.06, 0.14), leaf)
	_box(st, Vector3(0.20, 1.60, 0.40), Vector3(0.16, 0.06, 0.75), leaf)
	_box(st, Vector3(0.15, 1.52, -0.35), Vector3(0.14, 0.06, 0.70), leaf)
	return _commit(st)

static func _stall() -> ArrayMesh:
	var st := _begin()
	_box(st, Vector3(0, 0.45, 0), Vector3(1.20, 0.90, 0.55), Color(0.78, 0.40, 0.32))
	_box(st, Vector3(0, 1.00, 0.10), Vector3(1.45, 0.08, 0.95), Color(0.90, 0.72, 0.32))
	_box(st, Vector3(0, 1.00, 0.10), Vector3(1.45, 0.08, 0.18), Color(0.85, 0.45, 0.38))
	_box(st, Vector3(0, 0.70, 0.28), Vector3(0.70, 0.28, 0.04), Color(0.95, 0.92, 0.84))
	return _commit(st)

static func _hay() -> ArrayMesh:
	var st := _begin()
	_box(st, Vector3(0, 0.28, 0), Vector3(0.72, 0.42, 0.42), Color(0.78, 0.66, 0.24))
	_box(st, Vector3(0, 0.28, 0), Vector3(0.74, 0.10, 0.44), Color(0.62, 0.48, 0.18))
	return _commit(st)

static func _animal() -> ArrayMesh:
	var st := _begin()
	var body := Color(0.92, 0.90, 0.86)
	var dark := Color(0.35, 0.32, 0.30)
	_box(st, Vector3(0, 0.36, 0), Vector3(0.55, 0.26, 0.26), body)
	_box(st, Vector3(0.32, 0.46, 0), Vector3(0.18, 0.16, 0.16), body)
	_box(st, Vector3(-0.22, 0.16, 0.08), Vector3(0.08, 0.32, 0.08), dark)
	_box(st, Vector3(-0.22, 0.16, -0.08), Vector3(0.08, 0.32, 0.08), dark)
	_box(st, Vector3(0.16, 0.16, 0.08), Vector3(0.08, 0.32, 0.08), dark)
	_box(st, Vector3(0.16, 0.16, -0.08), Vector3(0.08, 0.32, 0.08), dark)
	return _commit(st)

static func _tractor() -> ArrayMesh:
	var st := _begin()
	var green := Color(0.30, 0.55, 0.28)
	var dark := Color(0.16, 0.18, 0.20)
	_box(st, Vector3(0, 0.55, -0.05), Vector3(0.55, 0.32, 0.70), green)
	_box(st, Vector3(0, 0.82, -0.15), Vector3(0.42, 0.28, 0.36), Color(0.70, 0.82, 0.78))
	_wheel(st, Vector3(0, 0.28, 0.32), 0.28, 0.55, dark)
	_wheel(st, Vector3(0, 0.16, -0.38), 0.16, 0.48, dark)
	return _commit(st)

static func _forklift() -> ArrayMesh:
	var st := _begin()
	var yellow := Color(0.86, 0.68, 0.18)
	var dark := Color(0.18, 0.20, 0.22)
	_box(st, Vector3(0, 0.40, -0.05), Vector3(0.50, 0.40, 0.70), yellow)
	_box(st, Vector3(0, 0.55, 0.42), Vector3(0.08, 0.70, 0.08), dark)
	_box(st, Vector3(-0.12, 0.12, 0.70), Vector3(0.06, 0.04, 0.55), Color(0.62, 0.64, 0.66))
	_box(st, Vector3(0.12, 0.12, 0.70), Vector3(0.06, 0.04, 0.55), Color(0.62, 0.64, 0.66))
	_wheel(st, Vector3(0, 0.16, 0.18), 0.16, 0.52, dark)
	_wheel(st, Vector3(0, 0.14, -0.32), 0.14, 0.48, dark)
	return _commit(st)

static func _boat() -> ArrayMesh:
	var st := _begin()
	_box(st, Vector3(0, 0.20, 0), Vector3(0.70, 0.24, 2.10), Color(0.90, 0.92, 0.94))
	_box(st, Vector3(0, 0.36, 0), Vector3(0.78, 0.08, 1.90), Color(0.28, 0.45, 0.62))
	_box(st, Vector3(0, 0.55, -0.15), Vector3(0.46, 0.32, 0.70), Color(0.85, 0.55, 0.32))
	return _commit(st)

static func _bus() -> ArrayMesh:
	var st := _begin()
	_box(st, Vector3(0, 0.70, 0), Vector3(0.85, 0.85, 2.30), Color(0.90, 0.74, 0.22))
	_box(st, Vector3(0, 0.85, 0.10), Vector3(0.88, 0.22, 1.70), Color(0.55, 0.75, 0.82))
	_wheel(st, Vector3(0, 0.22, 0.70), 0.22, 0.90, Color(0.15, 0.16, 0.18))
	_wheel(st, Vector3(0, 0.22, -0.70), 0.22, 0.90, Color(0.15, 0.16, 0.18))
	return _commit(st)

static func _locker() -> ArrayMesh:
	var st := _begin()
	_box(st, Vector3(0, 0.70, 0), Vector3(0.28, 1.40, 0.32), Color(0.45, 0.58, 0.70))
	_box(st, Vector3(0.10, 0.80, 0.16), Vector3(0.04, 0.08, 0.02), Color(0.85, 0.75, 0.30))
	return _commit(st)

static func _ride() -> ArrayMesh:
	var st := _begin()
	var steel := Color(0.55, 0.60, 0.68)
	var cab := Color(0.82, 0.38, 0.42)
	_box(st, Vector3(0, 0.12, 0), Vector3(2.90, 0.24, 2.90), Color(0.35, 0.40, 0.48))
	_cyl(st, Vector3.ZERO, 0.14, 2.15, steel, 6)
	for i in 4:
		var a := TAU * float(i) / 4.0
		var arm := Vector3(cos(a) * 0.85, 1.85, sin(a) * 0.85)
		_box(st, arm, Vector3(0.55, 0.08, 0.18), steel)
		_box(st, arm + Vector3(0, -0.18, 0), Vector3(0.28, 0.22, 0.28), cab)
	return _commit(st)

static func _tank() -> ArrayMesh:
	var st := _begin()
	_cyl(st, Vector3(0, 0.35, 0), 1.05, 1.15, Color(0.62, 0.66, 0.70), 8)
	_cyl(st, Vector3(0, 1.50, 0), 0.28, 0.35, Color(0.48, 0.52, 0.56), 6)
	_box(st, Vector3(0.7, 0.20, 0.7), Vector3(0.16, 0.40, 0.16), Color(0.40, 0.42, 0.46))
	_box(st, Vector3(-0.7, 0.20, 0.7), Vector3(0.16, 0.40, 0.16), Color(0.40, 0.42, 0.46))
	_box(st, Vector3(0.7, 0.20, -0.7), Vector3(0.16, 0.40, 0.16), Color(0.40, 0.42, 0.46))
	_box(st, Vector3(-0.7, 0.20, -0.7), Vector3(0.16, 0.40, 0.16), Color(0.40, 0.42, 0.46))
	return _commit(st)

static func _pipe() -> ArrayMesh:
	var st := _begin()
	var steel := Color(0.48, 0.55, 0.58)
	_box(st, Vector3(0, 0.16, 0), Vector3(1.24, 0.22, 0.22), steel)
	_box(st, Vector3(0.55, 0.28, 0.28), Vector3(0.22, 0.22, 0.55), steel)
	return _commit(st)

static func _fence() -> ArrayMesh:
	var st := _begin()
	var wood := Color(0.62, 0.50, 0.34)
	_box(st, Vector3(-0.48, 0.45, 0), Vector3(0.08, 0.90, 0.08), wood)
	_box(st, Vector3(0.48, 0.45, 0), Vector3(0.08, 0.90, 0.08), wood)
	_box(st, Vector3(0, 0.62, 0), Vector3(0.96, 0.08, 0.05), wood)
	_box(st, Vector3(0, 0.32, 0), Vector3(0.96, 0.08, 0.05), wood)
	return _commit(st)

static func _barn() -> ArrayMesh:
	var st := _begin()
	var red := Color(0.68, 0.26, 0.24)
	var white := Color(0.92, 0.90, 0.84)
	_box(st, Vector3(0, 1.05, 0), Vector3(2.40, 2.10, 3.20), red)
	_box(st, Vector3(0, 2.25, 0), Vector3(2.70, 0.28, 3.40), Color(0.42, 0.28, 0.22))
	_box(st, Vector3(0, 0.70, 1.61), Vector3(0.70, 1.20, 0.06), white)
	_box(st, Vector3(0, 1.40, 1.62), Vector3(0.90, 0.16, 0.04), white)
	return _commit(st)

static func _truck() -> ArrayMesh:
	var st := _begin()
	_box(st, Vector3(0, 0.70, 0.15), Vector3(0.90, 0.85, 1.50), Color(0.82, 0.36, 0.32))
	_box(st, Vector3(0, 0.62, -0.85), Vector3(0.88, 0.70, 0.70), Color(0.90, 0.90, 0.92))
	_box(st, Vector3(0, 1.15, 0.15), Vector3(1.05, 0.08, 0.70), Color(0.90, 0.72, 0.30))
	_wheel(st, Vector3(0, 0.22, 0.55), 0.22, 0.95, Color(0.15, 0.16, 0.18))
	_wheel(st, Vector3(0, 0.22, -0.70), 0.22, 0.95, Color(0.15, 0.16, 0.18))
	return _commit(st)

static func _bike() -> ArrayMesh:
	var st := _begin()
	var frame := Color(0.28, 0.48, 0.70)
	var tire := Color(0.16, 0.17, 0.20)
	_wheel(st, Vector3(0, 0.22, 0.32), 0.22, 0.08, tire)
	_wheel(st, Vector3(0, 0.22, -0.32), 0.22, 0.08, tire)
	_box(st, Vector3(0, 0.32, 0), Vector3(0.06, 0.06, 0.55), frame)
	_box(st, Vector3(0, 0.46, -0.28), Vector3(0.28, 0.04, 0.04), frame)
	_box(st, Vector3(0, 0.28, 0.05), Vector3(0.22, 0.04, 0.10), Color(0.20, 0.22, 0.24))
	return _commit(st)
