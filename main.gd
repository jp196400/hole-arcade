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
	col = pow(max(col, vec3(0.001)), vec3(0.9));
	ALBEDO = col * vec3(1.14, 1.06, 0.96);
	ROUGHNESS = 0.78;
	METALLIC = 0.0;
	SPECULAR = 0.35;
}
"""
const PIT_SHADER := """shader_type spatial;
render_mode unshaded, cull_disabled;
uniform vec3 rim_color : source_color = vec3(0.05, 0.86, 1.0);
uniform vec3 rim_color_b : source_color = vec3(0.8, 0.98, 1.0);
uniform int pattern = 0;
uniform float glow = 0.9;
varying vec4 vcol;
varying vec2 local_xz;
void vertex() {
	vcol = COLOR;
	local_xz = VERTEX.xz;
}
void fragment() {
	if (vcol.a > 0.5) {
		ALBEDO = vcol.rgb;
		EMISSION = vec3(0.0);
	} else {
		float ang = atan(local_xz.x, local_xz.y);
		float stripes = step(0.5, fract(ang / 6.2831853 * 8.0));
		float checks = step(0.5, fract(ang / 6.2831853 * 6.0 + length(local_xz) * 3.5));
		float wave = smoothstep(0.15, 0.85, sin(ang * 5.0) * 0.5 + 0.5);
		float metal = pow(clamp(sin(ang * 3.0) * 0.5 + 0.62, 0.0, 1.0), 1.35);
		vec3 rc = rim_color;
		if (pattern == 1) {
			rc = mix(rim_color, rim_color_b, stripes);
		} else if (pattern == 2) {
			rc = mix(rim_color, rim_color_b, checks);
		} else if (pattern == 3) {
			rc = mix(rim_color, rim_color_b, wave);
		} else if (pattern == 4) {
			rc = mix(rim_color, rim_color_b, metal);
		}
		ALBEDO = rc;
		EMISSION = rc * glow;
	}
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
var sky_mat: ProceduralSkyMaterial
var world_env: Environment
var sun: DirectionalLight3D
var pit_mat: ShaderMaterial
var city_root: Node3D
var prop_defs: Array = []
var ground_meshes: Array = []
var map: Dictionary = {}
var map_index := 0
var target_score := 80
var mode := "menu"
var round_cleared := false
var coins_earned := 0
var doubled := false
var menu_layer: CanvasLayer
var hud_layer: CanvasLayer
var continue_btn: Button
var next_btn: Button
var double_btn: Button
var menu_sha: Label
const CatalogScript = preload("res://catalog.gd")

func _ready() -> void:
	randomize()
	debug_on = _query_debug()
	speed_scale = _query_speed()
	body_mat = PhysicsMaterial.new()
	body_mat.friction = 0.55
	body_mat.bounce = 0.0
	_load_textures()
	_build_world()
	_build_ui()
	_make_pool()
	_ensure_models()
	_build_menu_layer()
	_show_screen("menu")
	hole_mesh.visible = false
	AdService.interstitial_closed.connect(_after_ad)
	AdService.rewarded_done.connect(_after_reward)
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
	mat_nature.roughness = 0.62
	mat_nature.metallic = 0.0
	mat_nature.metallic_specular = 0.28

func _tex_mat(tex: Texture2D) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_texture = tex
	m.albedo_color = Color(1.08, 1.02, 0.96)
	m.vertex_color_use_as_albedo = true
	m.roughness = 0.55
	m.metallic = 0.0
	m.metallic_specular = 0.48
	m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	return m

func _build_world() -> void:
	var env := WorldEnvironment.new()
	var e := Environment.new()
	sky_mat = ProceduralSkyMaterial.new()
	sky_mat.sky_top_color = Color(0.22, 0.48, 0.98)
	sky_mat.sky_horizon_color = Color(1.0, 0.72, 0.48)
	sky_mat.ground_horizon_color = Color(0.95, 0.78, 0.55)
	sky_mat.ground_bottom_color = Color(0.36, 0.58, 0.34)
	sky_mat.sun_angle_max = 22.0
	var sky := Sky.new()
	sky.sky_material = sky_mat
	e.background_mode = Environment.BG_SKY
	e.sky = sky
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	e.ambient_light_color = Color(0.48, 0.62, 0.92)
	e.ambient_light_energy = 0.38
	e.tonemap_mode = Environment.TONE_MAPPER_ACES
	e.tonemap_exposure = 1.06
	e.tonemap_white = 5.5
	e.adjustment_enabled = true
	e.adjustment_brightness = 1.02
	e.adjustment_contrast = 1.14
	e.adjustment_saturation = 1.16
	e.fog_enabled = true
	e.fog_mode = Environment.FOG_MODE_EXPONENTIAL
	e.fog_light_color = Color(0.72, 0.82, 1.0)
	e.fog_density = 0.016
	e.fog_aerial_perspective = 0.4
	e.fog_sky_affect = 0.5
	world_env = e
	env.environment = e
	add_child(env)
	sun = DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-54, 32, 0)
	sun.light_color = Color(1.0, 0.74, 0.46)
	sun.light_energy = 2.05
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
	pit_mat = ShaderMaterial.new()
	pit_mat.shader = pshader
	hole_mesh.material_override = pit_mat
	_apply_skin()
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
	for i in seg:
		var a0 := TAU * float(i) / float(seg)
		var a1 := TAU * float(i + 1) / float(seg)
		var i0 := Vector3(cos(a0) * inner, rim_y, sin(a0) * inner)
		var i1 := Vector3(cos(a1) * inner, rim_y, sin(a1) * inner)
		var o0 := Vector3(cos(a0) * outer, rim_y, sin(a0) * outer)
		var o1 := Vector3(cos(a1) * outer, rim_y, sin(a1) * outer)
		var rim_mark := Color(1, 1, 1, 0)
		st.set_color(rim_mark); st.add_vertex(i0)
		st.set_color(rim_mark); st.add_vertex(o0)
		st.set_color(rim_mark); st.add_vertex(i1)
		st.set_color(rim_mark); st.add_vertex(i1)
		st.set_color(rim_mark); st.add_vertex(o0)
		st.set_color(rim_mark); st.add_vertex(o1)
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
	var planted := _shade_mesh(st2.commit())
	return {"mesh": planted, "size": planted.get_aabb().size}

func _shade_mesh(mesh: Mesh) -> ArrayMesh:
	var arrays: Array = mesh.surface_get_arrays(0)
	var verts: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	var norms: PackedVector3Array = arrays[Mesh.ARRAY_NORMAL]
	var cols: PackedColorArray = arrays[Mesh.ARRAY_COLOR]
	if cols.is_empty():
		cols.resize(verts.size())
		cols.fill(Color.WHITE)
	var aabb := mesh.get_aabb()
	var h := maxf(aabb.size.y, 0.001)
	var y0 := aabb.position.y
	for i in verts.size():
		var t := clampf((verts[i].y - y0) / h, 0.0, 1.0)
		var ao := lerpf(0.55, 1.12, smoothstep(0.0, 0.62, t))
		if i < norms.size():
			ao *= lerpf(0.82, 1.0, clampf(norms[i].y, 0.0, 1.0))
		var c: Color = cols[i]
		cols[i] = Color(c.r * ao, c.g * ao, c.b * ao, 1.0)
	arrays[Mesh.ARRAY_COLOR] = cols
	var out := ArrayMesh.new()
	out.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return out

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

func _ensure_models() -> void:
	if not prop_defs.is_empty():
		return
	prop_defs = [
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
	for d in prop_defs:
		var info := _load_model(str(d[0]))
		kind_lists.append([])
		kind_meshes.append(info.mesh)
		kind_native.append(info.size)
		kind_mats.append(d[1])
		kind_multimeshes.append(null)
	ground_meshes = [
		_load_model("res://assets/kenney/roads/road-straight.glb").mesh,
		_load_model("res://assets/kenney/roads/road-crossing.glb").mesh,
		_load_model("res://assets/kenney/roads/road-crossroad.glb").mesh,
		_load_model("res://assets/kenney/roads/tile-low.glb").mesh,
	]

func _add_city(n: Node) -> void:
	if city_root == null or not is_instance_valid(city_root):
		city_root = Node3D.new()
		city_root.name = "City"
		add_child(city_root)
	city_root.add_child(n)

func _spawn_city() -> void:
	seed(int(map.get("seed", 1)))
	_ensure_models()
	for list in kind_lists:
		(list as Array).clear()
	for i in kind_multimeshes.size():
		kind_multimeshes[i] = null
	_spawn_ground()
	_place_props(prop_defs)
	for ki in kind_meshes.size():
		_build_kind_multimesh(ki)
	_build_shadows()

func _spawn_ground() -> void:
	var straight: Mesh = ground_meshes[0]
	var crossing: Mesh = ground_meshes[1]
	var cross: Mesh = ground_meshes[2]
	var grass: Mesh = ground_meshes[3]
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
	_add_city(inst)

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
			var every := int(map.get("plaza", 3))
			var plaza := (a + b + int(map.get("shift", 0))) % maxi(every, 2) == 0
			var role := _block_role(block_i, plaza, str(map.get("bias", "downtown")))
			var list: Array = by_role[role]
			var cursor := int(role_cursor.get(role, 0))
			role_cursor[role] = cursor + 1
			var ki: int = list[cursor % list.size()]
			var yaw := randf() * TAU if plaza else (PI * 0.5) * float(block_i % 4)
			_add_prop(ki, Vector3(ix, 0, iz), Vector3.ZERO, yaw, defs[ki])
			block_i += 1
	_scatter(by_role["small"], defs, int(map.get("small", 18)), "grass")
	_scatter(by_role["tree"], defs, int(map.get("trees", 12)), "grass")
	_scatter(by_role["dumpster"], defs, int(map.get("dumpsters", 6)), "grass")
	_spawn_walkers(by_role["person"], defs, int(map.get("people", 22)))
	_spawn_lamps(by_role["lamp"], defs, int(map.get("lamps", 14)))
	_spawn_cars(by_role["car"], defs, int(map.get("cars", 14)))

func _block_role(block_i: int, plaza: bool, bias: String) -> String:
	if plaza:
		return "tree"
	var pick := block_i % 7
	if bias == "suburb":
		return "building" if pick == 0 else "house"
	if bias == "industrial":
		if pick <= 2:
			return "wide"
		return "tower" if pick == 3 else "building"
	if bias == "towers" or bias == "skyline":
		return "tower" if pick % 2 == 0 else "wide"
	if bias == "park":
		return "tree" if pick >= 4 else "house"
	if bias == "market" or bias == "festival":
		return "house" if pick <= 2 else "building"
	if pick <= 1 and block_i % 5 == 0:
		return "tower"
	if pick == 2:
		return "wide"
	if pick == 3 or pick == 4:
		return "house"
	return "building"

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

func _spawn_walkers(kinds: Array, defs: Array, limit: int) -> void:
	var made := 0
	for i in range(GRID_MIN, GRID_MAX + 1):
		if not _road_line(i):
			continue
		for axis in [0, 1]:
			for side in [-1.0, 1.0]:
				if made >= limit:
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

func _spawn_lamps(kinds: Array, defs: Array, limit: int) -> void:
	var made := 0
	for i in range(GRID_MIN, GRID_MAX + 1):
		if not _road_line(i):
			continue
		var along := float(GRID_MIN + 2)
		while along < float(GRID_MAX - 1):
			if made >= limit:
				return
			if not _road_line(int(round(along))):
				var p := Vector3(along, 0, float(i) + 0.48)
				if not _overlaps(p, 0.25):
					var ki: int = kinds[made % kinds.size()]
					_add_prop(ki, p, Vector3.ZERO, 0.0, defs[ki])
					made += 1
			along += 3.0

func _spawn_cars(kinds: Array, defs: Array, limit: int) -> void:
	var made := 0
	for i in range(GRID_MIN, GRID_MAX + 1):
		if not _road_line(i):
			continue
		for axis in [0, 1]:
			for sgn in [-1.0, 1.0]:
				if made >= limit:
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
		tint = Color.WHITE.lerp(palette[randi() % palette.size()], 0.62)
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
	_add_city(inst)
	kind_multimeshes[ki] = mm

func _build_shadows() -> void:
	var img := Image.create(48, 48, false, Image.FORMAT_RGBA8)
	for y in 48:
		for x in 48:
			var d := Vector2(float(x) - 23.5, float(y) - 23.5).length() / 23.5
			var a := clampf(1.0 - smoothstep(0.15, 1.0, d), 0.0, 1.0)
			img.set_pixel(x, y, Color(0, 0, 0, a * a * 0.72))
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
	_add_city(inst)

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
	ui.layer = 2
	hud_layer = ui
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
	level_lbl.position = Vector2(18, 96)
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
	over_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	over_panel.visible = false
	ui.add_child(over_panel)
	over_lbl = Label.new()
	over_lbl.position = Vector2(40, 220)
	over_lbl.size = Vector2(640, 420)
	over_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	over_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_style(over_lbl, 40)
	over_panel.add_child(over_lbl)
	double_btn = _make_button("Double coins", Vector2(150, 680), Vector2(420, 70), Color(0.95, 0.62, 0.15))
	double_btn.pressed.connect(_on_double_coins)
	over_panel.add_child(double_btn)
	next_btn = _make_button("Next level", Vector2(150, 770), Vector2(420, 70), Color(0.18, 0.55, 0.42))
	next_btn.pressed.connect(_on_next_level)
	over_panel.add_child(next_btn)
	continue_btn = _make_button("Menu", Vector2(150, 860), Vector2(420, 70), Color(0.18, 0.28, 0.48))
	continue_btn.pressed.connect(_on_continue)
	over_panel.add_child(continue_btn)
	debug_lbl = Label.new()
	debug_lbl.position = Vector2(16, 150)
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
	if mode != "play" or not playing:
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

func _start_radius() -> float:
	return Save.start_radius()

func _move_speed() -> float:
	var base := _cam_dist_for(LEVEL_RADIUS[0])
	var dist := _cam_dist_for(shown_radius)
	var factor := pow(maxf(dist, 0.001) / base, SPEED_SCREEN)
	return BASE_SPEED * speed_scale * Save.speed_mul() * factor

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

func _mostly_over(size: float, dist: float) -> bool:
	return dist + size * 0.35 < hole_radius

func _sync_level() -> void:
	var n := level
	while n + 1 < LEVEL_SCORE.size() and score >= LEVEL_SCORE[n + 1]:
		n += 1
	if n != level:
		level = n
		pop_t = POP_TIME
	hole_radius = maxf(LEVEL_RADIUS[level], _start_radius())

func _map_progress() -> float:
	return clampf(float(score) / float(maxi(target_score, 1)), 0.0, 1.0)

func _refresh_hud() -> void:
	score_lbl.text = "%d / %d" % [score, target_score]
	var sec := int(ceili(time_left))
	var m := int(float(sec) / 60.0)
	var s := sec % 60
	timer_lbl.text = "%d:%02d" % [m, s]
	level_lbl.text = "%s  Size %d" % [str(map.get("name", "")), level + 1]
	bar_fill.size = Vector2(244.0 * _map_progress(), 12.0)
	shown_score = score
	shown_sec = sec
	shown_level = level

func _process(delta: float) -> void:
	var frame_delta := delta
	delta = minf(delta, 1.0 / 20.0)
	if mode != "play" and mode != "results":
		if debug_on:
			_update_debug(frame_delta)
		return
	if playing:
		time_left -= delta
		if time_left <= 0.0:
			_finish_round(false)
		elif score >= target_score:
			_finish_round(true)
		else:
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
	var over := _mostly_over(size, dist)
	if _fits(size) and (over or committed):
		b.collision_mask = 0
	elif _fits(size) and dist < hole_radius + size * 0.15:
		b.collision_mask = 1
		if dist < hole_radius and dist > 0.04:
			var axis := inward.cross(Vector3.UP)
			var lean := clampf((hole_radius - dist) / maxf(hole_radius, 0.2), 0.0, 1.0)
			b.apply_torque(axis * (4.0 * mass * lean))
	else:
		b.collision_mask = 1
		if not _fits(size) and dist < hole_radius:
			var push := inward
			if push.length_squared() < 0.01:
				push = Vector3(1, 0, 0)
			b.apply_central_force(-push * (48.0 * mass))
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

func _apply_theme(m: Dictionary) -> void:
	sky_mat.sky_top_color = m.sky_top
	sky_mat.sky_horizon_color = m.horizon
	sky_mat.ground_horizon_color = m.horizon
	sky_mat.ground_bottom_color = m.ground
	world_env.fog_light_color = m.fog
	world_env.adjustment_saturation = float(m.sat)
	sun.light_color = m.sun
	sun.rotation_degrees = Vector3(-54, float(m.sun_yaw), 0)

func _apply_skin() -> void:
	if pit_mat == null:
		return
	var skin: Dictionary = CatalogScript.skin_by_id(Save.skin_id)
	pit_mat.set_shader_parameter("rim_color", skin.a)
	pit_mat.set_shader_parameter("rim_color_b", skin.b)
	pit_mat.set_shader_parameter("pattern", int(skin.pattern))
	pit_mat.set_shader_parameter("glow", float(skin.glow))

func _clear_city() -> void:
	playing = false
	joy_held = false
	for o in active.duplicate():
		if o.body != null:
			_pool_body(o.body)
			o.body = null
		o.in_body = false
	active.clear()
	props.clear()
	movers.clear()
	for list in kind_lists:
		(list as Array).clear()
	for i in kind_multimeshes.size():
		kind_multimeshes[i] = null
	shadow_mm = null
	shadow_owners.clear()
	if city_root != null and is_instance_valid(city_root):
		city_root.queue_free()
	city_root = null

func start_round(index: int) -> void:
	_clear_city()
	map_index = clampi(index, 0, CatalogScript.maps().size() - 1)
	map = CatalogScript.maps()[map_index]
	target_score = int(map.target)
	_apply_theme(map)
	_apply_skin()
	score = 0
	level = 0
	pop_t = 0.0
	hole_radius = _start_radius()
	shown_radius = hole_radius
	_sync_level()
	hole_pos = Vector3.ZERO
	velocity = Vector3.ZERO
	joy_held = false
	time_left = ROUND_TIME + Save.extra_time()
	round_cleared = false
	coins_earned = 0
	doubled = false
	shown_score = -1
	shown_sec = -1
	shown_level = -1
	_spawn_city()
	hole_mesh.visible = true
	hole_mesh.position = hole_pos
	cam_distance = _cam_dist_for(hole_radius)
	cam_look = hole_pos
	cam.position = hole_pos + _camera_offset(cam_distance)
	cam.look_at(cam_look, Vector3.UP)
	over_panel.visible = false
	hud_layer.visible = true
	menu_layer.visible = false
	mode = "play"
	playing = true
	_refresh_hud()

func _finish_round(cleared: bool) -> void:
	if not playing:
		return
	playing = false
	joy_held = false
	_refresh_joystick()
	round_cleared = cleared
	mode = "results"
	var bonus := 50 if cleared else 0
	coins_earned = int(float(score) * 0.45) + bonus
	doubled = false
	if coins_earned > 0:
		Save.add_coins(coins_earned)
	if cleared:
		Save.mark_cleared(map_index, score)
	var headline := "Level clear!" if cleared else "Time's up"
	var pct := int(_map_progress() * 100.0)
	over_lbl.text = "%s\n%s\n%d / %d  (%d%%)\n+%d coins" % [headline, str(map.name), score, target_score, pct, coins_earned]
	double_btn.visible = true
	double_btn.disabled = false
	double_btn.text = "Double coins"
	next_btn.visible = cleared and map_index + 1 < CatalogScript.maps().size()
	over_panel.visible = true

func _on_double_coins() -> void:
	if doubled:
		return
	AdService.show_rewarded()

func _after_reward(granted: bool) -> void:
	if not granted or doubled or mode != "results":
		return
	doubled = true
	Save.add_coins(coins_earned)
	coins_earned *= 2
	double_btn.text = "Coins doubled"
	double_btn.disabled = true
	var pct := int(_map_progress() * 100.0)
	var headline := "Level clear!" if round_cleared else "Time's up"
	over_lbl.text = "%s\n%s\n%d / %d  (%d%%)\n+%d coins" % [headline, str(map.name), score, target_score, pct, coins_earned]

func _on_next_level() -> void:
	if map_index + 1 < CatalogScript.maps().size() and map_index + 1 <= Save.unlocked_level:
		start_round(map_index + 1)

func _on_continue() -> void:
	AdService.show_interstitial()

func _after_ad() -> void:
	_clear_city()
	hole_mesh.visible = false
	over_panel.visible = false
	hud_layer.visible = false
	_show_screen("menu")

func _build_menu_layer() -> void:
	menu_layer = CanvasLayer.new()
	menu_layer.layer = 4
	add_child(menu_layer)

func _show_screen(which: String) -> void:
	mode = which
	playing = false
	hud_layer.visible = false
	menu_layer.visible = true
	for c in menu_layer.get_children():
		c.queue_free()
	var bg := ColorRect.new()
	bg.color = Color(0.08, 0.12, 0.2)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_STOP
	menu_layer.add_child(bg)
	if which == "menu":
		_screen_menu()
	elif which == "levels":
		_screen_levels()
	elif which == "skins":
		_screen_skins()
	elif which == "shop":
		_screen_shop()
	menu_sha = Label.new()
	menu_sha.anchor_left = 1.0
	menu_sha.anchor_right = 1.0
	menu_sha.offset_left = -220
	menu_sha.offset_right = -16
	menu_sha.offset_top = 18
	menu_sha.offset_bottom = 52
	menu_sha.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_style(menu_sha, 18)
	menu_sha.text = _short_sha()
	menu_layer.add_child(menu_sha)

func _screen_menu() -> void:
	var title := _menu_label("Hole Arcade", Vector2(40, 160), 64)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.size = Vector2(640, 80)
	menu_layer.add_child(title)
	menu_layer.add_child(_menu_label("Coins %d" % Save.coins, Vector2(40, 260), 32))
	var play := _make_button("Play", Vector2(150, 380), Vector2(420, 84), Color(0.16, 0.55, 0.85))
	play.pressed.connect(_on_play)
	menu_layer.add_child(play)
	var levels := _make_button("Levels", Vector2(150, 490), Vector2(420, 76), Color(0.18, 0.32, 0.55))
	levels.pressed.connect(_show_screen.bind("levels"))
	menu_layer.add_child(levels)
	var skins := _make_button("Skins", Vector2(150, 590), Vector2(420, 76), Color(0.42, 0.22, 0.62))
	skins.pressed.connect(_show_screen.bind("skins"))
	menu_layer.add_child(skins)
	var shop := _make_button("Shop", Vector2(150, 690), Vector2(420, 76), Color(0.72, 0.42, 0.12))
	shop.pressed.connect(_show_screen.bind("shop"))
	menu_layer.add_child(shop)

func _on_play() -> void:
	var i := mini(Save.unlocked_level, CatalogScript.maps().size() - 1)
	start_round(i)

func _screen_levels() -> void:
	menu_layer.add_child(_menu_label("Levels", Vector2(40, 24), 42))
	var back := _make_button("Back", Vector2(500, 24), Vector2(180, 56), Color(0.2, 0.24, 0.34))
	back.pressed.connect(_show_screen.bind("menu"))
	menu_layer.add_child(back)
	var scroll := ScrollContainer.new()
	scroll.position = Vector2(36, 110)
	scroll.size = Vector2(648, 1100)
	menu_layer.add_child(scroll)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 10)
	box.custom_minimum_size = Vector2(620, 0)
	scroll.add_child(box)
	var maps: Array = CatalogScript.maps()
	for i in maps.size():
		var m: Dictionary = maps[i]
		var locked := i > Save.unlocked_level
		var best_score := int(Save.best[i]) if i < Save.best.size() else 0
		var label := "%d  %s    %d pts" % [i + 1, str(m.name), int(m.target)]
		if locked:
			label += "    Locked"
		elif best_score > 0:
			label += "    best %d" % best_score
		var b := _make_button(label, Vector2.ZERO, Vector2(600, 72), Color(0.16, 0.28, 0.42) if not locked else Color(0.14, 0.15, 0.18))
		b.disabled = locked
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.pressed.connect(start_round.bind(i))
		box.add_child(b)

func _screen_skins() -> void:
	menu_layer.add_child(_menu_label("Skins", Vector2(40, 24), 42))
	menu_layer.add_child(_menu_label("Coins %d" % Save.coins, Vector2(220, 32), 24))
	var back := _make_button("Back", Vector2(500, 24), Vector2(180, 56), Color(0.2, 0.24, 0.34))
	back.pressed.connect(_show_screen.bind("menu"))
	menu_layer.add_child(back)
	var scroll := ScrollContainer.new()
	scroll.position = Vector2(36, 110)
	scroll.size = Vector2(648, 1100)
	menu_layer.add_child(scroll)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 8)
	box.custom_minimum_size = Vector2(620, 0)
	scroll.add_child(box)
	for s in CatalogScript.skins():
		var id := str(s.id)
		var owned := Save.has_skin(id)
		var status := "Equip"
		if Save.skin_id == id:
			status = "Equipped"
		elif not owned:
			status = _lock_text(str(s.unlock))
		var b := _make_button("%s    %s" % [str(s.name), status], Vector2.ZERO, Vector2(600, 68), s.a)
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.add_theme_color_override("font_color", Color.WHITE)
		b.pressed.connect(_on_skin.bind(id))
		box.add_child(b)

func _lock_text(unlock: String) -> String:
	if unlock.begins_with("coins:"):
		return unlock.substr(6) + " coins"
	if unlock.begins_with("level:"):
		return "Clear level " + unlock.substr(6)
	return "Locked"

func _on_skin(id: String) -> void:
	if Save.has_skin(id):
		Save.equip(id)
		_apply_skin()
		_show_screen("skins")
		return
	var skin: Dictionary = CatalogScript.skin_by_id(id)
	if Save.try_buy_skin(skin):
		Save.equip(id)
		_apply_skin()
	_show_screen("skins")

func _screen_shop() -> void:
	menu_layer.add_child(_menu_label("Shop", Vector2(40, 24), 42))
	menu_layer.add_child(_menu_label("Coins %d" % Save.coins, Vector2(200, 32), 24))
	var back := _make_button("Back", Vector2(500, 24), Vector2(180, 56), Color(0.2, 0.24, 0.34))
	back.pressed.connect(_show_screen.bind("menu"))
	menu_layer.add_child(back)
	_shop_row("Starting size", Save.size_rank, "size", 220)
	_shop_row("Speed", Save.speed_rank, "speed", 360)
	_shop_row("Round time", Save.time_rank, "time", 500)
	var ads := "Ads removed" if IapService.no_ads else "Remove Ads"
	var ads_btn := _make_button(ads, Vector2(80, 700), Vector2(560, 80), Color(0.45, 0.18, 0.22))
	ads_btn.disabled = IapService.no_ads
	ads_btn.pressed.connect(_confirm_remove_ads)
	menu_layer.add_child(ads_btn)
	menu_layer.add_child(_menu_label("Placeholder purchase. No payment in this build.", Vector2(60, 800), 22))

func _shop_row(title: String, rank: int, which: String, y: float) -> void:
	var cost := Save.next_cost(rank)
	var detail := "%s  %d/5" % [title, rank + 1]
	if cost < 0:
		detail += "    Max"
	else:
		detail += "    %d coins" % cost
	menu_layer.add_child(_menu_label(detail, Vector2(50, y), 28))
	var b := _make_button("Buy", Vector2(500, y - 8), Vector2(170, 58), Color(0.2, 0.48, 0.32))
	b.disabled = cost < 0 or Save.coins < cost
	b.pressed.connect(_buy_upgrade.bind(which))
	menu_layer.add_child(b)

func _buy_upgrade(which: String) -> void:
	Save.try_buy_upgrade(which)
	_show_screen("shop")

func _confirm_remove_ads() -> void:
	for c in menu_layer.get_children():
		c.queue_free()
	var bg := ColorRect.new()
	bg.color = Color(0.08, 0.1, 0.16, 0.96)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_STOP
	menu_layer.add_child(bg)
	var msg := _menu_label("Remove ads?\nThis is a placeholder purchase.", Vector2(60, 420), 32)
	msg.size = Vector2(600, 140)
	msg.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	msg.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	menu_layer.add_child(msg)
	var yes := _make_button("Confirm", Vector2(150, 640), Vector2(420, 74), Color(0.55, 0.2, 0.22))
	yes.pressed.connect(_do_remove_ads)
	menu_layer.add_child(yes)
	var no := _make_button("Cancel", Vector2(150, 740), Vector2(420, 64), Color(0.2, 0.24, 0.34))
	no.pressed.connect(_show_screen.bind("shop"))
	menu_layer.add_child(no)

func _do_remove_ads() -> void:
	IapService.purchase_remove_ads()
	_show_screen("shop")

func _menu_label(text: String, pos: Vector2, size: int) -> Label:
	var l := Label.new()
	l.text = text
	l.position = pos
	_style(l, size)
	return l

func _make_button(text: String, pos: Vector2, size: Vector2, color: Color) -> Button:
	var b := Button.new()
	b.text = text
	b.position = pos
	b.size = size
	b.custom_minimum_size = size
	b.add_theme_font_size_override("font_size", 26)
	b.add_theme_color_override("font_color", Color.WHITE)
	b.add_theme_color_override("font_hover_color", Color.WHITE)
	b.add_theme_color_override("font_pressed_color", Color(1, 0.95, 0.8))
	var normal := _btn_box(color)
	var hover := _btn_box(color.lightened(0.12))
	var pressed := _btn_box(color.darkened(0.12))
	var disabled := _btn_box(Color(0.16, 0.17, 0.2))
	b.add_theme_stylebox_override("normal", normal)
	b.add_theme_stylebox_override("hover", hover)
	b.add_theme_stylebox_override("pressed", pressed)
	b.add_theme_stylebox_override("disabled", disabled)
	b.add_theme_stylebox_override("focus", normal)
	return b

func _btn_box(color: Color) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = color
	s.corner_radius_top_left = 14
	s.corner_radius_top_right = 14
	s.corner_radius_bottom_left = 14
	s.corner_radius_bottom_right = 14
	s.content_margin_left = 16
	s.content_margin_right = 16
	s.content_margin_top = 8
	s.content_margin_bottom = 8
	return s
