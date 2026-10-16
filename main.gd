extends Node3D
# Stage-1 hole.io-style prototype. Everything built procedurally from primitives.

const ROUND_TIME := 90.0
const CITY_HALF := 40.0
const SPEED := 0.06  # world units per screen pixel dragged

var hole_pos := Vector3.ZERO
var hole_radius := 1.0
var score := 0
var time_left := ROUND_TIME
var playing := true
var objects: Array = []   # [{node, size, points}]
var falling: Array = []   # [{node, t, start}]

var hole_mesh: MeshInstance3D
var rim_mesh: MeshInstance3D
var cam: Camera3D
var score_lbl: Label
var timer_lbl: Label
var over_panel: Control
var over_lbl: Label

func _ready() -> void:
	randomize()
	_build_world()
	_build_ui()
	_spawn_city()

func _mat(c: Color) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	return m

func _build_world() -> void:
	var env := WorldEnvironment.new()
	var e := Environment.new()
	e.background_mode = Environment.BG_COLOR
	e.background_color = Color(0.55, 0.78, 0.95)
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	e.ambient_light_color = Color(0.6, 0.6, 0.65)
	env.environment = e
	add_child(env)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-55, 35, 0)
	add_child(sun)
	var ground := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = Vector2(CITY_HALF * 2 + 10, CITY_HALF * 2 + 10)
	ground.mesh = pm
	ground.material_override = _mat(Color(0.45, 0.5, 0.45))
	add_child(ground)
	# roads grid
	for i in range(-4, 5):
		for horiz in [true, false]:
			var r := MeshInstance3D.new()
			var rm := PlaneMesh.new()
			rm.size = Vector2(CITY_HALF * 2, 2.5) if horiz else Vector2(2.5, CITY_HALF * 2)
			r.mesh = rm
			r.material_override = _mat(Color(0.25, 0.25, 0.28))
			r.position = Vector3(0, 0.005, i * 10) if horiz else Vector3(i * 10, 0.006, 0)
			add_child(r)
	hole_mesh = MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = 1.0; cm.bottom_radius = 1.0; cm.height = 0.02
	hole_mesh.mesh = cm
	var hm := _mat(Color.BLACK); hm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	hole_mesh.material_override = hm
	add_child(hole_mesh)
	rim_mesh = MeshInstance3D.new()
	var tm := TorusMesh.new(); tm.inner_radius = 0.95; tm.outer_radius = 1.08
	rim_mesh.mesh = tm
	rim_mesh.material_override = _mat(Color(0.2, 0.6, 1.0))
	add_child(rim_mesh)
	cam = Camera3D.new()
	cam.fov = 60
	add_child(cam)

func _spawn_city() -> void:
	# kinds: [size(footprint radius), height, color, points]
	var kinds := [
		[0.3, 0.3, Color(1, 0.8, 0.2), 1],    # cone/crate
		[0.4, 0.8, Color(0.9, 0.3, 0.3), 2],  # hydrant / bin
		[0.6, 1.2, Color(0.2, 0.7, 0.3), 3],  # tree
		[1.1, 0.9, Color(0.3, 0.5, 0.9), 6],  # car
		[1.8, 1.4, Color(0.95, 0.6, 0.2), 12],# truck/kiosk
		[3.0, 6.0, Color(0.8, 0.8, 0.85), 25],# house
		[4.0, 12.0, Color(0.6, 0.65, 0.75), 50] # tower
	]
	for i in range(260):
		var k: Array = kinds[mini(int(pow(randf(), 1.8) * kinds.size()), kinds.size() - 1)]
		var p := Vector3(randf_range(-CITY_HALF, CITY_HALF), 0, randf_range(-CITY_HALF, CITY_HALF))
		if p.length() < 4.0: continue
		var ok := true
		for o in objects:
			if o.node.position.distance_to(p) < o.size + k[0] + 0.3:
				ok = false; break
		if not ok: continue
		var n := MeshInstance3D.new()
		var size: float = k[0]
		if size >= 3.0 or size == 1.1 or size == 1.8:
			var b := BoxMesh.new()
			b.size = Vector3(size * 1.4, k[1], size * (1.4 if size >= 3.0 else 0.8))
			n.mesh = b
		elif size == 0.6:
			var c := CylinderMesh.new(); c.top_radius = 0.0; c.bottom_radius = size; c.height = k[1]
			n.mesh = c
		else:
			var c2 := CylinderMesh.new(); c2.top_radius = size * 0.8; c2.bottom_radius = size; c2.height = k[1]
			n.mesh = c2
		var col: Color = k[2]
		n.material_override = _mat(col.lightened(randf_range(-0.15, 0.15)))
		n.position = p + Vector3(0, k[1] * 0.5, 0)
		n.rotation.y = randf() * TAU
		add_child(n)
		objects.append({"node": n, "size": size, "points": k[3]})

func _build_ui() -> void:
	var ui := CanvasLayer.new(); add_child(ui)
	score_lbl = Label.new(); score_lbl.position = Vector2(20, 20)
	score_lbl.add_theme_font_size_override("font_size", 40)
	ui.add_child(score_lbl)
	timer_lbl = Label.new(); timer_lbl.position = Vector2(520, 20)
	timer_lbl.add_theme_font_size_override("font_size", 40)
	ui.add_child(timer_lbl)
	over_panel = ColorRect.new(); (over_panel as ColorRect).color = Color(0, 0, 0, 0.6)
	over_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	over_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	over_panel.visible = false
	ui.add_child(over_panel)
	over_lbl = Label.new()
	over_lbl.set_anchors_preset(Control.PRESET_FULL_RECT)
	over_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	over_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	over_lbl.add_theme_font_size_override("font_size", 56)
	over_panel.add_child(over_lbl)

func _input(event: InputEvent) -> void:
	if event is InputEventScreenDrag and playing:
		var d: Vector2 = event.relative * SPEED * (0.8 + hole_radius * 0.2)
		hole_pos += Vector3(d.x, 0, d.y)
		hole_pos.x = clampf(hole_pos.x, -CITY_HALF, CITY_HALF)
		hole_pos.z = clampf(hole_pos.z, -CITY_HALF, CITY_HALF)
	elif event is InputEventScreenTouch and event.pressed and not playing:
		get_tree().reload_current_scene()

func _process(delta: float) -> void:
	if playing:
		time_left -= delta
		if time_left <= 0.0:
			time_left = 0.0; playing = false
			over_lbl.text = "Time's up!\nScore: %d\n\nTap to play again" % score
			over_panel.visible = true
		_check_swallow()
	# grow smoothly toward target radius
	var target := 1.0 + sqrt(float(score)) * 0.35
	hole_radius = lerpf(hole_radius, target, delta * 3.0)
	hole_mesh.position = hole_pos + Vector3(0, 0.02, 0)
	hole_mesh.scale = Vector3(hole_radius, 1, hole_radius)
	rim_mesh.position = hole_pos + Vector3(0, 0.03, 0)
	rim_mesh.scale = Vector3(hole_radius, 0.3, hole_radius)
	for f in falling.duplicate():
		f.t += delta
		var n: MeshInstance3D = f.node
		n.position = n.position.lerp(Vector3(hole_pos.x, n.position.y, hole_pos.z), delta * 6.0)
		n.position.y -= delta * (4.0 + f.t * 25.0)
		n.rotation.x += delta * 3.0
		n.scale = Vector3.ONE * maxf(0.05, 1.0 - f.t * 1.2)
		if f.t > 0.8:
			n.queue_free(); falling.erase(f)
	var h := 10.0 + hole_radius * 5.0
	cam.position = cam.position.lerp(hole_pos + Vector3(0, h, h * 0.75), delta * 5.0)
	cam.look_at(hole_pos, Vector3.UP)
	score_lbl.text = "Score: %d" % score
	timer_lbl.text = "%d s" % ceili(time_left)

func _check_swallow() -> void:
	for o in objects.duplicate():
		var n: MeshInstance3D = o.node
		var d := Vector2(n.position.x - hole_pos.x, n.position.z - hole_pos.z).length()
		if o.size < hole_radius * 0.9 and d < hole_radius - o.size * 0.5:
			objects.erase(o)
			falling.append({"node": n, "t": 0.0})
			score += o.points
