extends Node3D

const ROUND_TIME := 120.0
const CITY_HALF := 40.0
const BASE_SPEED := 6.5  # world units / second at full stick, smallest hole; ?speed= multiplies this
const JOY_DEADZONE := 14.0
const JOY_FULL_RADIUS := 56.0
const STOP_RATE := 34.0  # release dumps speed in about a tenth of a second
const CAM_PITCH_DEG := 60.0  # degrees up from the ground; steep top-down
const CAM_FOV := 58.0
const CAM_BASE := 14.0
const CAM_PER_RADIUS := 2.5
const SPEED_SCREEN := 0.84  # world speed grows with the camera, a bit less than 1:1
const POOL := 8
const FIT_RATIO := 0.92
const POP_TIME := 0.32
const BUILD_SHA := "__BUILD_SHA__"
# Score to reach each level, and the hole radius once you are there.
const LEVEL_SCORE := [0, 10, 24, 46, 76, 116, 168, 232, 310, 400]
const LEVEL_RADIUS := [0.64, 1.0, 1.45, 2.0, 2.7, 3.5, 4.5, 5.7, 7.1, 8.6]

var hole_pos := Vector3.ZERO
var velocity := Vector3.ZERO
var joy_held := false
var joy_anchor := Vector2.ZERO
var joy_finger := Vector2.ZERO
var joy_id := 0
var hole_radius := LEVEL_RADIUS[0]
var shown_radius := LEVEL_RADIUS[0]
var level := 0
var pop_t := 0.0
var score := 0
var time_left := ROUND_TIME
var playing := true
var props: Array = []
var movers: Array = []
var active: Array = []
var kind_lists: Array = []
var kind_meshes: Array = []
var kind_shapes: Array = []
var kind_multimeshes: Array = []
var pool: Array = []
var pool_free: Array = []
var body_mat: PhysicsMaterial

var hole_mesh: MeshInstance3D
var rim_mesh: MeshInstance3D
var cam: Camera3D
var cam_look := Vector3.ZERO
var cam_distance := 16.0
var score_lbl: Label
var timer_lbl: Label
var level_lbl: Label
var sha_lbl: Label
var bar_fill: ColorRect
var over_panel: Control
var over_lbl: Label
var debug_lbl: Label
var debug_on := false
var speed_scale := 1.0
var joy_ui: Control
var lit_mat: StandardMaterial3D
var shown_score := -1
var shown_sec := -1
var shown_level := -1

func _ready() -> void:
	randomize()
	debug_on = _query_debug()
	speed_scale = _query_speed()
	lit_mat = StandardMaterial3D.new()
	lit_mat.albedo_color = Color.WHITE
	lit_mat.vertex_color_use_as_albedo = true
	lit_mat.roughness = 1.0
	lit_mat.metallic = 0.0
	body_mat = PhysicsMaterial.new()
	body_mat.friction = 0.45
	body_mat.bounce = 0.0
	_build_world()
	_build_ui()
	_make_pool()
	_spawn_city()
	_prewarm_shaders()

func _short_sha() -> String:
	var s := BUILD_SHA.strip_edges()
	if s.length() < 7 or s.begins_with("__"):
		return "dev"
	return s.substr(0, 7)

func _web_search() -> String:
	if not OS.has_feature("web"):
		return ""
	return str(JavaScriptBridge.eval("window.location.search", true))

func _query_debug() -> bool:
	return _web_search().find("debug=1") != -1

func _query_speed() -> float:
	var search := _web_search()
	var key := "speed="
	var at := search.find(key)
	if at == -1:
		return 1.0
	var rest := search.substr(at + key.length())
	var amp := rest.find("&")
	if amp != -1:
		rest = rest.substr(0, amp)
	var value := float(rest)
	if value <= 0.0:
		return 1.0
	return clampf(value, 0.05, 3.0)

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
	if DisplayServer.get_name() == "headless":
		return
	RenderingServer.force_draw(false)

func _no_shadow(g: GeometryInstance3D) -> void:
	g.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

func _style(l: Label, size: int) -> void:
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", Color.WHITE)
	l.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.88))
	l.add_theme_constant_override("outline_size", 8)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE

func _build_world() -> void:
	var env := WorldEnvironment.new()
	var e := Environment.new()
	e.background_mode = Environment.BG_COLOR
	e.background_color = Color(0.53, 0.82, 1.0)
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	e.ambient_light_color = Color(0.72, 0.76, 0.8)
	e.ambient_light_energy = 1.05
	env.environment = e
	add_child(env)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-58, 32, 0)
	sun.light_color = Color(1.0, 0.97, 0.9)
	sun.light_energy = 1.2
	sun.shadow_enabled = false
	add_child(sun)
	var ground := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = Vector2(CITY_HALF * 2 + 16, CITY_HALF * 2 + 16)
	ground.mesh = _with_color(pm, Color(0.4, 0.78, 0.34))
	ground.material_override = lit_mat
	_no_shadow(ground)
	add_child(ground)
	var roads := MeshInstance3D.new()
	roads.mesh = _with_color(_merged_roads(), Color(0.45, 0.5, 0.56))
	roads.material_override = lit_mat
	_no_shadow(roads)
	add_child(roads)
	var floor := StaticBody3D.new()
	floor.collision_layer = 1
	floor.collision_mask = 0
	floor.physics_material_override = body_mat
	var floor_shape := CollisionShape3D.new()
	var floor_box := BoxShape3D.new()
	floor_box.size = Vector3(CITY_HALF * 2 + 24, 2.0, CITY_HALF * 2 + 24)
	floor_shape.shape = floor_box
	floor.position = Vector3(0, -1.0, 0)
	floor.add_child(floor_shape)
	add_child(floor)
	hole_mesh = MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = 1.0
	cm.bottom_radius = 1.0
	cm.height = 0.02
	cm.radial_segments = 20
	hole_mesh.mesh = cm
	var hm := StandardMaterial3D.new()
	hm.albedo_color = Color.BLACK
	hm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	hole_mesh.material_override = hm
	_no_shadow(hole_mesh)
	hole_mesh.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	add_child(hole_mesh)
	rim_mesh = MeshInstance3D.new()
	var tm := TorusMesh.new()
	tm.inner_radius = 0.94
	tm.outer_radius = 1.08
	tm.rings = 10
	tm.ring_segments = 8
	rim_mesh.mesh = _with_color(tm, Color(0.15, 0.9, 1.0))
	rim_mesh.material_override = lit_mat
	_no_shadow(rim_mesh)
	rim_mesh.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	add_child(rim_mesh)
	cam = Camera3D.new()
	cam.fov = CAM_FOV
	cam.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	add_child(cam)
	cam_distance = _cam_dist_for(hole_radius)
	cam_look = hole_pos
	cam.position = hole_pos + _camera_offset(cam_distance)
	cam.look_at(cam_look, Vector3.UP)

func _merged_roads() -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in range(-4, 5):
		for horiz in [true, false]:
			var rm := PlaneMesh.new()
			rm.size = Vector2(CITY_HALF * 2, 3.1) if horiz else Vector2(3.1, CITY_HALF * 2)
			var at := Vector3(0, 0.02, i * 10) if horiz else Vector3(i * 10, 0.025, 0)
			st.append_from(rm, 0, Transform3D(Basis(), at))
	return st.commit()

func _camera_offset(dist: float) -> Vector3:
	var pitch := deg_to_rad(CAM_PITCH_DEG)
	return Vector3(0, sin(pitch) * dist, cos(pitch) * dist)

func _cam_dist_for(radius: float) -> float:
	return CAM_BASE + radius * CAM_PER_RADIUS

func _make_pool() -> void:
	for _i in POOL:
		var b := RigidBody3D.new()
		b.collision_layer = 2
		b.collision_mask = 1
		b.gravity_scale = 3.2
		b.linear_damp = 0.35
		b.angular_damp = 1.4
		b.can_sleep = false
		b.continuous_cd = false
		b.axis_lock_angular_y = true
		b.physics_material_override = body_mat
		b.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
		var cs := CollisionShape3D.new()
		cs.name = "Shape"
		b.add_child(cs)
		b.freeze = true
		b.position = Vector3(0, -50, 0)
		add_child(b)
		pool.append(b)
		pool_free.append(b)

func _spawn_city() -> void:
	# style: 0 person, 1 lamp, 2 bench, 3 tree, 4 car, 5 kiosk, 6 house, 7 tower
	# place: 0 sidewalk, 1 road, 2 yard
	# Large yards first so towers and houses claim a block before sidewalks fill in.
	var specs := [
		[7, 3.4, 11.5, 70, 0, 7, 2],
		[6, 2.55, 5.6, 36, 0, 12, 2],
		[5, 1.6, 2.5, 18, 0, 14, 2],
		[3, 0.75, 2.15, 6, 0, 36, 2],
		[2, 0.60, 0.48, 4, 0, 18, 0],
		[1, 0.18, 3.15, 2, 0, 26, 0],
		[0, 0.28, 1.55, 1, 1, 40, 0],
		[4, 1.15, 0.85, 10, 2, 20, 1],
	]
	kind_lists.resize(specs.size())
	kind_meshes.resize(specs.size())
	kind_shapes.resize(specs.size())
	kind_multimeshes.resize(specs.size())
	for i in specs.size():
		kind_lists[i] = []
		var size: float = specs[i][1]
		var height: float = specs[i][2]
		kind_meshes[i] = _mesh_for(int(specs[i][0]), size, height)
		kind_shapes[i] = _shape_for(int(specs[i][0]), size, height)
	for spec in specs:
		var count: int = spec[5]
		var made := 0
		var tries := 0
		while made < count and tries < count * 50:
			tries += 1
			var size: float = spec[1]
			var place: int = spec[6]
			var spot := _random_spot(place)
			var p: Vector3 = spot[0]
			var dir: Vector3 = spot[1]
			if not _accept(p, size, place):
				continue
			_add_prop(int(spec[0]), p, dir, size, float(spec[2]), int(spec[3]), int(spec[4]), place)
			made += 1
	for ki in specs.size():
		_build_kind_multimesh(ki)

func _mesh_for(style: int, size: float, height: float) -> Mesh:
	if style == 0:
		var cap := CapsuleMesh.new()
		cap.radius = 0.22
		cap.height = height
		cap.radial_segments = 8
		cap.rings = 3
		return cap
	if style == 1 or style == 3:
		var cyl := CylinderMesh.new()
		cyl.radial_segments = 8
		cyl.height = height
		if style == 3:
			cyl.top_radius = 0.0
			cyl.bottom_radius = size
		else:
			cyl.top_radius = size
			cyl.bottom_radius = size
		return cyl
	var box := BoxMesh.new()
	if style == 2:
		box.size = Vector3(size * 2.3, height, size * 0.85)
	elif style == 4:
		box.size = Vector3(size * 1.05, height, size * 2.0)
	else:
		box.size = Vector3(size * 2.0, height, size * 2.0)
	return box

func _shape_for(style: int, size: float, height: float) -> Shape3D:
	if style == 0:
		var cap := CapsuleShape3D.new()
		cap.radius = 0.22
		cap.height = height
		return cap
	if style == 1 or style == 3:
		var cyl := CylinderShape3D.new()
		cyl.height = height
		cyl.radius = size if style == 1 else size * 0.85
		return cyl
	var box := BoxShape3D.new()
	if style == 2:
		box.size = Vector3(size * 2.3, height, size * 0.85)
	elif style == 4:
		box.size = Vector3(size * 1.05, height, size * 2.0)
	else:
		box.size = Vector3(size * 2.0, height, size * 2.0)
	return box

func _kind_color(style: int) -> Color:
	var options: Array
	if style == 0:
		options = [Color(1, 0.32, 0.38), Color(0.25, 0.5, 1), Color(1, 0.82, 0.2), Color(0.25, 0.88, 0.5), Color(0.82, 0.38, 1)]
	elif style == 1:
		options = [Color(0.98, 0.9, 0.3)]
	elif style == 2:
		options = [Color(0.78, 0.48, 0.22), Color(0.55, 0.36, 0.2)]
	elif style == 3:
		options = [Color(0.18, 0.75, 0.28), Color(0.32, 0.82, 0.22), Color(0.12, 0.62, 0.32)]
	elif style == 4:
		options = [Color(0.95, 0.22, 0.22), Color(0.2, 0.45, 0.98), Color(1, 0.78, 0.15), Color(0.95, 0.95, 0.98), Color(0.15, 0.78, 0.72)]
	elif style == 5:
		options = [Color(1, 0.55, 0.15), Color(1, 0.4, 0.55), Color(0.2, 0.75, 0.85)]
	elif style == 6:
		options = [Color(0.95, 0.42, 0.38), Color(0.4, 0.68, 0.98), Color(0.98, 0.82, 0.35), Color(0.68, 0.48, 0.95)]
	else:
		options = [Color(0.5, 0.72, 0.98), Color(0.95, 0.5, 0.68), Color(0.98, 0.66, 0.32)]
	var c: Color = options[randi() % options.size()]
	return c.lightened(randf_range(-0.06, 0.08))

func _road_dist(v: float) -> float:
	var m := fposmod(v, 10.0)
	return minf(m, 10.0 - m)

func _random_spot(place: int) -> Array:
	var roads := [-40, -30, -20, -10, 0, 10, 20, 30, 40]
	var road := float(roads[randi() % roads.size()])
	var along := randf_range(-CITY_HALF + 1.0, CITY_HALF - 1.0)
	var horiz := randf() > 0.5
	var sign_side := 1.0 if randf() > 0.5 else -1.0
	var dir := Vector3.ZERO
	var p := Vector3.ZERO
	if place == 1:
		var lane := 0.85 * sign_side
		if horiz:
			p = Vector3(along, 0, road + lane)
			dir = Vector3(-sign_side, 0, 0)
		else:
			p = Vector3(road + lane, 0, along)
			dir = Vector3(0, 0, -sign_side)
	elif place == 0:
		var side := 2.45 * sign_side
		if horiz:
			p = Vector3(along, 0, road + side)
			dir = Vector3(1.0 if randf() > 0.5 else -1.0, 0, 0)
		else:
			p = Vector3(road + side, 0, along)
			dir = Vector3(0, 0, 1.0 if randf() > 0.5 else -1.0)
	else:
		p = Vector3(randf_range(-CITY_HALF + 2.0, CITY_HALF - 2.0), 0, randf_range(-CITY_HALF + 2.0, CITY_HALF - 2.0))
		dir = Vector3.ZERO
	if dir.length_squared() > 0.0:
		dir = dir.normalized()
	return [p, dir]

func _accept(p: Vector3, size: float, place: int) -> bool:
	if Vector2(p.x, p.z).length() < 6.0:
		return false
	if absf(p.x) > CITY_HALF - 0.5 or absf(p.z) > CITY_HALF - 0.5:
		return false
	var dx := _road_dist(p.x)
	var dz := _road_dist(p.z)
	if place == 2 and (dx < 3.1 or dz < 3.1):
		return false
	for o in props:
		var op: Vector3 = o.pos
		if Vector2(op.x - p.x, op.z - p.z).length() < float(o.size) + size + 0.45:
			return false
	return true

func _add_prop(style: int, p: Vector3, dir: Vector3, size: float, height: float, points: int, mover: int, _place: int) -> void:
	var yaw := atan2(dir.x, dir.z) if dir.length_squared() > 0.0 else randf() * TAU
	var spd := 0.0
	if mover == 1:
		spd = randf_range(1.15, 1.65)
	elif mover == 2:
		spd = randf_range(2.6, 4.4)
	var col := _kind_color(style)
	var list: Array = kind_lists[style]
	var xform := Transform3D(Basis(Vector3.UP, yaw), p + Vector3(0, height * 0.5, 0))
	var o := {
		"kind": style,
		"index": list.size(),
		"pos": p,
		"yaw": yaw,
		"size": size,
		"height": height,
		"points": points,
		"color": col,
		"mover": mover,
		"dir": dir,
		"speed": spd,
		"vel": dir * spd,
		"xform": xform,
		"in_mesh": true,
		"in_body": false,
		"alive": true,
		"body": null,
	}
	list.append(o)
	props.append(o)
	if mover != 0:
		movers.append(o)

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
	inst.custom_aabb = AABB(Vector3(-CITY_HALF - 4, -16, -CITY_HALF - 4), Vector3(CITY_HALF * 2 + 8, 48, CITY_HALF * 2 + 8))
	_no_shadow(inst)
	add_child(inst)
	kind_multimeshes[ki] = mm

func _unmesh(o: Dictionary) -> void:
	if not bool(o.in_mesh):
		return
	var list: Array = kind_lists[int(o.kind)]
	var mm: MultiMesh = kind_multimeshes[int(o.kind)]
	var i := int(o.index)
	var last := list.size() - 1
	if i != last:
		var swapped: Dictionary = list[last]
		swapped.index = i
		list[i] = swapped
		mm.set_instance_transform(i, swapped.xform)
		mm.set_instance_color(i, swapped.color)
	list.pop_back()
	mm.visible_instance_count = list.size()
	o.in_mesh = false

func _build_ui() -> void:
	var ui := CanvasLayer.new()
	add_child(ui)
	score_lbl = Label.new()
	score_lbl.position = Vector2(18, 16)
	_style(score_lbl, 36)
	ui.add_child(score_lbl)
	timer_lbl = Label.new()
	timer_lbl.anchor_left = 1.0
	timer_lbl.anchor_right = 1.0
	timer_lbl.offset_left = -210
	timer_lbl.offset_right = -18
	timer_lbl.offset_top = 16
	timer_lbl.offset_bottom = 64
	timer_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_style(timer_lbl, 36)
	ui.add_child(timer_lbl)
	var bar := ColorRect.new()
	bar.position = Vector2(18, 68)
	bar.size = Vector2(250, 18)
	bar.color = Color(0, 0, 0, 0.35)
	bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui.add_child(bar)
	bar_fill = ColorRect.new()
	bar_fill.position = Vector2(3, 3)
	bar_fill.size = Vector2(0, 12)
	bar_fill.color = Color(0.2, 0.9, 1.0)
	bar_fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bar.add_child(bar_fill)
	level_lbl = Label.new()
	level_lbl.position = Vector2(278, 58)
	_style(level_lbl, 26)
	ui.add_child(level_lbl)
	sha_lbl = Label.new()
	sha_lbl.anchor_left = 1.0
	sha_lbl.anchor_right = 1.0
	sha_lbl.anchor_top = 0.0
	sha_lbl.anchor_bottom = 0.0
	sha_lbl.offset_left = -210
	sha_lbl.offset_right = -18
	sha_lbl.offset_top = 68
	sha_lbl.offset_bottom = 98
	sha_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_style(sha_lbl, 18)
	sha_lbl.text = _short_sha()
	ui.add_child(sha_lbl)
	over_panel = ColorRect.new()
	(over_panel as ColorRect).color = Color(0, 0, 0, 0.62)
	over_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	over_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	over_panel.visible = false
	ui.add_child(over_panel)
	over_lbl = Label.new()
	over_lbl.set_anchors_preset(Control.PRESET_FULL_RECT)
	over_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	over_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_style(over_lbl, 52)
	over_panel.add_child(over_lbl)
	debug_lbl = Label.new()
	debug_lbl.position = Vector2(16, 110)
	_style(debug_lbl, 20)
	debug_lbl.visible = debug_on
	ui.add_child(debug_lbl)
	joy_ui = Control.new()
	joy_ui.set_anchors_preset(Control.PRESET_FULL_RECT)
	joy_ui.mouse_filter = Control.MOUSE_FILTER_IGNORE
	joy_ui.draw.connect(_draw_joystick)
	ui.add_child(joy_ui)
	_refresh_hud()

func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch and event.pressed and not playing:
		get_tree().reload_current_scene()
		return
	if not playing:
		return
	if event is InputEventScreenTouch:
		if event.pressed:
			joy_held = true
			joy_id = event.index
			joy_anchor = event.position
			joy_finger = event.position
		elif event.index == joy_id:
			joy_held = false
		_refresh_joystick()
	elif event is InputEventScreenDrag and joy_held and event.index == joy_id:
		joy_finger = event.position
		_refresh_joystick()

func _screen_vector_to_world(screen: Vector2) -> Vector3:
	var basis := cam.global_transform.basis
	var right := Vector3(basis.x.x, 0.0, basis.x.z)
	var forward := Vector3(-basis.z.x, 0.0, -basis.z.z)
	right = right.normalized() if right.length_squared() > 0.0001 else Vector3.RIGHT
	forward = forward.normalized() if forward.length_squared() > 0.0001 else Vector3(0, 0, -1)
	return right * screen.x - forward * screen.y

func _move_speed() -> float:
	var base := _cam_dist_for(LEVEL_RADIUS[0])
	var dist := _cam_dist_for(shown_radius)
	var factor := pow(maxf(dist, 0.001) / base, SPEED_SCREEN)
	return BASE_SPEED * speed_scale * factor

func _stick_velocity() -> Vector3:
	var offset := joy_finger - joy_anchor
	var mag := offset.length()
	if mag <= JOY_DEADZONE:
		return Vector3.ZERO
	var span := maxf(JOY_FULL_RADIUS - JOY_DEADZONE, 0.001)
	var power := clampf((mag - JOY_DEADZONE) / span, 0.0, 1.0)
	var dir := _screen_vector_to_world(offset / mag)
	if dir.length_squared() < 0.0001:
		return Vector3.ZERO
	return dir.normalized() * _move_speed() * power

func _move_hole(delta: float) -> void:
	if joy_held:
		velocity = _stick_velocity()
	else:
		var alpha := 1.0 - exp(-STOP_RATE * delta)
		velocity = velocity.lerp(Vector3.ZERO, alpha)
		if velocity.length_squared() < 0.04:
			velocity = Vector3.ZERO
	hole_pos += velocity * delta
	hole_pos.x = clampf(hole_pos.x, -CITY_HALF, CITY_HALF)
	hole_pos.z = clampf(hole_pos.z, -CITY_HALF, CITY_HALF)

func _refresh_joystick() -> void:
	if joy_ui:
		joy_ui.queue_redraw()

func _draw_joystick() -> void:
	if not joy_held:
		return
	joy_ui.draw_arc(joy_anchor, JOY_FULL_RADIUS, 0.0, TAU, 40, Color(1, 1, 1, 0.28), 2.5, true)
	joy_ui.draw_arc(joy_anchor, JOY_DEADZONE, 0.0, TAU, 24, Color(1, 1, 1, 0.12), 1.5, true)
	var offset := joy_finger - joy_anchor
	offset = offset.limit_length(JOY_FULL_RADIUS)
	joy_ui.draw_circle(joy_anchor + offset, 16.0, Color(1, 1, 1, 0.42))

func _smooth_camera(delta: float) -> void:
	var want_d := _cam_dist_for(shown_radius)
	cam_distance = lerpf(cam_distance, want_d, 1.0 - exp(-2.2 * delta))
	var want_pos := hole_pos + _camera_offset(cam_distance)
	cam.position = cam.position.lerp(want_pos, 1.0 - exp(-5.0 * delta))
	cam_look = cam_look.lerp(hole_pos, 1.0 - exp(-6.0 * delta))
	cam.look_at(cam_look, Vector3.UP)

func _fits(size: float) -> bool:
	return size < hole_radius * FIT_RATIO

func _over_opening(size: float, dist: float) -> bool:
	return _fits(size) and dist + size * 0.45 < hole_radius

func _sync_level() -> void:
	var n := level
	while n + 1 < LEVEL_SCORE.size() and score >= LEVEL_SCORE[n + 1]:
		n += 1
	if n != level:
		level = n
		hole_radius = LEVEL_RADIUS[level]
		pop_t = POP_TIME

func _progress() -> float:
	if level >= LEVEL_SCORE.size() - 1:
		return 1.0
	var a := int(LEVEL_SCORE[level])
	var b := int(LEVEL_SCORE[level + 1])
	return clampf(float(score - a) / float(b - a), 0.0, 1.0)

func _refresh_hud() -> void:
	score_lbl.text = "Score %d" % score
	var sec := int(ceili(time_left))
	var m := int(float(sec) / 60.0)
	var s := sec % 60
	timer_lbl.text = "%d:%02d" % [m, s]
	level_lbl.text = "Lv %d" % (level + 1)
	bar_fill.size = Vector2(244.0 * _progress(), 12.0)
	shown_score = score
	shown_sec = sec
	shown_level = level

func _process(delta: float) -> void:
	delta = minf(delta, 1.0 / 20.0)
	if playing:
		time_left -= delta
		if time_left <= 0.0:
			time_left = 0.0
			playing = false
			joy_held = false
			_refresh_joystick()
			over_lbl.text = "Time's up!\nScore: %d\n\nTap to play again" % score
			over_panel.visible = true
		_move_hole(delta)
		_tick_movers(delta)
	shown_radius = lerpf(shown_radius, hole_radius, 1.0 - exp(-7.0 * delta))
	var pop := 1.0
	if pop_t > 0.0:
		var u := 1.0 - clampf(pop_t / POP_TIME, 0.0, 1.0)
		pop = 1.0 + sin(u * PI) * 0.22
		pop_t = maxf(0.0, pop_t - delta)
	var vis := shown_radius * pop
	hole_mesh.position = hole_pos + Vector3(0, 0.045, 0)
	hole_mesh.scale = Vector3(vis, 1, vis)
	rim_mesh.position = hole_pos + Vector3(0, 0.06, 0)
	rim_mesh.scale = Vector3(vis, 0.35, vis)
	_smooth_camera(delta)
	var sec := int(ceili(time_left))
	if score != shown_score or level != shown_level or sec != shown_sec:
		_refresh_hud()
	if debug_on:
		_update_debug(delta)

func _tick_movers(delta: float) -> void:
	for o in movers:
		if bool(o.in_body) or not bool(o.alive):
			continue
		var dir: Vector3 = o.dir
		var spd := float(o.speed)
		var p: Vector3 = o.pos
		p += dir * spd * delta
		if p.x > CITY_HALF:
			p.x = -CITY_HALF
		elif p.x < -CITY_HALF:
			p.x = CITY_HALF
		if p.z > CITY_HALF:
			p.z = -CITY_HALF
		elif p.z < -CITY_HALF:
			p.z = CITY_HALF
		if int(o.mover) == 1 and randf() < delta * 0.35:
			dir = -dir
		o.dir = dir
		o.pos = p
		o.yaw = atan2(dir.x, dir.z)
		o.vel = dir * spd
		var h := float(o.height)
		var xform := Transform3D(Basis(Vector3.UP, float(o.yaw)), p + Vector3(0, h * 0.5, 0))
		o.xform = xform
		if bool(o.in_mesh):
			var mm: MultiMesh = kind_multimeshes[int(o.kind)]
			mm.set_instance_transform(int(o.index), xform)

func _update_debug(delta: float) -> void:
	var frame_ms := delta * 1000.0
	var phys_ms := Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS) * 1000.0
	var draws := int(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME))
	var bodies := int(Performance.get_monitor(Performance.PHYSICS_3D_ACTIVE_OBJECTS))
	var fps := Engine.get_frames_per_second()
	var win := DisplayServer.window_get_size()
	debug_lbl.text = "FPS %d\nframe %.1f ms\nphysics %.2f ms\ndraws %d\nbodies %d\nview %dx%d\nspeed x%.2f\n%s" % [fps, frame_ms, phys_ms, draws, bodies, win.x, win.y, speed_scale, _short_sha()]
	if OS.has_feature("web"):
		JavaScriptBridge.eval("window.__godotStats={fps:%d,frameMs:%.2f,physMs:%.2f,draws:%d,bodies:%d,vw:%d,vh:%d}" % [fps, frame_ms, phys_ms, draws, bodies, win.x, win.y], true)

func _physics_process(_delta: float) -> void:
	if playing:
		_activate_nearby()
	var i := active.size() - 1
	while i >= 0:
		_drive_body(active[i])
		i -= 1

func _flat_dist(p: Vector3) -> float:
	var dx := p.x - hole_pos.x
	var dz := p.z - hole_pos.z
	return sqrt(dx * dx + dz * dz)

func _wants_body(o: Dictionary, dist: float) -> bool:
	var size := float(o.size)
	if _fits(size):
		return dist < hole_radius + size + 1.5
	return dist < hole_radius + size * 0.25

func _activate_nearby() -> void:
	var budget := 2
	while budget > 0 and not pool_free.is_empty():
		budget -= 1
		var best: Dictionary = {}
		var best_d := INF
		var found := false
		for o in props:
			if bool(o.in_body) or not bool(o.alive):
				continue
			var dist := _flat_dist(o.pos)
			if dist < best_d and _wants_body(o, dist):
				best = o
				best_d = dist
				found = true
		if not found:
			return
		if not _take_body(best):
			return

func _take_body(o: Dictionary) -> bool:
	if pool_free.is_empty() or bool(o.in_body):
		return false
	var b: RigidBody3D = pool_free.pop_back()
	var cs := b.get_node("Shape") as CollisionShape3D
	cs.shape = kind_shapes[int(o.kind)]
	b.mass = maxf(0.35, float(o.size) * float(o.height) * 0.45)
	var h := float(o.height)
	var p: Vector3 = o.pos
	b.freeze = true
	b.global_transform = Transform3D(Basis(Vector3.UP, float(o.yaw)), p + Vector3(0, h * 0.5, 0))
	b.freeze = false
	b.collision_mask = 1
	b.linear_velocity = o.vel
	b.angular_velocity = Vector3.ZERO
	b.sleeping = false
	o.body = b
	o.in_body = true
	active.append(o)
	return true

func _pool_body(b: RigidBody3D) -> void:
	b.freeze = true
	b.collision_mask = 1
	b.linear_velocity = Vector3.ZERO
	b.angular_velocity = Vector3.ZERO
	b.position = Vector3(0, -50, 0)
	pool_free.append(b)

func _drive_body(o: Dictionary) -> void:
	var b: RigidBody3D = o.body
	if b == null:
		return
	var p := b.global_position
	if p.y < -1.7:
		_swallow_done(o)
		return
	var dx := p.x - hole_pos.x
	var dz := p.z - hole_pos.z
	var dist := sqrt(dx * dx + dz * dz)
	var size := float(o.size)
	var committed := p.y < float(o.height) * 0.35
	if dist > hole_radius + 6.0 and not committed:
		_release_body(o, p)
		return
	var mass := b.mass
	var inward := Vector3.ZERO
	if dist > 0.04:
		inward = Vector3(-dx / dist, 0.0, -dz / dist)
	if _fits(size):
		if _over_opening(size, dist) or committed:
			b.collision_mask = 0
			b.apply_central_force(inward * (12.0 * mass) + Vector3.DOWN * (22.0 * mass))
		else:
			b.collision_mask = 1
			if dist < hole_radius + size * 1.9:
				var axis := inward.cross(Vector3.UP)
				b.apply_torque(axis * (8.0 * mass))
				b.apply_central_force(inward * (18.0 * mass))
	else:
		b.collision_mask = 1
		if dist < maxf(hole_radius * 0.98, 0.2):
			var outward := -inward
			b.apply_central_force(outward * (28.0 * mass))
	var v := b.linear_velocity
	var hv := Vector2(v.x, v.z)
	if hv.length() > 8.0:
		hv = hv.limit_length(8.0)
		b.linear_velocity = Vector3(hv.x, minf(v.y, 5.0), hv.y)
	if bool(o.in_mesh):
		var mm: MultiMesh = kind_multimeshes[int(o.kind)]
		mm.set_instance_transform(int(o.index), b.global_transform)

func _swallow_done(o: Dictionary) -> void:
	if playing and bool(o.alive):
		score += int(o.points)
		_sync_level()
	o.alive = false
	if o.body != null:
		_pool_body(o.body)
		o.body = null
	o.in_body = false
	_unmesh(o)
	active.erase(o)
	props.erase(o)

func _release_body(o: Dictionary, p: Vector3) -> void:
	if o.body != null:
		_pool_body(o.body)
		o.body = null
	o.in_body = false
	var grounded := Vector3(p.x, 0, p.z)
	o.pos = grounded
	active.erase(o)
	if bool(o.in_mesh):
		var h := float(o.height)
		var xform := Transform3D(Basis(Vector3.UP, float(o.yaw)), grounded + Vector3(0, h * 0.5, 0))
		o.xform = xform
		var mm: MultiMesh = kind_multimeshes[int(o.kind)]
		mm.set_instance_transform(int(o.index), xform)
