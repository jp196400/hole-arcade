extends Node3D
# Stage-1 hole.io-style prototype. Everything built procedurally from primitives.

const ROUND_TIME := 90.0
const CITY_HALF := 40.0
const SPEED := 0.06  # world units per screen pixel dragged
const FOLLOW_RATE := 18.0  # exponential catch-up toward the finger
const MAX_SPEED := 72.0  # world units per second; stops a touch spike from teleporting

var hole_pos := Vector3.ZERO
var drag_target := Vector3.ZERO
var hole_radius := 1.0
var score := 0
var time_left := ROUND_TIME
var playing := true
var objects: Array = []   # props still in the city
var falling: Array = []   # [{node, t}]
var kind_lists: Array = []
var kind_meshes: Array = []
var kind_multimeshes: Array = []

var hole_mesh: MeshInstance3D
var rim_mesh: MeshInstance3D
var cam: Camera3D
var cam_look := Vector3.ZERO
var cam_distance := 15.0
var score_lbl: Label
var timer_lbl: Label
var over_panel: Control
var over_lbl: Label
var debug_lbl: Label
var debug_on := false
var lit_mat: StandardMaterial3D
var shown_score := -1
var shown_sec := -1

func _ready() -> void:
	randomize()
	debug_on = _query_debug()
	lit_mat = _mat(Color.WHITE)
	lit_mat.vertex_color_use_as_albedo = true
	_build_world()
	_build_ui()
	_spawn_city()
	_prewarm_shaders()

func _mat(c: Color) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	return m

func _no_shadow(g: GeometryInstance3D) -> void:
	g.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

func _query_debug() -> bool:
	if not OS.has_feature("web"):
		return false
	var search := str(JavaScriptBridge.eval("window.location.search", true))
	return search.find("debug=1") != -1

func _with_color(src: Mesh, color: Color) -> ArrayMesh:
	var arrays := src.surface_get_arrays(0)
	var count := (arrays[Mesh.ARRAY_VERTEX] as PackedVector3Array).size()
	var cols := PackedColorArray()
	cols.resize(count)
	cols.fill(color)
	arrays[Mesh.ARRAY_COLOR] = cols
	var out := ArrayMesh.new()
	out.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return out

func _prewarm_shaders() -> void:
	# Safari compiles WebGL2 programs on first draw. Draw once during load.
	if DisplayServer.get_name() == "headless":
		return
	RenderingServer.force_draw(false)

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
	sun.shadow_enabled = false
	add_child(sun)
	var ground := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = Vector2(CITY_HALF * 2 + 10, CITY_HALF * 2 + 10)
	ground.mesh = _with_color(pm, Color(0.45, 0.5, 0.45))
	ground.material_override = lit_mat
	_no_shadow(ground)
	add_child(ground)
	var roads := MeshInstance3D.new()
	roads.mesh = _with_color(_merged_roads(), Color(0.25, 0.25, 0.28))
	roads.material_override = lit_mat
	_no_shadow(roads)
	add_child(roads)
	hole_mesh = MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = 1.0; cm.bottom_radius = 1.0; cm.height = 0.02
	hole_mesh.mesh = cm
	var hm := _mat(Color.BLACK); hm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	hole_mesh.material_override = hm
	_no_shadow(hole_mesh)
	hole_mesh.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	add_child(hole_mesh)
	rim_mesh = MeshInstance3D.new()
	var tm := TorusMesh.new(); tm.inner_radius = 0.95; tm.outer_radius = 1.08
	rim_mesh.mesh = _with_color(tm, Color(0.2, 0.6, 1.0))
	rim_mesh.material_override = lit_mat
	_no_shadow(rim_mesh)
	rim_mesh.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	add_child(rim_mesh)
	cam = Camera3D.new()
	cam.fov = 60
	cam.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	add_child(cam)
	cam_distance = 10.0 + hole_radius * 5.0
	cam_look = hole_pos
	cam.position = hole_pos + Vector3(0, cam_distance, cam_distance * 0.75)
	cam.look_at(cam_look, Vector3.UP)

func _merged_roads() -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in range(-4, 5):
		for horiz in [true, false]:
			var rm := PlaneMesh.new()
			rm.size = Vector2(CITY_HALF * 2, 2.5) if horiz else Vector2(2.5, CITY_HALF * 2)
			var at := Vector3(0, 0.005, i * 10) if horiz else Vector3(i * 10, 0.006, 0)
			st.append_from(rm, 0, Transform3D(Basis(), at))
	return st.commit()

func _kind_mesh(size: float, height: float) -> Mesh:
	if size >= 3.0 or size == 1.1 or size == 1.8:
		var b := BoxMesh.new()
		b.size = Vector3(size * 1.4, height, size * (1.4 if size >= 3.0 else 0.8))
		return b
	if size == 0.6:
		var c := CylinderMesh.new()
		c.top_radius = 0.0
		c.bottom_radius = size
		c.height = height
		c.radial_segments = 10
		return c
	var c2 := CylinderMesh.new()
	c2.top_radius = size * 0.8
	c2.bottom_radius = size
	c2.height = height
	c2.radial_segments = 10
	return c2

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
	kind_lists.resize(kinds.size())
	kind_meshes.resize(kinds.size())
	kind_multimeshes.resize(kinds.size())
	for i in kinds.size():
		kind_lists[i] = []
		var size: float = kinds[i][0]
		var height: float = kinds[i][1]
		kind_meshes[i] = _kind_mesh(size, height)
	for i in range(260):
		var ki := mini(int(pow(randf(), 1.8) * kinds.size()), kinds.size() - 1)
		var k: Array = kinds[ki]
		var p := Vector3(randf_range(-CITY_HALF, CITY_HALF), 0, randf_range(-CITY_HALF, CITY_HALF))
		if p.length() < 4.0: continue
		var ok := true
		var height: float = k[1]
		var center := p + Vector3(0, height * 0.5, 0)
		for o in objects:
			if o.center.distance_to(p) < o.size + k[0] + 0.3:
				ok = false
				break
		if not ok: continue
		var size: float = k[0]
		var col: Color = k[2]
		col = col.lightened(randf_range(-0.15, 0.15))
		var basis := Basis(Vector3.UP, randf() * TAU)
		var list: Array = kind_lists[ki]
		var obj := {
			"kind": ki,
			"index": list.size(),
			"pos": p,
			"center": center,
			"xform": Transform3D(basis, center),
			"size": size,
			"height": height,
			"points": k[3],
			"color": col,
		}
		list.append(obj)
		objects.append(obj)
	for ki in kinds.size():
		_build_kind_multimesh(ki)

func _build_kind_multimesh(ki: int) -> void:
	var list: Array = kind_lists[ki]
	if list.is_empty():
		return
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = true
	mm.mesh = kind_meshes[ki]
	mm.instance_count = list.size()
	mm.visible_instance_count = list.size()
	for obj in list:
		mm.set_instance_transform(obj.index, obj.xform)
		mm.set_instance_color(obj.index, obj.color)
	var inst := MultiMeshInstance3D.new()
	inst.multimesh = mm
	inst.material_override = lit_mat
	inst.custom_aabb = AABB(Vector3(-CITY_HALF, -2, -CITY_HALF), Vector3(CITY_HALF * 2, 40, CITY_HALF * 2))
	_no_shadow(inst)
	add_child(inst)
	kind_multimeshes[ki] = mm

func _remove_prop(o: Dictionary) -> void:
	var list: Array = kind_lists[o.kind]
	var mm: MultiMesh = kind_multimeshes[o.kind]
	var i: int = o.index
	var last: int = list.size() - 1
	if i != last:
		var swapped: Dictionary = list[last]
		swapped.index = i
		list[i] = swapped
		mm.set_instance_transform(i, swapped.xform)
		mm.set_instance_color(i, swapped.color)
	list.pop_back()
	mm.visible_instance_count = list.size()
	objects.erase(o)

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
	debug_lbl = Label.new()
	debug_lbl.position = Vector2(16, 78)
	debug_lbl.add_theme_font_size_override("font_size", 22)
	debug_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	debug_lbl.visible = debug_on
	ui.add_child(debug_lbl)

func _input(event: InputEvent) -> void:
	if event is InputEventScreenDrag and playing:
		# Relative drag moves the target. The hole eases toward it in _process.
		var d: Vector2 = event.relative * SPEED * (0.8 + hole_radius * 0.2)
		drag_target += Vector3(d.x, 0, d.y)
		drag_target.x = clampf(drag_target.x, -CITY_HALF, CITY_HALF)
		drag_target.z = clampf(drag_target.z, -CITY_HALF, CITY_HALF)
	elif event is InputEventScreenTouch and event.pressed and not playing:
		get_tree().reload_current_scene()

func _move_hole(delta: float) -> void:
	var to := drag_target - hole_pos
	var dist := to.length()
	if dist < 0.0001:
		return
	var alpha := 1.0 - exp(-FOLLOW_RATE * delta)
	var step := to * alpha
	var max_step := MAX_SPEED * (0.8 + hole_radius * 0.2) * delta
	if step.length() > max_step:
		step = to.normalized() * max_step
	# Never step past the target (large delta would otherwise overshoot the cap math).
	if step.length() > dist:
		step = to
	hole_pos += step
	hole_pos.x = clampf(hole_pos.x, -CITY_HALF, CITY_HALF)
	hole_pos.z = clampf(hole_pos.z, -CITY_HALF, CITY_HALF)

func _smooth_camera(delta: float) -> void:
	var want_h := 10.0 + hole_radius * 5.0
	cam_distance = lerpf(cam_distance, want_h, 1.0 - exp(-2.4 * delta))
	var want_pos := hole_pos + Vector3(0, cam_distance, cam_distance * 0.75)
	cam.position = cam.position.lerp(want_pos, 1.0 - exp(-4.5 * delta))
	cam_look = cam_look.lerp(hole_pos, 1.0 - exp(-6.0 * delta))
	cam.look_at(cam_look, Vector3.UP)

func _process(delta: float) -> void:
	# Drop browser hitches so one stalled frame cannot teleport the sim.
	delta = minf(delta, 1.0 / 20.0)
	if playing:
		time_left -= delta
		if time_left <= 0.0:
			time_left = 0.0; playing = false
			over_lbl.text = "Time's up!\nScore: %d\n\nTap to play again" % score
			over_panel.visible = true
		_move_hole(delta)
		_check_swallow()
	var target := 1.0 + sqrt(float(score)) * 0.35
	hole_radius = lerpf(hole_radius, target, 1.0 - exp(-3.0 * delta))
	hole_mesh.position = hole_pos + Vector3(0, 0.02, 0)
	hole_mesh.scale = Vector3(hole_radius, 1, hole_radius)
	rim_mesh.position = hole_pos + Vector3(0, 0.03, 0)
	rim_mesh.scale = Vector3(hole_radius, 0.3, hole_radius)
	var fall_pull := 1.0 - exp(-6.0 * delta)
	var fi := falling.size() - 1
	while fi >= 0:
		var f: Dictionary = falling[fi]
		f.t += delta
		var n: MeshInstance3D = f.node
		n.position.x = lerpf(n.position.x, hole_pos.x, fall_pull)
		n.position.z = lerpf(n.position.z, hole_pos.z, fall_pull)
		n.position.y -= delta * (4.0 + f.t * 25.0)
		n.rotation.x += delta * 3.0
		n.scale = Vector3.ONE * maxf(0.05, 1.0 - f.t * 1.2)
		if f.t > 0.8:
			n.queue_free()
			falling.remove_at(fi)
		fi -= 1
	_smooth_camera(delta)
	if score != shown_score:
		shown_score = score
		score_lbl.text = "Score: %d" % score
	var sec := ceili(time_left)
	if sec != shown_sec:
		shown_sec = sec
		timer_lbl.text = "%d s" % sec
	if debug_on:
		_update_debug(delta)

func _update_debug(delta: float) -> void:
	var frame_ms := delta * 1000.0
	var phys_ms := Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS) * 1000.0
	var draws := int(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME))
	var bodies := int(Performance.get_monitor(Performance.PHYSICS_3D_ACTIVE_OBJECTS))
	var fps := Engine.get_frames_per_second()
	var win := DisplayServer.window_get_size()
	debug_lbl.text = "FPS %d\nframe %.1f ms\nphysics %.2f ms\ndraws %d\nbodies %d\nview %dx%d" % [fps, frame_ms, phys_ms, draws, bodies, win.x, win.y]
	if OS.has_feature("web"):
		JavaScriptBridge.eval("window.__godotStats={fps:%d,frameMs:%.2f,physMs:%.2f,draws:%d,bodies:%d,vw:%d,vh:%d}" % [fps, frame_ms, phys_ms, draws, bodies, win.x, win.y], true)

func _check_swallow() -> void:
	var i := objects.size() - 1
	while i >= 0:
		var o: Dictionary = objects[i]
		var d := Vector2(o.pos.x - hole_pos.x, o.pos.z - hole_pos.z).length()
		if o.size < hole_radius * 0.9 and d < hole_radius - o.size * 0.5:
			var n := MeshInstance3D.new()
			n.mesh = _with_color(kind_meshes[o.kind], o.color)
			n.material_override = lit_mat
			n.transform = o.xform
			n.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
			_no_shadow(n)
			add_child(n)
			_remove_prop(o)
			falling.append({"node": n, "t": 0.0})
			score += int(o.points)
		i -= 1
