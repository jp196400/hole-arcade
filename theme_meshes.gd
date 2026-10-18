extends RefCounted

# Original low-poly theme props. Kenney CC0 models cover the rest.
# `base` is the swallow half-width, kept close to the real footprint.

static func defs() -> Array:
	return [
		_def("chicken", "small", 3, 0.26, _chicken()),
		_def("piglet", "small", 4, 0.46, _pig()),
		_def("cow", "small", 8, 0.82, _cow()),
		_def("sheep", "small", 6, 0.58, _sheep()),
		_def("penguin", "small", 4, 0.32, _penguin()),
		_def("snowmobile", "ride", 10, 0.70, _snowmobile()),
		_def("scare", "small", 6, 0.70, _scare()),
		_def("farmtractor", "ride", 16, 0.78, _tractor()),
		_def("pickup", "ride", 14, 0.92, _pickup()),
		_def("safarijeep", "car", 14, 0.88, _safarijeep(), 2),
		_def("safaritruck", "car", 18, 1.05, _safaritruck(), 2),
		_def("grainsilo", "barn", 28, 1.15, _silo()),
		_def("redbarn", "barn", 48, 1.85, _barn()),
		_def("raptord", "ride", 14, 0.95, _raptor()),
		_def("trike", "ride", 22, 1.0, _trike()),
		_def("tyrant", "barn", 36, 1.55, _trex()),
		_def("brachio", "barn", 42, 1.85, _brachio()),
		_def("jhut", "barn", 20, 1.35, _hut()),
		_def("lavacone", "barn", 60, 2.15, _volcano()),
		_def("panchor", "small", 6, 0.72, _anchor()),
		_def("tavern", "barn", 30, 1.70, _tavern()),
		_def("skier", "small", 6, 0.62, _skier()),
		_def("hcabin", "barn", 26, 1.55, _cabin()),
		_def("skilift", "barn", 34, 1.70, _skilift()),
		_def("icecastle", "barn", 60, 2.20, _icecastle()),
		_def("dcamel", "ride", 16, 1.15, _camel()),
		_def("dadobe", "barn", 28, 1.60, _adobe()),
		_def("dpyramid", "barn", 46, 1.90, _pyramid()),
		_def("dsphinx", "barn", 60, 2.25, _sphinx()),
		_def("tball", "small", 2, 0.30, _ball()),
		_def("teddybear", "small", 8, 0.72, _teddy()),
		_def("bot", "ride", 14, 0.85, _robot()),
		_def("toyhouse", "barn", 30, 1.55, _dollhouse()),
		_def("blockfort", "barn", 60, 2.15, _blocktower()),
		_def("gantry", "barn", 60, 2.20, _gantry()),
		_def("hbat", "small", 3, 0.34, _bat()),
		_def("hcrow", "small", 3, 0.32, _crow()),
		_def("hhouse", "barn", 32, 1.65, _crooked()),
		_def("ghouse", "barn", 28, 1.55, _gingerbread()),
		_def("ccastle", "barn", 60, 2.30, _candycastle()),
		_def("fballoon", "small", 3, 0.28, _balloons()),
		_def("fbumper", "ride", 10, 0.70, _bumper()),
		_def("teacups", "ride", 22, 1.35, _teacups(), 4),
		_def("carousel", "ride", 40, 1.75, _carousel(), 4),
		_def("ferris", "ride", 60, 2.20, _ferris()),
		_def("roundtree", "tree", 8, 0.72, _round_tree()),
		_def("spottedegg", "small", 2, 0.22, _spotted_egg()),
		_def("dinonest", "small", 6, 0.7, _dino_nest()),
		_def("dinobone", "small", 3, 0.55, _dino_bone()),
		_def("jvine", "palm", 4, 0.28, _vine()),
		_def("antenna", "ride", 12, 0.45, _antenna()),
		_def("solarpanel", "small", 10, 0.85, _solar()),
		_def("satprobe", "small", 4, 0.36, _sat_probe()),
		_def("candybench", "small", 5, 0.62, _candy_bench()),
		_def("pier", "small", 8, 0.6, _pier()),
		_def("skiff", "small", 10, 0.55, _skiff()),
		_def("toybench", "small", 5, 0.6, _toy_bench()),
		_def("blossom", "clutter", 1, 0.2, _blossom()),
		_def("pebbles", "clutter", 1, 0.22, _pebbles()),
		_def("puddle", "clutter", 1, 0.32, _puddle()),
	]

static func _def(id: String, role: String, points: int, base: float, mesh: ArrayMesh, mover: int = 0) -> Dictionary:
	return {"id": id, "role": role, "points": points, "base": base, "mover": mover, "mesh": mesh, "size": mesh.get_aabb().size}

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
	_box_basis(st, c, s, Basis.IDENTITY, col)

static func _box_basis(st: SurfaceTool, c: Vector3, s: Vector3, b: Basis, col: Color) -> void:
	var hx := s.x * 0.5
	var hy := s.y * 0.5
	var hz := s.z * 0.5
	var p000 := c + b * Vector3(-hx, -hy, -hz)
	var p001 := c + b * Vector3(-hx, -hy, hz)
	var p010 := c + b * Vector3(-hx, hy, -hz)
	var p011 := c + b * Vector3(-hx, hy, hz)
	var p100 := c + b * Vector3(hx, -hy, -hz)
	var p101 := c + b * Vector3(hx, -hy, hz)
	var p110 := c + b * Vector3(hx, hy, -hz)
	var p111 := c + b * Vector3(hx, hy, hz)
	_quad(st, p010, p110, p111, p011, col)
	_quad(st, p000, p001, p101, p100, col)
	_quad(st, p001, p011, p111, p101, col)
	_quad(st, p100, p110, p010, p000, col)
	_quad(st, p101, p111, p110, p100, col)
	_quad(st, p000, p010, p011, p001, col)

static func _beam(st: SurfaceTool, a: Vector3, b: Vector3, thick: float, col: Color) -> void:
	var dir := b - a
	var leng := dir.length()
	if leng < 0.001:
		return
	var y := dir / leng
	var x := y.cross(Vector3.UP)
	if x.length_squared() < 0.000001:
		x = y.cross(Vector3.RIGHT)
	x = x.normalized()
	var z := x.cross(y).normalized()
	_box_basis(st, (a + b) * 0.5, Vector3(thick, leng, thick), Basis(x, y, z), col)

static func _cyl(st: SurfaceTool, base: Vector3, radius: float, height: float, col: Color, sides: int = 10) -> void:
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

static func _cone(st: SurfaceTool, base: Vector3, radius: float, height: float, col: Color, sides: int = 10) -> void:
	var apex := base + Vector3(0, height, 0)
	for i in sides:
		var a0 := TAU * float(i) / float(sides)
		var a1 := TAU * float(i + 1) / float(sides)
		var b0 := base + Vector3(cos(a0) * radius, 0, sin(a0) * radius)
		var b1 := base + Vector3(cos(a1) * radius, 0, sin(a1) * radius)
		_tri(st, b0, apex, b1, col)
		_tri(st, base, b1, b0, col)

static func _ellip(st: SurfaceTool, c: Vector3, r: Vector3, col: Color, seg: int = 8, rings: int = 6, band: Color = Color(0, 0, 0, 0)) -> void:
	for i in rings:
		var p0 := PI * float(i) / float(rings)
		var p1 := PI * float(i + 1) / float(rings)
		for j in seg:
			var u0 := TAU * float(j) / float(seg)
			var u1 := TAU * float(j + 1) / float(seg)
			var a := _sphere_pt(c, r, p0, u0)
			var b := _sphere_pt(c, r, p0, u1)
			var d := _sphere_pt(c, r, p1, u1)
			var e := _sphere_pt(c, r, p1, u0)
			var use := col
			if band.a > 0.5 and absf(cos((p0 + p1) * 0.5)) < 0.28:
				use = band
			_quad(st, a, b, d, e, use)

static func _sphere_pt(c: Vector3, r: Vector3, phi: float, theta: float) -> Vector3:
	var sp := sin(phi)
	return c + Vector3(sp * cos(theta) * r.x, cos(phi) * r.y, sp * sin(theta) * r.z)

static func _wheel(st: SurfaceTool, c: Vector3, radius: float, thick: float, col: Color) -> void:
	var sides := 10
	var x0 := c.x - thick * 0.5
	var x1 := c.x + thick * 0.5
	for i in sides:
		var a0 := TAU * float(i) / float(sides)
		var a1 := TAU * float(i + 1) / float(sides)
		var p0 := Vector2(cos(a0) * radius, sin(a0) * radius)
		var p1 := Vector2(cos(a1) * radius, sin(a1) * radius)
		_quad(st, Vector3(x0, c.y + p0.x, c.z + p0.y), Vector3(x0, c.y + p1.x, c.z + p1.y), Vector3(x1, c.y + p1.x, c.z + p1.y), Vector3(x1, c.y + p0.x, c.z + p0.y), col)

static func _eye(st: SurfaceTool, c: Vector3, s: float = 0.06) -> void:
	_box(st, c, Vector3(s, s, s * 0.4), Color(0.08, 0.08, 0.1))

static func _legs4(st: SurfaceTool, y: float, x: float, z: float, h: float, col: Color) -> void:
	_box(st, Vector3(-x, y, z), Vector3(0.1, h, 0.1), col)
	_box(st, Vector3(x, y, z), Vector3(0.1, h, 0.1), col)
	_box(st, Vector3(-x, y, -z), Vector3(0.1, h, 0.1), col)
	_box(st, Vector3(x, y, -z), Vector3(0.1, h, 0.1), col)

static func _chicken() -> ArrayMesh:
	var st := _begin()
	var body := Color(1.0, 0.86, 0.58)
	var wing := Color(0.96, 0.74, 0.42)
	var red := Color(0.92, 0.06, 0.05)
	var beak := Color(0.98, 0.52, 0.08)
	var leg := Color(0.96, 0.46, 0.1)
	_ellip(st, Vector3(0, 0.38, 0), Vector3(0.26, 0.2, 0.34), body)
	_ellip(st, Vector3(0, 0.56, 0.28), Vector3(0.15, 0.14, 0.15), body)
	_cone(st, Vector3(0, 0.54, 0.4), 0.055, 0.14, beak, 6)
	_box(st, Vector3(0, 0.78, 0.22), Vector3(0.08, 0.26, 0.12), red)
	_box(st, Vector3(-0.07, 0.7, 0.2), Vector3(0.06, 0.16, 0.08), red)
	_box(st, Vector3(0.07, 0.68, 0.2), Vector3(0.06, 0.14, 0.08), red)
	_box(st, Vector3(0, 0.52, 0.42), Vector3(0.16, 0.09, 0.07), red)
	_box(st, Vector3(-0.24, 0.4, 0), Vector3(0.18, 0.06, 0.26), wing)
	_box(st, Vector3(0.24, 0.4, 0), Vector3(0.18, 0.06, 0.26), wing)
	_box(st, Vector3(0, 0.42, -0.32), Vector3(0.14, 0.12, 0.12), Color(0.95, 0.48, 0.14))
	_box(st, Vector3(-0.09, 0.12, 0.08), Vector3(0.045, 0.24, 0.045), leg)
	_box(st, Vector3(0.09, 0.12, 0.08), Vector3(0.045, 0.24, 0.045), leg)
	_eye(st, Vector3(-0.07, 0.58, 0.4), 0.04)
	_eye(st, Vector3(0.07, 0.58, 0.4), 0.04)
	return _commit(st)

static func _round_tree() -> ArrayMesh:
	var st := _begin()
	var trunk := Color(0.55, 0.34, 0.16)
	var leaf := Color(0.28, 0.55, 0.26)
	var lite := Color(0.42, 0.66, 0.32)
	_cyl(st, Vector3(0, 0, 0), 0.16, 1.15, trunk, 8)
	_ellip(st, Vector3(0, 1.75, 0), Vector3(0.98, 0.74, 0.98), leaf)
	_ellip(st, Vector3(0.18, 2.1, 0.08), Vector3(0.52, 0.4, 0.52), lite)
	return _commit(st)

static func _pig() -> ArrayMesh:
	var st := _begin()
	var pink := Color(0.95, 0.62, 0.68)
	var dark := Color(0.84, 0.4, 0.5)
	_ellip(st, Vector3(0, 0.38, 0), Vector3(0.32, 0.22, 0.42), pink)
	_ellip(st, Vector3(0, 0.46, 0.38), Vector3(0.18, 0.16, 0.16), pink)
	_cyl(st, Vector3(0, 0.42, 0.5), 0.07, 0.08, dark, 8)
	_box(st, Vector3(-0.1, 0.6, 0.34), Vector3(0.08, 0.1, 0.05), pink)
	_box(st, Vector3(0.1, 0.6, 0.34), Vector3(0.08, 0.1, 0.05), pink)
	_legs4(st, 0.12, 0.18, 0.22, 0.24, dark)
	_box(st, Vector3(0, 0.4, -0.4), Vector3(0.06, 0.06, 0.1), dark)
	_eye(st, Vector3(-0.08, 0.5, 0.5))
	_eye(st, Vector3(0.08, 0.5, 0.5))
	return _commit(st)

static func _cow() -> ArrayMesh:
	var st := _begin()
	var hide := Color(0.93, 0.9, 0.84)
	var spot := Color(0.16, 0.14, 0.14)
	var nose := Color(0.4, 0.28, 0.26)
	_box(st, Vector3(0, 0.72, 0), Vector3(0.7, 0.52, 1.45), hide)
	_box(st, Vector3(-0.2, 0.86, -0.15), Vector3(0.28, 0.18, 0.36), spot)
	_box(st, Vector3(0.22, 0.7, 0.25), Vector3(0.22, 0.22, 0.3), spot)
	_box(st, Vector3(0, 0.78, 0.82), Vector3(0.36, 0.32, 0.38), hide)
	_box(st, Vector3(-0.12, 0.7, 0.9), Vector3(0.12, 0.16, 0.1), spot)
	_box(st, Vector3(0, 0.68, 1.02), Vector3(0.18, 0.12, 0.08), nose)
	_box(st, Vector3(-0.1, 0.98, 0.78), Vector3(0.06, 0.14, 0.06), Color(0.85, 0.78, 0.55))
	_box(st, Vector3(0.1, 0.98, 0.78), Vector3(0.06, 0.14, 0.06), Color(0.85, 0.78, 0.55))
	_box(st, Vector3(-0.16, 0.9, 0.7), Vector3(0.1, 0.06, 0.04), hide)
	_box(st, Vector3(0.16, 0.9, 0.7), Vector3(0.1, 0.06, 0.04), hide)
	_legs4(st, 0.28, 0.24, 0.48, 0.52, hide)
	_box(st, Vector3(0, 0.48, -0.15), Vector3(0.16, 0.12, 0.16), Color(0.92, 0.78, 0.78))
	_beam(st, Vector3(0, 0.7, -0.7), Vector3(0.15, 0.55, -0.95), 0.06, hide)
	_eye(st, Vector3(-0.12, 0.82, 1.0), 0.05)
	_eye(st, Vector3(0.12, 0.82, 1.0), 0.05)
	_box(st, Vector3(0, 0.52, 1.02), Vector3(0.08, 0.1, 0.06), Color(0.92, 0.74, 0.18))
	_box(st, Vector3(0.18, 0.9, -0.2), Vector3(0.22, 0.16, 0.28), spot)
	return _commit(st)

static func _sheep() -> ArrayMesh:
	var st := _begin()
	var wool := Color(0.94, 0.93, 0.9)
	var face := Color(0.28, 0.24, 0.22)
	_ellip(st, Vector3(0, 0.46, 0), Vector3(0.38, 0.3, 0.48), wool)
	_ellip(st, Vector3(0, 0.52, 0.4), Vector3(0.14, 0.12, 0.16), face)
	_box(st, Vector3(-0.08, 0.7, 0.28), Vector3(0.05, 0.1, 0.04), face)
	_box(st, Vector3(0.08, 0.7, 0.28), Vector3(0.05, 0.1, 0.04), face)
	_legs4(st, 0.16, 0.16, 0.26, 0.22, face)
	_eye(st, Vector3(-0.05, 0.54, 0.52), 0.03)
	_eye(st, Vector3(0.05, 0.54, 0.52), 0.03)
	return _commit(st)

static func _penguin() -> ArrayMesh:
	var st := _begin()
	var body := Color(0.16, 0.18, 0.22)
	var belly := Color(0.95, 0.94, 0.9)
	var beak := Color(0.95, 0.62, 0.16)
	_ellip(st, Vector3(0, 0.42, 0), Vector3(0.22, 0.32, 0.2), body)
	_ellip(st, Vector3(0, 0.4, 0.06), Vector3(0.12, 0.22, 0.08), belly)
	_box(st, Vector3(-0.2, 0.38, 0), Vector3(0.12, 0.06, 0.16), body)
	_box(st, Vector3(0.2, 0.38, 0), Vector3(0.12, 0.06, 0.16), body)
	_cone(st, Vector3(0, 0.48, 0.2), 0.04, 0.1, beak, 6)
	_box(st, Vector3(-0.06, 0.08, 0.04), Vector3(0.05, 0.14, 0.08), Color(0.9, 0.55, 0.16))
	_box(st, Vector3(0.06, 0.08, 0.04), Vector3(0.05, 0.14, 0.08), Color(0.9, 0.55, 0.16))
	_eye(st, Vector3(-0.06, 0.58, 0.16), 0.028)
	_eye(st, Vector3(0.06, 0.58, 0.16), 0.028)
	return _commit(st)

static func _snowmobile() -> ArrayMesh:
	var st := _begin()
	var body := Color(0.82, 0.18, 0.16)
	var ski := Color(0.75, 0.78, 0.82)
	var dark := Color(0.2, 0.22, 0.26)
	_box(st, Vector3(0, 0.32, 0), Vector3(0.42, 0.22, 0.9), body)
	_box(st, Vector3(0, 0.48, -0.16), Vector3(0.36, 0.16, 0.28), dark)
	_box(st, Vector3(0, 0.22, 0.1), Vector3(0.5, 0.08, 0.7), ski)
	_box(st, Vector3(-0.16, 0.12, 0.42), Vector3(0.08, 0.06, 0.55), ski)
	_box(st, Vector3(0.16, 0.12, 0.42), Vector3(0.08, 0.06, 0.55), ski)
	_box(st, Vector3(0, 0.4, 0.36), Vector3(0.16, 0.1, 0.16), Color(0.95, 0.84, 0.2))
	return _commit(st)

static func _scare() -> ArrayMesh:
	var st := _begin()
	var wood := Color(0.48, 0.32, 0.16)
	var shirt := Color(0.2, 0.48, 0.78)
	var straw := Color(0.86, 0.72, 0.28)
	_box(st, Vector3(0, 0.9, 0), Vector3(0.1, 1.8, 0.1), wood)
	_box(st, Vector3(0, 1.25, 0), Vector3(1.35, 0.08, 0.08), wood)
	_box(st, Vector3(0, 1.05, 0.06), Vector3(0.55, 0.55, 0.12), shirt)
	_box(st, Vector3(-0.45, 1.15, 0), Vector3(0.4, 0.1, 0.1), straw)
	_box(st, Vector3(0.45, 1.15, 0), Vector3(0.4, 0.1, 0.1), straw)
	_ellip(st, Vector3(0, 1.6, 0), Vector3(0.18, 0.18, 0.18), Color(0.9, 0.72, 0.48))
	_cone(st, Vector3(0, 1.74, 0), 0.28, 0.16, Color(0.62, 0.42, 0.16), 8)
	_box(st, Vector3(0, 1.72, 0), Vector3(0.46, 0.05, 0.46), Color(0.55, 0.38, 0.14))
	_eye(st, Vector3(-0.06, 1.62, 0.16), 0.04)
	_eye(st, Vector3(0.06, 1.62, 0.16), 0.04)
	_box(st, Vector3(0, 0.35, 0), Vector3(0.28, 0.08, 0.08), straw)
	return _commit(st)

static func _tractor() -> ArrayMesh:
	var st := _begin()
	var green := Color(0.18, 0.62, 0.22)
	var dark := Color(0.12, 0.13, 0.15)
	var yellow := Color(0.95, 0.78, 0.16)
	_box(st, Vector3(0, 0.62, -0.05), Vector3(0.7, 0.48, 0.85), green)
	_box(st, Vector3(0, 0.95, -0.2), Vector3(0.62, 0.4, 0.48), Color(0.55, 0.82, 0.9))
	_box(st, Vector3(0, 1.18, -0.2), Vector3(0.7, 0.06, 0.55), green)
	_box(st, Vector3(0, 0.48, 0.55), Vector3(0.55, 0.28, 0.45), yellow)
	_box(st, Vector3(0, 0.72, 0.7), Vector3(0.12, 0.55, 0.12), dark)
	_wheel(st, Vector3(-0.38, 0.42, 0.15), 0.42, 0.16, dark)
	_wheel(st, Vector3(0.38, 0.42, 0.15), 0.42, 0.16, dark)
	_wheel(st, Vector3(-0.32, 0.22, -0.48), 0.2, 0.12, dark)
	_wheel(st, Vector3(0.32, 0.22, -0.48), 0.2, 0.12, dark)
	_box(st, Vector3(0, 0.55, -0.55), Vector3(0.16, 0.1, 0.28), Color(0.9, 0.3, 0.18))
	_cyl(st, Vector3(-0.22, 0.86, 0.12), 0.035, 0.42, dark, 6)
	_box(st, Vector3(0, 0.58, 0.78), Vector3(0.38, 0.16, 0.05), Color(0.18, 0.2, 0.22))
	_box(st, Vector3(-0.12, 0.62, 0.81), Vector3(0.08, 0.08, 0.04), Color(0.95, 0.92, 0.62))
	_box(st, Vector3(0.12, 0.62, 0.81), Vector3(0.08, 0.08, 0.04), Color(0.95, 0.92, 0.62))
	_box(st, Vector3(0, 0.78, -0.02), Vector3(0.26, 0.08, 0.26), Color(0.16, 0.12, 0.1))
	_box(st, Vector3(-0.38, 0.42, 0.15), Vector3(0.06, 0.12, 0.12), yellow)
	_box(st, Vector3(0.38, 0.42, 0.15), Vector3(0.06, 0.12, 0.12), yellow)
	return _commit(st)

static func _pickup() -> ArrayMesh:
	var st := _begin()
	var red := Color(0.78, 0.16, 0.16)
	var dark := Color(0.1, 0.11, 0.13)
	var glass := Color(0.45, 0.7, 0.86)
	_box(st, Vector3(0, 0.48, 0.35), Vector3(0.85, 0.4, 1.15), red)
	_box(st, Vector3(0, 0.72, -0.45), Vector3(0.8, 0.48, 0.7), red)
	_box(st, Vector3(0, 0.78, -0.42), Vector3(0.7, 0.28, 0.48), glass)
	_box(st, Vector3(0, 0.42, 0.95), Vector3(0.82, 0.28, 0.08), Color(0.55, 0.12, 0.12))
	_box(st, Vector3(-0.28, 0.42, -0.82), Vector3(0.14, 0.08, 0.06), Color(0.95, 0.92, 0.7))
	_box(st, Vector3(0.28, 0.42, -0.82), Vector3(0.14, 0.08, 0.06), Color(0.95, 0.92, 0.7))
	_box(st, Vector3(0, 0.46, -0.82), Vector3(0.42, 0.1, 0.04), Color(0.72, 0.76, 0.8))
	_box(st, Vector3(-0.42, 0.72, -0.55), Vector3(0.06, 0.08, 0.14), dark)
	_box(st, Vector3(0.42, 0.72, -0.55), Vector3(0.06, 0.08, 0.14), dark)
	_wheel(st, Vector3(-0.42, 0.24, 0.45), 0.22, 0.12, dark)
	_wheel(st, Vector3(0.42, 0.24, 0.45), 0.22, 0.12, dark)
	_wheel(st, Vector3(-0.42, 0.24, -0.45), 0.22, 0.12, dark)
	_wheel(st, Vector3(0.42, 0.24, -0.45), 0.22, 0.12, dark)
	return _commit(st)

static func _safarijeep() -> ArrayMesh:
	var st := _begin()
	var olive := Color(0.58, 0.8, 0.26)
	var tan := Color(0.97, 0.78, 0.4)
	var orange := Color(0.98, 0.46, 0.1)
	var dark := Color(0.18, 0.16, 0.14)
	var glass := Color(0.78, 0.93, 0.98)
	_box(st, Vector3(0, 0.46, 0.05), Vector3(0.92, 0.34, 1.65), tan)
	_box(st, Vector3(0, 0.56, 0.72), Vector3(0.84, 0.14, 0.5), olive)
	_box(st, Vector3(0, 0.84, 0.36), Vector3(0.78, 0.28, 0.06), glass)
	_box(st, Vector3(-0.38, 0.92, -0.12), Vector3(0.06, 0.4, 0.06), olive)
	_box(st, Vector3(0.38, 0.92, -0.12), Vector3(0.06, 0.4, 0.06), olive)
	_box(st, Vector3(0, 1.1, -0.12), Vector3(0.82, 0.06, 0.06), olive)
	_box(st, Vector3(0, 1.08, -0.42), Vector3(0.86, 0.08, 0.66), orange)
	_box(st, Vector3(0, 0.64, 0.42), Vector3(0.78, 0.06, 0.22), orange)
	_box(st, Vector3(-0.18, 0.68, -0.02), Vector3(0.28, 0.14, 0.28), tan)
	_box(st, Vector3(0.18, 0.68, -0.02), Vector3(0.28, 0.14, 0.28), tan)
	_wheel(st, Vector3(0, 0.58, -0.86), 0.16, 0.08, orange)
	_wheel(st, Vector3(-0.48, 0.24, 0.52), 0.24, 0.14, dark)
	_wheel(st, Vector3(0.48, 0.24, 0.52), 0.24, 0.14, dark)
	_wheel(st, Vector3(-0.48, 0.24, -0.48), 0.24, 0.14, dark)
	_wheel(st, Vector3(0.48, 0.24, -0.48), 0.24, 0.14, dark)
	return _commit(st)

static func _safaritruck() -> ArrayMesh:
	var st := _begin()
	var olive := Color(0.52, 0.74, 0.24)
	var tan := Color(0.96, 0.76, 0.38)
	var orange := Color(0.98, 0.48, 0.12)
	var dark := Color(0.18, 0.16, 0.14)
	var glass := Color(0.78, 0.93, 0.98)
	_box(st, Vector3(0, 0.58, 0.82), Vector3(0.9, 0.52, 0.68), olive)
	_box(st, Vector3(0, 0.74, 0.92), Vector3(0.74, 0.26, 0.36), glass)
	_box(st, Vector3(0, 0.46, -0.32), Vector3(0.96, 0.26, 1.3), tan)
	_box(st, Vector3(-0.44, 0.82, -0.32), Vector3(0.05, 0.48, 1.15), olive)
	_box(st, Vector3(0.44, 0.82, -0.32), Vector3(0.05, 0.48, 1.15), olive)
	_box(st, Vector3(0, 1.06, -0.32), Vector3(0.92, 0.08, 1.22), orange)
	_box(st, Vector3(0, 0.72, -0.95), Vector3(0.9, 0.42, 0.05), tan)
	_wheel(st, Vector3(-0.5, 0.26, 0.7), 0.26, 0.16, dark)
	_wheel(st, Vector3(0.5, 0.26, 0.7), 0.26, 0.16, dark)
	_wheel(st, Vector3(-0.5, 0.26, -0.15), 0.26, 0.16, dark)
	_wheel(st, Vector3(0.5, 0.26, -0.15), 0.26, 0.16, dark)
	_wheel(st, Vector3(-0.5, 0.26, -0.72), 0.26, 0.16, dark)
	_wheel(st, Vector3(0.5, 0.26, -0.72), 0.26, 0.16, dark)
	return _commit(st)

static func _silo() -> ArrayMesh:
	var st := _begin()
	var body := Color(0.82, 0.84, 0.86)
	var band := Color(0.3, 0.55, 0.78)
	_cyl(st, Vector3.ZERO, 0.7, 3.4, body, 12)
	_cone(st, Vector3(0, 3.4, 0), 0.78, 0.7, Color(0.55, 0.2, 0.18), 12)
	_cyl(st, Vector3(0, 1.1, 0), 0.74, 0.12, band, 12)
	_cyl(st, Vector3(0, 2.2, 0), 0.74, 0.12, band, 12)
	_box(st, Vector3(0.55, 1.5, 0), Vector3(0.08, 2.2, 0.16), Color(0.45, 0.32, 0.18))
	return _commit(st)

static func _barn() -> ArrayMesh:
	var st := _begin()
	var red := Color(0.72, 0.14, 0.16)
	var white := Color(0.95, 0.94, 0.9)
	var roof := Color(0.42, 0.18, 0.16)
	_box(st, Vector3(0, 1.15, 0), Vector3(2.6, 2.2, 3.6), red)
	_beam(st, Vector3(-1.35, 2.2, -1.8), Vector3(0, 3.15, -1.8), 0.16, roof)
	_beam(st, Vector3(1.35, 2.2, -1.8), Vector3(0, 3.15, -1.8), 0.16, roof)
	_beam(st, Vector3(-1.35, 2.2, 1.8), Vector3(0, 3.15, 1.8), 0.16, roof)
	_beam(st, Vector3(1.35, 2.2, 1.8), Vector3(0, 3.15, 1.8), 0.16, roof)
	_box(st, Vector3(0, 2.7, 0), Vector3(0.2, 0.16, 3.7), roof)
	_box(st, Vector3(0, 0.7, 1.82), Vector3(0.9, 1.3, 0.08), white)
	_beam(st, Vector3(-0.4, 0.2, 1.88), Vector3(0.4, 1.3, 1.88), 0.08, red)
	_beam(st, Vector3(0.4, 0.2, 1.88), Vector3(-0.4, 1.3, 1.88), 0.08, red)
	_box(st, Vector3(-0.7, 1.5, 1.84), Vector3(0.4, 0.4, 0.06), Color(0.55, 0.78, 0.9))
	_box(st, Vector3(0.7, 1.5, 1.84), Vector3(0.4, 0.4, 0.06), Color(0.55, 0.78, 0.9))
	_box(st, Vector3(0, 2.35, 1.84), Vector3(0.45, 0.4, 0.06), white)
	_box(st, Vector3(-1.28, 1.15, 1.82), Vector3(0.08, 2.2, 0.08), white)
	_box(st, Vector3(1.28, 1.15, 1.82), Vector3(0.08, 2.2, 0.08), white)
	_box(st, Vector3(-0.96, 1.5, 1.88), Vector3(0.08, 0.38, 0.04), white)
	_box(st, Vector3(-0.44, 1.5, 1.88), Vector3(0.08, 0.38, 0.04), white)
	_box(st, Vector3(0.44, 1.5, 1.88), Vector3(0.08, 0.38, 0.04), white)
	_box(st, Vector3(0.96, 1.5, 1.88), Vector3(0.08, 0.38, 0.04), white)
	_box(st, Vector3(0, 3.42, 0), Vector3(0.04, 0.5, 0.04), Color(0.25, 0.26, 0.3))
	_box(st, Vector3(0.14, 3.62, 0), Vector3(0.32, 0.05, 0.05), Color(0.92, 0.76, 0.2))
	_box(st, Vector3(-0.9, 1.55, -1.82), Vector3(0.32, 0.32, 0.05), Color(0.55, 0.78, 0.9))
	return _commit(st)

static func _raptor() -> ArrayMesh:
	var st := _begin()
	var hide := Color(0.22, 0.62, 0.28)
	var belly := Color(0.78, 0.72, 0.4)
	var dark := Color(0.12, 0.32, 0.16)
	_ellip(st, Vector3(0, 0.7, 0), Vector3(0.28, 0.32, 0.55), hide)
	_box(st, Vector3(0, 0.62, 0.05), Vector3(0.22, 0.16, 0.5), belly)
	_beam(st, Vector3(0, 0.7, -0.4), Vector3(0, 0.85, -1.15), 0.12, hide)
	_beam(st, Vector3(0, 0.85, 0.4), Vector3(0.15, 1.15, 0.75), 0.14, hide)
	_box(st, Vector3(0.2, 1.15, 0.9), Vector3(0.28, 0.18, 0.36), hide)
	_box(st, Vector3(0.28, 1.05, 1.05), Vector3(0.16, 0.08, 0.22), Color(0.85, 0.3, 0.22))
	_cone(st, Vector3(0.22, 1.02, 1.12), 0.02, 0.07, Color(0.95, 0.94, 0.86), 4)
	_cone(st, Vector3(0.3, 1.0, 1.14), 0.02, 0.06, Color(0.95, 0.94, 0.86), 4)
	_box(st, Vector3(-0.12, 0.4, 0.15), Vector3(0.12, 0.55, 0.12), dark)
	_box(st, Vector3(0.12, 0.4, -0.1), Vector3(0.12, 0.55, 0.12), dark)
	_box(st, Vector3(-0.12, 0.12, 0.22), Vector3(0.16, 0.06, 0.28), dark)
	_box(st, Vector3(-0.28, 0.85, 0.2), Vector3(0.22, 0.06, 0.1), hide)
	_eye(st, Vector3(0.28, 1.22, 1.02), 0.04)
	return _commit(st)

static func _trike() -> ArrayMesh:
	var st := _begin()
	var hide := Color(0.36, 0.62, 0.28)
	var frill := Color(0.72, 0.42, 0.22)
	_ellip(st, Vector3(0, 0.7, 0), Vector3(0.55, 0.4, 0.85), hide)
	_box(st, Vector3(0, 0.95, 0.7), Vector3(0.9, 0.7, 0.12), frill)
	_box(st, Vector3(0, 0.78, 0.95), Vector3(0.4, 0.32, 0.4), hide)
	_cone(st, Vector3(0, 0.85, 1.05), 0.06, 0.35, Color(0.9, 0.86, 0.7), 6)
	_cone(st, Vector3(-0.18, 0.95, 0.85), 0.05, 0.22, Color(0.9, 0.86, 0.7), 6)
	_cone(st, Vector3(0.18, 0.95, 0.85), 0.05, 0.22, Color(0.9, 0.86, 0.7), 6)
	_legs4(st, 0.28, 0.32, 0.4, 0.5, hide)
	_beam(st, Vector3(0, 0.65, -0.7), Vector3(0, 0.55, -1.15), 0.16, hide)
	_eye(st, Vector3(-0.12, 0.82, 1.12), 0.045)
	_eye(st, Vector3(0.12, 0.82, 1.12), 0.045)
	return _commit(st)

static func _trex() -> ArrayMesh:
	var st := _begin()
	var hide := Color(0.55, 0.62, 0.22)
	var dark := Color(0.28, 0.36, 0.12)
	_ellip(st, Vector3(0, 1.15, 0.1), Vector3(0.55, 0.55, 0.9), hide)
	_beam(st, Vector3(0, 1.15, -0.7), Vector3(0, 0.85, -1.9), 0.28, dark)
	_beam(st, Vector3(0, 1.45, 0.7), Vector3(0.15, 1.9, 1.15), 0.32, hide)
	_box(st, Vector3(0.25, 1.95, 1.4), Vector3(0.7, 0.5, 0.85), hide)
	_box(st, Vector3(0.35, 1.75, 1.75), Vector3(0.45, 0.18, 0.4), Color(0.72, 0.28, 0.18))
	_box(st, Vector3(-0.15, 1.7, 0.85), Vector3(0.12, 0.28, 0.35), hide)
	_box(st, Vector3(0.15, 1.7, 0.85), Vector3(0.12, 0.28, 0.35), hide)
	_box(st, Vector3(-0.28, 0.6, 0.25), Vector3(0.28, 1.15, 0.32), dark)
	_box(st, Vector3(0.28, 0.6, -0.15), Vector3(0.28, 1.15, 0.32), dark)
	_box(st, Vector3(-0.28, 0.12, 0.4), Vector3(0.36, 0.1, 0.5), dark)
	_eye(st, Vector3(0.4, 2.1, 1.7), 0.06)
	_box(st, Vector3(0, 1.62, -0.15), Vector3(0.08, 0.22, 0.08), dark)
	_box(st, Vector3(0, 1.48, 0.2), Vector3(0.08, 0.2, 0.08), dark)
	_box(st, Vector3(0, 1.35, 0.5), Vector3(0.07, 0.16, 0.07), dark)
	for i in 4:
		_cone(st, Vector3(0.22, 1.66, 1.58 + float(i) * 0.08), 0.02, 0.07, Color(0.95, 0.93, 0.84), 4)
	_box(st, Vector3(-0.15, 1.55, 0.95), Vector3(0.08, 0.08, 0.16), Color(0.85, 0.32, 0.22))
	return _commit(st)

static func _brachio() -> ArrayMesh:
	var st := _begin()
	var hide := Color(0.42, 0.58, 0.32)
	var dark := Color(0.28, 0.4, 0.22)
	_ellip(st, Vector3(0, 1.15, 0), Vector3(0.7, 0.55, 1.15), hide)
	_beam(st, Vector3(0, 1.4, 0.8), Vector3(0.1, 3.3, 1.15), 0.28, hide)
	_ellip(st, Vector3(0.15, 3.45, 1.25), Vector3(0.22, 0.18, 0.32), hide)
	_beam(st, Vector3(0, 1.15, -1.0), Vector3(0, 0.8, -2.3), 0.22, dark)
	_legs4(st, 0.5, 0.4, 0.55, 0.95, dark)
	_eye(st, Vector3(0.12, 3.5, 1.5), 0.04)
	return _commit(st)

static func _hut() -> ArrayMesh:
	var st := _begin()
	var thatch := Color(0.72, 0.58, 0.22)
	var wood := Color(0.45, 0.3, 0.16)
	var leaf := Color(0.2, 0.55, 0.22)
	_box(st, Vector3(-0.7, 0.45, -0.5), Vector3(0.1, 0.9, 0.1), wood)
	_box(st, Vector3(0.7, 0.45, -0.5), Vector3(0.1, 0.9, 0.1), wood)
	_box(st, Vector3(-0.7, 0.45, 0.5), Vector3(0.1, 0.9, 0.1), wood)
	_box(st, Vector3(0.7, 0.45, 0.5), Vector3(0.1, 0.9, 0.1), wood)
	_box(st, Vector3(0, 0.95, 0), Vector3(1.7, 0.9, 1.4), wood)
	_cone(st, Vector3(0, 1.35, 0), 1.35, 1.15, thatch, 8)
	_box(st, Vector3(0, 1.15, 0.72), Vector3(0.4, 0.55, 0.08), Color(0.3, 0.18, 0.1))
	_box(st, Vector3(0.55, 1.7, 0.2), Vector3(0.35, 0.08, 0.2), leaf)
	return _commit(st)

static func _volcano() -> ArrayMesh:
	var st := _begin()
	var rock := Color(0.32, 0.28, 0.26)
	var lava := Color(0.95, 0.32, 0.08)
	_cone(st, Vector3.ZERO, 2.5, 3.6, rock, 12)
	_cyl(st, Vector3(0, 3.15, 0), 0.7, 0.35, lava, 10)
	_cone(st, Vector3(0, 3.4, 0), 0.35, 0.45, Color(0.98, 0.7, 0.15), 8)
	_box(st, Vector3(1.5, 0.35, 0.8), Vector3(0.9, 0.55, 0.7), Color(0.22, 0.2, 0.2))
	_box(st, Vector3(-1.3, 0.28, -0.9), Vector3(0.8, 0.45, 0.6), Color(0.26, 0.22, 0.2))
	_box(st, Vector3(0.4, 1.6, 1.5), Vector3(0.35, 0.2, 0.7), lava)
	return _commit(st)

static func _anchor() -> ArrayMesh:
	var st := _begin()
	var iron := Color(0.25, 0.28, 0.32)
	_cyl(st, Vector3(0, 0.85, 0), 0.18, 0.08, iron, 10)
	_box(st, Vector3(0, 0.55, 0), Vector3(0.1, 0.7, 0.1), iron)
	_box(st, Vector3(0, 0.95, 0), Vector3(0.55, 0.08, 0.08), iron)
	_beam(st, Vector3(-0.28, 0.2, 0), Vector3(-0.45, 0.02, 0.12), 0.08, iron)
	_beam(st, Vector3(0.28, 0.2, 0), Vector3(0.45, 0.02, 0.12), 0.08, iron)
	_box(st, Vector3(0, 0.18, 0), Vector3(0.62, 0.08, 0.1), iron)
	return _commit(st)

static func _tavern() -> ArrayMesh:
	var st := _begin()
	var wall := Color(0.62, 0.42, 0.24)
	var roof := Color(0.45, 0.18, 0.16)
	var sign := Color(0.9, 0.78, 0.3)
	_box(st, Vector3(0, 1.15, 0), Vector3(2.6, 2.1, 2.0), wall)
	_beam(st, Vector3(-1.4, 2.15, -1.0), Vector3(0, 2.9, -1.0), 0.14, roof)
	_beam(st, Vector3(1.4, 2.15, -1.0), Vector3(0, 2.9, -1.0), 0.14, roof)
	_beam(st, Vector3(-1.4, 2.15, 1.0), Vector3(0, 2.9, 1.0), 0.14, roof)
	_beam(st, Vector3(1.4, 2.15, 1.0), Vector3(0, 2.9, 1.0), 0.14, roof)
	_box(st, Vector3(0, 0.6, 1.02), Vector3(0.6, 1.05, 0.08), Color(0.35, 0.2, 0.12))
	_box(st, Vector3(-0.7, 1.35, 1.04), Vector3(0.4, 0.4, 0.06), Color(0.55, 0.75, 0.88))
	_box(st, Vector3(0.7, 1.35, 1.04), Vector3(0.4, 0.4, 0.06), Color(0.55, 0.75, 0.88))
	_box(st, Vector3(1.15, 1.7, 1.2), Vector3(0.7, 0.4, 0.08), sign)
	_cyl(st, Vector3(1.15, 0, 1.35), 0.06, 1.9, Color(0.3, 0.2, 0.12), 6)
	return _commit(st)

static func _skier() -> ArrayMesh:
	var st := _begin()
	var suit := Color(0.15, 0.45, 0.85)
	var ski := Color(0.9, 0.25, 0.28)
	_box(st, Vector3(0, 0.7, 0), Vector3(0.36, 0.55, 0.22), suit)
	_ellip(st, Vector3(0, 1.12, 0), Vector3(0.14, 0.14, 0.14), Color(0.92, 0.74, 0.58))
	_box(st, Vector3(0, 1.24, 0), Vector3(0.2, 0.1, 0.2), Color(0.85, 0.2, 0.25))
	_box(st, Vector3(-0.22, 0.75, 0), Vector3(0.1, 0.4, 0.1), suit)
	_box(st, Vector3(0.22, 0.75, 0), Vector3(0.1, 0.4, 0.1), suit)
	_box(st, Vector3(-0.1, 0.28, 0), Vector3(0.1, 0.45, 0.1), Color(0.2, 0.22, 0.28))
	_box(st, Vector3(0.1, 0.28, 0), Vector3(0.1, 0.45, 0.1), Color(0.2, 0.22, 0.28))
	_box(st, Vector3(-0.1, 0.06, 0.05), Vector3(0.1, 0.04, 0.9), ski)
	_box(st, Vector3(0.1, 0.06, 0.05), Vector3(0.1, 0.04, 0.9), ski)
	_beam(st, Vector3(-0.2, 0.5, 0.15), Vector3(-0.35, 1.05, -0.1), 0.04, Color(0.35, 0.28, 0.2))
	_beam(st, Vector3(0.2, 0.5, 0.15), Vector3(0.35, 1.05, -0.1), 0.04, Color(0.35, 0.28, 0.2))
	return _commit(st)

static func _cabin() -> ArrayMesh:
	var st := _begin()
	var log := Color(0.55, 0.34, 0.18)
	var snow := Color(0.94, 0.96, 0.98)
	for i in 5:
		_box(st, Vector3(0, 0.28 + float(i) * 0.32, 0), Vector3(2.3, 0.26, 1.8), log if i % 2 == 0 else Color(0.48, 0.3, 0.16))
	_beam(st, Vector3(-1.2, 1.85, -0.9), Vector3(0, 2.55, -0.9), 0.16, snow)
	_beam(st, Vector3(1.2, 1.85, -0.9), Vector3(0, 2.55, -0.9), 0.16, snow)
	_beam(st, Vector3(-1.2, 1.85, 0.9), Vector3(0, 2.55, 0.9), 0.16, snow)
	_beam(st, Vector3(1.2, 1.85, 0.9), Vector3(0, 2.55, 0.9), 0.16, snow)
	_box(st, Vector3(0, 0.55, 0.92), Vector3(0.45, 0.8, 0.08), Color(0.32, 0.18, 0.1))
	_box(st, Vector3(-0.6, 1.15, 0.94), Vector3(0.35, 0.35, 0.06), Color(0.95, 0.82, 0.35))
	_box(st, Vector3(0.7, 1.6, 0), Vector3(0.28, 0.7, 0.28), Color(0.4, 0.28, 0.22))
	_box(st, Vector3(0.7, 2.05, 0), Vector3(0.4, 0.16, 0.4), Color(0.35, 0.35, 0.38))
	return _commit(st)

static func _skilift() -> ArrayMesh:
	var st := _begin()
	var steel := Color(0.55, 0.6, 0.66)
	var red := Color(0.8, 0.2, 0.22)
	_box(st, Vector3(-1.3, 1.6, 0), Vector3(0.12, 3.2, 0.12), steel)
	_box(st, Vector3(1.3, 1.3, 0), Vector3(0.12, 2.6, 0.12), steel)
	_beam(st, Vector3(-1.3, 3.15, 0), Vector3(1.3, 2.55, 0), 0.08, steel)
	_box(st, Vector3(-0.4, 2.55, 0), Vector3(0.35, 0.28, 0.28), red)
	_beam(st, Vector3(-0.4, 2.7, 0), Vector3(-0.4, 2.95, 0), 0.05, steel)
	_box(st, Vector3(0.55, 2.15, 0), Vector3(0.35, 0.28, 0.28), Color(0.2, 0.45, 0.8))
	_beam(st, Vector3(0.55, 2.3, 0), Vector3(0.55, 2.7, 0), 0.05, steel)
	return _commit(st)

static func _icecastle() -> ArrayMesh:
	var st := _begin()
	var ice := Color(0.78, 0.9, 0.98)
	var deep := Color(0.45, 0.68, 0.9)
	var roof := Color(0.55, 0.78, 0.95)
	_box(st, Vector3(0, 1.3, 0), Vector3(3.2, 2.4, 2.4), ice)
	_cyl(st, Vector3(-1.3, 0, -0.8), 0.45, 3.4, deep, 8)
	_cyl(st, Vector3(1.3, 0, -0.8), 0.45, 3.6, deep, 8)
	_cyl(st, Vector3(0, 0, 0), 0.5, 4.2, ice, 8)
	_cone(st, Vector3(-1.3, 3.4, -0.8), 0.55, 0.9, roof, 8)
	_cone(st, Vector3(1.3, 3.6, -0.8), 0.55, 0.9, roof, 8)
	_cone(st, Vector3(0, 4.2, 0), 0.6, 1.1, Color(0.9, 0.95, 1.0), 8)
	_box(st, Vector3(0, 0.7, 1.22), Vector3(0.55, 1.2, 0.08), Color(0.35, 0.55, 0.78))
	_box(st, Vector3(0, 5.15, 0), Vector3(0.08, 0.4, 0.08), Color(0.7, 0.85, 0.95))
	return _commit(st)

static func _camel() -> ArrayMesh:
	var st := _begin()
	var hide := Color(0.78, 0.6, 0.32)
	var dark := Color(0.55, 0.4, 0.2)
	_ellip(st, Vector3(0, 0.85, 0), Vector3(0.32, 0.28, 0.7), hide)
	_ellip(st, Vector3(0, 1.2, 0.05), Vector3(0.22, 0.2, 0.28), hide)
	_beam(st, Vector3(0, 0.95, 0.55), Vector3(0.05, 1.35, 0.95), 0.14, hide)
	_box(st, Vector3(0.08, 1.4, 1.1), Vector3(0.22, 0.16, 0.32), hide)
	_box(st, Vector3(0.05, 1.52, 1.05), Vector3(0.08, 0.08, 0.1), dark)
	_legs4(st, 0.38, 0.18, 0.35, 0.7, dark)
	_eye(st, Vector3(0.12, 1.46, 1.24), 0.035)
	return _commit(st)

static func _adobe() -> ArrayMesh:
	var st := _begin()
	var clay := Color(0.82, 0.58, 0.32)
	var dark := Color(0.55, 0.32, 0.18)
	_box(st, Vector3(0, 1.05, 0), Vector3(2.4, 2.0, 1.9), clay)
	_box(st, Vector3(0, 2.1, 0), Vector3(2.7, 0.18, 2.15), Color(0.9, 0.7, 0.4))
	_box(st, Vector3(-0.9, 2.2, 0.4), Vector3(0.5, 0.1, 0.12), dark)
	_box(st, Vector3(0.2, 2.2, -0.3), Vector3(0.5, 0.1, 0.12), dark)
	_box(st, Vector3(0.9, 2.2, 0.2), Vector3(0.45, 0.1, 0.12), dark)
	_box(st, Vector3(0, 0.55, 0.98), Vector3(0.45, 0.95, 0.08), dark)
	_box(st, Vector3(-0.65, 1.25, 0.98), Vector3(0.4, 0.4, 0.06), Color(0.35, 0.55, 0.7))
	_box(st, Vector3(0.7, 1.25, 0.98), Vector3(0.35, 0.45, 0.06), Color(0.9, 0.8, 0.45))
	return _commit(st)

static func _pyramid() -> ArrayMesh:
	var st := _begin()
	var sand := Color(0.9, 0.74, 0.4)
	var shade := Color(0.72, 0.55, 0.28)
	_box(st, Vector3(0, 0.35, 0), Vector3(3.4, 0.7, 3.4), sand)
	_box(st, Vector3(0, 1.0, 0), Vector3(2.6, 0.6, 2.6), shade)
	_box(st, Vector3(0, 1.55, 0), Vector3(1.85, 0.5, 1.85), sand)
	_box(st, Vector3(0, 2.0, 0), Vector3(1.15, 0.42, 1.15), shade)
	_box(st, Vector3(0, 2.35, 0), Vector3(0.55, 0.3, 0.55), Color(0.95, 0.82, 0.48))
	_box(st, Vector3(0, 0.4, 1.55), Vector3(0.4, 0.55, 0.2), Color(0.45, 0.3, 0.16))
	return _commit(st)

static func _sphinx() -> ArrayMesh:
	var st := _begin()
	var stone := Color(0.84, 0.68, 0.38)
	var dark := Color(0.55, 0.4, 0.22)
	var gold := Color(0.9, 0.72, 0.28)
	_box(st, Vector3(0, 0.55, 0), Vector3(1.15, 0.9, 2.5), stone)
	_box(st, Vector3(-0.45, 0.28, 0.7), Vector3(0.35, 0.4, 0.7), stone)
	_box(st, Vector3(0.45, 0.28, 0.7), Vector3(0.35, 0.4, 0.7), stone)
	_box(st, Vector3(0, 1.15, 1.15), Vector3(0.55, 0.55, 0.5), stone)
	_box(st, Vector3(0, 1.25, 1.05), Vector3(0.7, 0.18, 0.55), gold)
	_box(st, Vector3(-0.28, 0.95, 1.15), Vector3(0.12, 0.45, 0.35), gold)
	_box(st, Vector3(0.28, 0.95, 1.15), Vector3(0.12, 0.45, 0.35), gold)
	_box(st, Vector3(0, 1.05, 1.4), Vector3(0.16, 0.1, 0.12), dark)
	_beam(st, Vector3(0, 0.6, -1.15), Vector3(0, 0.45, -1.6), 0.16, stone)
	_eye(st, Vector3(-0.12, 1.22, 1.38), 0.04)
	_eye(st, Vector3(0.12, 1.22, 1.38), 0.04)
	return _commit(st)

static func _ball() -> ArrayMesh:
	var st := _begin()
	_ellip(st, Vector3(0, 0.28, 0), Vector3(0.28, 0.28, 0.28), Color(0.2, 0.48, 0.95), 10, 6, Color(0.95, 0.82, 0.18))
	return _commit(st)

static func _teddy() -> ArrayMesh:
	var st := _begin()
	var fur := Color(0.62, 0.4, 0.22)
	var light := Color(0.82, 0.62, 0.4)
	_ellip(st, Vector3(0, 0.48, 0), Vector3(0.38, 0.36, 0.3), fur)
	_ellip(st, Vector3(0, 0.95, 0.05), Vector3(0.28, 0.26, 0.24), fur)
	_ellip(st, Vector3(-0.2, 1.18, 0), Vector3(0.1, 0.1, 0.08), fur)
	_ellip(st, Vector3(0.2, 1.18, 0), Vector3(0.1, 0.1, 0.08), fur)
	_ellip(st, Vector3(0, 0.88, 0.2), Vector3(0.12, 0.1, 0.1), light)
	_box(st, Vector3(0, 0.84, 0.28), Vector3(0.06, 0.04, 0.04), Color(0.25, 0.14, 0.1))
	_box(st, Vector3(-0.4, 0.45, 0), Vector3(0.16, 0.4, 0.16), fur)
	_box(st, Vector3(0.4, 0.45, 0), Vector3(0.16, 0.4, 0.16), fur)
	_box(st, Vector3(-0.14, 0.16, 0), Vector3(0.16, 0.28, 0.16), fur)
	_box(st, Vector3(0.14, 0.16, 0), Vector3(0.16, 0.28, 0.16), fur)
	_box(st, Vector3(0, 0.7, 0.28), Vector3(0.16, 0.12, 0.04), Color(0.85, 0.2, 0.28))
	_eye(st, Vector3(-0.08, 0.98, 0.24), 0.04)
	_eye(st, Vector3(0.08, 0.98, 0.24), 0.04)
	return _commit(st)

static func _robot() -> ArrayMesh:
	var st := _begin()
	var body := Color(0.72, 0.76, 0.82)
	var dark := Color(0.25, 0.3, 0.38)
	_box(st, Vector3(0, 0.7, 0), Vector3(0.7, 0.75, 0.5), body)
	_box(st, Vector3(0, 1.25, 0), Vector3(0.48, 0.4, 0.42), Color(0.4, 0.78, 0.9))
	_box(st, Vector3(0, 1.25, 0.2), Vector3(0.32, 0.1, 0.06), Color(0.15, 0.85, 0.95))
	_box(st, Vector3(0, 1.52, 0), Vector3(0.06, 0.22, 0.06), Color(0.9, 0.3, 0.25))
	_box(st, Vector3(0, 1.64, 0), Vector3(0.1, 0.1, 0.1), Color(0.95, 0.3, 0.22))
	_box(st, Vector3(-0.48, 0.7, 0), Vector3(0.16, 0.55, 0.16), dark)
	_box(st, Vector3(0.48, 0.7, 0), Vector3(0.16, 0.55, 0.16), Color(0.9, 0.45, 0.18))
	_box(st, Vector3(-0.16, 0.22, 0), Vector3(0.16, 0.4, 0.18), dark)
	_box(st, Vector3(0.16, 0.22, 0), Vector3(0.16, 0.4, 0.18), dark)
	_box(st, Vector3(0, 0.85, 0.26), Vector3(0.16, 0.16, 0.04), Color(0.95, 0.82, 0.2))
	return _commit(st)

static func _dollhouse() -> ArrayMesh:
	var st := _begin()
	var wall := Color(0.98, 0.78, 0.84)
	var roof := Color(0.9, 0.35, 0.48)
	_box(st, Vector3(0, 1.15, 0), Vector3(2.0, 2.1, 1.5), wall)
	_beam(st, Vector3(-1.05, 2.15, -0.75), Vector3(0, 2.85, -0.75), 0.12, roof)
	_beam(st, Vector3(1.05, 2.15, -0.75), Vector3(0, 2.85, -0.75), 0.12, roof)
	_beam(st, Vector3(-1.05, 2.15, 0.75), Vector3(0, 2.85, 0.75), 0.12, roof)
	_beam(st, Vector3(1.05, 2.15, 0.75), Vector3(0, 2.85, 0.75), 0.12, roof)
	_box(st, Vector3(-0.5, 1.45, 0.78), Vector3(0.35, 0.35, 0.06), Color(0.45, 0.75, 0.95))
	_box(st, Vector3(0.5, 1.45, 0.78), Vector3(0.35, 0.35, 0.06), Color(0.45, 0.75, 0.95))
	_box(st, Vector3(-0.5, 0.7, 0.78), Vector3(0.35, 0.35, 0.06), Color(0.95, 0.85, 0.4))
	_box(st, Vector3(0, 0.5, 0.78), Vector3(0.4, 0.75, 0.08), Color(0.85, 0.45, 0.55))
	_box(st, Vector3(0.7, 2.3, 0), Vector3(0.22, 0.45, 0.22), Color(0.7, 0.3, 0.32))
	return _commit(st)

static func _blocktower() -> ArrayMesh:
	var st := _begin()
	var cols := [Color(0.9, 0.25, 0.22), Color(0.25, 0.5, 0.9), Color(0.95, 0.78, 0.18), Color(0.3, 0.72, 0.35), Color(0.9, 0.45, 0.7), Color(0.95, 0.55, 0.2)]
	for i in 6:
		var y := 0.35 + float(i) * 0.62
		var shift := 0.12 if i % 2 == 0 else -0.1
		_box(st, Vector3(shift, y, float(i % 2) * 0.08), Vector3(1.15 - float(i) * 0.06, 0.58, 1.15 - float(i) * 0.06), cols[i])
	return _commit(st)

static func _gantry() -> ArrayMesh:
	var st := _begin()
	var steel := Color(0.62, 0.66, 0.72)
	var red := Color(0.8, 0.22, 0.18)
	_cyl(st, Vector3(0, 0, 0), 1.3, 0.25, Color(0.35, 0.4, 0.48), 12)
	_box(st, Vector3(-1.15, 2.4, 0), Vector3(0.22, 4.6, 0.22), steel)
	_box(st, Vector3(-1.15, 2.4, 0.5), Vector3(0.12, 4.6, 0.12), steel)
	_beam(st, Vector3(-1.15, 4.5, 0), Vector3(0.3, 4.5, 0), 0.14, red)
	_cyl(st, Vector3(0.15, 0.25, 0), 0.28, 3.2, Color(0.9, 0.92, 0.94), 10)
	_cone(st, Vector3(0.15, 3.45, 0), 0.28, 0.7, red, 8)
	_box(st, Vector3(-1.15, 1.2, 0), Vector3(0.5, 0.1, 0.5), Color(0.95, 0.78, 0.2))
	return _commit(st)

static func _bat() -> ArrayMesh:
	var st := _begin()
	var hide := Color(0.22, 0.16, 0.28)
	_ellip(st, Vector3(0, 0.35, 0), Vector3(0.12, 0.1, 0.16), hide)
	_box(st, Vector3(-0.28, 0.38, 0), Vector3(0.4, 0.04, 0.22), Color(0.35, 0.22, 0.4))
	_box(st, Vector3(0.28, 0.38, 0), Vector3(0.4, 0.04, 0.22), Color(0.35, 0.22, 0.4))
	_box(st, Vector3(-0.08, 0.48, 0.02), Vector3(0.04, 0.1, 0.04), hide)
	_box(st, Vector3(0.08, 0.48, 0.02), Vector3(0.04, 0.1, 0.04), hide)
	_eye(st, Vector3(-0.04, 0.38, 0.14), 0.03)
	_eye(st, Vector3(0.04, 0.38, 0.14), 0.03)
	return _commit(st)

static func _crow() -> ArrayMesh:
	var st := _begin()
	var body := Color(0.12, 0.12, 0.14)
	_ellip(st, Vector3(0, 0.32, 0), Vector3(0.16, 0.14, 0.26), body)
	_ellip(st, Vector3(0, 0.42, 0.18), Vector3(0.1, 0.1, 0.12), body)
	_cone(st, Vector3(0, 0.4, 0.26), 0.04, 0.12, Color(0.9, 0.72, 0.18), 5)
	_box(st, Vector3(-0.16, 0.36, -0.02), Vector3(0.2, 0.04, 0.16), Color(0.2, 0.2, 0.24))
	_box(st, Vector3(0.16, 0.36, -0.02), Vector3(0.2, 0.04, 0.16), Color(0.2, 0.2, 0.24))
	_box(st, Vector3(0, 0.34, -0.26), Vector3(0.1, 0.04, 0.16), body)
	_box(st, Vector3(-0.06, 0.12, 0), Vector3(0.03, 0.2, 0.03), Color(0.35, 0.28, 0.2))
	_box(st, Vector3(0.06, 0.12, 0), Vector3(0.03, 0.2, 0.03), Color(0.35, 0.28, 0.2))
	_eye(st, Vector3(0.05, 0.44, 0.26), 0.025)
	return _commit(st)

static func _crooked() -> ArrayMesh:
	var st := _begin()
	var wall := Color(0.32, 0.26, 0.38)
	var roof := Color(0.18, 0.12, 0.22)
	_box_basis(st, Vector3(0, 1.2, 0), Vector3(1.8, 2.2, 1.5), Basis(Vector3(0.98, 0.08, 0), Vector3(-0.08, 0.98, 0), Vector3(0, 0, 1)), wall)
	_beam(st, Vector3(-1.0, 2.2, -0.7), Vector3(0.15, 3.05, -0.7), 0.14, roof)
	_beam(st, Vector3(1.0, 2.15, -0.7), Vector3(0.15, 3.05, -0.7), 0.14, roof)
	_beam(st, Vector3(-1.0, 2.2, 0.7), Vector3(0.15, 3.05, 0.7), 0.14, roof)
	_beam(st, Vector3(1.0, 2.15, 0.7), Vector3(0.15, 3.05, 0.7), 0.14, roof)
	_box(st, Vector3(0.15, 0.6, 0.8), Vector3(0.4, 1.0, 0.08), Color(0.12, 0.08, 0.14))
	_box(st, Vector3(-0.45, 1.55, 0.78), Vector3(0.32, 0.48, 0.06), Color(0.95, 0.78, 0.28))
	_box(st, Vector3(0.7, 2.6, 0.1), Vector3(0.22, 0.8, 0.22), Color(0.4, 0.32, 0.36))
	return _commit(st)

static func _gingerbread() -> ArrayMesh:
	var st := _begin()
	var dough := Color(0.62, 0.36, 0.18)
	var ice := Color(0.96, 0.94, 0.9)
	var candy := Color(0.9, 0.25, 0.35)
	_box(st, Vector3(0, 0.9, 0), Vector3(1.8, 1.6, 1.4), dough)
	_beam(st, Vector3(-0.95, 1.65, -0.7), Vector3(0, 2.35, -0.7), 0.12, ice)
	_beam(st, Vector3(0.95, 1.65, -0.7), Vector3(0, 2.35, -0.7), 0.12, ice)
	_beam(st, Vector3(-0.95, 1.65, 0.7), Vector3(0, 2.35, 0.7), 0.12, ice)
	_beam(st, Vector3(0.95, 1.65, 0.7), Vector3(0, 2.35, 0.7), 0.12, ice)
	_box(st, Vector3(0, 2.05, 0.72), Vector3(1.5, 0.08, 0.06), ice)
	_box(st, Vector3(0, 0.45, 0.72), Vector3(0.4, 0.7, 0.08), Color(0.85, 0.2, 0.25))
	_box(st, Vector3(-0.45, 1.1, 0.74), Vector3(0.28, 0.28, 0.06), Color(0.35, 0.7, 0.9))
	_box(st, Vector3(0.45, 1.1, 0.74), Vector3(0.28, 0.28, 0.06), Color(0.95, 0.8, 0.25))
	_ellip(st, Vector3(-0.55, 1.7, 0.6), Vector3(0.1, 0.1, 0.1), candy, 6, 4)
	_ellip(st, Vector3(0.5, 1.85, 0.55), Vector3(0.1, 0.1, 0.1), Color(0.3, 0.75, 0.45), 6, 4)
	_ellip(st, Vector3(0, 2.4, 0), Vector3(0.12, 0.12, 0.12), Color(0.95, 0.45, 0.55), 6, 4)
	_ellip(st, Vector3(-0.2, 1.95, 0.62), Vector3(0.08, 0.08, 0.06), Color(0.35, 0.75, 0.95), 5, 4)
	_ellip(st, Vector3(0.25, 1.55, 0.68), Vector3(0.08, 0.08, 0.06), Color(0.95, 0.8, 0.25), 5, 4)
	_box(st, Vector3(0, 1.68, 0.76), Vector3(1.2, 0.06, 0.05), ice)
	return _commit(st)

static func _candycastle() -> ArrayMesh:
	var st := _begin()
	var wall := Color(0.98, 0.72, 0.82)
	var pink := Color(0.95, 0.4, 0.6)
	var blue := Color(0.45, 0.75, 0.98)
	var yellow := Color(0.98, 0.86, 0.35)
	_box(st, Vector3(0, 1.2, 0), Vector3(3.4, 2.2, 2.4), wall)
	_cyl(st, Vector3(-1.4, 0, -0.7), 0.4, 3.1, pink, 8)
	_cyl(st, Vector3(1.4, 0, -0.7), 0.4, 3.4, blue, 8)
	_cyl(st, Vector3(0, 0, 0.2), 0.48, 3.8, yellow, 8)
	_cone(st, Vector3(-1.4, 3.1, -0.7), 0.55, 0.8, Color(0.98, 0.55, 0.7), 8)
	_cone(st, Vector3(1.4, 3.4, -0.7), 0.55, 0.85, Color(0.7, 0.9, 1.0), 8)
	_cone(st, Vector3(0, 3.8, 0.2), 0.62, 1.0, Color(0.98, 0.45, 0.55), 8)
	_box(st, Vector3(0, 0.6, 1.22), Vector3(0.5, 1.05, 0.08), Color(0.72, 0.3, 0.45))
	_box(st, Vector3(-0.7, 1.4, 1.24), Vector3(0.35, 0.4, 0.06), Color(0.98, 0.9, 0.5))
	_box(st, Vector3(0.7, 1.4, 1.24), Vector3(0.35, 0.4, 0.06), Color(0.7, 0.9, 0.98))
	_box(st, Vector3(0, 4.7, 0.2), Vector3(0.08, 0.35, 0.35), pink)
	_box(st, Vector3(0, 2.2, 1.24), Vector3(2.4, 0.1, 0.08), Color(0.98, 0.96, 0.94))
	_ellip(st, Vector3(-0.45, 1.7, 1.24), Vector3(0.1, 0.1, 0.05), Color(0.95, 0.35, 0.5), 6, 4)
	_ellip(st, Vector3(0.5, 1.95, 1.24), Vector3(0.1, 0.1, 0.05), blue, 6, 4)
	_ellip(st, Vector3(0.15, 1.35, 1.24), Vector3(0.08, 0.08, 0.05), yellow, 6, 4)
	_ellip(st, Vector3(-1.4, 2.4, -0.28), Vector3(0.1, 0.1, 0.1), yellow, 6, 4)
	_ellip(st, Vector3(1.4, 2.6, -0.28), Vector3(0.1, 0.1, 0.1), pink, 6, 4)
	return _commit(st)

static func _balloons() -> ArrayMesh:
	var st := _begin()
	_ellip(st, Vector3(-0.16, 0.85, 0), Vector3(0.18, 0.22, 0.18), Color(0.92, 0.22, 0.32))
	_ellip(st, Vector3(0.16, 0.9, 0.05), Vector3(0.18, 0.22, 0.18), Color(0.25, 0.55, 0.95))
	_ellip(st, Vector3(0, 1.05, -0.08), Vector3(0.18, 0.22, 0.18), Color(0.98, 0.78, 0.2))
	_beam(st, Vector3(-0.16, 0.62, 0), Vector3(0, 0.28, 0), 0.02, Color(0.85, 0.85, 0.88))
	_beam(st, Vector3(0.16, 0.66, 0), Vector3(0, 0.28, 0), 0.02, Color(0.85, 0.85, 0.88))
	_beam(st, Vector3(0, 0.82, 0), Vector3(0, 0.28, 0), 0.02, Color(0.85, 0.85, 0.88))
	_box(st, Vector3(0, 0.18, 0), Vector3(0.22, 0.16, 0.18), Color(0.55, 0.32, 0.18))
	return _commit(st)

static func _bumper() -> ArrayMesh:
	var st := _begin()
	var body := Color(0.15, 0.5, 0.95)
	var dark := Color(0.12, 0.13, 0.16)
	_cyl(st, Vector3.ZERO, 0.55, 0.32, body, 12)
	_cyl(st, Vector3(0, 0.28, 0), 0.4, 0.16, Color(0.95, 0.3, 0.38), 10)
	_box(st, Vector3(0, 0.38, 0), Vector3(0.12, 0.08, 0.55), Color(0.98, 0.86, 0.25))
	_wheel(st, Vector3(-0.35, 0.16, 0.28), 0.14, 0.1, dark)
	_wheel(st, Vector3(0.35, 0.16, 0.28), 0.14, 0.1, dark)
	_wheel(st, Vector3(-0.35, 0.16, -0.28), 0.14, 0.1, dark)
	_wheel(st, Vector3(0.35, 0.16, -0.28), 0.14, 0.1, dark)
	return _commit(st)

static func _teacups() -> ArrayMesh:
	var st := _begin()
	var cup := Color(0.95, 0.45, 0.55)
	var saucer := Color(0.98, 0.9, 0.55)
	_cyl(st, Vector3.ZERO, 1.15, 0.16, Color(0.35, 0.55, 0.85), 14)
	_cyl(st, Vector3(0, 0.16, 0), 0.12, 0.7, Color(0.9, 0.75, 0.3), 8)
	for i in 3:
		var a := TAU * float(i) / 3.0
		var p := Vector3(cos(a) * 0.62, 0.16, sin(a) * 0.62)
		_cyl(st, p, 0.28, 0.06, saucer, 8)
		_cyl(st, p + Vector3(0, 0.06, 0), 0.2, 0.28, cup, 8)
		_box(st, p + Vector3(0.22, 0.18, 0), Vector3(0.08, 0.12, 0.04), cup)
	return _commit(st)

static func _carousel() -> ArrayMesh:
	var st := _begin()
	var roof := Color(0.9, 0.28, 0.38)
	var gold := Color(0.95, 0.78, 0.28)
	var pole := Color(0.85, 0.7, 0.3)
	_cyl(st, Vector3.ZERO, 1.45, 0.2, Color(0.25, 0.45, 0.8), 14)
	_cyl(st, Vector3(0, 0.2, 0), 0.12, 1.7, pole, 8)
	_cone(st, Vector3(0, 1.7, 0), 1.55, 0.85, roof, 12)
	_cyl(st, Vector3(0, 1.55, 0), 1.5, 0.1, gold, 12)
	_box(st, Vector3(0, 2.6, 0), Vector3(0.08, 0.35, 0.28), Color(0.95, 0.9, 0.4))
	for i in 4:
		var a := TAU * float(i) / 4.0
		var p := Vector3(cos(a) * 0.85, 0.55, sin(a) * 0.85)
		var hide := Color(0.95, 0.85, 0.9) if i % 2 == 0 else Color(0.55, 0.75, 0.95)
		_box(st, p, Vector3(0.22, 0.28, 0.45), hide)
		_box(st, p + Vector3(0, 0.22, 0.18), Vector3(0.14, 0.14, 0.18), hide)
		_box(st, p + Vector3(0, 0.08, 0), Vector3(0.24, 0.06, 0.28), Color(0.72, 0.22, 0.28))
		_cyl(st, Vector3(cos(a) * 0.85, 0.2, sin(a) * 0.85), 0.04, 1.35, gold, 6)
		_box(st, Vector3(cos(a) * 1.35, 1.62, sin(a) * 1.35), Vector3(0.1, 0.1, 0.1), Color(0.98, 0.92, 0.45))
	return _commit(st)

static func _ferris() -> ArrayMesh:
	var st := _begin()
	var steel := Color(0.78, 0.82, 0.88)
	var red := Color(0.86, 0.22, 0.28)
	var gold := Color(0.95, 0.78, 0.22)
	var hub := Vector3(0, 2.7, 0)
	var radius := 2.15
	_beam(st, Vector3(-0.7, 0, -0.3), hub, 0.1, red)
	_beam(st, Vector3(0.7, 0, -0.3), hub, 0.1, Color(0.22, 0.48, 0.9))
	_beam(st, Vector3(0, 0, 0.55), hub, 0.1, gold)
	var prev := hub + Vector3(radius, 0, 0)
	for i in 16:
		var a := TAU * float(i + 1) / 16.0
		var p := hub + Vector3(cos(a) * radius, sin(a) * radius, 0)
		_beam(st, prev, p, 0.08, steel)
		prev = p
		if i % 2 == 0:
			_beam(st, hub, p, 0.05, gold)
			_box(st, p + Vector3(0, -0.18, 0), Vector3(0.22, 0.2, 0.22), Color(0.95, 0.4, 0.45) if i % 4 == 0 else Color(0.35, 0.7, 0.95))
	_box(st, hub, Vector3(0.28, 0.28, 0.28), red)
	_box(st, Vector3(0, 0.08, 0.05), Vector3(1.8, 0.14, 1.15), Color(0.22, 0.24, 0.3))
	_box(st, Vector3(0, 0.2, 0.55), Vector3(0.7, 0.16, 0.16), Color(0.9, 0.28, 0.32))
	return _commit(st)

static func _spotted_egg() -> ArrayMesh:
	var st := _begin()
	var shell := Color(0.96, 0.9, 0.78)
	var spot := Color(0.55, 0.36, 0.22)
	_ellip(st, Vector3(0, 0.22, 0), Vector3(0.16, 0.22, 0.14), shell, 8, 6)
	_ellip(st, Vector3(0.06, 0.3, 0.08), Vector3(0.035, 0.03, 0.03), spot, 5, 3)
	_ellip(st, Vector3(-0.05, 0.22, 0.1), Vector3(0.03, 0.025, 0.025), spot, 5, 3)
	_ellip(st, Vector3(0.02, 0.16, -0.08), Vector3(0.028, 0.022, 0.022), spot, 5, 3)
	return _commit(st)

static func _dino_nest() -> ArrayMesh:
	var st := _begin()
	var twig := Color(0.42, 0.28, 0.14)
	var dry := Color(0.62, 0.5, 0.24)
	var shell := Color(0.96, 0.9, 0.78)
	var spot := Color(0.52, 0.34, 0.2)
	for i in 10:
		var a := TAU * float(i) / 10.0
		var p := Vector3(cos(a) * 0.55, 0.08, sin(a) * 0.42)
		_box(st, p, Vector3(0.28, 0.08, 0.1), twig if i % 2 == 0 else dry)
	_ellip(st, Vector3(0, 0.16, 0), Vector3(0.42, 0.06, 0.3), dry, 8, 4)
	_ellip(st, Vector3(-0.12, 0.28, 0.02), Vector3(0.14, 0.18, 0.12), shell, 7, 5)
	_ellip(st, Vector3(0.14, 0.26, -0.04), Vector3(0.13, 0.16, 0.11), shell, 7, 5)
	_ellip(st, Vector3(0.02, 0.3, 0.12), Vector3(0.11, 0.14, 0.1), shell, 7, 5)
	_ellip(st, Vector3(-0.08, 0.38, 0.06), Vector3(0.03, 0.025, 0.02), spot, 4, 3)
	_ellip(st, Vector3(0.16, 0.34, -0.02), Vector3(0.028, 0.02, 0.02), spot, 4, 3)
	return _commit(st)

static func _dino_bone() -> ArrayMesh:
	var st := _begin()
	var bone := Color(0.93, 0.9, 0.8)
	var knob := Color(0.86, 0.82, 0.72)
	_beam(st, Vector3(-0.55, 0.12, -0.28), Vector3(0.55, 0.14, 0.28), 0.08, bone)
	_beam(st, Vector3(-0.5, 0.14, 0.26), Vector3(0.5, 0.12, -0.26), 0.07, bone)
	_ellip(st, Vector3(-0.58, 0.16, -0.3), Vector3(0.1, 0.08, 0.1), knob, 6, 4)
	_ellip(st, Vector3(0.58, 0.16, 0.3), Vector3(0.1, 0.08, 0.1), knob, 6, 4)
	_ellip(st, Vector3(-0.52, 0.16, 0.28), Vector3(0.09, 0.07, 0.09), knob, 6, 4)
	_ellip(st, Vector3(0.52, 0.16, -0.28), Vector3(0.09, 0.07, 0.09), knob, 6, 4)
	return _commit(st)

static func _vine() -> ArrayMesh:
	var st := _begin()
	var wood := Color(0.4, 0.26, 0.14)
	var leaf := Color(0.18, 0.5, 0.18)
	var lite := Color(0.32, 0.62, 0.22)
	_cyl(st, Vector3(0, 0, 0), 0.06, 1.35, wood, 6)
	_beam(st, Vector3(0, 1.2, 0), Vector3(0.35, 0.7, 0.1), 0.045, leaf)
	_beam(st, Vector3(0.15, 1.05, 0.05), Vector3(0.45, 0.4, -0.1), 0.04, lite)
	_beam(st, Vector3(0, 0.9, 0), Vector3(-0.32, 0.35, 0.12), 0.04, leaf)
	_ellip(st, Vector3(0.38, 0.62, 0.08), Vector3(0.16, 0.08, 0.1), leaf, 6, 4)
	_ellip(st, Vector3(0.48, 0.34, -0.08), Vector3(0.14, 0.07, 0.09), lite, 6, 4)
	_ellip(st, Vector3(-0.34, 0.3, 0.12), Vector3(0.15, 0.07, 0.1), leaf, 6, 4)
	_ellip(st, Vector3(0.1, 1.15, 0.05), Vector3(0.18, 0.08, 0.12), lite, 6, 4)
	return _commit(st)

static func _antenna() -> ArrayMesh:
	var st := _begin()
	var mast := Color(0.72, 0.76, 0.82)
	var dark := Color(0.22, 0.26, 0.32)
	var lamp := Color(0.95, 0.55, 0.18)
	_cyl(st, Vector3(0, 0, 0), 0.08, 2.4, mast, 6)
	_box(st, Vector3(0, 0.08, 0), Vector3(0.55, 0.08, 0.55), dark)
	_box(st, Vector3(0, 1.7, 0), Vector3(0.7, 0.04, 0.04), mast)
	_box(st, Vector3(0, 1.35, 0), Vector3(0.04, 0.04, 0.55), mast)
	_cyl(st, Vector3(0, 2.35, 0), 0.06, 0.12, lamp, 6)
	_cone(st, Vector3(0.28, 1.85, 0), 0.16, 0.08, Color(0.55, 0.78, 0.9), 8)
	_box(st, Vector3(0.28, 1.82, 0), Vector3(0.04, 0.16, 0.04), dark)
	return _commit(st)

static func _solar() -> ArrayMesh:
	var st := _begin()
	var cell := Color(0.15, 0.32, 0.62)
	var line := Color(0.08, 0.16, 0.32)
	var frame := Color(0.75, 0.78, 0.82)
	var leg := Color(0.45, 0.48, 0.52)
	_box(st, Vector3(0, 0.72, 0), Vector3(1.5, 0.06, 0.9), cell)
	for i in 3:
		_box(st, Vector3(-0.5 + float(i) * 0.5, 0.76, 0), Vector3(0.03, 0.02, 0.82), line)
	_box(st, Vector3(0, 0.76, 0), Vector3(1.4, 0.02, 0.03), line)
	_box(st, Vector3(0, 0.7, 0.46), Vector3(1.55, 0.05, 0.05), frame)
	_box(st, Vector3(0, 0.7, -0.46), Vector3(1.55, 0.05, 0.05), frame)
	_box(st, Vector3(-0.55, 0.36, 0), Vector3(0.06, 0.7, 0.06), leg)
	_box(st, Vector3(0.55, 0.36, 0), Vector3(0.06, 0.7, 0.06), leg)
	_box(st, Vector3(0, 0.06, 0), Vector3(0.9, 0.06, 0.4), frame)
	return _commit(st)

static func _sat_probe() -> ArrayMesh:
	var st := _begin()
	var body := Color(0.82, 0.84, 0.88)
	var panel := Color(0.16, 0.34, 0.68)
	var dish := Color(0.7, 0.74, 0.8)
	_box(st, Vector3(0, 0.28, 0), Vector3(0.22, 0.22, 0.22), body)
	_box(st, Vector3(-0.32, 0.28, 0), Vector3(0.38, 0.04, 0.18), panel)
	_box(st, Vector3(0.32, 0.28, 0), Vector3(0.38, 0.04, 0.18), panel)
	_box(st, Vector3(-0.32, 0.3, 0), Vector3(0.02, 0.01, 0.16), Color(0.08, 0.16, 0.32))
	_cone(st, Vector3(0, 0.38, 0.12), 0.1, 0.08, dish, 8)
	_cyl(st, Vector3(0, 0.46, 0), 0.03, 0.12, Color(0.9, 0.72, 0.28), 5)
	return _commit(st)

static func _candy_bench() -> ArrayMesh:
	var st := _begin()
	var wafer := Color(0.96, 0.86, 0.58)
	var choc := Color(0.55, 0.3, 0.16)
	var red := Color(0.86, 0.16, 0.18)
	var white := Color(0.97, 0.95, 0.9)
	for i in 5:
		_box(st, Vector3(-0.44 + float(i) * 0.22, 0.42, 0), Vector3(0.18, 0.07, 0.36), wafer if i % 2 == 0 else choc)
	for i in 4:
		_box(st, Vector3(-0.36 + float(i) * 0.24, 0.64, -0.14), Vector3(0.16, 0.22, 0.06), wafer if i % 2 == 0 else choc)
	for side in [-1.0, 1.0]:
		_cyl(st, Vector3(side * 0.42, 0.0, 0.08), 0.045, 0.16, red, 6)
		_cyl(st, Vector3(side * 0.42, 0.16, 0.08), 0.045, 0.14, white, 6)
		_cyl(st, Vector3(side * 0.42, 0.3, 0.08), 0.045, 0.12, red, 6)
		_box(st, Vector3(side * 0.42, 0.48, -0.02), Vector3(0.08, 0.08, 0.16), white)
		_box(st, Vector3(side * 0.42, 0.56, -0.1), Vector3(0.08, 0.12, 0.08), red)
	return _commit(st)

static func _pier() -> ArrayMesh:
	var st := _begin()
	var wood := Color(0.52, 0.34, 0.16)
	var post := Color(0.32, 0.22, 0.12)
	for i in 5:
		_box(st, Vector3(-0.7 + float(i) * 0.35, 0.22, 0), Vector3(0.28, 0.06, 0.7), wood)
	_box(st, Vector3(-0.62, 0.1, 0.28), Vector3(0.08, 0.2, 0.08), post)
	_box(st, Vector3(0.62, 0.1, 0.28), Vector3(0.08, 0.2, 0.08), post)
	_box(st, Vector3(-0.62, 0.1, -0.28), Vector3(0.08, 0.2, 0.08), post)
	_box(st, Vector3(0.62, 0.1, -0.28), Vector3(0.08, 0.2, 0.08), post)
	return _commit(st)

static func _skiff() -> ArrayMesh:
	var st := _begin()
	var hull := Color(0.55, 0.32, 0.16)
	var sail := Color(0.9, 0.9, 0.84)
	_box(st, Vector3(0, 0.16, 0), Vector3(0.55, 0.14, 1.15), hull)
	_box(st, Vector3(0, 0.26, 0.35), Vector3(0.4, 0.08, 0.28), Color(0.72, 0.48, 0.24))
	_box(st, Vector3(0, 0.55, -0.05), Vector3(0.04, 0.55, 0.04), Color(0.35, 0.24, 0.14))
	_box(st, Vector3(0.16, 0.7, -0.05), Vector3(0.28, 0.36, 0.04), sail)
	return _commit(st)

static func _toy_bench() -> ArrayMesh:
	var st := _begin()
	var red := Color(0.82, 0.24, 0.22)
	var yellow := Color(0.9, 0.74, 0.22)
	var blue := Color(0.28, 0.46, 0.78)
	var colors := [red, yellow, blue, red]
	for i in 4:
		_box(st, Vector3(0, 0.4, -0.12 + float(i) * 0.08), Vector3(1.05, 0.05, 0.055), colors[i])
	_box(st, Vector3(0, 0.58, -0.16), Vector3(1.05, 0.16, 0.05), yellow)
	_box(st, Vector3(0, 0.72, -0.16), Vector3(1.05, 0.08, 0.05), blue)
	_box(st, Vector3(-0.42, 0.22, 0), Vector3(0.08, 0.4, 0.28), red)
	_box(st, Vector3(0.42, 0.22, 0), Vector3(0.08, 0.4, 0.28), blue)
	return _commit(st)

static func _blossom() -> ArrayMesh:
	var st := _begin()
	var stem := Color(0.22, 0.55, 0.24)
	var colors := [Color(0.95, 0.38, 0.48), Color(0.98, 0.82, 0.28), Color(0.95, 0.55, 0.75), Color(0.45, 0.7, 0.95)]
	for i in 4:
		var a := TAU * float(i) / 4.0
		var p := Vector3(cos(a) * 0.16, 0.0, sin(a) * 0.14)
		_box(st, p + Vector3(0, 0.12, 0), Vector3(0.03, 0.24, 0.03), stem)
		_ellip(st, p + Vector3(0, 0.26, 0), Vector3(0.07, 0.05, 0.07), colors[i], 6, 4)
		_ellip(st, p + Vector3(0, 0.3, 0), Vector3(0.025, 0.02, 0.025), Color(0.98, 0.9, 0.35), 5, 3)
	return _commit(st)

static func _pebbles() -> ArrayMesh:
	var st := _begin()
	var tones := [Color(0.55, 0.52, 0.48), Color(0.42, 0.4, 0.38), Color(0.68, 0.62, 0.54), Color(0.36, 0.38, 0.4)]
	var spots := [Vector3(-0.1, 0.05, 0.04), Vector3(0.12, 0.04, -0.06), Vector3(0.02, 0.06, 0.12), Vector3(-0.04, 0.04, -0.12)]
	for i in spots.size():
		_ellip(st, spots[i], Vector3(0.08, 0.045, 0.07), tones[i], 6, 4)
	return _commit(st)

static func _puddle() -> ArrayMesh:
	var st := _begin()
	var wet := Color(0.82, 0.9, 0.96)
	_ellip(st, Vector3(0, 0.03, 0), Vector3(0.34, 0.02, 0.26), wet, 8, 4)
	_ellip(st, Vector3(0.08, 0.045, 0.04), Vector3(0.08, 0.012, 0.05), Color(0.95, 0.98, 1.0), 6, 3)
	return _commit(st)
