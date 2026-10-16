extends Node3D

const ROUND_TIME := 120.0
const CITY_HALF := 15.4
const GRID_MIN := -15
const GRID_MAX := 15
const ROAD_STEP := 5
const BASE_SPEED := 3.6  # world units / second at full stick, smallest hole; ?speed= multiplies this
const JOY_DEADZONE := 14.0
const JOY_FULL_RADIUS := 56.0
const STOP_RATE := 34.0
const CAM_PITCH_DEG := 60.0
const CAM_FOV := 56.0
const CAM_BASE := 7.2
const CAM_PER_RADIUS := 2.15
const SPEED_SCREEN := 0.84
const POOL := 8
const FIT_RATIO := 0.92
const POP_TIME := 0.32
const BUILD_SHA := "__BUILD_SHA__"
const LEVEL_SCORE := [0, 14, 36, 70, 120, 190]
const LEVEL_RADIUS := [0.50, 0.78, 1.05, 1.42, 1.9, 2.5]
const GROUND_SHADER := """shader_type spatial;
render_mode diffuse_lambert, cull_back;
uniform sampler2D albedo_tex : source_color, filter_linear_mipmap;
uniform vec3 hole_center = vec3(0.0);
uniform float hole_radius = 0.0;
varying vec3 world_pos;
void vertex() {
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}
void fragment() {
	vec2 d = world_pos.xz - hole_center.xz;
	if (hole_radius > 0.0 && dot(d, d) < hole_radius * hole_radius) {
		discard;
	}
	vec3 col = texture(albedo_tex, UV).rgb;
	ALBEDO = col * vec3(1.08, 1.06, 1.02);
	ROUGHNESS = 1.0;
	METALLIC = 0.0;
}
"""
const PIT_SHADER := """shader_type spatial;
render_mode unshaded, cull_disabled;
varying vec4 vcol;
void vertex() {
	vcol = COLOR;
}
void fragment() {
	ALBEDO = vcol.rgb;
}
"""

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
var kind_native: Array = []
var kind_multimeshes: Array = []
var kind_mats: Array = []
var pool: Array = []
var pool_free: Array = []
var body_mat: PhysicsMaterial
var shadow_mm: MultiMesh
var shadow_owners: Array = []
var ground_mat: ShaderMaterial
var hole_mesh: MeshInstance3D
var pop_fx: CPUParticles3D
var floaters: Array = []
var cam: Camera3D
var cam_look := Vector3.ZERO
var cam_distance := 8.0
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
var shown_score := -1
var shown_sec := -1
var shown_level := -1
var tex_roads: Texture2D
var tex_commercial: Texture2D
var tex_suburban: Texture2D
var tex_cars: Texture2D
var tex_chars: Texture2D
var mat_roads: StandardMaterial3D
var mat_commercial: StandardMaterial3D
var mat_suburban: StandardMaterial3D
var mat_cars: StandardMaterial3D
var mat_chars: StandardMaterial3D
var mat_nature: StandardMaterial3D

func _ready() -> void:
	randomize()
	debug_on = _query_debug()
	speed_scale = _query_speed()
	body_mat = PhysicsMaterial.new()
	body_mat.friction = 0.4
	body_mat.bounce = 0.0
	_load_textures()
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

func _load_textures() -> void:
	tex_roads = load("res://assets/kenney/roads/Textures/colormap.png")
	tex_commercial = load("res://assets/kenney/commercial/Textures/colormap.png")
	tex_suburban = load("res://assets/kenney/suburban/Textures/colormap.png")
	tex_cars = load("res://assets/kenney/cars/Textures/colormap.png")
	tex_chars = load("res://assets/kenney/characters/Textures/colormap.png")
	mat_roads = _tex_mat(tex_roads)
	mat_commercial = _tex_mat(tex_commercial)
	mat_suburban = _tex_mat(tex_suburban)
	mat_cars = _tex_mat(tex_cars)
	mat_chars = _tex_mat(tex_chars)
	mat_nature = StandardMaterial3D.new()
	mat_nature.albedo_color = Color.WHITE
	mat_nature.vertex_color_use_as_albedo = true
	mat_nature.roughness = 1.0
	mat_nature.metallic = 0.0

func _tex_mat(tex: Texture2D) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_texture = tex
	m.albedo_color = Color(1.06, 1.04, 1.0)
	m.vertex_color_use_as_albedo = true
	m.roughness = 1.0
	m.metallic = 0.0
	m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	return m

func _build_world() -> void:
	var env := WorldEnvironment.new()
	var e := Environment.new()
	var sky_mat := ProceduralSkyMaterial.new()
	sky_mat.sky_top_color = Color(0.28, 0.58, 1.0)
	sky_mat.sky_horizon_color = Color(1.0, 0.78, 0.58)
	sky_mat.ground_horizon_color = Color(0.95, 0.8, 0.62)
	sky_mat.ground_bottom_color = Color(0.45, 0.72, 0.4)
	sky_mat.sun_angle_max = 28.0
	var sky := Sky.new()
	sky.sky_material = sky_mat
	e.background_mode = Environment.BG_SKY
	e.sky = sky
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	e.ambient_light_color = Color(1.0, 0.9, 0.78)
	e.ambient_light_energy = 0.9
	e.fog_enabled = true
	e.fog_mode = Environment.FOG_MODE_EXPONENTIAL
	e.fog_light_color = Color(0.78, 0.88, 1.0)
	e.fog_density = 0.018
	e.fog_aerial_perspective = 0.35
	e.fog_sky_affect = 0.45
	env.environment = e
	add_child(env)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-48, 38, 0)
	sun.light_color = Color(1.0, 0.9, 0.72)
	sun.light_energy = 1.45
	sun.shadow_enabled = false
	add_child(sun)
	var floor := StaticBody3D.new()
	floor.collision_layer = 1
	floor.collision_mask = 0
	floor.physics_material_override = body_mat
	var floor_shape := CollisionShape3D.new()
	var floor_box := BoxShape3D.new()
	floor_box.size = Vector3(CITY_HALF * 2 + 8, 2.0, CITY_HALF * 2 + 8)
	floor_shape.shape = floor_box
	floor.position = Vector3(0, -1.0, 0)
	floor.add_child(floor_shape)
	add_child(floor)
	var gshader := Shader.new()
	gshader.code = GROUND_SHADER
	ground_mat = ShaderMaterial.new()
	ground_mat.shader = gshader
	ground_mat.set_shader_parameter("albedo_tex", tex_roads)
	ground_mat.set_shader_parameter("hole_center", Vector3.ZERO)
	ground_mat.set_shader_parameter("hole_radius", hole_radius)
	hole_mesh = MeshInstance3D.new()
	hole_mesh.mesh = _build_pit_mesh()
	var pshader := Shader.new()
	pshader.code = PIT_SHADER
	var pmat := ShaderMaterial.new()
	pmat.shader = pshader
	hole_mesh.material_override = pmat
	_no_shadow(hole_mesh)
	hole_mesh.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	add_child(hole_mesh)
	_build_pop_fx()
	cam = Camera3D.new()
	cam.fov = CAM_FOV
	cam.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	add_child(cam)
	cam_distance = _cam_dist_for(hole_radius)
	cam_look = hole_pos
	cam.position = hole_pos + _camera_offset(cam_distance)
	cam.look_at(cam_look, Vector3.UP)

func _build_pop_fx() -> void:
	pop_fx = CPUParticles3D.new()
	pop_fx.amount = 12
	pop_fx.lifetime = 0.42
	pop_fx.one_shot = true
	pop_fx.explosiveness = 0.92
	pop_fx.direction = Vector3(0, 1, 0)
	pop_fx.spread = 58.0
	pop_fx.initial_velocity_min = 1.4
	pop_fx.initial_velocity_max = 2.6
	pop_fx.gravity = Vector3(0, -4.2, 0)
	pop_fx.scale_amount_min = 0.07
	pop_fx.scale_amount_max = 0.16
	pop_fx.emitting = false
	var quad := QuadMesh.new()
	quad.size = Vector2(0.22, 0.22)
	pop_fx.mesh = quad
	var pm := StandardMaterial3D.new()
	pm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	pm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	pm.albedo_color = Color(1, 0.92, 0.35, 0.95)
	pm.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	pm.cull_mode = BaseMaterial3D.CULL_DISABLED
	pop_fx.material_override = pm
	_no_shadow(pop_fx)
	add_child(pop_fx)

func _build_pit_mesh() -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var seg := 24
	var rings := [
		[0.98, 0.015, Color(0.09, 0.1, 0.13)],
		[0.86, -0.45, Color(0.035, 0.038, 0.05)],
		[0.68, -1.25, Color(0.012, 0.012, 0.016)],
		[0.5, -2.55, Color(0, 0, 0)],
	]
	for r in rings.size() - 1:
		var a: Array = rings[r]
		var b: Array = rings[r + 1]
		var r0 := float(a[0])
		var y0 := float(a[1])
		var c0: Color = a[2]
		var r1 := float(b[0])
		var y1 := float(b[1])
		var c1: Color = b[2]
		for i in seg:
			var a0 := TAU * float(i) / float(seg)
			var a1 := TAU * float(i + 1) / float(seg)
			var p00 := Vector3(cos(a0) * r0, y0, sin(a0) * r0)
			var p01 := Vector3(cos(a1) * r0, y0, sin(a1) * r0)
			var p10 := Vector3(cos(a0) * r1, y1, sin(a0) * r1)
			var p11 := Vector3(cos(a1) * r1, y1, sin(a1) * r1)
			st.set_color(c0); st.add_vertex(p00)
			st.set_color(c1); st.add_vertex(p10)
			st.set_color(c0); st.add_vertex(p01)
			st.set_color(c0); st.add_vertex(p01)
			st.set_color(c1); st.add_vertex(p10)
			st.set_color(c1); st.add_vertex(p11)
	var bottom_y := -2.55
	var bottom_r := 0.5
	for i in seg:
		var a0 := TAU * float(i) / float(seg)
		var a1 := TAU * float(i + 1) / float(seg)
		st.set_color(Color(0, 0, 0))
		st.add_vertex(Vector3(0, bottom_y, 0))
		st.set_color(Color(0, 0, 0))
		st.add_vertex(Vector3(cos(a1) * bottom_r, bottom_y, sin(a1) * bottom_r))
		st.set_color(Color(0, 0, 0))
		st.add_vertex(Vector3(cos(a0) * bottom_r, bottom_y, sin(a0) * bottom_r))
	var inner := 0.94
	var outer := 1.16
	var rim_y := 0.05
	var rim := Color(0.05, 0.78, 1.0)
	var rim_hi := Color(0.72, 0.97, 1.0)
	for i in seg:
		var a0 := TAU * float(i) / float(seg)
		var a1 := TAU * float(i + 1) / float(seg)
		var i0 := Vector3(cos(a0) * inner, rim_y, sin(a0) * inner)
		var i1 := Vector3(cos(a1) * inner, rim_y, sin(a1) * inner)
		var o0 := Vector3(cos(a0) * outer, rim_y, sin(a0) * outer)
		var o1 := Vector3(cos(a1) * outer, rim_y, sin(a1) * outer)
		st.set_color(rim); st.add_vertex(i0)
		st.set_color(rim_hi); st.add_vertex(o0)
		st.set_color(rim); st.add_vertex(i1)
		st.set_color(rim); st.add_vertex(i1)
		st.set_color(rim_hi); st.add_vertex(o0)
		st.set_color(rim_hi); st.add_vertex(o1)
	st.generate_normals()
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

func _load_model(path: String) -> Dictionary:
	var scene := load(path) as PackedScene
	var inst := scene.instantiate()
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	_collect_mesh(inst, Transform3D.IDENTITY, st)
	inst.free()
	var mesh := st.commit()
	var aabb := mesh.get_aabb()
	var shift := Vector3(
		-(aabb.position.x + aabb.size.x * 0.5),
		-aabb.position.y,
		-(aabb.position.z + aabb.size.z * 0.5)
	)
	var st2 := SurfaceTool.new()
	st2.begin(Mesh.PRIMITIVE_TRIANGLES)
	for s in mesh.get_surface_count():
		st2.append_from(mesh, s, Transform3D(Basis(), shift))
	var planted := st2.commit()
	return {"mesh": planted, "size": planted.get_aabb().size}

func _collect_mesh(n: Node, parent: Transform3D, st: SurfaceTool) -> void:
	var xform := parent
	if n is Node3D:
		xform = parent * (n as Node3D).transform
	if n is MeshInstance3D:
		var mi := n as MeshInstance3D
		if mi.mesh:
			for s in mi.mesh.get_surface_count():
				var tint := Color.WHITE
				var surf_mat := mi.mesh.surface_get_material(s)
				if surf_mat is StandardMaterial3D:
					var sm := surf_mat as StandardMaterial3D
					if sm.albedo_texture == null:
						tint = sm.albedo_color
				_append_surface(st, mi.mesh, s, xform, tint)
	for c in n.get_children():
		_collect_mesh(c, xform, st)

func _append_surface(st: SurfaceTool, mesh: Mesh, surface: int, xform: Transform3D, color: Color) -> void:
	var arrays: Array = mesh.surface_get_arrays(surface)
	var verts: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	var norms: PackedVector3Array = arrays[Mesh.ARRAY_NORMAL]
	var uvs: PackedVector2Array = arrays[Mesh.ARRAY_TEX_UV]
	var indices: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
	var basis := xform.basis
	var origin := xform.origin
	var ids: PackedInt32Array = indices
	if ids.is_empty():
		ids.resize(verts.size())
		for i in verts.size():
			ids[i] = i
	for idx in ids:
		st.set_color(color)
		if idx < norms.size():
			st.set_normal((basis * norms[idx]).normalized())
		if idx < uvs.size():
			st.set_uv(uvs[idx])
		st.add_vertex(basis * verts[idx] + origin)

func _spawn_city() -> void:
	_spawn_ground()
	# path, material, scale xz, scale y, points, role, mover, yaw_offset
	# mover: 0 static, 1 person, 2 car. yaw_offset turns model nose onto the move direction.
	var defs := [
		["res://assets/kenney/roads/construction-cone.glb", mat_roads, 3.4, 3.4, 1, "small", 0, 0.0],
		["res://assets/kenney/roads/construction-barrier.glb", mat_roads, 2.1, 2.1, 2, "small", 0, 0.0],
		["res://assets/kenney/characters/character-male-a.glb", mat_chars, 0.62, 0.62, 2, "person", 1, 0.0],
		["res://assets/kenney/characters/character-female-a.glb", mat_chars, 0.55, 0.55, 2, "person", 1, 0.0],
		["res://assets/kenney/characters/character-male-c.glb", mat_chars, 0.6, 0.6, 2, "person", 1, 0.0],
		["res://assets/kenney/roads/light-curved.glb", mat_roads, 1.75, 1.75, 2, "lamp", 0, 0.0],
		["res://assets/kenney/nature/plant_bush.glb", mat_nature, 0.95, 0.95, 1, "small", 0, 0.0],
		["res://assets/kenney/suburban/planter.glb", mat_suburban, 1.15, 1.15, 2, "small", 0, 0.0],
		["res://assets/kenney/suburban/tree-small.glb", mat_suburban, 1.85, 1.85, 3, "tree", 0, 0.0],
		["res://assets/kenney/roads/dumpster.glb", mat_roads, 2.7, 2.7, 4, "dumpster", 0, 0.0],
		["res://assets/kenney/suburban/tree-large.glb", mat_suburban, 3.2, 3.2, 6, "tree", 0, 0.0],
		["res://assets/kenney/nature/tree_simple.glb", mat_nature, 2.4, 2.2, 8, "tree", 0, 0.0],
		["res://assets/kenney/cars/sedan.glb", mat_cars, 0.62, 0.62, 12, "car", 2, 0.0],
		["res://assets/kenney/cars/taxi.glb", mat_cars, 0.58, 0.58, 12, "car", 2, 0.0],
		["res://assets/kenney/cars/hatchback-sports.glb", mat_cars, 0.6, 0.6, 14, "car", 2, 0.0],
		["res://assets/kenney/cars/van.glb", mat_cars, 0.55, 0.55, 16, "car", 2, 0.0],
		["res://assets/kenney/commercial/low-detail-building-a.glb", mat_commercial, 4.0, 2.3, 22, "building", 0, 0.0],
		["res://assets/kenney/commercial/low-detail-building-b.glb", mat_commercial, 3.8, 2.5, 22, "building", 0, 0.0],
		["res://assets/kenney/commercial/low-detail-building-c.glb", mat_commercial, 4.1, 2.15, 24, "building", 0, 0.0],
		["res://assets/kenney/commercial/low-detail-building-d.glb", mat_commercial, 3.7, 2.6, 24, "building", 0, 0.0],
		["res://assets/kenney/commercial/low-detail-building-wide-a.glb", mat_commercial, 2.55, 1.9, 30, "wide", 0, 0.0],
		["res://assets/kenney/suburban/building-type-a.glb", mat_suburban, 1.75, 1.45, 34, "house", 0, 0.0],
		["res://assets/kenney/suburban/building-type-b.glb", mat_suburban, 1.7, 1.55, 34, "house", 0, 0.0],
		["res://assets/kenney/suburban/building-type-c.glb", mat_suburban, 1.65, 1.35, 36, "house", 0, 0.0],
		["res://assets/kenney/commercial/building-skyscraper-a.glb", mat_commercial, 2.2, 1.65, 70, "tower", 0, 0.0],
		["res://assets/kenney/commercial/building-skyscraper-c.glb", mat_commercial, 2.05, 1.85, 70, "tower", 0, 0.0],
	]
	for d in defs:
		var info := _load_model(str(d[0]))
		kind_lists.append([])
		kind_meshes.append(info.mesh)
		kind_native.append(info.size)
		kind_mats.append(d[1])
		kind_multimeshes.append(null)
	_place_props(defs)
	for ki in kind_meshes.size():
		_build_kind_multimesh(ki)
	_build_shadows()

func _spawn_ground() -> void:
	var straight: Mesh = _load_model("res://assets/kenney/roads/road-straight.glb").mesh
	var crossing: Mesh = _load_model("res://assets/kenney/roads/road-crossing.glb").mesh
	var cross: Mesh = _load_model("res://assets/kenney/roads/road-crossroad.glb").mesh
	var grass: Mesh = _load_model("res://assets/kenney/roads/tile-low.glb").mesh
	var straights: Array = []
	var crossings: Array = []
	var crosses: Array = []
	var grasses: Array = []
	for i in range(GRID_MIN, GRID_MAX + 1):
		for j in range(GRID_MIN, GRID_MAX + 1):
			var on_i := _road_line(i)
			var on_j := _road_line(j)
			var at := Vector3(float(i), 0.0, float(j))
			if on_i and on_j:
				crosses.append(at)
			elif on_j:
				var near := _road_line(i - 1) or _road_line(i + 1)
				if near:
					crossings.append({"at": at, "yaw": 0.0})
				else:
					straights.append({"at": at, "yaw": 0.0})
			elif on_i:
				var near_j := _road_line(j - 1) or _road_line(j + 1)
				if near_j:
					crossings.append({"at": at, "yaw": PI * 0.5})
				else:
					straights.append({"at": at, "yaw": PI * 0.5})
			else:
				grasses.append(at)
	_tile_multimesh(straight, straights, true)
	_tile_multimesh(crossing, crossings, true)
	_tile_multimesh(cross, crosses, false)
	_tile_multimesh(grass, grasses, false)

func _road_line(i: int) -> bool:
	return i % ROAD_STEP == 0

func _tile_multimesh(mesh: Mesh, items: Array, has_yaw: bool) -> void:
	if items.is_empty():
		return
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = mesh
	mm.instance_count = items.size()
	for n in items.size():
		var pos: Vector3
		var yaw := 0.0
		if has_yaw:
			var item: Dictionary = items[n]
			pos = item.at
			yaw = float(item.yaw)
		else:
			pos = items[n]
		mm.set_instance_transform(n, Transform3D(Basis(Vector3.UP, yaw), pos))
	var inst := MultiMeshInstance3D.new()
	inst.multimesh = mm
	inst.material_override = ground_mat
	inst.custom_aabb = AABB(Vector3(-CITY_HALF - 2, -4, -CITY_HALF - 2), Vector3(CITY_HALF * 2 + 4, 20, CITY_HALF * 2 + 4))
	_no_shadow(inst)
	add_child(inst)

func _place_props(defs: Array) -> void:
	var by_role := {}
	for i in defs.size():
		var role := str(defs[i][5])
		if not by_role.has(role):
			by_role[role] = []
		(by_role[role] as Array).append(i)
	var lines: Array = []
	for i in range(GRID_MIN, GRID_MAX + 1):
		if _road_line(i):
			lines.append(i)
	var block_i := 0
	var role_cursor := {}
	for a in range(lines.size() - 1):
		for b in range(lines.size() - 1):
			var ix := (float(lines[a]) + float(lines[a + 1])) * 0.5
			var iz := (float(lines[b]) + float(lines[b + 1])) * 0.5
			var plaza := (a + b) % 3 == 0
			var role := "tree" if plaza else "building"
			if not plaza:
				var pick := block_i % 7
				if pick <= 1 and block_i % 5 == 0:
					role = "tower"
				elif pick == 2:
					role = "wide"
				elif pick == 3 or pick == 4:
					role = "house"
			var list: Array = by_role[role]
			var cursor := int(role_cursor.get(role, 0))
			role_cursor[role] = cursor + 1
			var ki: int = list[cursor % list.size()]
			var yaw := randf() * TAU if plaza else (PI * 0.5) * float(block_i % 4)
			_add_prop(ki, Vector3(ix, 0, iz), Vector3.ZERO, yaw, defs[ki])
			block_i += 1
	_scatter(by_role["small"], defs, 22, "grass")
	_scatter(by_role["tree"], defs, 16, "grass")
	_scatter(by_role["dumpster"], defs, 8, "grass")
	_spawn_walkers(by_role["person"], defs)
	_spawn_lamps(by_role["lamp"], defs)
	_spawn_cars(by_role["car"], defs)

func _scatter(kinds: Array, defs: Array, count: int, _where: String) -> void:
	var made := 0
	var tries := 0
	while made < count and tries < count * 30:
		tries += 1
		var p := Vector3(randf_range(GRID_MIN + 0.2, GRID_MAX - 0.2), 0, randf_range(GRID_MIN + 0.2, GRID_MAX - 0.2))
		if _road_line(int(round(p.x))) or _road_line(int(round(p.z))):
			continue
		if p.length() < 2.2:
			continue
		var ki: int = kinds[randi() % kinds.size()]
		var native: Vector3 = kind_native[ki]
		var sxz := float(defs[ki][2])
		var foot := maxf(native.x, native.z) * sxz * 0.5
		if _overlaps(p, foot):
			continue
		_add_prop(ki, p, Vector3.ZERO, randf() * TAU, defs[ki])
		made += 1

func _spawn_walkers(kinds: Array, defs: Array) -> void:
	var made := 0
	for i in range(GRID_MIN, GRID_MAX + 1):
		if not _road_line(i):
			continue
		for axis in [0, 1]:
			for side in [-1.0, 1.0]:
				if made >= 28:
					return
				var along := randf_range(float(GRID_MIN) + 1.4, float(GRID_MAX) - 1.4)
				var p := Vector3(along, 0, float(i) + 0.36 * side) if axis == 0 else Vector3(float(i) + 0.36 * side, 0, along)
				if _road_line(int(round(p.x))) and _road_line(int(round(p.z))):
					continue
				if _overlaps(p, 0.22) or p.length() < 1.6:
					continue
				var dir := Vector3(1.0 if side > 0.0 else -1.0, 0, 0) if axis == 0 else Vector3(0, 0, 1.0 if side > 0.0 else -1.0)
				var ki: int = kinds[made % kinds.size()]
				_add_prop(ki, p, dir, 0.0, defs[ki])
				made += 1

func _spawn_lamps(kinds: Array, defs: Array) -> void:
	var made := 0
	for i in range(GRID_MIN, GRID_MAX + 1):
		if not _road_line(i):
			continue
		var along := float(GRID_MIN + 2)
		while along < float(GRID_MAX - 1):
			if made >= 20:
				return
			if not _road_line(int(round(along))):
				var p := Vector3(along, 0, float(i) + 0.48)
				if not _overlaps(p, 0.25):
					var ki: int = kinds[made % kinds.size()]
					_add_prop(ki, p, Vector3.ZERO, 0.0, defs[ki])
					made += 1
			along += 3.0

func _spawn_cars(kinds: Array, defs: Array) -> void:
	var made := 0
	for i in range(GRID_MIN, GRID_MAX + 1):
		if not _road_line(i):
			continue
		for axis in [0, 1]:
			for sgn in [-1.0, 1.0]:
				if made >= 16:
					return
				var along := randf_range(GRID_MIN + 1.0, GRID_MAX - 1.0)
				var p: Vector3
				var dir: Vector3
				if axis == 0:
					p = Vector3(along, 0, float(i) + 0.16 * sgn)
					dir = Vector3(sgn, 0, 0)
				else:
					p = Vector3(float(i) + 0.16 * sgn, 0, along)
					dir = Vector3(0, 0, sgn)
				if _overlaps(p, 0.85, ["person", "lamp", "small"]):
					continue
				var ki: int = kinds[made % kinds.size()]
				_add_prop(ki, p, dir, 0.0, defs[ki])
				made += 1

func _overlaps(p: Vector3, foot: float, ignore_roles: Array = []) -> bool:
	for o in props:
		if str(o.role) in ignore_roles:
			continue
		var op: Vector3 = o.pos
		if Vector2(op.x - p.x, op.z - p.z).length() < float(o.size) + foot + 0.28:
			return true
	return false

func _add_prop(ki: int, p: Vector3, dir: Vector3, yaw_in: float, spec: Array) -> void:
	var native: Vector3 = kind_native[ki]
	var sxz := float(spec[2])
	var sy := float(spec[3])
	if str(spec[5]) in ["building", "wide", "house", "tower"]:
		sy *= randf_range(0.86, 1.22)
		sxz *= randf_range(0.94, 1.06)
	var yaw_off := float(spec[7])
	var yaw := yaw_in
	if dir.length_squared() > 0.001:
		yaw = atan2(dir.x, dir.z) + yaw_off
	var scale := Vector3(sxz, sy, sxz)
	var basis := Basis(Vector3.UP, yaw).scaled(scale)
	var xform := Transform3D(basis, p)
	var foot := maxf(native.x, native.z) * sxz * 0.5
	var height := native.y * sy
	var mover := int(spec[6])
	var spd := 0.0
	if mover == 1:
		spd = randf_range(0.55, 0.85)
	elif mover == 2:
		spd = randf_range(1.3, 2.1)
	var tint := Color.WHITE
	var role := str(spec[5])
	if role in ["building", "wide", "house", "tower"]:
		var palette := [Color(1, 0.45, 0.4), Color(0.35, 0.62, 1), Color(1, 0.82, 0.3), Color(0.45, 0.9, 0.55), Color(0.78, 0.48, 1), Color(1, 0.62, 0.25)]
		tint = Color.WHITE.lerp(palette[randi() % palette.size()], 0.42)
	var list: Array = kind_lists[ki]
	var o := {
		"kind": ki,
		"index": list.size(),
		"shadow": -1,
		"pos": p,
		"yaw": yaw,
		"scale": scale,
		"size": foot,
		"height": height,
		"points": int(spec[4]),
		"role": role,
		"color": tint,
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
	inst.material_override = kind_mats[ki]
	inst.custom_aabb = AABB(Vector3(-CITY_HALF - 2, -6, -CITY_HALF - 2), Vector3(CITY_HALF * 2 + 4, 24, CITY_HALF * 2 + 4))
	_no_shadow(inst)
	add_child(inst)
	kind_multimeshes[ki] = mm

func _build_shadows() -> void:
	var img := Image.create(48, 48, false, Image.FORMAT_RGBA8)
	for y in 48:
		for x in 48:
			var d := Vector2(float(x) - 23.5, float(y) - 23.5).length() / 23.5
			var a := clampf(1.0 - smoothstep(0.15, 1.0, d), 0.0, 1.0)
			img.set_pixel(x, y, Color(0, 0, 0, a * a * 0.42))
	var tex := ImageTexture.create_from_image(img)
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.albedo_texture = tex
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR
	var quad := PlaneMesh.new()
	quad.size = Vector2(1, 1)
	shadow_mm = MultiMesh.new()
	shadow_mm.transform_format = MultiMesh.TRANSFORM_3D
	shadow_mm.mesh = quad
	shadow_mm.instance_count = maxi(props.size(), 1)
	shadow_mm.visible_instance_count = props.size()
	shadow_owners.resize(props.size())
	for i in props.size():
		props[i].shadow = i
		shadow_owners[i] = props[i]
		shadow_mm.set_instance_transform(i, _shadow_xform(props[i]))
	var inst := MultiMeshInstance3D.new()
	inst.multimesh = shadow_mm
	inst.material_override = mat
	inst.custom_aabb = AABB(Vector3(-CITY_HALF - 2, -2, -CITY_HALF - 2), Vector3(CITY_HALF * 2 + 4, 8, CITY_HALF * 2 + 4))
	_no_shadow(inst)
	add_child(inst)

func _shadow_xform(o: Dictionary) -> Transform3D:
	var p: Vector3 = o.pos
	if bool(o.in_body) and o.body != null:
		var b: RigidBody3D = o.body
		p = b.global_position
	var dx := p.x - hole_pos.x
	var dz := p.z - hole_pos.z
	if dx * dx + dz * dz < hole_radius * hole_radius * 0.8:
		return Transform3D(Basis(), Vector3(0, -30, 0))
	var s := float(o.size) * 2.6
	var basis := Basis()
	basis.x *= s
	basis.z *= s
	return Transform3D(basis, Vector3(p.x, 0.045, p.z))

func _set_shadow(o: Dictionary) -> void:
	if shadow_mm == null:
		return
	var idx := int(o.shadow)
	if idx < 0:
		return
	shadow_mm.set_instance_transform(idx, _shadow_xform(o))

func _drop_shadow(o: Dictionary) -> void:
	if shadow_mm == null or int(o.shadow) < 0:
		return
	var i := int(o.shadow)
	var last := shadow_owners.size() - 1
	if i != last and last >= 0:
		var swapped: Dictionary = shadow_owners[last]
		swapped.shadow = i
		shadow_owners[i] = swapped
		shadow_mm.set_instance_transform(i, shadow_mm.get_instance_transform(last))
	if last >= 0:
		shadow_owners.remove_at(last)
	shadow_mm.visible_instance_count = shadow_owners.size()
	o.shadow = -1

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
	_drop_shadow(o)

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
	bar_fill.color = Color(1.0, 0.78, 0.2)
	bar_fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bar.add_child(bar_fill)
	level_lbl = Label.new()
	level_lbl.position = Vector2(278, 58)
	_style(level_lbl, 26)
	ui.add_child(level_lbl)
	sha_lbl = Label.new()
	sha_lbl.anchor_left = 1.0
	sha_lbl.anchor_right = 1.0
	sha_lbl.offset_left = -210
	sha_lbl.offset_right = -18
	sha_lbl.offset_top = 100
	sha_lbl.offset_bottom = 130
	sha_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_style(sha_lbl, 18)
	sha_lbl.text = _short_sha()
	ui.add_child(sha_lbl)
	for _i in 6:
		var fl := Label.new()
		_style(fl, 32)
		fl.visible = false
		fl.modulate = Color(1, 0.95, 0.4)
		ui.add_child(fl)
		floaters.append({"lbl": fl, "pos": Vector3.ZERO, "age": -1.0})
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
		if velocity.length_squared() < 0.01:
			velocity = Vector3.ZERO
	hole_pos += velocity * delta
	var lim := CITY_HALF - 0.6
	hole_pos.x = clampf(hole_pos.x, -lim, lim)
	hole_pos.z = clampf(hole_pos.z, -lim, lim)

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
	var frame_delta := delta
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
	hole_mesh.position = hole_pos
	hole_mesh.scale = Vector3(vis, 1.0, vis)
	if ground_mat:
		ground_mat.set_shader_parameter("hole_center", hole_pos)
		ground_mat.set_shader_parameter("hole_radius", vis)
	_smooth_camera(delta)
	_tick_floaters(delta)
	var sec := int(ceili(time_left))
	if score != shown_score or level != shown_level or sec != shown_sec:
		_refresh_hud()
	if debug_on:
		_update_debug(frame_delta)

func _tick_floaters(delta: float) -> void:
	for f in floaters:
		if float(f.age) < 0.0:
			continue
		f.age = float(f.age) + delta
		var p: Vector3 = f.pos
		p.y += delta * 0.9
		f.pos = p
		var lbl: Label = f.lbl
		if float(f.age) > 0.85 or cam.is_position_behind(p):
			lbl.visible = false
			if float(f.age) > 0.85:
				f.age = -1.0
			continue
		var sp := cam.unproject_position(p)
		lbl.visible = true
		lbl.position = sp + Vector2(-16, -8)
		var col := lbl.modulate
		col.a = clampf(1.0 - float(f.age) / 0.85, 0.0, 1.0)
		lbl.modulate = col

func _tick_movers(delta: float) -> void:
	var lim := float(GRID_MAX) + 0.15
	for o in movers:
		if bool(o.in_body) or not bool(o.alive):
			continue
		var dir: Vector3 = o.dir
		var spd := float(o.speed)
		var p: Vector3 = o.pos
		p += dir * spd * delta
		if p.x > lim:
			p.x = -lim
		elif p.x < -lim:
			p.x = lim
		if p.z > lim:
			p.z = -lim
		elif p.z < -lim:
			p.z = lim
		if int(o.mover) == 1 and randf() < delta * 0.25:
			dir = -dir
		o.dir = dir
		o.pos = p
		# Kenney cars and characters face +Z. atan2(dir.x, dir.z) maps +Z onto dir.
		o.yaw = atan2(dir.x, dir.z)
		o.vel = dir * spd
		var basis := Basis(Vector3.UP, float(o.yaw)).scaled(o.scale)
		var xform := Transform3D(basis, p)
		o.xform = xform
		if bool(o.in_mesh):
			var mm: MultiMesh = kind_multimeshes[int(o.kind)]
			mm.set_instance_transform(int(o.index), xform)
			_set_shadow(o)

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
		return dist < hole_radius + size + 0.8
	return dist < hole_radius + size * 0.2

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
	var native: Vector3 = kind_native[int(o.kind)]
	var sc: Vector3 = o.scale
	var box := BoxShape3D.new()
	box.size = Vector3(maxf(native.x * sc.x, 0.08), maxf(native.y * sc.y, 0.08), maxf(native.z * sc.z, 0.08))
	cs.shape = box
	cs.position = Vector3(0, box.size.y * 0.5, 0)
	b.mass = maxf(0.35, box.size.x * box.size.y * box.size.z * 0.45)
	var p: Vector3 = o.pos
	b.freeze = true
	b.global_transform = Transform3D(Basis(Vector3.UP, float(o.yaw)), Vector3(p.x, 0.0, p.z))
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

func _visual_from_body(o: Dictionary, b: RigidBody3D) -> Transform3D:
	var t := b.global_transform
	var sc: Vector3 = o.scale
	var basis := Basis(t.basis.x.normalized() * sc.x, t.basis.y.normalized() * sc.y, t.basis.z.normalized() * sc.z)
	return Transform3D(basis, t.origin)

func _drive_body(o: Dictionary) -> void:
	var b: RigidBody3D = o.body
	if b == null:
		return
	var p := b.global_position
	if p.y < -2.25:
		_swallow_done(o)
		return
	var dx := p.x - hole_pos.x
	var dz := p.z - hole_pos.z
	var dist := sqrt(dx * dx + dz * dz)
	var size := float(o.size)
	var committed := p.y < -0.12
	if dist > hole_radius + 3.2 and not committed:
		_release_body(o, p)
		return
	var mass := b.mass
	var inward := Vector3.ZERO
	if dist > 0.04:
		inward = Vector3(-dx / dist, 0.0, -dz / dist)
	if _fits(size):
		if _over_opening(size, dist) or committed:
			b.collision_mask = 0
			b.apply_central_force(inward * (14.0 * mass) + Vector3.DOWN * (26.0 * mass))
		else:
			b.collision_mask = 1
			if dist < hole_radius + size * 1.9:
				var axis := inward.cross(Vector3.UP)
				b.apply_torque(axis * (9.0 * mass))
				b.apply_central_force(inward * (16.0 * mass))
	else:
		b.collision_mask = 1
		if dist < maxf(hole_radius * 0.98, 0.2) and dist > 0.04:
			b.apply_central_force(-inward * (22.0 * mass))
	var v := b.linear_velocity
	var hv := Vector2(v.x, v.z)
	if hv.length() > 4.2:
		hv = hv.limit_length(4.2)
		b.linear_velocity = Vector3(hv.x, minf(v.y, 4.0), hv.y)
	if bool(o.in_mesh):
		var mm: MultiMesh = kind_multimeshes[int(o.kind)]
		var xf := _visual_from_body(o, b)
		o.xform = xf
		mm.set_instance_transform(int(o.index), xf)
		_set_shadow(o)

func _burst(at: Vector3, points: int, tint: Color) -> void:
	pop_fx.global_position = at + Vector3(0, 0.45, 0)
	var pm := pop_fx.material_override as StandardMaterial3D
	pm.albedo_color = Color(tint.r, tint.g, tint.b, 0.95).lerp(Color(1, 0.95, 0.4, 0.95), 0.45)
	pop_fx.restart()
	pop_fx.emitting = true
	for f in floaters:
		if float(f.age) < 0.0:
			f.age = 0.0
			f.pos = at + Vector3(0, 0.7, 0)
			var lbl: Label = f.lbl
			lbl.text = "+%d" % points
			lbl.visible = true
			lbl.modulate = Color(1, 0.95, 0.35, 1)
			return

func _swallow_done(o: Dictionary) -> void:
	var at := hole_pos
	if o.body != null:
		var b: RigidBody3D = o.body
		at = b.global_position
	if playing and bool(o.alive):
		score += int(o.points)
		_sync_level()
		_burst(at, int(o.points), o.color)
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
		var basis := Basis(Vector3.UP, float(o.yaw)).scaled(o.scale)
		var xform := Transform3D(basis, grounded)
		o.xform = xform
		var mm: MultiMesh = kind_multimeshes[int(o.kind)]
		mm.set_instance_transform(int(o.index), xform)
		_set_shadow(o)
