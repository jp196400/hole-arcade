extends Node3D

const ROUND_TIME := 120.0
const CITY_HALF := 24.6
const GRID_MIN := -24
const GRID_MAX := 24
const PROP_CAP := 1500
const CHUNK_N := 3
const STATIC_CHUNKS := 9
const SLOT_COUNT := 10
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
const FALL_GRAVITY := 2.15
const RIM_MASK := 8
const RIM_COUNT := 16
const COMBO_WINDOW := 1.15
const BUILD_SHA := "__BUILD_SHA__"
const FIRST_AD_SECONDS := 120.0  # cumulative play before the first interstitial; the only first-ad threshold
const AD_COOLDOWN := 90.0
const SAFE_TOP := 58.0
const SAFE_BOTTOM := 40.0
const SAFE_SIDE := 22.0
const BRAND_INK := Color(0.11, 0.16, 0.29)
const BRAND_CREAM := Color(0.99, 0.97, 0.93)
const BRAND_CYAN := Color(0.05, 0.74, 0.84)
const SURF_ROAD := 0
const SURF_GRASS := 1
const SURF_SAND := 2
const SURF_DIRT := 3
const SURF_WATER := 4
const SURF_CONCRETE := 5
const SURF_WOOD := 6
const SURF_FIELD := 7
const SURF_TRACK := 8
const SURF_DOCK := 9
const LEVEL_SCORE := [0, 14, 36, 70, 120, 190]
const LEVEL_RADIUS := [0.50, 0.78, 1.05, 1.42, 1.9, 2.5]
const CLEAR_RATIO := 0.98
const GROW_AT := [0.0, 0.12, 0.28, 0.46, 0.64, 0.82, 1.0]
const GROW_W := [0.0, 0.16, 0.34, 0.52, 0.70, 0.88, 1.0]
const GROUND_SHADER := """shader_type spatial;
render_mode diffuse_lambert, cull_back;
uniform sampler2D albedo_tex : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform vec3 openings[8];
uniform float opening_r[8];
uniform float paint_mode = 0.0;
uniform vec3 grade_tint = vec3(1.0);
varying vec3 world_pos;
void vertex() {
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}
void fragment() {
	float cover = 0.0;
	for (int i = 0; i < 8; i++) {
		if (opening_r[i] > 0.0) {
			float dist = length(world_pos.xz - openings[i].xz);
			float fw = max(fwidth(dist), 0.0008);
			float edge = 1.0 - smoothstep(opening_r[i] - fw, opening_r[i] + fw, dist);
			cover = max(cover, edge);
		}
	}
	if (cover > 0.985) {
		discard;
	}
	vec3 col = texture(albedo_tex, UV).rgb;
	float luma = dot(col, vec3(0.299, 0.587, 0.114));
	float mx = max(col.r, max(col.g, col.b));
	float mn = min(col.r, min(col.g, col.b));
	float sat = mx - mn;
	vec3 outc = col;
	float shade = clamp(0.28 + luma * 0.85, 0.0, 1.0);
	if (paint_mode > 8.5) {
		outc = mix(vec3(0.40, 0.30, 0.18), vec3(0.66, 0.50, 0.32), shade);
	} else if (paint_mode > 7.5) {
		outc = mix(vec3(0.58, 0.30, 0.24), vec3(0.78, 0.42, 0.32), shade);
	} else if (paint_mode > 6.5) {
		outc = mix(vec3(0.52, 0.58, 0.20), vec3(0.74, 0.78, 0.32), shade);
	} else if (paint_mode > 5.5) {
		outc = mix(vec3(0.58, 0.40, 0.24), vec3(0.84, 0.64, 0.40), shade);
	} else if (paint_mode > 4.5) {
		outc = mix(vec3(0.62, 0.64, 0.66), vec3(0.84, 0.85, 0.86), shade);
	} else if (paint_mode > 3.5) {
		outc = mix(vec3(0.10, 0.32, 0.50), vec3(0.22, 0.52, 0.70), shade);
	} else if (paint_mode > 2.5) {
		outc = mix(vec3(0.46, 0.34, 0.22), vec3(0.70, 0.56, 0.36), shade);
	} else if (paint_mode > 1.5) {
		outc = mix(vec3(0.82, 0.70, 0.46), vec3(0.97, 0.88, 0.66), shade);
	} else if (paint_mode > 0.5) {
		outc = mix(vec3(0.16, 0.50, 0.20), vec3(0.46, 0.76, 0.32), shade);
	} else if (luma > 0.78 && sat < 0.2) {
		outc = vec3(0.95, 0.96, 0.98);
	} else if (col.g > col.r + 0.04 && col.g >= col.b - 0.02) {
		outc = mix(vec3(0.16, 0.52, 0.20), vec3(0.48, 0.78, 0.32), shade);
	} else if (luma > 0.64 && sat < 0.22) {
		float walk = clamp((luma - 0.4) / 0.5, 0.0, 1.0);
		outc = mix(vec3(0.90, 0.70, 0.50), vec3(0.98, 0.91, 0.78), walk);
		float tile = step(0.93, fract(world_pos.x * 0.85)) + step(0.93, fract(world_pos.z * 0.85));
		outc *= mix(1.0, 0.82, clamp(tile, 0.0, 1.0));
	} else if (sat < 0.34) {
		float road = clamp(luma * 1.1, 0.0, 1.0);
		vec3 asphalt = mix(vec3(0.16, 0.20, 0.28), vec3(0.34, 0.42, 0.52), road);
		outc = mix(asphalt, col, 0.78);
		float yellow = smoothstep(0.55, 0.85, col.r) * smoothstep(0.4, 0.75, col.g) * (1.0 - col.b);
		float paint = smoothstep(0.68, 0.9, luma);
		outc = mix(outc, vec3(0.96, 0.97, 0.98), paint * 0.8);
		outc = mix(outc, vec3(0.95, 0.78, 0.2), clamp(yellow, 0.0, 1.0) * 0.85);
		float groove = step(0.965, fract(world_pos.x * 1.7)) + step(0.965, fract(world_pos.z * 1.7));
		if (luma > 0.72) {
			outc *= mix(1.0, 0.78, clamp(groove, 0.0, 1.0));
		}
		vec2 cell = floor(world_pos.xz / 5.0);
		vec2 cap = (cell + vec2(0.5)) * 5.0 + vec2(1.2, 0.35);
		float md = length(world_pos.xz - cap);
		float mfw = max(fwidth(md), 0.001);
		float lid = 1.0 - smoothstep(0.18 - mfw, 0.24 + mfw, md);
		if (luma < 0.62) {
			outc = mix(outc, vec3(0.1, 0.11, 0.13), lid * 0.9);
			float ring = smoothstep(0.16, 0.2, md) * (1.0 - smoothstep(0.22, 0.26, md));
			outc = mix(outc, vec3(0.55, 0.58, 0.62), ring);
		}
	} else {
		outc = clamp(vec3(luma) + (col - vec3(luma)) * 1.35, vec3(0.0), vec3(1.0));
	}
	outc = mix(outc, vec3(0.012, 0.014, 0.02), cover);
	ALBEDO = outc * grade_tint;
	ROUGHNESS = 1.0;
	METALLIC = 0.0;
	SPECULAR = 0.0;
}
"""
const BUILDING_SHADER := """shader_type spatial;
render_mode diffuse_lambert, cull_back;
uniform sampler2D albedo_tex : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
void fragment() {
	float ao = clamp(NORMAL.y * 0.42 + 0.7, 0.58, 1.05);
	if (UV.x > 1.5) {
		vec3 dcol = vec3(0.5, 0.53, 0.56);
		if (UV.y < 0.15) {
			dcol = vec3(0.55, 0.58, 0.62);
		} else if (UV.y < 0.25) {
			dcol = vec3(0.24, 0.16, 0.12);
		} else if (UV.y < 0.35) {
			dcol = vec3(0.82, 0.28, 0.26);
		} else if (UV.y < 0.45) {
			dcol = vec3(0.95, 0.93, 0.86);
		} else if (UV.y < 0.55) {
			dcol = vec3(0.32, 0.52, 0.70);
		} else if (UV.y < 0.65) {
			dcol = COLOR.rgb * 0.72;
		} else if (UV.y < 0.75) {
			dcol = vec3(0.42, 0.58, 0.66);
		} else if (UV.y < 0.85) {
			dcol = vec3(0.96, 0.90, 0.62);
		} else {
			dcol = COLOR.rgb * 0.88;
		}
		ALBEDO = dcol * ao;
		ROUGHNESS = UV.y < 0.55 ? 0.55 : 1.0;
		SPECULAR = 0.0;
	} else {
		vec3 tex = texture(albedo_tex, UV).rgb;
		float luma = dot(tex, vec3(0.299, 0.587, 0.114));
		vec3 candy = COLOR.rgb * mix(0.78, 1.12, clamp(luma, 0.0, 1.0));
		vec3 body = mix(tex, candy, 0.24);
		body *= mix(0.9, 1.08, luma);
		ALBEDO = body * ao;
		ROUGHNESS = mix(0.45, 1.0, luma);
		SPECULAR = 0.0;
	}
	if (COLOR.a < 0.98) {
		float dots = fract(sin(dot(floor(FRAGCOORD.xy * 0.5), vec2(12.9898, 78.233))) * 43758.5453);
		if (dots > COLOR.a) {
			discard;
		}
	}
}
"""
const CAR_SHADER := """shader_type spatial;
render_mode diffuse_lambert, cull_back;
uniform sampler2D albedo_tex : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
void fragment() {
	vec3 tex = texture(albedo_tex, UV).rgb;
	float luma = dot(tex, vec3(0.299, 0.587, 0.114));
	float ao = clamp(NORMAL.y * 0.32 + 0.78, 0.64, 1.05);
	ALBEDO = tex * ao * mix(0.94, 1.06, luma);
	ROUGHNESS = mix(0.35, 0.95, luma);
	SPECULAR = 0.08;
}
"""
const KIT_SHADER := """shader_type spatial;
render_mode diffuse_lambert, cull_disabled;
void fragment() {
	float ao = clamp(NORMAL.y * 0.4 + 0.74, 0.58, 1.05);
	ALBEDO = COLOR.rgb * ao;
	ROUGHNESS = 1.0;
	SPECULAR = 0.0;
	if (COLOR.a < 0.98) {
		float dots = fract(sin(dot(floor(FRAGCOORD.xy * 0.5), vec2(12.9898, 78.233))) * 43758.5453);
		if (dots > COLOR.a) {
			discard;
		}
	}
}
"""
const HOLE_SHADER := """shader_type spatial;
render_mode unshaded, cull_disabled, blend_mix, depth_draw_opaque;
uniform vec3 rim_color : source_color = vec3(0.05, 0.86, 1.0);
uniform vec3 rim_color_b : source_color = vec3(0.8, 0.98, 1.0);
uniform int pattern = 0;
uniform float glow = 0.9;
uniform float vertex_rim = 0.0;
varying vec4 vcol;
varying vec2 xz;
void vertex() {
	vcol = COLOR;
	xz = VERTEX.xz;
}
void fragment() {
	float dist = length(xz);
	float fw = max(fwidth(dist) * 1.5, 0.022);
	float rim_in = 0.96;
	float rim_out = 1.14;
	float alpha = 1.0 - smoothstep(rim_out - fw, rim_out + fw, dist);
	if (alpha < 0.02) {
		discard;
	}
	float t = clamp(dist, 0.0, 1.0);
	vec3 pit = mix(vec3(0.012, 0.014, 0.02), vec3(0.18, 0.19, 0.22), smoothstep(0.12, 0.94, t));
	pit = mix(pit, vec3(0.03, 0.034, 0.04), smoothstep(0.78, 1.0, dist) * 0.25);
	vec3 rim = rim_color;
	if (vertex_rim > 0.5) {
		rim = vcol.rgb;
	} else {
		float ang = atan(xz.x, xz.y);
		float band = sin(ang * 8.0);
		float bw = min(fwidth(band), 0.35);
		float stripes = smoothstep(-bw, bw, band);
		float checks = smoothstep(-bw, bw, sin(ang * 6.0 + dist * 18.0));
		float wave = smoothstep(0.15, 0.85, sin(ang * 5.0) * 0.5 + 0.5);
		float metal = pow(clamp(sin(ang * 3.0) * 0.5 + 0.62, 0.0, 1.0), 1.35);
		if (pattern == 1) {
			rim = mix(rim_color, rim_color_b, stripes);
		} else if (pattern == 2) {
			rim = mix(rim_color, rim_color_b, checks);
		} else if (pattern == 3) {
			rim = mix(rim_color, rim_color_b, wave);
		} else if (pattern == 4) {
			rim = mix(rim_color, rim_color_b, metal);
		}
	}
	float rim_band = smoothstep(rim_in - fw, rim_in + fw, dist);
	rim_band *= 1.0 - smoothstep(rim_out - fw, rim_out + fw, dist);
	float inner = smoothstep(0.90 - fw, 0.97 + fw, dist) * (1.0 - smoothstep(rim_in, rim_in + fw * 1.6, dist));
	float core = smoothstep(1.0, 1.04, dist) * (1.0 - smoothstep(1.06, 1.12, dist));
	vec3 col = mix(pit, rim, rim_band);
	vec3 glow_col = rim * core * glow * 0.16 + rim * inner * 0.14;
	ALBEDO = col + glow_col;
	EMISSION = glow_col;
	ALPHA = alpha;
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
var kind_base: Array = []
var rim_root: Node3D
var rim_bodies: Array = []
var rim_radius := -1.0
var hole_open := 0.5
var combo := 0
var combo_left := 0.0
var size_banner_t := 0.0
var result_anim := 1.0
var result_targets: Array = []
var result_fills: Array = []
var result_labels: Array = []
var so_close_lbl: Label
var star_row: Control
var next_lbl: Label
var next_fill: ColorRect
var combo_lbl: Label
var size_lbl: Label
var round_stars := 0
var rivals: Array = []
var rival_mm: MultiMesh
var rival_labels: Array = []
var rival_rings: Array = []
var player_invuln := 0.0
var shake_t := 0.0
var shake_mag := 0.0
var rim_pulse := 0.0
var opening_centers := PackedVector3Array()
var opening_radii := PackedFloat32Array()
var kind_multimeshes: Array = []
var kind_mats: Array = []
var kind_by_id := {}
var kit_mat: ShaderMaterial
var ground_shader: Shader
var ground_mats: Array = []
var surfaces := PackedByteArray()
var buckets := {}
var prop_seq := 0
var ad_intent := ""
var ad_hold := false
var reward_intent := ""
var reward_skin := ""
var continue_used := false
var rivals_bitten := {}
var fadeables: Array = []
var eaten_name := ""
var round_eaten := ""
var round_trial := ""
var continue_layer: CanvasLayer
var daily_btn: Button
var play_save_wait := 0.0
var chrome_layer: CanvasLayer
var chrome_buttons: Array = []
var hint_lbl: Label
var hand_icon: Control
var level_pill: Button
var logo_lbl: Label
var coin_pill: Button
var star_pill: Button
var result_card: Panel
var attract_armed := false
var pool: Array = []
var pool_free: Array = []
var body_mat: PhysicsMaterial
var shadow_mm: MultiMesh
var shadow_owners: Array = []
var ground_mat: ShaderMaterial
var grass_mat: ShaderMaterial
var hole_mesh: MeshInstance3D
var pop_fx: CPUParticles3D
var floaters: Array = []
var cam: Camera3D
var cam_look := Vector3.ZERO
var cam_distance := 8.0
var cam_pitch := CAM_PITCH_DEG
var cam_dist_mul := 1.0
var cam_look_lift := 0.0
var quality_scale := 1.5
var quality_render := 1.5
var quality_msaa := 2
var quality_fxaa := false
var quality_phase := 0
var quality_warmup := 0.0
var quality_timer := 0.0
var quality_acc := 0.0
var quality_n := 0
var quality_tries := 0
var quality_ceiling := 2.05
var quality_locked := false
var score_lbl: Label
var timer_lbl: Label
var level_lbl: Label
var sha_lbl: Label
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
var clear_total := 0
var clear_eaten := 0
var clear_shown := 0.0
var player_eaten := 0
var map_max_base := 0.4
var final_radius := 2.6
var round_settled := false
var clear_track: ColorRect
var clear_fill: ColorRect
var clear_lbl: Label
var guide_ui: Control
var guide_target := Vector3.ZERO
var guide_on := false
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
var ui_font: Font
var progress_ring: Control
var name_lbl: Label
var unlock_layer: CanvasLayer
var unlock_title: Label
var unlock_body: Label
var unlock_ok: Button
var unlock_queue: Array = []
var toast_busy := false
var toast_gen := 0
const PLAYER_NAME := "You"
const RIVAL_NAMES := ["Midge", "Puddle", "Niblet", "Scoot", "Bramble", "Tumble"]
const RIVAL_COLORS := [
	Color(1.0, 0.32, 0.38), Color(0.25, 0.75, 0.95), Color(0.95, 0.72, 0.18),
	Color(0.35, 0.9, 0.42), Color(0.62, 0.38, 0.95), Color(1.0, 0.48, 0.18),
]
const RIVAL_RADIUS := [0.34, 0.42, 0.30, 0.48, 0.36, 0.44]
const RIVAL_SPEED := [2.15, 2.25, 2.40, 2.05, 2.20, 2.10]
const CatalogScript = preload("res://catalog.gd")
const PropKitScript = preload("res://props_kit.gd")

func _ready() -> void:
	randomize()
	debug_on = _query_debug()
	speed_scale = _query_speed()
	if _query_unlockall():
		Save.unlock_all()
	_boot_quality()
	_load_font()
	body_mat = PhysicsMaterial.new()
	body_mat.friction = 0.42
	body_mat.bounce = 0.04
	_load_textures()
	_build_world()
	_build_ui()
	_make_pool()
	_ensure_models()
	_build_menu_layer()
	_build_chrome()
	AdService.interstitial_closed.connect(_after_ad)
	AdService.rewarded_done.connect(_after_reward)
	_prewarm_shaders()
	var start_idx := mini(Save.unlocked_level, CatalogScript.maps().size() - 1)
	_enter_attract(start_idx)
	var preview := _query_preview()
	if preview == "levels":
		_show_screen("levels")
	elif preview == "results":
		call_deferred("_preview_results")
	elif preview == "ad":
		call_deferred("_preview_ad")
	elif preview == "eaten":
		call_deferred("_preview_eaten")
	elif preview == "progress":
		call_deferred("_preview_progress")
	elif preview == "daily":
		_show_screen("daily")
	elif preview == "skins":
		_show_screen("skins")
	elif preview == "hole" or preview == "street" or preview == "facade":
		call_deferred("_preview_shot", preview)
	elif preview.begins_with("play"):
		var rest := preview.substr(4)
		var idx := start_idx
		if rest.is_valid_int():
			idx = int(rest)
		call_deferred("start_round", idx)

func _preview_results() -> void:
	start_round(2)
	var total := maxi(clear_total, 1)
	clear_eaten = int(ceil(float(total) * CLEAR_RATIO))
	player_eaten = int(float(total) * 0.66)
	score = player_eaten * 5
	clear_shown = _clear_ratio()
	_sync_level()
	shown_radius = hole_radius
	playing = true
	_finish_round(true)
	_dismiss_unlock()

func _preview_progress() -> void:
	start_round(2)
	playing = false
	mode = "play"
	_set_chrome(false)
	_set_match_hud(true)
	var total := maxi(clear_total, 1)
	clear_eaten = int(float(total) * 0.42)
	player_eaten = int(float(clear_eaten) * 0.65)
	score = player_eaten * 4
	clear_shown = _clear_ratio()
	_sync_level()
	shown_radius = hole_radius
	hole_mesh.scale = Vector3(shown_radius, 1.0, shown_radius)
	_refresh_hud()

func _preview_ad() -> void:
	AdService.show_interstitial()

func _preview_eaten() -> void:
	start_round(2)
	playing = false
	_offer_continue("Scoot")

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

func _query_unlockall() -> bool:
	return _web_search().find("unlockall=1") != -1

func _query_preview() -> String:
	var search := _web_search()
	var key := "preview="
	var at := search.find(key)
	if at == -1:
		return ""
	var rest := search.substr(at + key.length())
	var amp := rest.find("&")
	if amp != -1:
		rest = rest.substr(0, amp)
	return rest

func _load_font() -> void:
	var file := load("res://assets/fonts/Fredoka.ttf") as Font
	if file == null:
		ui_font = ThemeDB.fallback_font
		return
	var variation := FontVariation.new()
	variation.base_font = file
	variation.variation_opentype = {"wght": 700.0, "wdth": 100.0}
	ui_font = variation

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
	if ui_font:
		l.add_theme_font_override("font", ui_font)
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", Color.WHITE)
	l.add_theme_color_override("font_outline_color", Color(0.1, 0.18, 0.32, 0.9))
	l.add_theme_constant_override("outline_size", maxi(4, int(size / 5.0)))
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
	mat_nature.metallic_specular = 0.0

func _tex_mat(tex: Texture2D) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_texture = tex
	m.albedo_color = Color.WHITE
	m.vertex_color_use_as_albedo = true
	m.roughness = 1.0
	m.metallic = 0.0
	m.metallic_specular = 0.0
	m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
	return m

func _build_world() -> void:
	var env := WorldEnvironment.new()
	var e := Environment.new()
	sky_mat = ProceduralSkyMaterial.new()
	sky_mat.sky_top_color = Color(0.25, 0.58, 1.0)
	sky_mat.sky_horizon_color = Color(0.55, 0.86, 1.0)
	sky_mat.ground_horizon_color = Color(0.55, 0.9, 0.55)
	sky_mat.ground_bottom_color = Color(0.28, 0.75, 0.32)
	sky_mat.sun_angle_max = 0.0
	var sky := Sky.new()
	sky.sky_material = sky_mat
	e.background_mode = Environment.BG_SKY
	e.sky = sky
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	e.ambient_light_color = Color(1.0, 0.98, 0.94)
	e.ambient_light_energy = 1.0
	e.tonemap_mode = Environment.TONE_MAPPER_LINEAR
	e.tonemap_exposure = 1.02
	e.adjustment_enabled = true
	e.adjustment_brightness = 1.03
	e.adjustment_contrast = 1.12
	e.adjustment_saturation = 0.98
	e.fog_enabled = false
	world_env = e
	env.environment = e
	add_child(env)
	sun = DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-62, 32, 0)
	sun.light_color = Color(1.0, 0.96, 0.86)
	sun.light_energy = 0.4
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
	_build_rim()
	ground_shader = Shader.new()
	ground_shader.code = GROUND_SHADER
	for mode in 10:
		var mat := ShaderMaterial.new()
		mat.shader = ground_shader
		mat.set_shader_parameter("albedo_tex", tex_roads)
		mat.set_shader_parameter("paint_mode", float(mode))
		mat.set_shader_parameter("grade_tint", Vector3.ONE)
		ground_mats.append(mat)
	ground_mat = ground_mats[SURF_ROAD]
	grass_mat = ground_mats[SURF_GRASS]
	opening_centers.resize(8)
	opening_radii.resize(8)
	hole_mesh = MeshInstance3D.new()
	hole_mesh.mesh = _build_pit_mesh()
	var pshader := Shader.new()
	pshader.code = HOLE_SHADER
	pit_mat = ShaderMaterial.new()
	pit_mat.shader = pshader
	pit_mat.render_priority = 2
	pit_mat.set_shader_parameter("vertex_rim", 0.0)
	hole_mesh.material_override = pit_mat
	_apply_skin()
	_no_shadow(hole_mesh)
	hole_mesh.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	add_child(hole_mesh)
	_build_rival_view()
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
	# Flat quad. Local length 1 is the hole radius. The shader draws the rim.
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var y := 0.04
	var e := 1.36
	var c := Color(1, 1, 1, 1)
	var uv := Vector2(0.5, 0.5)
	var n := Vector3.UP
	var p00 := Vector3(-e, y, -e)
	var p10 := Vector3(e, y, -e)
	var p11 := Vector3(e, y, e)
	var p01 := Vector3(-e, y, e)
	for p in [p00, p10, p11, p00, p11, p01]:
		st.set_color(c)
		st.set_uv(uv)
		st.set_normal(n)
		st.add_vertex(p)
	return st.commit()

func _camera_offset(dist: float) -> Vector3:
	var pitch := deg_to_rad(cam_pitch)
	return Vector3(0, sin(pitch) * dist, cos(pitch) * dist)

func _cam_dist_for(radius: float) -> float:
	return (CAM_BASE + radius * CAM_PER_RADIUS) * cam_dist_mul

func _build_rival_view() -> void:
	var sh := Shader.new()
	sh.code = HOLE_SHADER
	var mat := ShaderMaterial.new()
	mat.shader = sh
	mat.render_priority = 2
	mat.set_shader_parameter("vertex_rim", 1.0)
	mat.set_shader_parameter("glow", 0.75)
	rival_mm = MultiMesh.new()
	rival_mm.transform_format = MultiMesh.TRANSFORM_3D
	rival_mm.use_colors = true
	rival_mm.mesh = hole_mesh.mesh
	rival_mm.instance_count = RIVAL_NAMES.size()
	var inst := MultiMeshInstance3D.new()
	inst.multimesh = rival_mm
	inst.material_override = mat
	inst.custom_aabb = AABB(Vector3(-CITY_HALF - 4, -6, -CITY_HALF - 4), Vector3(CITY_HALF * 2 + 8, 16, CITY_HALF * 2 + 8))
	_no_shadow(inst)
	add_child(inst)
	for i in RIVAL_NAMES.size():
		rival_mm.set_instance_transform(i, Transform3D(Basis(), Vector3(0, -30, 0)))
		rival_mm.set_instance_color(i, RIVAL_COLORS[i])

func _build_rim() -> void:
	var made := _make_ring("Rim")
	rim_root = made.root
	rim_bodies = made.bodies
	rim_radius = -1.0
	_layout_ring(rim_bodies, 0.5)
	rim_radius = 0.5
	for i in RIVAL_NAMES.size():
		var ring := _make_ring("RivalRim%d" % i)
		ring.radius = -1.0
		rival_rings.append(ring)

func _make_ring(ring_name: String) -> Dictionary:
	var root := Node3D.new()
	root.name = ring_name
	add_child(root)
	var mat := PhysicsMaterial.new()
	mat.friction = 0.45
	mat.bounce = 0.0
	var bodies: Array = []
	for _i in RIM_COUNT:
		var body := StaticBody3D.new()
		body.collision_layer = RIM_MASK
		body.collision_mask = 0
		body.physics_material_override = mat
		var cs := CollisionShape3D.new()
		cs.shape = BoxShape3D.new()
		body.add_child(cs)
		root.add_child(body)
		bodies.append(body)
	return {"root": root, "bodies": bodies, "radius": -1.0}

func _layout_ring(bodies: Array, radius: float) -> void:
	# Thin ground shelf around the opening. The inner edge is the fulcrum;
	# there is no tall wall, so a body tips over the rim and tumbles in.
	var reach := maxf(1.8, radius * 1.5)
	var height := 0.14
	var mid := radius + reach * 0.5
	var chord := maxf(TAU * radius / float(RIM_COUNT) * 1.32, 0.16)
	for i in bodies.size():
		var ang := TAU * float(i) / float(RIM_COUNT)
		var body: StaticBody3D = bodies[i]
		var cs := body.get_child(0) as CollisionShape3D
		var box := cs.shape as BoxShape3D
		box.size = Vector3(reach, height, chord)
		var outward := Vector3(cos(ang), 0.0, sin(ang))
		var tangent := Vector3(-sin(ang), 0.0, cos(ang))
		body.transform = Transform3D(Basis(outward, Vector3.UP, tangent), outward * mid + Vector3(0, -height * 0.5, 0))

func _place_ring(ring: Dictionary, radius: float, at: Vector3, enabled: bool) -> void:
	var root: Node3D = ring.root
	if not enabled or radius < 0.05:
		root.position = Vector3(0, -40, 0)
		return
	root.global_position = Vector3(at.x, 0.0, at.z)
	if absf(radius - float(ring.radius)) > 0.015:
		_layout_ring(ring.bodies, radius)
		ring.radius = radius

func _sync_rim() -> void:
	if rim_root == null:
		return
	var player_ring := {"root": rim_root, "bodies": rim_bodies, "radius": rim_radius}
	var show_player := playing and hole_open > 0.05
	_place_ring(player_ring, hole_open, hole_pos, show_player)
	rim_radius = float(player_ring.radius)
	for i in rival_rings.size():
		var alive := playing and i < rivals.size() and bool(rivals[i].alive)
		var rad := float(rivals[i].shown) if alive else 0.0
		var at: Vector3 = rivals[i].pos if alive else Vector3.ZERO
		_place_ring(rival_rings[i], rad, at, alive and rad > 0.05)

func _make_pool() -> void:
	for _i in POOL:
		var b := RigidBody3D.new()
		b.collision_layer = 2
		b.collision_mask = 1
		b.gravity_scale = FALL_GRAVITY
		b.linear_damp = 0.04
		b.angular_damp = 0.1
		b.can_sleep = false
		b.continuous_cd = false
		b.axis_lock_angular_x = false
		b.axis_lock_angular_y = false
		b.axis_lock_angular_z = false
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
	return {"mesh": planted, "size": planted.get_aabb().size, "base": _contact_half(planted)}

func _shade_mesh(mesh: Mesh) -> ArrayMesh:
	var arrays: Array = mesh.surface_get_arrays(0)
	var cols: PackedColorArray = arrays[Mesh.ARRAY_COLOR]
	if cols.is_empty():
		return mesh as ArrayMesh
	for i in cols.size():
		var c: Color = cols[i]
		var luma := c.r * 0.3 + c.g * 0.59 + c.b * 0.11
		cols[i] = Color(
			clampf(luma + (c.r - luma) * 1.25, 0.0, 1.0),
			clampf(luma + (c.g - luma) * 1.25, 0.0, 1.0),
			clampf(luma + (c.b - luma) * 1.25, 0.0, 1.0),
			1.0
		)
	arrays[Mesh.ARRAY_COLOR] = cols
	var out := ArrayMesh.new()
	out.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return out

func _contact_half(mesh: Mesh) -> float:
	var aabb := mesh.get_aabb()
	var arrays: Array = mesh.surface_get_arrays(0)
	var verts: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	var y0 := aabb.position.y
	var h := maxf(aabb.size.y, 0.001)
	var cx := aabb.position.x + aabb.size.x * 0.5
	var cz := aabb.position.z + aabb.size.z * 0.5
	var half := 0.0
	var count := 0
	for v in verts:
		if v.y <= y0 + maxf(h * 0.1, 0.02):
			half = maxf(half, maxf(absf(v.x - cx), absf(v.z - cz)))
			count += 1
	if count < 3 or half < 0.012:
		half = maxf(aabb.size.x, aabb.size.z) * 0.22
	return half

func _dress_structure(mesh: ArrayMesh, role: String) -> ArrayMesh:
	# Roof and facade extras stay off the ground-contact band, so swallow size
	# is unchanged. UV.x > 1.5 marks them for the flat detail palette.
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	st.append_from(mesh, 0, Transform3D.IDENTITY)
	var aabb := mesh.get_aabb()
	var sz := aabb.size
	var p := aabb.position
	var cx := p.x + sz.x * 0.5
	var cz := p.z + sz.z * 0.5
	var top := p.y + sz.y
	var u := minf(sz.x, sz.z)
	var ledge_h := clampf(u * 0.045, 0.03, 0.12)
	_detail_box(st, Vector3(cx, top - ledge_h * 0.35, cz), Vector3(sz.x * 0.985, ledge_h, sz.z * 0.985), 0.60)
	_detail_box(st, Vector3(cx + sz.x * 0.22, top + u * 0.055, cz - sz.z * 0.18), Vector3(u * 0.28, u * 0.11, u * 0.22), 0.10)
	_detail_box(st, Vector3(cx + sz.x * 0.22, top + u * 0.12, cz - sz.z * 0.18), Vector3(u * 0.16, u * 0.025, u * 0.10), 0.80)
	if role == "tower" or role == "building":
		_detail_cyl(st, Vector3(cx - sz.x * 0.22, top, cz + sz.z * 0.12), u * 0.11, u * 0.16, 0.70)
		_detail_box(st, Vector3(cx - sz.x * 0.22, top + u * 0.16, cz + sz.z * 0.12), Vector3(u * 0.16, u * 0.03, u * 0.16), 0.10)
	if role == "tower":
		_detail_box(st, Vector3(cx, top, cz), Vector3(u * 0.035, u * 0.55, u * 0.035), 0.10)
		_detail_box(st, Vector3(cx, top + u * 0.52, cz), Vector3(u * 0.16, u * 0.02, u * 0.035), 0.10)
	var door_w := clampf(u * 0.22, 0.12, sz.x * 0.28)
	var door_h := clampf(sz.y * 0.28, 0.2, sz.y * 0.42)
	var front_z := p.z + sz.z - 0.012
	_detail_box(st, Vector3(cx, p.y + door_h * 0.5 + 0.02, front_z), Vector3(door_w, door_h, 0.02), 0.20)
	var awning_y := p.y + door_h + u * 0.06
	if role != "tower":
		_detail_box(st, Vector3(cx, awning_y, p.z + sz.z + u * 0.06), Vector3(door_w * 1.7, u * 0.035, u * 0.16), 0.30)
		_detail_box(st, Vector3(cx, awning_y + u * 0.08, p.z + sz.z - 0.01), Vector3(door_w * 1.35, u * 0.1, 0.02), 0.40)
	_facade_windows(st, aabb, role)
	return st.commit()

func _facade_windows(st: SurfaceTool, aabb: AABB, role: String) -> void:
	var sz := aabb.size
	var p := aabb.position
	var cols := 2 if role == "house" or role == "wide" else 3
	var rows := 2 if role == "house" else mini(4, maxi(2, int(sz.y / maxf(sz.x, 0.2))))
	var win_w := sz.x * 0.12
	var win_h := clampf(sz.y * 0.08, 0.06, sz.y * 0.12)
	for face in 4:
		for row in rows:
			for col in cols:
				var fx := (float(col) + 0.5) / float(cols) - 0.5
				var fy := 0.38 + float(row) * 0.16
				if fy > 0.86:
					continue
				var y := p.y + sz.y * fy
				var c := Vector3.ZERO
				var s := Vector3.ZERO
				if face == 0:
					c = Vector3(p.x + sz.x * 0.5 + fx * sz.x * 0.7, y, p.z + sz.z + 0.01)
					s = Vector3(win_w, win_h, 0.02)
				elif face == 1:
					c = Vector3(p.x + sz.x * 0.5 + fx * sz.x * 0.7, y, p.z - 0.01)
					s = Vector3(win_w, win_h, 0.02)
				elif face == 2:
					c = Vector3(p.x + sz.x + 0.01, y, p.z + sz.z * 0.5 + fx * sz.z * 0.7)
					s = Vector3(0.02, win_h, win_w)
				else:
					c = Vector3(p.x - 0.01, y, p.z + sz.z * 0.5 + fx * sz.z * 0.7)
					s = Vector3(0.02, win_h, win_w)
				_detail_box(st, c, s, 0.50)
				var frame := s * Vector3(1.18, 1.22, 1.0)
				if face >= 2:
					frame = s * Vector3(1.0, 1.22, 1.18)
				_detail_box(st, c, frame, 0.10)

func _detail_box(st: SurfaceTool, c: Vector3, s: Vector3, uv_y: float) -> void:
	var hx := s.x * 0.5
	var hy := s.y * 0.5
	var hz := s.z * 0.5
	var y0 := c.y - hy
	var y1 := c.y + hy
	_detail_quad(st, Vector3(c.x - hx, y1, c.z + hz), Vector3(c.x + hx, y1, c.z + hz), Vector3(c.x + hx, y1, c.z - hz), Vector3(c.x - hx, y1, c.z - hz), uv_y)
	_detail_quad(st, Vector3(c.x - hx, y0, c.z - hz), Vector3(c.x + hx, y0, c.z - hz), Vector3(c.x + hx, y0, c.z + hz), Vector3(c.x - hx, y0, c.z + hz), uv_y)
	_detail_quad(st, Vector3(c.x - hx, y0, c.z + hz), Vector3(c.x + hx, y0, c.z + hz), Vector3(c.x + hx, y1, c.z + hz), Vector3(c.x - hx, y1, c.z + hz), uv_y)
	_detail_quad(st, Vector3(c.x + hx, y0, c.z - hz), Vector3(c.x - hx, y0, c.z - hz), Vector3(c.x - hx, y1, c.z - hz), Vector3(c.x + hx, y1, c.z - hz), uv_y)
	_detail_quad(st, Vector3(c.x + hx, y0, c.z + hz), Vector3(c.x + hx, y0, c.z - hz), Vector3(c.x + hx, y1, c.z - hz), Vector3(c.x + hx, y1, c.z + hz), uv_y)
	_detail_quad(st, Vector3(c.x - hx, y0, c.z - hz), Vector3(c.x - hx, y0, c.z + hz), Vector3(c.x - hx, y1, c.z + hz), Vector3(c.x - hx, y1, c.z - hz), uv_y)

func _detail_cyl(st: SurfaceTool, base: Vector3, radius: float, height: float, uv_y: float) -> void:
	var sides := 10
	var top := base + Vector3(0, height, 0)
	for i in sides:
		var a0 := TAU * float(i) / float(sides)
		var a1 := TAU * float(i + 1) / float(sides)
		var b0 := base + Vector3(cos(a0) * radius, 0, sin(a0) * radius)
		var b1 := base + Vector3(cos(a1) * radius, 0, sin(a1) * radius)
		var t0 := b0 + Vector3(0, height, 0)
		var t1 := b1 + Vector3(0, height, 0)
		_detail_quad(st, b0, t0, t1, b1, uv_y)
		_detail_tri(st, top, t1, t0, uv_y)
		_detail_tri(st, base, b0, b1, uv_y)

func _detail_quad(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, d: Vector3, uv_y: float) -> void:
	_detail_tri(st, a, b, c, uv_y)
	_detail_tri(st, a, c, d, uv_y)

func _detail_tri(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, uv_y: float) -> void:
	var n := (b - a).cross(c - a)
	n = Vector3.UP if n.length_squared() < 0.000001 else n.normalized()
	var uv := Vector2(2.0, uv_y)
	st.set_normal(n)
	st.set_color(Color.WHITE)
	st.set_uv(uv)
	st.add_vertex(a)
	st.set_normal(n)
	st.set_color(Color.WHITE)
	st.set_uv(uv)
	st.add_vertex(b)
	st.set_normal(n)
	st.set_color(Color.WHITE)
	st.set_uv(uv)
	st.add_vertex(c)

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

func _kind_material(spec: Array) -> Material:
	if str(spec[0]) == "":
		return kit_mat
	var role := str(spec[5])
	if role in ["building", "wide", "house", "tower"]:
		return _textured_shader(BUILDING_SHADER, spec[1])
	if role == "car":
		return _textured_shader(CAR_SHADER, spec[1])
	return spec[1]

func _textured_shader(code: String, src_mat: Material) -> ShaderMaterial:
	var sm := ShaderMaterial.new()
	var sh := Shader.new()
	sh.code = code
	sm.shader = sh
	var src := src_mat as StandardMaterial3D
	if src:
		sm.set_shader_parameter("albedo_tex", src.albedo_texture)
	return sm

func _boot_quality() -> void:
	var preview := _query_preview()
	if preview in ["hole", "street", "facade"]:
		quality_locked = true
	_apply_quality(1.5, Viewport.MSAA_4X, false)

func _pixel_ratio() -> float:
	if not OS.has_feature("web"):
		return 1.0
	var raw = JavaScriptBridge.eval("(window.devicePixelRatio||1)", true)
	var ratio := float(raw)
	if ratio < 0.5 or ratio > 4.0:
		return 1.0
	return ratio

func _apply_quality(scale: float, msaa: Viewport.MSAA, fxaa: bool) -> void:
	quality_scale = scale
	quality_msaa = int(msaa)
	quality_fxaa = fxaa
	var vp := get_viewport()
	if vp == null:
		return
	var render := clampf(scale / _pixel_ratio(), 0.2, 2.0)
	quality_render = render
	vp.scaling_3d_mode = Viewport.SCALING_3D_MODE_BILINEAR
	vp.scaling_3d_scale = render
	vp.msaa_3d = msaa
	vp.screen_space_aa = Viewport.SCREEN_SPACE_AA_FXAA if fxaa else Viewport.SCREEN_SPACE_AA_DISABLED

func _tick_quality(delta: float) -> void:
	if quality_locked:
		return
	if quality_phase == 0:
		quality_warmup += delta
		if quality_warmup >= 1.6:
			quality_phase = 1
			quality_timer = 0.0
			quality_acc = 0.0
			quality_n = 0
		return
	quality_timer += delta
	quality_acc += delta
	quality_n += 1
	if quality_timer < 1.0:
		return
	var fps := float(quality_n) / maxf(quality_acc, 0.001)
	quality_tries += 1
	var steps: Array = [1.0, 1.25, 1.5, 2.0]
	var idx := 0
	var best := 99.0
	for i in steps.size():
		var d := absf(float(steps[i]) - quality_scale)
		if d < best:
			best = d
			idx = i
	if fps < 55.0:
		if idx > 0:
			quality_ceiling = float(steps[idx])
			_apply_quality(float(steps[idx - 1]), Viewport.MSAA_4X, false)
		else:
			_apply_quality(1.0, Viewport.MSAA_2X, true)
			quality_locked = true
	elif fps > 58.0 and idx + 1 < steps.size() and float(steps[idx + 1]) < quality_ceiling and quality_tries < 4:
		_apply_quality(float(steps[idx + 1]), Viewport.MSAA_4X, false)
	else:
		quality_locked = true
	quality_timer = 0.0
	quality_acc = 0.0
	quality_n = 0

func _preview_shot(kind: String) -> void:
	quality_locked = true
	_apply_quality(1.5, Viewport.MSAA_4X, false)
	_set_chrome(false)
	_set_match_hud(false)
	if hud_layer:
		hud_layer.visible = false
	if kind == "street":
		hole_pos = Vector3(0.05, 0.0, 0.35)
		cam_pitch = 50.0
		cam_dist_mul = 0.44
		cam_look_lift = 0.85
		_stage_showcase()
	elif kind == "facade":
		hole_pos = Vector3(2.5, 0.0, 5.25)
		cam_pitch = 38.0
		cam_dist_mul = 0.48
		cam_look_lift = 2.6
	else:
		hole_pos = Vector3.ZERO
		cam_pitch = 54.0
		cam_dist_mul = 0.34
		cam_look_lift = 0.05
	shown_radius = hole_radius
	hole_open = hole_radius
	hole_mesh.position = hole_pos
	hole_mesh.scale = Vector3(hole_radius, 1.0, hole_radius)
	cam_distance = _cam_dist_for(shown_radius)
	cam_look = hole_pos + Vector3(0.0, cam_look_lift, 0.0)
	cam.position = hole_pos + _camera_offset(cam_distance)
	cam.look_at(cam_look, Vector3.UP)

func _stage_showcase() -> void:
	var spots: Array = [
		Vector3(0.22, 0, -1.15),
		Vector3(-0.28, 0, -2.35),
		Vector3(0.18, 0, -3.55),
		Vector3(-0.24, 0, -4.85),
		Vector3(0.26, 0, -6.15),
	]
	var headings: Array = [
		Vector3(0, 0, -1),
		Vector3(0, 0, -1),
		Vector3(0, 0, 1),
		Vector3(0, 0, -1),
		Vector3(0, 0, -1),
	]
	var used := {}
	var n := 0
	for o in props:
		if n >= spots.size():
			break
		var role := str(o.role)
		if role != "car" and role != "bus" and role != "truck":
			continue
		var ki := int(o.kind)
		if used.has(ki):
			continue
		used[ki] = true
		var p: Vector3 = spots[n]
		var dir: Vector3 = headings[n]
		o.pos = p
		o.dir = dir
		o.mover = 0
		o.speed = 0.0
		o.yaw = atan2(dir.x, dir.z)
		var basis := Basis(Vector3.UP, float(o.yaw)).scaled(o.scale)
		var xform := Transform3D(basis, p)
		o.xform = xform
		var mm := _mm_of(o)
		if mm:
			mm.set_instance_transform(int(o.index), xform)
		_set_shadow(o)
		_bucket_move(o)
		n += 1

func _ensure_models() -> void:
	if not prop_defs.is_empty():
		return
	var kit_shader := Shader.new()
	kit_shader.code = KIT_SHADER
	kit_mat = ShaderMaterial.new()
	kit_mat.shader = kit_shader
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
	var ids := ["cone", "barrier", "person_a", "person_b", "person_c", "lamp", "bush", "planter", "tree_small", "dumpster", "tree_large", "tree_simple", "sedan", "taxi", "hatch", "van", "bld_a", "bld_b", "bld_c", "bld_d", "wide", "house_a", "house_b", "house_c", "tower_a", "tower_c"]
	for d in prop_defs:
		var info := _load_model(str(d[0]))
		var role := str(d[5])
		if role in ["building", "wide", "house", "tower"]:
			var base := float(info.base)
			var dressed := _dress_structure(info.mesh, role)
			info.mesh = dressed
			info.size = dressed.get_aabb().size
			info.base = base
		kind_lists.append(_empty_slots())
		kind_meshes.append(info.mesh)
		kind_native.append(info.size)
		kind_base.append(float(info.base))
		kind_mats.append(_kind_material(d))
		kind_multimeshes.append(null)
	for i in ids.size():
		kind_by_id[ids[i]] = i
	for item in PropKitScript.defs():
		var spec := ["", kit_mat, 1.0, 1.0, int(item.points), str(item.role), int(item.mover), 0.0]
		prop_defs.append(spec)
		kind_lists.append(_empty_slots())
		kind_meshes.append(item.mesh)
		kind_native.append(item.size)
		kind_base.append(float(item.base))
		kind_mats.append(kit_mat)
		kind_multimeshes.append(null)
		kind_by_id[str(item.id)] = prop_defs.size() - 1
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
	for slots in kind_lists:
		for list in slots:
			(list as Array).clear()
	for i in kind_multimeshes.size():
		kind_multimeshes[i] = null
	fadeables.clear()
	buckets.clear()
	prop_seq = 0
	_spawn_ground()
	_populate()
	for ki in kind_meshes.size():
		_build_kind_multimesh(ki)
	_build_shadows()

func _spawn_ground() -> void:
	_build_surfaces()
	var straight: Array = []
	var crosses: Array = []
	var piles := {}
	for surf in range(0, 10):
		piles[surf] = []
	var n := GRID_MAX - GRID_MIN + 1
	for j in n:
		for i in n:
			var x := GRID_MIN + i
			var z := GRID_MIN + j
			var surf := int(surfaces[j * n + i])
			var at := Vector3(float(x), 0.0, float(z))
			if surf == SURF_ROAD:
				var ex := _surf_i(x - 1, z) == SURF_ROAD or _surf_i(x + 1, z) == SURF_ROAD
				var ez := _surf_i(x, z - 1) == SURF_ROAD or _surf_i(x, z + 1) == SURF_ROAD
				if ex and ez:
					crosses.append(at)
				elif ex:
					straight.append({"at": at, "yaw": 0.0})
				else:
					straight.append({"at": at, "yaw": PI * 0.5})
			else:
				(piles[surf] as Array).append(at)
	_tile_multimesh(ground_meshes[0], straight, true, ground_mat)
	_tile_multimesh(ground_meshes[2], crosses, false, ground_mat)
	for surf in range(1, 10):
		var items: Array = piles[surf]
		if items.is_empty():
			continue
		_tile_multimesh(ground_meshes[3], items, false, ground_mats[surf])

func _build_surfaces() -> void:
	var n := GRID_MAX - GRID_MIN + 1
	surfaces = PackedByteArray()
	surfaces.resize(n * n)
	var layout := str(map.get("layout", "grid"))
	for j in n:
		for i in n:
			var x := GRID_MIN + i
			var z := GRID_MIN + j
			surfaces[j * n + i] = _surface_at(layout, x, z)

func _surface_at(layout: String, x: int, z: int) -> int:
	if layout == "grid":
		return SURF_ROAD if x % 5 == 0 or z % 5 == 0 else SURF_GRASS
	if layout == "suburb":
		return SURF_ROAD if x % 10 == 0 or z % 10 == 0 else SURF_GRASS
	if layout == "park":
		var path := absf(float(x) - sin(float(z) * 0.22) * 11.0)
		if path < 1.15:
			return SURF_DIRT
		var px := float(x) - 6.0
		var pz := float(z) - 4.0
		if px * px + pz * pz < 22.0 and path > 1.45:
			return SURF_WATER
		var qx := float(x) + 14.0
		var qz := float(z) + 10.0
		if qx * qx * 0.35 + qz * qz < 16.0 and path > 1.45:
			return SURF_WATER
		var rx := float(x) + 4.0
		var rz := float(z) - 16.0
		if rx * rx + rz * rz < 14.0 and path > 1.45:
			return SURF_WATER
		return SURF_GRASS
	if layout == "boardwalk":
		if z >= 15:
			return SURF_WATER
		if z >= 11 and z <= 13:
			return SURF_WOOD
		return SURF_SAND
	if layout == "farm":
		if absi(x) <= 1 or absi(z) <= 1:
			return SURF_DIRT
		if (absi(x) / 4) % 2 == (absi(z) / 4) % 2:
			return SURF_FIELD
		return SURF_GRASS
	if layout == "harbor":
		var dock := absi(x) % 7 == 0 and z >= 1 and z <= 18
		if dock:
			return SURF_DOCK if z >= 8 else SURF_CONCRETE
		if z >= 10:
			return SURF_WATER
		return SURF_CONCRETE
	if layout == "campus":
		if absi(x) <= 6 and absi(z) <= 6:
			return SURF_CONCRETE
		if x >= 10 and z <= -8:
			var fx := float(x) - 16.0
			var fz := float(z) + 15.5
			var ring := sqrt(fx * fx + fz * fz)
			if ring > 5.0 and ring < 7.4:
				return SURF_TRACK
			if ring <= 5.0:
				return SURF_GRASS
		if absi(x) <= 1 or absi(z) <= 1:
			return SURF_ROAD
		return SURF_GRASS
	if layout == "fair":
		var radial := sqrt(float(x * x + z * z))
		if radial > 10.0 and radial < 13.8:
			return SURF_DIRT
		if absi(x) <= 3 and absi(z) <= 3:
			return SURF_CONCRETE
		return SURF_GRASS
	if layout == "industrial":
		return SURF_ROAD if x % 6 == 0 or z % 6 == 0 else SURF_CONCRETE
	return SURF_ROAD if x % 4 == 0 or z % 4 == 0 else SURF_CONCRETE

func _surf_i(x: int, z: int) -> int:
	if x < GRID_MIN or x > GRID_MAX or z < GRID_MIN or z > GRID_MAX:
		return -1
	return _surf_f(float(x), float(z))

func _surf_f(x: float, z: float) -> int:
	if surfaces.is_empty():
		return SURF_GRASS
	var n := GRID_MAX - GRID_MIN + 1
	var i := clampi(int(round(x)) - GRID_MIN, 0, n - 1)
	var j := clampi(int(round(z)) - GRID_MIN, 0, n - 1)
	return int(surfaces[j * n + i])

func _tile_multimesh(mesh: Mesh, items: Array, has_yaw: bool, mat: Material) -> void:
	if items.is_empty() or mat == null:
		return
	var bins: Array = []
	bins.resize(STATIC_CHUNKS)
	for c in STATIC_CHUNKS:
		bins[c] = []
	for n in items.size():
		var pos := Vector3.ZERO
		if has_yaw:
			pos = (items[n] as Dictionary).at
		else:
			pos = items[n]
		(bins[_static_chunk(pos)] as Array).append(n)
	for c in STATIC_CHUNKS:
		var bin: Array = bins[c]
		if bin.is_empty():
			continue
		var mm := MultiMesh.new()
		mm.transform_format = MultiMesh.TRANSFORM_3D
		mm.mesh = mesh
		mm.instance_count = bin.size()
		for n in bin.size():
			var src: int = bin[n]
			var pos: Vector3
			var yaw := 0.0
			if has_yaw:
				var item: Dictionary = items[src]
				pos = item.at
				yaw = float(item.yaw)
			else:
				pos = items[src]
			mm.set_instance_transform(n, Transform3D(Basis(Vector3.UP, yaw), pos))
		var inst := MultiMeshInstance3D.new()
		inst.multimesh = mm
		inst.material_override = mat
		inst.custom_aabb = _chunk_aabb(c, -4.0, 20.0)
		_no_shadow(inst)
		_add_city(inst)

func _populate() -> void:
	var layout := str(map.get("layout", "grid"))
	if layout == "grid":
		_fill_blocks(5, ["bld_a", "bld_b", "bld_c", "bld_d", "wide", "tower_a", "tower_c"], 0.92, 1.55)
		_scatter_on(["tree_small", "tree_large", "tree_simple"], 120, [SURF_GRASS], 1.0)
		_scatter_on(["dumpster"], 48, [SURF_GRASS], 1.0)
		_scatter_on(["bush", "planter"], 160, [SURF_GRASS], 1.0)
		_scatter_on(["cone", "bin", "crate", "hydrant", "sign"], 160, [SURF_GRASS], 1.0)
		_edge_props(["hydrant", "bin", "cone", "sign", "mailbox", "crate", "barrier", "bike"], 2, 400)
		_lamps(64)
		_traffic(36, 70)
		_crowd(110)
		_scatter_on(["stall"], 18, [SURF_GRASS], 1.15)
		_scatter_on(["truck"], 10, [SURF_GRASS], 1.0)
		_place_id("barn", Vector3(8.5, 0, -8.5), Vector3.ZERO, 0.4, 0.72, Color.WHITE, 40)
	elif layout == "suburb":
		_grid_ids(["house_a", "house_b", "house_c"], 3, [SURF_GRASS], 110, 1.0, true)
		_scatter_on(["house_a"], 12, [SURF_GRASS], 1.65)
		_scatter_on(["house_b"], 6, [SURF_GRASS], 2.05)
		_scatter_on(["fence"], 200, [SURF_GRASS], 1.0)
		_scatter_on(["mailbox"], 90, [SURF_GRASS], 1.0)
		_scatter_on(["tree_small", "tree_large", "bush"], 180, [SURF_GRASS], 1.0)
		_scatter_on(["planter"], 80, [SURF_GRASS], 1.0)
		_scatter_on(["bike"], 70, [SURF_GRASS], 1.0)
		_traffic(12, 40)
		_crowd(60)
		_lamps(28)
	elif layout == "park":
		var barn_spots: Array = [Vector3(-9.0, 0, 8.0), Vector3(-11.0, 0, 3.5), Vector3(10.0, 0, -6.0), Vector3(5.5, 0, 10.0), Vector3(-4.0, 0, -11.0), Vector3(16.0, 0, 12.0), Vector3(-16.0, 0, -8.0)]
		for spot in barn_spots:
			if _place_id("barn", spot, Vector3.ZERO, 0.6, 1.12, Color.WHITE, 52):
				break
		_scatter_on(["tree_small", "tree_large", "tree_simple"], 260, [SURF_GRASS], 1.0)
		_scatter_on(["bush"], 200, [SURF_GRASS], 1.0)
		_scatter_on(["bench"], 110, [SURF_GRASS, SURF_DIRT], 1.0)
		_scatter_on(["picnic"], 80, [SURF_GRASS], 1.0)
		_scatter_on(["bike"], 60, [SURF_GRASS, SURF_DIRT], 1.0)
		_scatter_on(["bin", "sign"], 50, [SURF_DIRT], 1.0)
		_scatter_on(["stall"], 16, [SURF_GRASS], 1.0)
		_scatter_on(["stall"], 6, [SURF_GRASS], 1.55)
		_scatter_on(["stall"], 4, [SURF_GRASS], 2.15)
		_crowd(100)
		_lamps(32)
	elif layout == "boardwalk":
		_edge_props(["palm", "bin", "bike"], 2, 180)
		_scatter_on(["umbrella"], 140, [SURF_SAND], 1.0)
		_scatter_on(["chair"], 200, [SURF_SAND], 1.0)
		_scatter_on(["surf"], 80, [SURF_SAND], 1.0)
		_scatter_on(["stall"], 40, [SURF_WOOD, SURF_SAND], 1.0)
		_scatter_on(["truck"], 12, [SURF_SAND], 1.0)
		_scatter_on(["truck"], 4, [SURF_SAND], 1.4)
		_scatter_on(["truck"], 2, [SURF_SAND], 1.75)
		_scatter_on(["palm"], 90, [SURF_SAND], 1.0)
		_scatter_on(["bin", "bike", "sign"], 80, [SURF_SAND], 1.0)
		_crowd(90)
	elif layout == "farm":
		_scatter_on(["barn"], 16, [SURF_GRASS, SURF_FIELD], 1.0)
		_scatter_on(["barn"], 6, [SURF_FIELD], 1.28)
		_scatter_on(["hay"], 240, [SURF_FIELD, SURF_GRASS], 1.0)
		_scatter_on(["hay"], 50, [SURF_FIELD], 1.55)
		_scatter_on(["animal"], 160, [SURF_GRASS, SURF_FIELD], 1.0, Color(0.92, 0.90, 0.86))
		_scatter_on(["fence"], 220, [SURF_GRASS, SURF_FIELD], 1.0)
		_scatter_on(["tractor"], 28, [SURF_DIRT, SURF_GRASS], 1.0)
		_scatter_on(["tractor"], 8, [SURF_FIELD], 1.45)
		_scatter_on(["tree_large"], 48, [SURF_GRASS], 1.0)
		_crowd(48)
	elif layout == "harbor":
		_scatter_on(["crate"], 180, [SURF_CONCRETE, SURF_DOCK], 1.0)
		_scatter_on(["crate"], 80, [SURF_CONCRETE], 2.3, Color(0.35, 0.48, 0.68))
		_scatter_on(["forklift"], 40, [SURF_CONCRETE, SURF_DOCK], 1.0)
		_scatter_on(["tank"], 16, [SURF_CONCRETE], 1.0)
		_scatter_on(["tank"], 5, [SURF_CONCRETE], 1.45)
		_scatter_on(["tank"], 2, [SURF_CONCRETE], 1.8)
		_boats()
		_scatter_on(["pipe"], 80, [SURF_CONCRETE], 1.0)
		_scatter_on(["crate", "bin", "cone", "barrier", "hydrant"], 240, [SURF_CONCRETE, SURF_DOCK], 1.0)
		_crowd(70)
		_lamps(28)
	elif layout == "campus":
		_fill_blocks(8, ["wide", "bld_a", "bld_d", "house_a"], 1.0, 1.35)
		_scatter_on(["bus"], 10, [SURF_ROAD, SURF_CONCRETE], 1.0)
		_scatter_on(["bus"], 2, [SURF_CONCRETE], 1.35)
		_scatter_on(["bus"], 2, [SURF_CONCRETE], 1.65)
		_grid_ids(["locker"], 2, [SURF_CONCRETE, SURF_GRASS], 50, 1.0, false)
		_scatter_on(["bench"], 80, [SURF_GRASS, SURF_CONCRETE], 1.0)
		_scatter_on(["tree_small", "tree_large"], 140, [SURF_GRASS], 1.0)
		_scatter_on(["bush", "planter"], 90, [SURF_GRASS], 1.0)
		_scatter_on(["bike"], 60, [SURF_GRASS, SURF_CONCRETE], 1.0)
		_scatter_on(["bin", "cone", "sign", "bike", "crate"], 200, [SURF_CONCRETE, SURF_GRASS], 1.0)
		_crowd(110)
		_lamps(28)
	elif layout == "fair":
		_scatter_on(["stall"], 160, [SURF_DIRT, SURF_GRASS], 1.0)
		_scatter_on(["ride"], 18, [SURF_GRASS, SURF_CONCRETE], 1.0)
		_scatter_on(["ride"], 6, [SURF_GRASS], 1.28)
		_scatter_on(["bench", "bin", "sign"], 160, [SURF_GRASS, SURF_DIRT], 1.0)
		_scatter_on(["cone"], 90, [SURF_DIRT], 1.0)
		_scatter_on(["bike", "crate", "hydrant", "planter"], 160, [SURF_GRASS], 1.0)
		_crowd(140)
	elif layout == "industrial":
		_fill_blocks(6, ["wide", "bld_b", "bld_c", "dumpster"], 1.0, 1.25)
		_scatter_on(["tank"], 36, [SURF_CONCRETE], 1.0)
		_scatter_on(["tank"], 8, [SURF_CONCRETE], 1.4)
		_scatter_on(["tank"], 4, [SURF_CONCRETE], 1.75)
		_scatter_on(["pipe"], 140, [SURF_CONCRETE], 1.0)
		_scatter_on(["crate"], 70, [SURF_CONCRETE], 2.1, Color(0.55, 0.42, 0.28))
		_scatter_on(["cone", "barrier", "crate", "bin", "hydrant"], 240, [SURF_CONCRETE, SURF_ROAD], 1.0)
		_traffic(16, 28)
		_crowd(60)
		_lamps(32)
	else:
		_fill_blocks(4, ["tower_a", "tower_c", "tower_a", "wide"], 1.05, 1.7)
		_scatter_on(["tree_small"], 60, [SURF_CONCRETE], 1.0)
		_scatter_on(["hydrant", "bin", "cone", "sign", "crate", "bike", "barrier", "mailbox"], 400, [SURF_CONCRETE], 1.0)
		_edge_props(["hydrant", "bin", "cone", "sign", "crate"], 2, 200)
		_lamps(48)
		_traffic(32, 40)
		_crowd(100)
	_tint_animals()

func _fill_blocks(step: int, ids: Array, grow_min: float, grow_max: float) -> void:
	var lines: Array = []
	var i := GRID_MIN
	while i <= GRID_MAX:
		if i % step == 0:
			lines.append(i)
		i += 1
	if lines.size() < 2:
		return
	var n := 0
	for a in range(lines.size() - 1):
		for b in range(lines.size() - 1):
			var ix := (float(lines[a]) + float(lines[a + 1])) * 0.5
			var iz := (float(lines[b]) + float(lines[b + 1])) * 0.5
			var id := str(ids[n % ids.size()])
			_place_id(id, Vector3(ix, 0, iz), Vector3.ZERO, (PI * 0.5) * float(n % 4), randf_range(grow_min, grow_max))
			n += 1

func _scatter_on(ids: Array, count: int, surfs: Array, grow: float, tint: Color = Color.WHITE, points: int = -1) -> void:
	var made := 0
	var tries := 0
	var limit := count * 28
	while made < count and tries < limit and props.size() < PROP_CAP:
		tries += 1
		var span := CITY_HALF - 1.2
		var p := Vector3(randf_range(-span, span), 0, randf_range(-span, span))
		if not _surf_ok(p, surfs):
			continue
		if _layout_blocked(p):
			continue
		var id := str(ids[randi() % ids.size()])
		var yaw := randf() * TAU
		if _place_id(id, p, Vector3.ZERO, yaw, grow, tint, points):
			made += 1

func _grid_ids(ids: Array, step: int, surfs: Array, cap: int, grow: float, with_mail: bool) -> void:
	var made := 0
	var x := GRID_MIN + 2
	while x < GRID_MAX - 1 and made < cap and props.size() < PROP_CAP:
		var z := GRID_MIN + 2
		while z < GRID_MAX - 1 and made < cap and props.size() < PROP_CAP:
			var p := Vector3(float(x), 0, float(z))
			if _surf_ok(p, surfs) and not _layout_blocked(p) and not _near_road(x, z):
				var id := str(ids[absi(x + z) % ids.size()])
				if _place_id(id, p, Vector3.ZERO, (PI * 0.5) * float(absi(x) % 4), grow):
					made += 1
					if with_mail:
						_place_id("mailbox", p + Vector3(1.15, 0, 0.7), Vector3.ZERO, 0.0, 1.0)
			z += step
		x += step

func _edge_props(ids: Array, step: int, cap: int) -> void:
	var made := 0
	var tick := 0
	var n := GRID_MAX - GRID_MIN + 1
	for j in range(1, n - 1):
		for i in range(1, n - 1):
			if made >= cap or props.size() >= PROP_CAP:
				return
			if (i + j * 3) % step != 0:
				continue
			var x := GRID_MIN + i
			var z := GRID_MIN + j
			var surf := _surf_i(x, z)
			if surf != SURF_ROAD and surf != SURF_WOOD and surf != SURF_DOCK and surf != SURF_DIRT:
				continue
			var offs := [Vector3(0.82, 0, 0), Vector3(-0.82, 0, 0), Vector3(0, 0, 0.82), Vector3(0, 0, -0.82)]
			var d: Vector3 = offs[(i + j) % 4]
			var p := Vector3(float(x), 0, float(z)) + d
			var land := _surf_f(p.x, p.z)
			if land == SURF_WATER or land == SURF_ROAD:
				continue
			if _place_id(str(ids[tick % ids.size()]), p, Vector3.ZERO, randf() * TAU):
				made += 1
			tick += 1

func _crowd(count: int) -> void:
	var ids := ["person_a", "person_b", "person_c"]
	var made := 0
	var tries := 0
	while made < count and tries < count * 24 and props.size() < PROP_CAP:
		tries += 1
		var span := CITY_HALF - 1.4
		var p := Vector3(randf_range(-span, span), 0, randf_range(-span, span))
		var surf := _surf_f(p.x, p.z)
		if surf == SURF_WATER or surf == SURF_ROAD or _layout_blocked(p):
			continue
		var ang := randf() * TAU
		var dir := Vector3(cos(ang), 0, sin(ang))
		if _place_id(ids[made % 3], p, dir, -1.0, randf_range(0.92, 1.05)):
			made += 1

func _traffic(moving: int, parked: int) -> void:
	var ids := ["sedan", "taxi", "hatch", "van", "police", "sedan", "taxi", "hatch", "truck", "bus"]
	var spots: Array = []
	var n := GRID_MAX - GRID_MIN + 1
	for j in range(2, n - 2, 2):
		for i in range(2, n - 2, 2):
			var x := GRID_MIN + i
			var z := GRID_MIN + j
			if _surf_f(float(x), float(z)) == SURF_ROAD:
				spots.append(Vector3(float(x), 0, float(z)))
	spots.shuffle()
	var made := 0
	for spot in spots:
		if made >= moving + parked or props.size() >= PROP_CAP:
			return
		var p: Vector3 = spot
		var along_x := _surf_f(p.x + 1.0, p.z) == SURF_ROAD
		var sgn := 1.0 if made % 2 == 0 else -1.0
		var dir := Vector3(sgn, 0, 0) if along_x else Vector3(0, 0, sgn)
		var parked_now := made >= moving
		var at := p
		if parked_now:
			at += Vector3(0, 0, 0.22) if along_x else Vector3(0.22, 0, 0)
		var use_dir := Vector3.ZERO if parked_now else dir
		var mover := 0 if parked_now else -1
		var traffic_id := str(ids[made % ids.size()])
		var traffic_grow := 1.0
		if traffic_id == "bus" or traffic_id == "truck":
			traffic_grow = 0.82
		if _place_id(traffic_id, at, use_dir, -1.0, traffic_grow, Color.WHITE, -1, mover):
			made += 1

func _lamps(cap: int) -> void:
	var made := 0
	var n := GRID_MAX - GRID_MIN + 1
	for j in range(0, n, 4):
		for i in range(0, n, 4):
			if made >= cap:
				return
			var x := GRID_MIN + i
			var z := GRID_MIN + j
			if _surf_f(float(x), float(z)) != SURF_ROAD and _surf_f(float(x), float(z)) != SURF_DIRT and _surf_f(float(x), float(z)) != SURF_WOOD:
				continue
			var p := Vector3(float(x) + 0.7, 0, float(z) + 0.15)
			if _surf_f(p.x, p.z) == SURF_WATER:
				continue
			if _place_id("lamp", p, Vector3.ZERO, 0.0):
				made += 1

func _boats() -> void:
	var n := GRID_MAX - GRID_MIN + 1
	for j in range(0, n, 3):
		for i in n:
			var x := GRID_MIN + i
			var z := GRID_MIN + j
			if _surf_i(x, z) != SURF_DOCK:
				continue
			if _surf_i(x, z + 1) != SURF_WATER and _surf_i(x + 1, z) != SURF_WATER:
				continue
			_place_id("boat", Vector3(float(x), 0, float(z)), Vector3.ZERO, 0.0, 1.0)

func _tint_animals() -> void:
	var coats := [Color(0.92, 0.90, 0.86), Color(0.82, 0.78, 0.72), Color(0.55, 0.42, 0.32), Color(0.95, 0.72, 0.74), Color(0.95, 0.86, 0.35)]
	var n := 0
	for o in props:
		if str(o.role) == "small" and str(kind_id_of(int(o.kind))) == "animal":
			o.color = coats[n % coats.size()]
			n += 1

func _swallow_bucket(id: String) -> String:
	if id in ["sedan", "taxi", "hatch", "van", "police", "truck", "bus", "tractor", "forklift"]:
		return "cars"
	if id in ["tree_small", "tree_large", "tree_simple", "palm"]:
		return "trees"
	if id in ["bld_a", "bld_b", "bld_c", "bld_d", "wide", "house_a", "house_b", "house_c", "tower_a", "tower_c", "barn"]:
		return "buildings"
	if id in ["person_a", "person_b", "person_c"]:
		return "people"
	if id == "boat":
		return "boats"
	if id == "lamp":
		return "lamps"
	if id == "animal":
		return "animals"
	return "props"

func kind_id_of(ki: int) -> String:
	for key in kind_by_id.keys():
		if int(kind_by_id[key]) == ki:
			return str(key)
	return ""

func _surf_ok(p: Vector3, surfs: Array) -> bool:
	var s := _surf_f(p.x, p.z)
	for w in surfs:
		if s == int(w):
			return true
	return false

func _near_road(x: int, z: int) -> bool:
	for dz in range(-1, 2):
		for dx in range(-1, 2):
			if _surf_i(x + dx, z + dz) == SURF_ROAD:
				return true
	return false

func _layout_blocked(p: Vector3) -> bool:
	var layout := str(map.get("layout", ""))
	if layout == "campus":
		var fx := p.x - 16.0
		var fz := p.z + 15.5
		if fx * fx + fz * fz < 30.0:
			return true
	return false

func _overlap_foot(ki: int, sxz: float) -> float:
	var role := str(prop_defs[ki][5])
	if role in ["tree", "lamp", "palm", "umbrella"]:
		return maxf(float(kind_base[ki]) * sxz, 0.08)
	var native: Vector3 = kind_native[ki]
	return maxf(native.x, native.z) * sxz * 0.45

func _place_id(id: String, p: Vector3, dir: Vector3 = Vector3.ZERO, yaw: float = -1.0, grow: float = 1.0, tint: Color = Color.WHITE, points: int = -1, mover: int = -1) -> bool:
	if props.size() >= PROP_CAP or not kind_by_id.has(id):
		return false
	if p.length() < 2.15:
		return false
	if absf(p.x) > CITY_HALF - 0.45 or absf(p.z) > CITY_HALF - 0.45:
		return false
	if _surf_f(p.x, p.z) == SURF_WATER:
		return false
	var ki: int = int(kind_by_id[id])
	var spec: Array = (prop_defs[ki] as Array).duplicate()
	spec[2] = float(spec[2]) * grow
	spec[3] = float(spec[3]) * grow
	if points >= 0:
		spec[4] = points
	elif grow > 1.08:
		spec[4] = maxi(int(spec[4]), int(round(float(spec[4]) * grow)))
	if mover >= 0:
		spec[6] = mover
	var foot := _overlap_foot(ki, float(spec[2]))
	if _overlaps(p, foot):
		return false
	var use_yaw := yaw if yaw >= 0.0 else randf() * TAU
	_add_prop(ki, p, dir, use_yaw, spec)
	if tint != Color.WHITE:
		props[props.size() - 1].color = tint
	return true

func _overlaps(p: Vector3, foot: float, ignore_roles: Array = []) -> bool:
	var reach := foot + 5.5
	var x0 := int(floor((p.x - reach) / 4.0))
	var x1 := int(floor((p.x + reach) / 4.0))
	var z0 := int(floor((p.z - reach) / 4.0))
	var z1 := int(floor((p.z + reach) / 4.0))
	for gx in range(x0, x1 + 1):
		for gz in range(z0, z1 + 1):
			var key := gx * 128 + gz + 8192
			if not buckets.has(key):
				continue
			for o in buckets[key]:
				if str(o.role) in ignore_roles:
					continue
				var op: Vector3 = o.pos
				var pad := 0.16 if foot >= 0.4 else 0.05
				if Vector2(op.x - p.x, op.z - p.z).length() < float(o.size) * 0.72 + foot + pad:
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
	var base := maxf(float(kind_base[ki]) * sxz, 0.05)
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
		var palette: Array = map.get("palette", [])
		if palette.is_empty():
			palette = [Color(0.76, 0.36, 0.36), Color(0.84, 0.70, 0.34), Color(0.36, 0.60, 0.64), Color(0.78, 0.48, 0.52), Color(0.40, 0.50, 0.72)]
		tint = palette[randi() % palette.size()]
	var chunk := _chunk_for(p, mover)
	var list: Array = (kind_lists[ki] as Array)[chunk]
	var o := {
		"kind": ki,
		"chunk": chunk,
		"index": list.size(),
		"shadow": -1,
		"pos": p,
		"yaw": yaw,
		"scale": scale,
		"size": foot,
		"base": base,
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
		"sink": -1,
		"faded": false,
		"uid": prop_seq,
		"fadeable": role in ["building", "wide", "house", "tower", "barn", "ride", "tank", "bus", "boat", "truck"],
	}
	prop_seq += 1
	list.append(o)
	props.append(o)
	_bucket_add(o)
	if bool(o.fadeable):
		fadeables.append(o)
	if mover != 0:
		movers.append(o)

func _empty_slots() -> Array:
	var slots: Array = []
	slots.resize(SLOT_COUNT)
	for i in SLOT_COUNT:
		slots[i] = []
	return slots

func _static_chunk(pos: Vector3) -> int:
	var cell := (CITY_HALF * 2.0) / float(CHUNK_N)
	var ix := clampi(int(floor((pos.x + CITY_HALF) / cell)), 0, CHUNK_N - 1)
	var iz := clampi(int(floor((pos.z + CITY_HALF) / cell)), 0, CHUNK_N - 1)
	return iz * CHUNK_N + ix

func _chunk_for(pos: Vector3, mover: int) -> int:
	if mover != 0:
		return STATIC_CHUNKS
	return _static_chunk(pos)

func _chunk_aabb(c: int, y0: float, height: float) -> AABB:
	if c >= STATIC_CHUNKS:
		return AABB(Vector3(-CITY_HALF - 2, y0, -CITY_HALF - 2), Vector3(CITY_HALF * 2 + 4, height, CITY_HALF * 2 + 4))
	var cell := (CITY_HALF * 2.0) / float(CHUNK_N)
	var ix := c % CHUNK_N
	var iz := int(c / CHUNK_N)
	var margin := 4.0
	var x0 := -CITY_HALF + float(ix) * cell - margin
	var z0 := -CITY_HALF + float(iz) * cell - margin
	return AABB(Vector3(x0, y0, z0), Vector3(cell + margin * 2.0, height, cell + margin * 2.0))

func _mm_of(o: Dictionary) -> MultiMesh:
	var slots = kind_multimeshes[int(o.kind)]
	if slots == null or not (slots is Array):
		return null
	var chunk := int(o.get("chunk", 0))
	var arr: Array = slots
	if chunk < 0 or chunk >= arr.size():
		return null
	return arr[chunk] as MultiMesh

func _build_kind_multimesh(ki: int) -> void:
	var slots: Array = kind_lists[ki]
	var mms: Array = []
	mms.resize(SLOT_COUNT)
	var any := false
	for c in SLOT_COUNT:
		var list: Array = slots[c]
		if list.is_empty():
			mms[c] = null
			continue
		any = true
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
		inst.custom_aabb = _chunk_aabb(c, -6.0, 36.0)
		_no_shadow(inst)
		_add_city(inst)
		mms[c] = mm
	kind_multimeshes[ki] = mms if any else null

func _build_shadows() -> void:
	var img := Image.create(48, 48, false, Image.FORMAT_RGBA8)
	for y in 48:
		for x in 48:
			var d := Vector2(float(x) - 23.5, float(y) - 23.5).length() / 23.5
			var a := clampf(1.0 - smoothstep(0.08, 1.0, d), 0.0, 1.0)
			img.set_pixel(x, y, Color(0.16, 0.22, 0.34, a * 0.46))
	img.generate_mipmaps()
	var tex := ImageTexture.create_from_image(img)
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.albedo_texture = tex
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
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
	var s := float(o.size) * 2.2
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
	var list: Array = (kind_lists[int(o.kind)] as Array)[int(o.chunk)]
	var mm := _mm_of(o)
	var i := int(o.index)
	var last := list.size() - 1
	if i != last:
		var swapped: Dictionary = list[last]
		swapped.index = i
		list[i] = swapped
		if mm:
			mm.set_instance_transform(i, swapped.xform)
			mm.set_instance_color(i, swapped.color)
		swapped.faded = false
	list.pop_back()
	if mm:
		mm.visible_instance_count = list.size()
	o.in_mesh = false
	_drop_shadow(o)

func _build_ui() -> void:
	var ui := CanvasLayer.new()
	ui.layer = 2
	hud_layer = ui
	add_child(ui)
	clear_track = ColorRect.new()
	clear_track.position = Vector2(28, 18)
	clear_track.size = Vector2(664, 36)
	clear_track.color = Color(0.08, 0.10, 0.16, 0.78)
	clear_track.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui.add_child(clear_track)
	clear_fill = ColorRect.new()
	clear_fill.position = Vector2(4, 4)
	clear_fill.size = Vector2(0, 28)
	clear_fill.color = BRAND_CYAN
	clear_fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	clear_track.add_child(clear_fill)
	clear_lbl = Label.new()
	clear_lbl.position = Vector2(28, 58)
	clear_lbl.size = Vector2(664, 56)
	clear_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	clear_lbl.text = "City cleared 0%"
	_style(clear_lbl, 42)
	ui.add_child(clear_lbl)
	score_lbl = Label.new()
	score_lbl.position = Vector2(28, 118)
	score_lbl.size = Vector2(320, 52)
	_style(score_lbl, 40)
	ui.add_child(score_lbl)
	timer_lbl = Label.new()
	timer_lbl.visible = false
	ui.add_child(timer_lbl)
	level_lbl = Label.new()
	level_lbl.position = Vector2(340, 118)
	level_lbl.size = Vector2(352, 52)
	level_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_style(level_lbl, 36)
	ui.add_child(level_lbl)
	next_lbl = Label.new()
	next_lbl.position = Vector2(28, 176)
	next_lbl.size = Vector2(664, 44)
	_style(next_lbl, 32)
	ui.add_child(next_lbl)
	var next_bg := ColorRect.new()
	next_bg.position = Vector2(28, 224)
	next_bg.size = Vector2(420, 18)
	next_bg.color = Color(0.08, 0.10, 0.16, 0.55)
	next_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui.add_child(next_bg)
	next_fill = ColorRect.new()
	next_fill.position = Vector2(3, 3)
	next_fill.size = Vector2(0, 12)
	next_fill.color = Color(1.0, 0.45, 0.7)
	next_fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	next_bg.add_child(next_fill)
	combo_lbl = Label.new()
	combo_lbl.position = Vector2(160, 260)
	combo_lbl.size = Vector2(400, 56)
	combo_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	combo_lbl.visible = false
	_style(combo_lbl, 44)
	combo_lbl.modulate = Color(1, 0.86, 0.2)
	ui.add_child(combo_lbl)
	size_lbl = Label.new()
	size_lbl.text = "SIZE UP!"
	size_lbl.position = Vector2(80, 500)
	size_lbl.size = Vector2(560, 96)
	size_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	size_lbl.visible = false
	size_lbl.pivot_offset = Vector2(280, 48)
	_style(size_lbl, 72)
	ui.add_child(size_lbl)
	name_lbl = Label.new()
	name_lbl.text = PLAYER_NAME
	name_lbl.size = Vector2(180, 48)
	name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_style(name_lbl, 36)
	ui.add_child(name_lbl)
	for i in RIVAL_NAMES.size():
		var tag := Label.new()
		tag.visible = false
		tag.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		tag.size = Vector2(220, 48)
		_style(tag, 36)
		tag.modulate = RIVAL_COLORS[i]
		ui.add_child(tag)
		rival_labels.append(tag)
	sha_lbl = Label.new()
	sha_lbl.anchor_left = 1.0
	sha_lbl.anchor_right = 1.0
	sha_lbl.anchor_top = 1.0
	sha_lbl.anchor_bottom = 1.0
	sha_lbl.offset_left = -220
	sha_lbl.offset_right = -18
	sha_lbl.offset_top = -72
	sha_lbl.offset_bottom = -32
	sha_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_style(sha_lbl, 22)
	sha_lbl.text = _short_sha()
	ui.add_child(sha_lbl)
	for _i in 6:
		var fl := Label.new()
		_style(fl, 40)
		fl.visible = false
		fl.modulate = Color(1, 0.95, 0.4)
		ui.add_child(fl)
		floaters.append({"lbl": fl, "pos": Vector3.ZERO, "age": -1.0})
	over_panel = ColorRect.new()
	(over_panel as ColorRect).color = Color(0.11, 0.16, 0.29, 0.38)
	over_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	over_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	over_panel.visible = false
	ui.add_child(over_panel)
	result_card = Panel.new()
	result_card.anchor_left = 0.5
	result_card.anchor_right = 0.5
	result_card.anchor_top = 0.5
	result_card.anchor_bottom = 0.5
	result_card.offset_left = -330
	result_card.offset_right = 330
	result_card.offset_top = -500
	result_card.offset_bottom = 500
	result_card.add_theme_stylebox_override("panel", _panel_style())
	over_panel.add_child(result_card)
	over_lbl = Label.new()
	over_lbl.position = Vector2(24, 28)
	over_lbl.size = Vector2(612, 150)
	over_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	over_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_style(over_lbl, 56)
	over_lbl.add_theme_color_override("font_color", BRAND_INK)
	over_lbl.add_theme_constant_override("outline_size", 0)
	result_card.add_child(over_lbl)
	star_row = Control.new()
	star_row.position = Vector2(186, 186)
	star_row.size = Vector2(288, 64)
	star_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	star_row.set_meta("stars", 0)
	star_row.draw.connect(_draw_star_row.bind(star_row))
	result_card.add_child(star_row)
	for i in 3:
		var cap := Label.new()
		cap.position = Vector2(36, 268 + i * 112)
		cap.size = Vector2(588, 48)
		_style(cap, 36)
		cap.add_theme_color_override("font_color", BRAND_INK)
		cap.add_theme_constant_override("outline_size", 0)
		result_card.add_child(cap)
		result_labels.append(cap)
		var track := ColorRect.new()
		track.position = Vector2(36, 320 + i * 112)
		track.size = Vector2(588, 22)
		track.color = Color(0.86, 0.88, 0.92)
		track.mouse_filter = Control.MOUSE_FILTER_IGNORE
		result_card.add_child(track)
		var fill := ColorRect.new()
		fill.position = Vector2(3, 3)
		fill.size = Vector2(0, 16)
		fill.color = BRAND_CYAN
		fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
		track.add_child(fill)
		result_fills.append(fill)
	so_close_lbl = Label.new()
	so_close_lbl.text = "So close!"
	so_close_lbl.position = Vector2(36, 600)
	so_close_lbl.size = Vector2(588, 48)
	so_close_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	so_close_lbl.visible = false
	_style(so_close_lbl, 40)
	so_close_lbl.add_theme_color_override("font_color", Color(0.75, 0.22, 0.16))
	so_close_lbl.add_theme_constant_override("outline_size", 0)
	result_card.add_child(so_close_lbl)
	double_btn = _make_button("Watch ad for 2x coins", Vector2(40, 656), Vector2(580, 92), Color(0.90, 0.62, 0.18))
	double_btn.pressed.connect(_on_double_coins)
	result_card.add_child(double_btn)
	next_btn = _make_button("Next level", Vector2(40, 764), Vector2(580, 92), Color(0.16, 0.66, 0.42))
	next_btn.pressed.connect(_on_next_level)
	result_card.add_child(next_btn)
	continue_btn = _make_button("Home", Vector2(40, 872), Vector2(580, 92), BRAND_INK)
	continue_btn.pressed.connect(_on_continue)
	result_card.add_child(continue_btn)
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
	guide_ui = Control.new()
	guide_ui.set_anchors_preset(Control.PRESET_FULL_RECT)
	guide_ui.mouse_filter = Control.MOUSE_FILTER_IGNORE
	guide_ui.draw.connect(_draw_guide)
	ui.add_child(guide_ui)
	_refresh_hud()
	_build_unlock_popup()

func _draw_guide() -> void:
	if guide_ui == null or not guide_on or cam == null:
		return
	var world := guide_target + Vector3(0.0, 1.4, 0.0)
	var vp := guide_ui.size
	if vp.x < 10.0:
		vp = get_viewport().get_visible_rect().size
	var center := vp * 0.5
	var behind := cam.is_position_behind(world)
	var sp := center
	if not behind:
		sp = cam.unproject_position(world)
	var margin := 86.0
	var on_screen := not behind and sp.x > margin and sp.y > 150.0 and sp.x < vp.x - margin and sp.y < vp.y - margin
	var dir := sp - center
	if behind:
		dir = -dir
	if dir.length_squared() < 1.0:
		dir = Vector2(0, -1)
	dir = dir.normalized()
	var pos := sp
	if not on_screen:
		pos = _edge_point(center, dir, vp, margin)
	var tip := pos + dir * 28.0
	var side := Vector2(-dir.y, dir.x)
	var col := Color(1.0, 0.92, 0.35, 0.95)
	guide_ui.draw_colored_polygon(PackedVector2Array([tip, pos - dir * 18.0 + side * 16.0, pos - dir * 18.0 - side * 16.0]), col)
	guide_ui.draw_circle(pos, 8.0, Color(0.08, 0.10, 0.16, 0.9))

func _edge_point(center: Vector2, dir: Vector2, vp: Vector2, margin: float) -> Vector2:
	var half := Vector2(vp.x * 0.5 - margin, vp.y * 0.5 - margin)
	var tx := half.x / maxf(absf(dir.x), 0.001)
	var ty := half.y / maxf(absf(dir.y), 0.001)
	return center + dir * minf(tx, ty)

func _build_unlock_popup() -> void:
	unlock_layer = CanvasLayer.new()
	unlock_layer.layer = 30
	unlock_layer.visible = false
	add_child(unlock_layer)
	var card := Panel.new()
	card.name = "Toast"
	card.anchor_left = 0.5
	card.anchor_right = 0.5
	card.anchor_top = 0.0
	card.offset_left = -320
	card.offset_right = 320
	card.offset_top = 280
	card.offset_bottom = 420
	card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_theme_stylebox_override("panel", _panel_style())
	unlock_layer.add_child(card)
	unlock_title = Label.new()
	unlock_title.text = "Challenge complete"
	unlock_title.position = Vector2(24, 16)
	unlock_title.size = Vector2(592, 48)
	unlock_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	unlock_title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_style(unlock_title, 36)
	unlock_title.add_theme_color_override("font_color", BRAND_INK)
	unlock_title.add_theme_constant_override("outline_size", 0)
	card.add_child(unlock_title)
	unlock_body = Label.new()
	unlock_body.position = Vector2(24, 68)
	unlock_body.size = Vector2(592, 64)
	unlock_body.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	unlock_body.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_style(unlock_body, 32)
	unlock_body.add_theme_constant_override("outline_size", 0)
	card.add_child(unlock_body)

func _announce_skins(found: Array) -> void:
	for s in found:
		unlock_queue.append(s)
	if unlock_layer == null or toast_busy:
		return
	_present_unlock()

func _present_unlock() -> void:
	if unlock_layer == null:
		return
	if unlock_queue.is_empty():
		unlock_layer.visible = false
		toast_busy = false
		return
	var s: Dictionary = unlock_queue.pop_front()
	var prog := Save.progress_for(str(s.unlock))
	var shown := mini(int(prog.cur), int(prog.need))
	unlock_body.text = "%s\n%s %d/%d" % [str(s.name), str(prog.get("label", "")), shown, int(prog.need)]
	unlock_body.add_theme_color_override("font_color", s.a)
	var card := unlock_layer.get_node("Toast") as Panel
	unlock_layer.visible = true
	toast_busy = true
	toast_gen += 1
	var gen := toast_gen
	card.modulate.a = 0.0
	card.offset_top = 280.0
	card.offset_bottom = 420.0
	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(card, "modulate:a", 1.0, 0.28).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tw.tween_property(card, "offset_top", 430.0, 0.32).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tw.tween_property(card, "offset_bottom", 570.0, 0.32).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tw.set_parallel(false)
	tw.tween_interval(2.15)
	tw.tween_property(card, "modulate:a", 0.0, 0.28).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	tw.tween_callback(_finish_toast.bind(gen))

func _finish_toast(gen: int) -> void:
	if gen != toast_gen:
		return
	toast_busy = false
	_present_unlock()

func _dismiss_unlock() -> void:
	toast_gen += 1
	toast_busy = false
	unlock_queue.clear()
	if unlock_layer:
		unlock_layer.visible = false

func _place_name_tag() -> void:
	if name_lbl == null or cam == null or not hole_mesh.visible:
		return
	var p := hole_pos + Vector3(0.0, 1.05, 0.0)
	if cam.is_position_behind(p):
		name_lbl.visible = false
		return
	var sp := cam.unproject_position(p)
	name_lbl.visible = true
	name_lbl.position = sp - Vector2(90, 52)

func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch or event is InputEventMouseButton:
		if event.pressed:
			_unlock_audio()

func _unhandled_input(event: InputEvent) -> void:
	if ad_hold:
		return
	if mode != "play" and mode != "attract":
		return
	if mode == "play" and not playing:
		return
	if event is InputEventScreenTouch:
		if event.pressed:
			joy_held = true
			joy_id = event.index
			joy_anchor = event.position
			joy_finger = event.position
		elif event.index == joy_id:
			if mode == "attract" and joy_finger.distance_to(joy_anchor) <= JOY_DEADZONE:
				_begin_play()
			joy_held = false
		_refresh_joystick()
	elif event is InputEventScreenDrag and joy_held and event.index == joy_id:
		joy_finger = event.position
		if mode == "attract" and joy_finger.distance_to(joy_anchor) > JOY_DEADZONE:
			_begin_play()
		_refresh_joystick()

func _screen_vector_to_world(screen: Vector2) -> Vector3:
	var basis := cam.global_transform.basis
	var right := Vector3(basis.x.x, 0.0, basis.x.z)
	var forward := Vector3(-basis.z.x, 0.0, -basis.z.z)
	right = right.normalized() if right.length_squared() > 0.0001 else Vector3.RIGHT
	forward = forward.normalized() if forward.length_squared() > 0.0001 else Vector3(0, 0, -1)
	return right * screen.x - forward * screen.y

func _start_radius() -> float:
	return Save.start_radius() + float(Save.time_rank) * 0.04

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
	var step := velocity * delta
	var nx := hole_pos.x + step.x
	var nz := hole_pos.z + step.z
	if _surf_f(nx, hole_pos.z) != SURF_WATER:
		hole_pos.x = nx
	if _surf_f(hole_pos.x, nz) != SURF_WATER:
		hole_pos.z = nz
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
	var focus := hole_pos + Vector3(0.0, cam_look_lift, 0.0)
	var want_pos := hole_pos + _camera_offset(cam_distance)
	cam.position = cam.position.lerp(want_pos, 1.0 - exp(-5.0 * delta))
	cam_look = cam_look.lerp(focus, 1.0 - exp(-6.0 * delta))
	cam.look_at(cam_look, Vector3.UP)
	if shake_t > 0.0:
		shake_t = maxf(0.0, shake_t - delta)
		var kick := shake_mag * clampf(shake_t / 0.32, 0.0, 1.0)
		cam.position += cam.basis.x * sin(shake_t * 74.0) * kick
		cam.position += cam.basis.y * cos(shake_t * 61.0) * kick * 0.55

func _fits(size: float) -> bool:
	return size < hole_radius * FIT_RATIO

func _mostly_over(size: float, dist: float) -> bool:
	return dist + size * 0.35 < hole_radius

func _clear_ratio() -> float:
	if clear_total <= 0:
		return 0.0
	return clampf(float(clear_eaten) / float(clear_total), 0.0, 1.0)

func _player_progress() -> float:
	var total := float(maxi(clear_total, 1))
	var personal := float(player_eaten) / (total * 0.55)
	var city := _clear_ratio()
	var floor_p := smoothstep(0.62, 0.98, city)
	return clampf(maxf(personal, floor_p), 0.0, 1.0)

func _rival_progress(rival: Dictionary) -> float:
	var total := float(maxi(clear_total, 1))
	return clampf(float(rival.get("eaten", 0)) / (total * 0.42), 0.0, 1.0)

func _radius_for(start_r: float, progress: float) -> float:
	var t := clampf(progress, 0.0, 1.0)
	var i := 0
	while i + 1 < GROW_AT.size() and t > float(GROW_AT[i + 1]):
		i += 1
	var span := float(GROW_AT[i + 1]) - float(GROW_AT[i])
	var u := 0.0 if span <= 0.001 else (t - float(GROW_AT[i])) / span
	var w := lerpf(float(GROW_W[i]), float(GROW_W[i + 1]), u)
	return lerpf(start_r, maxf(final_radius, start_r + 0.2), w)

func _size_index(progress: float) -> int:
	var n := 0
	for i in range(1, GROW_AT.size() - 1):
		if progress + 0.0001 >= float(GROW_AT[i]):
			n = i
	return n

func _tally_clear() -> void:
	clear_total = 0
	clear_eaten = 0
	clear_shown = 0.0
	player_eaten = 0
	map_max_base = 0.2
	for o in props:
		if not bool(o.alive):
			continue
		clear_total += 1
		map_max_base = maxf(map_max_base, float(o.base))
	var need := map_max_base / FIT_RATIO * 1.04
	final_radius = maxf(need, _start_radius() + 0.45)

func _sync_level() -> void:
	var progress := _player_progress()
	var n := _size_index(progress)
	var grew := n > level
	if grew:
		level = n
		pop_t = POP_TIME
		size_banner_t = 1.15
		rim_pulse = 0.2
		_sfx("fanfare", 1.0, false)
		if size_lbl:
			size_lbl.text = "SIZE UP!"
	hole_radius = maxf(_radius_for(_start_radius(), progress), _start_radius())
	hole_open = maxf(hole_open, hole_radius)
	if grew:
		_announce_skins(Save.note_size(level + 1))

func _map_progress() -> float:
	return _clear_ratio()

func _tick_clear_bar(delta: float) -> void:
	var goal := _clear_ratio()
	clear_shown = lerpf(clear_shown, goal, 1.0 - exp(-5.5 * delta))
	if absf(clear_shown - goal) < 0.002:
		clear_shown = goal
	if clear_fill != null and clear_track != null:
		var inner := maxf(clear_track.size.x - 8.0, 0.0)
		clear_fill.size = Vector2(inner * clear_shown, clear_fill.size.y)
	if clear_lbl:
		clear_lbl.text = "City cleared %d%%" % int(round(clear_shown * 100.0))
	_update_guide()

func _update_guide() -> void:
	var was := guide_on
	guide_on = false
	if guide_ui == null or not playing:
		if guide_ui and was:
			guide_ui.queue_redraw()
		return
	var remain := clear_total - clear_eaten
	if remain <= 0 or (remain > 12 and _clear_ratio() < 0.90):
		if was:
			guide_ui.queue_redraw()
		return
	var best_d := 999999.0
	var found := false
	var at := Vector3.ZERO
	for o in props:
		if not bool(o.alive):
			continue
		var d := _xz_dist(hole_pos, o.pos)
		if d < best_d:
			best_d = d
			at = o.pos
			found = true
	if not found:
		if was:
			guide_ui.queue_redraw()
		return
	guide_on = true
	guide_target = at
	guide_ui.queue_redraw()

func _refresh_hud() -> void:
	if score_lbl:
		score_lbl.text = "%d pts" % score
	if level_lbl:
		level_lbl.text = "%s   Size %d" % [str(map.get("name", "")), level + 1]
	if clear_lbl:
		clear_lbl.text = "City cleared %d%%" % int(round(clear_shown * 100.0))
	_refresh_next_skin()
	if combo_lbl:
		combo_lbl.visible = combo >= 2 and combo_left > 0.0
		combo_lbl.text = "Combo x%d" % combo
	shown_score = score
	shown_level = level

func _refresh_next_skin() -> void:
	if next_lbl == null:
		return
	var nxt: Dictionary = Save.next_skin()
	if nxt.is_empty():
		next_lbl.visible = false
		if next_fill:
			next_fill.visible = false
		return
	var skin: Dictionary = nxt.skin
	var prog: Dictionary = nxt.progress
	next_lbl.visible = true
	next_lbl.text = "%s  %d/%d" % [str(prog.get("label", "Next skin")), int(prog.cur), int(prog.need)]
	if next_fill:
		next_fill.visible = true
		var track := next_fill.get_parent() as ColorRect
		var inner := 400.0
		if track:
			inner = maxf(track.size.x - 6.0, 0.0)
		next_fill.size = Vector2(inner * float(prog.ratio), next_fill.size.y)
		next_fill.color = skin.a

func _tick_feedback(delta: float) -> void:
	if combo_left > 0.0:
		combo_left = maxf(0.0, combo_left - delta)
		if combo_left <= 0.0 and combo_lbl:
			combo_lbl.visible = false
	if size_lbl:
		if size_banner_t > 0.0:
			size_banner_t = maxf(0.0, size_banner_t - delta)
			size_lbl.visible = true
			var u := clampf(size_banner_t / 1.15, 0.0, 1.0)
			size_lbl.modulate = Color(1, 0.95, 0.35, u)
			size_lbl.scale = Vector2.ONE * (1.0 + (1.0 - u) * 0.18)
		else:
			size_lbl.visible = false
	if mode == "results" and result_anim < 1.0:
		result_anim = minf(1.0, result_anim + delta * 1.35)
		var eased := 1.0 - pow(1.0 - result_anim, 3.0)
		for i in result_fills.size():
			var fill: ColorRect = result_fills[i]
			var goal := float(result_targets[i]) if i < result_targets.size() else 0.0
			var inner := 560.0
			var track := fill.get_parent() as ColorRect
			if track:
				inner = maxf(track.size.x - 6.0, 0.0)
			fill.size = Vector2(inner * goal * eased, fill.size.y)
		if star_row:
			var shown := int(round(float(round_stars) * eased))
			star_row.set_meta("stars", shown)
			star_row.queue_redraw()
		if so_close_lbl:
			var close := false
			if not round_cleared:
				for g in result_targets:
					if float(g) >= 0.82 and float(g) < 1.0:
						close = true
			so_close_lbl.visible = close and eased > 0.72

func _spawn_rivals() -> void:
	rivals.clear()
	var spots: Array = [
		Vector3(1.1, 0.0, -3.2), Vector3(-1.5, 0.0, -4.4), Vector3(2.6, 0.0, -1.8),
		Vector3(-3.4, 0.0, 2.2), Vector3(4.8, 0.0, 0.6), Vector3(-0.6, 0.0, 6.4),
	]
	for i in RIVAL_NAMES.size():
		var ang := TAU * float(i) / float(RIVAL_NAMES.size()) + 0.35
		var spot: Vector3 = spots[i]
		rivals.append({
			"name": RIVAL_NAMES[i],
			"color": RIVAL_COLORS[i],
			"pos": spot,
			"radius": RIVAL_RADIUS[i],
			"shown": RIVAL_RADIUS[i],
			"base_radius": RIVAL_RADIUS[i],
			"speed": RIVAL_SPEED[i],
			"score": 0,
			"eaten": 0,
			"alive": true,
			"respawn": 0.0,
			"wander": ang + 1.7,
			"aim": Vector3(cos(ang + 2.0), 0.0, sin(ang + 2.0)),
			"think": randf() * 0.15,
			"pulse": 0.0,
		})

func _tick_rivals(delta: float) -> void:
	if not playing:
		return
	for i in rivals.size():
		var rival: Dictionary = rivals[i]
		if not bool(rival.alive):
			rival.respawn = float(rival.respawn) - delta
			if float(rival.respawn) <= 0.0:
				_respawn_rival(rival)
			continue
		rival.think = float(rival.think) - delta
		if float(rival.think) <= 0.0:
			rival.think = 0.34
			rival.aim = _rival_aim(i)
		var aim: Vector3 = rival.aim
		if aim.length_squared() < 0.0001:
			aim = Vector3(1.0, 0.0, 0.0)
		var pos: Vector3 = rival.pos
		var nxt := pos + aim.normalized() * float(rival.speed) * delta
		if _surf_f(nxt.x, nxt.z) != SURF_WATER:
			pos = nxt
		pos = _separate_hole(pos, float(rival.radius), i)
		if _surf_f(pos.x, pos.z) == SURF_WATER:
			pos = rival.pos
		var lim := CITY_HALF - 1.3
		pos.x = clampf(pos.x, -lim, lim)
		pos.z = clampf(pos.z, -lim, lim)
		rival.pos = pos
		rival.shown = lerpf(float(rival.shown), float(rival.radius), 1.0 - exp(-6.0 * delta))
		if float(rival.pulse) > 0.0:
			rival.pulse = maxf(0.0, float(rival.pulse) - delta)
	_resolve_eats()

func _rival_aim(i: int) -> Vector3:
	var rival: Dictionary = rivals[i]
	var pos: Vector3 = rival.pos
	var radius := float(rival.radius)
	var flee_from := Vector3.ZERO
	var fleeing := false
	var flee_d := 999.0
	if hole_radius > radius * 1.12:
		var d := _xz_dist(pos, hole_pos)
		if d < hole_radius + 3.4 and d < flee_d:
			flee_d = d
			flee_from = hole_pos
			fleeing = true
	for j in rivals.size():
		if j == i or not bool(rivals[j].alive):
			continue
		var other: Dictionary = rivals[j]
		if float(other.radius) <= radius * 1.12:
			continue
		var od := _xz_dist(pos, other.pos)
		if od < float(other.radius) + 3.4 and od < flee_d:
			flee_d = od
			flee_from = other.pos
			fleeing = true
	if fleeing:
		var away := pos - flee_from
		if away.length_squared() < 0.01:
			away = Vector3(1.0, 0.0, 0.0)
		return away.normalized()
	var chase_at := Vector3.ZERO
	var chasing := false
	var chase_d := 999.0
	if player_invuln <= 0.0 and radius > hole_radius * 1.15:
		var pd := _xz_dist(pos, hole_pos)
		if pd < 6.8 and pd < chase_d:
			chase_d = pd
			chase_at = hole_pos
			chasing = true
	for j in rivals.size():
		if j == i or not bool(rivals[j].alive):
			continue
		var other2: Dictionary = rivals[j]
		if radius <= float(other2.radius) * 1.15:
			continue
		var cd := _xz_dist(pos, other2.pos)
		if cd < 6.8 and cd < chase_d:
			chase_d = cd
			chase_at = other2.pos
			chasing = true
	if chasing:
		var toward := chase_at - pos
		if toward.length_squared() > 0.0001:
			return toward.normalized()
	var food := Vector3.ZERO
	var found := false
	var food_d := 4.8
	var x0 := int(floor((pos.x - food_d) / 4.0))
	var x1 := int(floor((pos.x + food_d) / 4.0))
	var z0 := int(floor((pos.z - food_d) / 4.0))
	var z1 := int(floor((pos.z + food_d) / 4.0))
	for gx in range(x0, x1 + 1):
		for gz in range(z0, z1 + 1):
			var key := gx * 128 + gz + 8192
			if not buckets.has(key):
				continue
			for o in buckets[key]:
				if not bool(o.alive) or bool(o.in_body):
					continue
				if not _fits_r(float(o.base), radius):
					continue
				var fd := _xz_dist(pos, o.pos)
				if fd < food_d:
					food_d = fd
					food = o.pos
					found = true
	if found:
		var bite := food - pos
		if bite.length_squared() > 0.0001:
			return bite.normalized()
	rival.wander = float(rival.wander) + randf_range(-0.9, 0.9)
	return Vector3(cos(float(rival.wander)), 0.0, sin(float(rival.wander)))

func _separate_hole(pos: Vector3, radius: float, ignore: int) -> Vector3:
	var out := pos
	var can_eat_player := radius > hole_radius * 1.12
	var player_can_eat := hole_radius > radius * 1.12
	if not can_eat_player and not player_can_eat and _xz_dist(out, hole_pos) < radius + hole_radius + 0.35:
		var push := out - hole_pos
		if push.length_squared() < 0.0001:
			push = Vector3(1.0, 0.0, 0.0)
		out = hole_pos + push.normalized() * (radius + hole_radius + 0.4)
	for j in rivals.size():
		if j == ignore or not bool(rivals[j].alive):
			continue
		var other: Dictionary = rivals[j]
		var other_r := float(other.radius)
		var bigger := radius > other_r * 1.12 or other_r > radius * 1.12
		var need := radius + other_r + 0.35
		if not bigger and _xz_dist(out, other.pos) < need:
			var push2: Vector3 = out - other.pos
			if push2.length_squared() < 0.0001:
				push2 = Vector3(0.0, 0.0, 1.0)
			out = other.pos + push2.normalized() * (need + 0.05)
	return out

func _resolve_eats() -> void:
	if not playing:
		return
	var i := 0
	while i < rivals.size() and playing:
		var rival: Dictionary = rivals[i]
		if bool(rival.alive):
			var dist := _xz_dist(hole_pos, rival.pos)
			if hole_radius > float(rival.radius) * 1.12 and dist < hole_radius * 0.72:
				_player_eats_rival(rival)
			elif player_invuln <= 0.0 and float(rival.radius) > hole_radius * 1.12 and dist < float(rival.radius) * 0.72:
				_rival_eats_player(rival)
		i += 1
	for a in rivals.size():
		if not playing:
			return
		var left: Dictionary = rivals[a]
		if not bool(left.alive):
			continue
		for b in range(a + 1, rivals.size()):
			var right: Dictionary = rivals[b]
			if not bool(right.alive):
				continue
			var gap := _xz_dist(left.pos, right.pos)
			if float(left.radius) > float(right.radius) * 1.12 and gap < float(left.radius) * 0.72:
				_credit_rival(left, 6 + int(float(right.radius) * 4.0))
				left.pulse = 0.18
				_kill_rival(right)
			elif float(right.radius) > float(left.radius) * 1.12 and gap < float(right.radius) * 0.72:
				_credit_rival(right, 6 + int(float(left.radius) * 4.0))
				right.pulse = 0.18
				_kill_rival(left)

func _player_eats_rival(rival: Dictionary) -> void:
	var bonus := 42 + int(float(rival.radius) * 36.0)
	if combo_left > 0.0:
		combo += 1
	else:
		combo = 1
	combo_left = COMBO_WINDOW
	bonus += maxi(combo - 1, 0)
	score += bonus
	player_eaten += 4
	_sync_level()
	_burst(rival.pos, bonus, rival.color)
	_feel(bonus, true, false)
	_sfx("sting_win", 1.0, true)
	rivals_bitten[str(rival.name)] = true
	_announce_skins(Save.note_rival_eat())
	_refresh_hud()
	_kill_rival(rival)

func _rival_eats_player(rival: Dictionary) -> void:
	shake_t = 0.42
	shake_mag = 0.28
	_sfx("sting_lose", 1.0, false)
	_offer_continue(str(rival.name))

func _kill_rival(rival: Dictionary) -> void:
	rival.alive = false
	rival.respawn = 2.1
	rival.pulse = 0.0

func _respawn_rival(rival: Dictionary) -> void:
	var ang := randf() * TAU
	rival.pos = Vector3(cos(ang) * 11.0, 0.0, sin(ang) * 11.0)
	var restart := float(rival.get("base_radius", 0.34))
	rival.radius = restart
	rival.shown = restart
	rival.score = 0
	rival.eaten = 0
	rival.alive = true
	rival.wander = ang
	rival.aim = Vector3(cos(ang), 0.0, sin(ang))

func _credit_rival(rival: Dictionary, bites: int) -> void:
	rival.eaten = int(rival.get("eaten", 0)) + maxi(bites, 1)
	rival.score = int(rival.score) + bites
	_apply_rival_radius(rival)

func _apply_rival_radius(rival: Dictionary) -> void:
	var start_r := float(rival.get("base_radius", 0.34))
	var rad := _radius_for(start_r, _rival_progress(rival))
	if rad > float(rival.radius) + 0.004:
		rival.radius = rad
		rival.pulse = 0.18

func _rival_grow(rival: Dictionary, points: int) -> void:
	_credit_rival(rival, maxi(1, int(round(float(points) / 8.0))))

func _sink_pos(sink: int) -> Vector3:
	if sink >= 0 and sink < rivals.size():
		return rivals[sink].pos
	return hole_pos

func _sink_radius(sink: int) -> float:
	if sink >= 0 and sink < rivals.size():
		if not bool(rivals[sink].alive):
			return 0.0
		return float(rivals[sink].radius)
	return hole_radius

func _sync_rival_visuals() -> void:
	if rival_mm == null:
		return
	for i in rivals.size():
		var rival: Dictionary = rivals[i]
		var s := 0.0
		if playing and bool(rival.alive):
			var pulse := 1.0
			if float(rival.pulse) > 0.0:
				pulse = 1.0 + sin(clampf(float(rival.pulse) / 0.18, 0.0, 1.0) * PI) * 0.1
			s = float(rival.shown) * pulse
		var xf := Transform3D(Basis().scaled(Vector3(s, 1.0, s)), rival.pos if s > 0.0 else Vector3(0, -30, 0))
		rival_mm.set_instance_transform(i, xf)
		rival_mm.set_instance_color(i, rival.color)
		if i >= rival_labels.size():
			continue
		var tag: Label = rival_labels[i]
		var above: Vector3 = rival.pos + Vector3(0.0, 0.95, 0.0)
		if s < 0.05 or cam == null or cam.is_position_behind(above):
			tag.visible = false
		else:
			tag.visible = true
			tag.text = str(rival.name)
			tag.position = cam.unproject_position(above) - Vector2(90, 46)

func _push_openings() -> void:
	if ground_mat == null or opening_centers.size() < 8:
		return
	for i in 8:
		opening_centers[i] = Vector3.ZERO
		opening_radii[i] = 0.0
	if playing:
		opening_centers[0] = hole_pos
		opening_radii[0] = hole_open
		for i in rivals.size():
			if i + 1 >= 8 or not bool(rivals[i].alive):
				continue
			opening_centers[i + 1] = rivals[i].pos
			opening_radii[i + 1] = float(rivals[i].shown)
	for mat in ground_mats:
		var gm: ShaderMaterial = mat
		gm.set_shader_parameter("openings", opening_centers)
		gm.set_shader_parameter("opening_r", opening_radii)

func _fade_blockers() -> void:
	if cam == null:
		return
	var eye := cam.global_position
	var ab := Vector2(hole_pos.x - eye.x, hole_pos.z - eye.z)
	var ab_len2 := ab.length_squared()
	if ab_len2 < 0.04:
		return
	for o in fadeables:
		if not bool(o.in_mesh) or not bool(o.alive):
			continue
		var p: Vector3 = o.pos
		var ap := Vector2(p.x - eye.x, p.z - eye.z)
		var t := clampf(ap.dot(ab) / ab_len2, 0.0, 1.0)
		var block := false
		if t > 0.16 and t < 0.88:
			var closest := Vector2(eye.x, eye.z) + ab * t
			block = closest.distance_to(Vector2(p.x, p.z)) < float(o.size) * 0.9
		if bool(o.faded) == block:
			continue
		o.faded = block
		var mm := _mm_of(o)
		if mm == null:
			continue
		var tint: Color = o.color
		var fade := 0.28 if block else 1.0
		mm.set_instance_color(int(o.index), Color(tint.r, tint.g, tint.b, fade))

func _feel(points: int, heavy: bool, sound: bool = true) -> void:
	rim_pulse = 0.2
	if heavy or points >= 14:
		shake_t = 0.34
		shake_mag = 0.24 if points >= 24 else 0.14
	if not sound:
		return
	var kind := "pop"
	if points >= 18:
		kind = "crunch"
	elif points >= 8:
		kind = "clunk"
	var pitch := 1.0 + float(mini(combo, 10)) * 0.08
	_sfx(kind, pitch, heavy or points >= 14)

func _process(delta: float) -> void:
	var frame_delta := delta
	_tick_quality(frame_delta)
	delta = minf(delta, 1.0 / 20.0)
	if mode != "play" and mode != "results" and mode != "attract":
		if debug_on:
			_update_debug(frame_delta)
		return
	if playing:
		Save.add_play_time(delta)
		play_save_wait += delta
		if play_save_wait >= 5.0:
			play_save_wait = 0.0
			Save.save_game()
		if _maybe_first_ad():
			pass
		elif clear_total > 0 and _clear_ratio() >= CLEAR_RATIO:
			_finish_round(true)
		else:
			if player_invuln > 0.0:
				player_invuln = maxf(0.0, player_invuln - delta)
			_move_hole(delta)
			_tick_movers(delta)
			_tick_rivals(delta)
	shown_radius = lerpf(shown_radius, hole_radius, 1.0 - exp(-7.0 * delta))
	var pop := 1.0
	if pop_t > 0.0:
		var u := 1.0 - clampf(pop_t / POP_TIME, 0.0, 1.0)
		pop = 1.0 + sin(u * PI) * 0.22
		pop_t = maxf(0.0, pop_t - delta)
	if rim_pulse > 0.0:
		rim_pulse = maxf(0.0, rim_pulse - delta)
		pop *= 1.0 + sin(clampf(rim_pulse / 0.2, 0.0, 1.0) * PI) * 0.14
	var vis := shown_radius * pop
	hole_open = vis
	hole_mesh.position = hole_pos
	hole_mesh.scale = Vector3(vis, 1.0, vis)
	_sync_rival_visuals()
	_push_openings()
	_smooth_camera(delta)
	_tick_floaters(delta)
	_place_name_tag()
	if playing:
		_fade_blockers()
	_tick_feedback(delta)
	_tick_clear_bar(delta)
	if score != shown_score or level != shown_level:
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
			var mm := _mm_of(o)
			if mm:
				mm.set_instance_transform(int(o.index), xform)
			_set_shadow(o)
		_bucket_move(o)

func _update_debug(delta: float) -> void:
	var frame_ms := delta * 1000.0
	var phys_ms := Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS) * 1000.0
	var draws := int(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME))
	var bodies := int(Performance.get_monitor(Performance.PHYSICS_3D_ACTIVE_OBJECTS))
	var fps := Engine.get_frames_per_second()
	var win := DisplayServer.window_get_size()
	debug_lbl.text = "FPS %d\nframe %.1f ms\nphysics %.2f ms\ndraws %d\nbodies %d\nview %dx%d\nspeed x%.2f\nscale %.2f render %.2f msaa %d\n%s" % [fps, frame_ms, phys_ms, draws, bodies, win.x, win.y, speed_scale, quality_scale, quality_render, quality_msaa, _short_sha()]
	if OS.has_feature("web"):
		JavaScriptBridge.eval("window.__godotStats={fps:%d,frameMs:%.2f,physMs:%.2f,draws:%d,bodies:%d,vw:%d,vh:%d,coins:%d,level:%d,skin:%s,noAds:%d,music:%d,sfx:%d,size:%d,speed:%d,time:%d,cars:%d,stars:%d,clears:%d,daily:%s,doubled:%d}" % [fps, frame_ms, phys_ms, draws, bodies, win.x, win.y, Save.coins, Save.unlocked_level, JSON.stringify(str(Save.skin_id)), 1 if Save.no_ads else 0, 1 if Save.music_on else 0, 1 if Save.sfx_on else 0, Save.size_rank, Save.speed_rank, Save.time_rank, int(Save.tallies.get("cars", 0)), Save.total_stars(), Save.clears, JSON.stringify(str(Save.last_daily)), 1 if Save.daily_doubled else 0], true)

func _physics_process(_delta: float) -> void:
	_sync_rim()
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

func _fits_r(size: float, radius: float) -> bool:
	return size < radius * FIT_RATIO

func _xz_dist(a: Vector3, b: Vector3) -> float:
	var dx := a.x - b.x
	var dz := a.z - b.z
	return sqrt(dx * dx + dz * dz)

func _best_sink(o: Dictionary) -> Dictionary:
	var base := float(o.base)
	var p: Vector3 = o.pos
	var best := -2
	var best_d := INF
	if _fits_r(base, hole_radius):
		var d := _xz_dist(p, hole_pos)
		if d < hole_radius + base * 0.95:
			best = -1
			best_d = d
	for i in rivals.size():
		var rival: Dictionary = rivals[i]
		if not bool(rival.alive):
			continue
		var radius := float(rival.radius)
		if not _fits_r(base, radius):
			continue
		var at: Vector3 = rival.pos
		var d2 := _xz_dist(p, at)
		if d2 < radius + base * 0.95 and d2 < best_d:
			best = i
			best_d = d2
	return {"ok": best > -2, "sink": best, "dist": best_d}

func _bkey(x: float, z: float) -> int:
	return int(floor(x / 4.0)) * 128 + int(floor(z / 4.0)) + 8192

func _bucket_add(o: Dictionary) -> void:
	var k := _bkey(float(o.pos.x), float(o.pos.z))
	o["bkey"] = k
	if not buckets.has(k):
		buckets[k] = []
	(buckets[k] as Array).append(o)

func _bucket_remove(o: Dictionary) -> void:
	var k := int(o.get("bkey", 0))
	if buckets.has(k):
		(buckets[k] as Array).erase(o)

func _bucket_move(o: Dictionary) -> void:
	var k := _bkey(float(o.pos.x), float(o.pos.z))
	if int(o.get("bkey", -99999)) == k:
		return
	_bucket_remove(o)
	_bucket_add(o)

func _activate_nearby() -> void:
	var budget := 2
	while budget > 0 and not pool_free.is_empty():
		budget -= 1
		var best: Dictionary = {}
		var best_d := INF
		var found := false
		var seen := {}
		var centers: Array = [hole_pos]
		var radii: Array = [hole_radius]
		for rv in rivals:
			if bool(rv.alive):
				centers.append(rv.pos)
				radii.append(float(rv.radius))
		for s in centers.size():
			var sp: Vector3 = centers[s]
			var rad := float(radii[s])
			var reach := rad + 2.6
			var x0 := int(floor((sp.x - reach) / 4.0))
			var x1 := int(floor((sp.x + reach) / 4.0))
			var z0 := int(floor((sp.z - reach) / 4.0))
			var z1 := int(floor((sp.z + reach) / 4.0))
			for gx in range(x0, x1 + 1):
				for gz in range(z0, z1 + 1):
					var key := gx * 128 + gz + 8192
					if not buckets.has(key):
						continue
					for o in buckets[key]:
						var uid := int(o.get("uid", -1))
						if seen.has(uid):
							continue
						seen[uid] = true
						if bool(o.in_body) or not bool(o.alive):
							continue
						var pick := _best_sink(o)
						if bool(pick.ok) and float(pick.dist) < best_d:
							best = o
							best.sink = int(pick.sink)
							best_d = float(pick.dist)
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
	var foot_w := maxf(float(o.base) * 2.0, 0.08)
	box.size = Vector3(foot_w, maxf(native.y * sc.y, 0.08), foot_w)
	cs.shape = box
	cs.position = Vector3(0, box.size.y * 0.5, 0)
	b.mass = clampf(foot_w * foot_w * box.size.y * 1.6, 0.35, 6.0)
	var p: Vector3 = o.pos
	b.freeze = true
	b.global_transform = Transform3D(Basis(Vector3.UP, float(o.yaw)), Vector3(p.x, 0.0, p.z))
	b.freeze = false
	b.collision_mask = RIM_MASK
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
	var sink := int(o.get("sink", -1))
	var hp := _sink_pos(sink)
	var hr := _sink_radius(sink)
	var dx := p.x - hp.x
	var dz := p.z - hp.z
	var dist := sqrt(dx * dx + dz * dz)
	var base := float(o.base)
	if hr < 0.05 or not _fits_r(base, hr):
		_release_body(o, p)
		return
	var upright := b.global_transform.basis.y.dot(Vector3.UP)
	var tilt := 1.0 - upright
	var reaching := dist < hr + base * 0.95
	var falling := p.y < -0.28
	var tipped := tilt > 0.1 or p.y < -0.04
	# The shelf is only the fulcrum. Once the body has clearly tipped and its
	# center is over the opening, drop the rim so it tumbles instead of hanging.
	var committed := tilt > 0.07 and dist < hr
	if committed or (falling and dist < hr + base * 0.2):
		b.collision_mask = 0
	elif reaching or tipped:
		b.collision_mask = RIM_MASK
	else:
		_release_body(o, p)
		return
	if bool(o.in_mesh):
		var mm := _mm_of(o)
		var xf := _visual_from_body(o, b)
		o.xform = xf
		if mm:
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
		clear_eaten += 1
		var sink := int(o.get("sink", -1))
		if sink >= 0 and sink < rivals.size() and bool(rivals[sink].alive):
			_credit_rival(rivals[sink], 1)
		else:
			if combo_left > 0.0:
				combo += 1
			else:
				combo = 1
			combo_left = COMBO_WINDOW
			var gained := int(o.points) + maxi(combo - 1, 0)
			score += gained
			player_eaten += 1
			_sync_level()
			_announce_skins(Save.note_swallow(_swallow_bucket(kind_id_of(int(o.kind)))))
			_burst(at, gained, o.color)
			_feel(gained, gained >= 14)
			_refresh_hud()
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
		var mm := _mm_of(o)
		if mm:
			mm.set_instance_transform(int(o.index), xform)
		_set_shadow(o)

func _apply_theme(m: Dictionary) -> void:
	sky_mat.sky_top_color = m.sky_top
	sky_mat.sky_horizon_color = m.horizon
	sky_mat.ground_horizon_color = m.horizon
	sky_mat.ground_bottom_color = m.ground
	world_env.adjustment_saturation = clampf(float(m.sat) * 0.82, 0.90, 1.02)
	sun.light_color = m.sun
	sun.light_energy = 0.4
	sun.rotation_degrees = Vector3(-62, float(m.sun_yaw), 0)
	var tint: Color = m.get("tint", Color.WHITE)
	var grade := Vector3(tint.r, tint.g, tint.b)
	for mat in ground_mats:
		(mat as ShaderMaterial).set_shader_parameter("grade_tint", grade)

func _apply_skin() -> void:
	if pit_mat == null:
		return
	var id := Save.skin_id
	if round_trial != "":
		id = round_trial
	elif mode != "results" and Save.trial_skin != "":
		id = Save.trial_skin
	var skin: Dictionary = CatalogScript.skin_by_id(id)
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
	fadeables.clear()
	for slots in kind_lists:
		for list in slots:
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
	combo = 0
	combo_left = 0.0
	size_banner_t = 0.0
	hole_radius = _start_radius()
	shown_radius = hole_radius
	hole_open = hole_radius
	hole_pos = Vector3.ZERO
	velocity = Vector3.ZERO
	joy_held = false
	time_left = ROUND_TIME
	round_cleared = false
	round_settled = false
	coins_earned = 0
	doubled = false
	shown_score = -1
	shown_sec = -1
	shown_level = -1
	_spawn_city()
	_spawn_rivals()
	_tally_clear()
	_sync_level()
	player_invuln = 2.8
	continue_used = false
	rivals_bitten = {}
	round_eaten = ""
	_arm_trial()
	_close_continue_layer()
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
	ad_hold = false
	_set_match_hud(true)
	_set_chrome(false)
	_refresh_hud()
	_sync_audio()

func _enter_attract(index: int) -> void:
	_clear_city()
	map_index = clampi(index, 0, CatalogScript.maps().size() - 1)
	map = CatalogScript.maps()[map_index]
	target_score = int(map.target)
	_apply_theme(map)
	_apply_skin()
	score = 0
	level = 0
	pop_t = 0.0
	combo = 0
	combo_left = 0.0
	size_banner_t = 0.0
	hole_radius = _start_radius()
	shown_radius = hole_radius
	hole_open = hole_radius
	hole_pos = Vector3.ZERO
	velocity = Vector3.ZERO
	joy_held = false
	time_left = ROUND_TIME
	round_cleared = false
	round_settled = false
	coins_earned = 0
	doubled = false
	shown_score = -1
	shown_sec = -1
	shown_level = -1
	ad_hold = false
	_spawn_city()
	_spawn_rivals()
	_tally_clear()
	_sync_level()
	player_invuln = 0.0
	hole_mesh.visible = true
	hole_mesh.position = hole_pos
	cam_distance = _cam_dist_for(hole_radius)
	cam_look = hole_pos
	cam.position = hole_pos + _camera_offset(cam_distance)
	cam.look_at(cam_look, Vector3.UP)
	over_panel.visible = false
	hud_layer.visible = true
	if menu_layer:
		menu_layer.visible = false
	mode = "attract"
	playing = false
	_apply_skin()
	_set_match_hud(false)
	_set_chrome(true)
	_refresh_level_pill()
	_refresh_hud()

func _begin_play() -> void:
	if mode != "attract" or playing or ad_hold:
		return
	mode = "play"
	playing = true
	score = 0
	level = 0
	combo = 0
	combo_left = 0.0
	hole_radius = _start_radius()
	shown_radius = hole_radius
	hole_open = hole_radius
	time_left = ROUND_TIME
	round_settled = false
	player_invuln = 2.8
	continue_used = false
	rivals_bitten = {}
	round_eaten = ""
	_arm_trial()
	_tally_clear()
	shown_score = -1
	shown_sec = -1
	shown_level = -1
	_set_chrome(false)
	_set_match_hud(true)
	_sync_level()
	_refresh_hud()
	_sync_audio()

func _arm_trial() -> void:
	round_trial = Save.trial_skin
	_apply_skin()

func _maybe_first_ad() -> bool:
	if ad_hold or IapService.no_ads or Save.first_ad_shown:
		return false
	if Save.play_time < FIRST_AD_SECONDS:
		return false
	if Save.last_ad_play > 0.0 and Save.play_time - Save.last_ad_play < AD_COOLDOWN:
		return false
	_show_interstitial("resume", false)
	return true

func _between_ad_due() -> bool:
	if IapService.no_ads:
		return false
	if Save.rounds < 2 or Save.rounds < Save.next_interstitial_round:
		return false
	if Save.play_time < FIRST_AD_SECONDS:
		return false
	if Save.last_ad_play > 0.0 and Save.play_time - Save.last_ad_play < AD_COOLDOWN:
		return false
	return true

func _show_interstitial(intent: String, between: bool) -> void:
	ad_hold = true
	playing = false
	joy_held = false
	ad_intent = intent
	Save.mark_interstitial(Save.play_time)
	if between:
		Save.advance_interstitial_schedule()
	AdService.show_interstitial()

func _show_rewarded(intent: String) -> void:
	reward_intent = intent
	Save.note_ad(Save.play_time)
	AdService.show_rewarded()

func _sfx(kind: String, pitch: float, heavy: bool) -> void:
	if not Save.sfx_on:
		return
	if not OS.has_feature("web"):
		return
	var flag := "true" if heavy else "false"
	JavaScriptBridge.eval("if(window.__holePlay)window.__holePlay('%s',%.3f,%s);" % [kind, pitch, flag], true)

func _unlock_audio() -> void:
	if not OS.has_feature("web"):
		return
	JavaScriptBridge.eval("if(window.__holeUnlock)window.__holeUnlock();", true)

func _sync_audio() -> void:
	if not OS.has_feature("web"):
		return
	var music := "true" if Save.music_on else "false"
	var sfx_on := "true" if Save.sfx_on else "false"
	JavaScriptBridge.eval("if(window.__holeSetAudio)window.__holeSetAudio(%s,%s);" % [music, sfx_on], true)

func _finish_round(cleared: bool, eaten_by: String = "") -> void:
	if not playing:
		return
	playing = false
	joy_held = false
	_refresh_joystick()
	round_cleared = cleared
	round_eaten = eaten_by
	if round_trial != "":
		round_trial = ""
		Save.clear_trial()
		_apply_skin()
	mode = "results"
	round_settled = true
	var bonus := 60 if cleared else 0
	coins_earned = int(float(score) * 0.08) + bonus
	doubled = false
	if coins_earned > 0:
		Save.add_coins(coins_earned)
	round_stars = _star_rating(cleared)
	_announce_skins(Save.note_round())
	if cleared:
		_announce_skins(Save.mark_cleared(map_index, score))
	_announce_skins(Save.note_stars(map_index, round_stars))
	if cleared:
		var clean := not continue_used
		var sweep := rivals_bitten.size() >= RIVAL_NAMES.size()
		_announce_skins(Save.note_clear(map_index, clean, sweep))
	over_lbl.text = "%s\n%s   +%d coins" % [_round_headline(), str(map.name), coins_earned]
	_fill_result_bars()
	result_anim = 0.0
	if star_row:
		star_row.set_meta("stars", 0)
		star_row.queue_redraw()
	if so_close_lbl:
		so_close_lbl.visible = false
	double_btn.visible = true
	double_btn.disabled = false
	double_btn.text = "Watch ad for 2x coins"
	var nxt_open := map_index + 1 < CatalogScript.maps().size() and map_index + 1 <= Save.unlocked_level
	next_btn.visible = cleared and nxt_open
	_set_chrome(false)
	_set_match_hud(false)
	over_panel.visible = true
	if result_card:
		_ease_panel(result_card, -500.0, 500.0, Vector2(330, 500))

func _ease_panel(card: Control, rest_top: float, rest_bottom: float, pivot: Vector2) -> void:
	card.modulate.a = 0.0
	card.scale = Vector2(0.92, 0.92)
	card.pivot_offset = pivot
	card.offset_top = rest_top + 64.0
	card.offset_bottom = rest_bottom + 64.0
	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(card, "modulate:a", 1.0, 0.28).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tw.tween_property(card, "scale", Vector2.ONE, 0.28).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tw.tween_property(card, "offset_top", rest_top, 0.28).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tw.tween_property(card, "offset_bottom", rest_bottom, 0.28).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)

func _round_headline() -> String:
	if round_eaten != "":
		return "Swallowed by %s" % round_eaten
	return "Level clear!" if round_cleared else "Run over"

func _on_double_coins() -> void:
	if doubled or mode != "results":
		return
	_show_rewarded("double")

func _after_reward(granted: bool) -> void:
	var intent := reward_intent
	reward_intent = ""
	if intent == "double":
		if not granted or doubled or mode != "results":
			return
		doubled = true
		Save.add_coins(coins_earned)
		coins_earned *= 2
		double_btn.text = "Coins doubled"
		double_btn.disabled = true
		over_lbl.text = "%s\n%s   +%d coins" % [_round_headline(), str(map.name), coins_earned]
		_fill_result_bars()
		result_anim = 0.35
	elif intent == "continue":
		if granted:
			_resume_after_eaten()
		else:
			_offer_continue(eaten_name)
	elif intent == "skin":
		if granted and reward_skin != "":
			Save.set_trial(reward_skin)
		reward_skin = ""
		if mode == "skins":
			_show_screen("skins")
	elif intent == "daily":
		if granted:
			Save.grant_daily_double()
			_refresh_currency()
		if mode == "daily":
			_show_screen("daily")

func _on_next_level() -> void:
	if map_index + 1 >= CatalogScript.maps().size() or map_index + 1 > Save.unlocked_level:
		return
	if _between_ad_due():
		_show_interstitial("next", true)
	else:
		start_round(map_index + 1)

func _on_continue() -> void:
	if _between_ad_due():
		_show_interstitial("home", true)
	else:
		ad_intent = "home"
		_after_ad()

func _after_ad() -> void:
	var intent := ad_intent
	ad_intent = ""
	ad_hold = false
	if intent == "resume":
		if mode == "play":
			playing = true
		return
	if intent == "retry":
		start_round(map_index)
		return
	if intent == "next":
		var nxt := map_index + 1
		if nxt < CatalogScript.maps().size() and nxt <= Save.unlocked_level:
			start_round(nxt)
			return
	var home := mini(Save.unlocked_level, CatalogScript.maps().size() - 1)
	_enter_attract(home)

func _offer_continue(who: String) -> void:
	playing = false
	joy_held = false
	ad_hold = true
	eaten_name = who
	_refresh_joystick()
	_close_continue_layer()
	continue_layer = CanvasLayer.new()
	continue_layer.layer = 45
	add_child(continue_layer)
	var dim := ColorRect.new()
	dim.color = Color(0.08, 0.10, 0.16, 0.55)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	continue_layer.add_child(dim)
	var card := Panel.new()
	card.anchor_left = 0.5
	card.anchor_right = 0.5
	card.anchor_top = 0.5
	card.anchor_bottom = 0.5
	card.offset_left = -330
	card.offset_right = 330
	card.offset_top = -360
	card.offset_bottom = 400
	card.add_theme_stylebox_override("panel", _panel_style())
	continue_layer.add_child(card)
	var title := Label.new()
	title.text = "Game Over"
	title.position = Vector2(24, 36)
	title.size = Vector2(612, 90)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_style(title, 68)
	title.add_theme_color_override("font_color", BRAND_INK)
	title.add_theme_constant_override("outline_size", 0)
	card.add_child(title)
	var body := Label.new()
	body.text = "Swallowed by %s" % who
	body.position = Vector2(36, 136)
	body.size = Vector2(588, 70)
	body.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_style(body, 40)
	body.add_theme_color_override("font_color", BRAND_INK)
	body.add_theme_constant_override("outline_size", 0)
	card.add_child(body)
	var y := 230.0
	if not continue_used:
		var note := Label.new()
		note.text = "Watch an ad to keep going. Once per round."
		note.position = Vector2(36, y)
		note.size = Vector2(588, 80)
		note.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_style(note, 32)
		note.add_theme_color_override("font_color", BRAND_INK)
		note.add_theme_constant_override("outline_size", 0)
		card.add_child(note)
		y += 96.0
		var watch := _make_button("Watch ad to keep going", Vector2(40, y), Vector2(580, 92), Color(0.16, 0.66, 0.42))
		watch.pressed.connect(_on_continue_ad)
		card.add_child(watch)
		y += 112.0
	var retry := _make_button("Retry", Vector2(40, y), Vector2(580, 92), Color(0.20, 0.48, 0.86))
	retry.pressed.connect(_on_retry)
	card.add_child(retry)
	y += 112.0
	var home := _make_button("Home", Vector2(40, y), Vector2(580, 92), BRAND_INK)
	home.pressed.connect(_on_game_home)
	card.add_child(home)
	_ease_panel(card, -360.0, 400.0, Vector2(330, 380))

func _close_continue_layer() -> void:
	if continue_layer != null and is_instance_valid(continue_layer):
		continue_layer.queue_free()
	continue_layer = null

func _on_continue_ad() -> void:
	continue_used = true
	_close_continue_layer()
	_show_rewarded("continue")

func _settle_eaten() -> void:
	if round_settled:
		return
	round_settled = true
	if round_trial != "":
		round_trial = ""
		Save.clear_trial()
		_apply_skin()
	var payout := int(float(score) * 0.08)
	if payout > 0:
		Save.add_coins(payout)
	Save.note_fail()
	_announce_skins(Save.note_round())
	var stars_n := 1 if _clear_ratio() >= 0.5 else 0
	_announce_skins(Save.note_stars(map_index, stars_n))

func _on_retry() -> void:
	_close_continue_layer()
	ad_hold = false
	_settle_eaten()
	if _between_ad_due():
		_show_interstitial("retry", true)
	else:
		start_round(map_index)

func _on_game_home() -> void:
	_close_continue_layer()
	ad_hold = false
	_settle_eaten()
	_on_continue()

func _on_continue_decline() -> void:
	_on_game_home()

func _resume_after_eaten() -> void:
	ad_hold = false
	var src := hole_pos + Vector3(0.0, 0.0, 2.0)
	for rival in rivals:
		if str(rival.name) == eaten_name and bool(rival.alive):
			src = rival.pos
			break
	var away: Vector3 = hole_pos - src
	if away.length_squared() < 0.01:
		away = Vector3(0.0, 0.0, 1.0)
	var kicked: Vector3 = src + away.normalized() * (hole_radius + 2.4)
	var lim := CITY_HALF - 1.2
	hole_pos = Vector3(clampf(kicked.x, -lim, lim), 0.0, clampf(kicked.z, -lim, lim))
	player_invuln = 2.6
	shake_t = 0.28
	shake_mag = 0.16
	if size_lbl:
		size_lbl.text = "Kept going!"
	size_banner_t = 1.1
	playing = true
	mode = "play"
	_refresh_hud()

func _set_match_hud(on: bool) -> void:
	for n in [clear_track, clear_lbl, score_lbl, level_lbl, next_lbl]:
		if n:
			n.visible = on
	if timer_lbl:
		timer_lbl.visible = false
	if next_fill and next_fill.get_parent():
		next_fill.get_parent().visible = on
	if combo_lbl and not on:
		combo_lbl.visible = false

func _set_chrome(on: bool) -> void:
	if chrome_layer:
		chrome_layer.visible = on
	if on:
		_refresh_level_pill()
		_refresh_currency()

func _refresh_level_pill() -> void:
	if level_pill == null:
		return
	level_pill.text = "%d   %s" % [map_index + 1, str(map.get("name", ""))]

func _refresh_currency() -> void:
	if coin_pill:
		coin_pill.text = "%d" % Save.coins
	if star_pill:
		star_pill.text = "%d" % Save.total_stars()

func _build_chrome() -> void:
	chrome_layer = CanvasLayer.new()
	chrome_layer.layer = 6
	add_child(chrome_layer)
	coin_pill = _make_pill(true)
	coin_pill.anchor_left = 0.0
	coin_pill.anchor_top = 0.0
	coin_pill.offset_left = SAFE_SIDE
	coin_pill.offset_top = SAFE_TOP
	coin_pill.offset_right = SAFE_SIDE + 180
	coin_pill.offset_bottom = SAFE_TOP + 64
	chrome_layer.add_child(coin_pill)
	star_pill = _make_pill(false)
	star_pill.anchor_left = 1.0
	star_pill.anchor_right = 1.0
	star_pill.anchor_top = 0.0
	star_pill.offset_left = -(SAFE_SIDE + 180)
	star_pill.offset_top = SAFE_TOP
	star_pill.offset_right = -SAFE_SIDE
	star_pill.offset_bottom = SAFE_TOP + 64
	chrome_layer.add_child(star_pill)
	logo_lbl = Label.new()
	logo_lbl.text = "Hole Arcade"
	logo_lbl.anchor_left = 0.5
	logo_lbl.anchor_right = 0.5
	logo_lbl.anchor_top = 0.0
	logo_lbl.offset_left = -280
	logo_lbl.offset_right = 280
	logo_lbl.offset_top = SAFE_TOP + 72
	logo_lbl.offset_bottom = SAFE_TOP + 180
	logo_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_style(logo_lbl, 76)
	logo_lbl.add_theme_color_override("font_outline_color", BRAND_CYAN)
	logo_lbl.add_theme_constant_override("outline_size", 14)
	chrome_layer.add_child(logo_lbl)
	level_pill = _make_pill(false)
	level_pill.anchor_left = 0.5
	level_pill.anchor_right = 0.5
	level_pill.offset_left = -150
	level_pill.offset_right = 150
	level_pill.offset_top = SAFE_TOP + 188
	level_pill.offset_bottom = SAFE_TOP + 252
	level_pill.alignment = HORIZONTAL_ALIGNMENT_CENTER
	chrome_layer.add_child(level_pill)
	daily_btn = _make_button("Daily reward", Vector2.ZERO, Vector2(280, 72), BRAND_CYAN, 32)
	daily_btn.anchor_left = 0.5
	daily_btn.anchor_right = 0.5
	daily_btn.offset_left = -140
	daily_btn.offset_right = 140
	daily_btn.offset_top = SAFE_TOP + 264
	daily_btn.offset_bottom = SAFE_TOP + 336
	daily_btn.pressed.connect(_show_screen.bind("daily"))
	chrome_layer.add_child(daily_btn)
	hint_lbl = Label.new()
	hint_lbl.text = "Tap or drag to play"
	hint_lbl.anchor_left = 0.5
	hint_lbl.anchor_right = 0.5
	hint_lbl.anchor_top = 1.0
	hint_lbl.anchor_bottom = 1.0
	hint_lbl.offset_left = -240
	hint_lbl.offset_right = 240
	hint_lbl.offset_top = -(SAFE_BOTTOM + 210)
	hint_lbl.offset_bottom = -(SAFE_BOTTOM + 160)
	hint_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_style(hint_lbl, 44)
	chrome_layer.add_child(hint_lbl)
	hand_icon = UiGlyph.new()
	hand_icon.glyph = "hand"
	hand_icon.anchor_left = 0.5
	hand_icon.anchor_right = 0.5
	hand_icon.anchor_top = 1.0
	hand_icon.anchor_bottom = 1.0
	hand_icon.offset_left = -28
	hand_icon.offset_right = 28
	hand_icon.offset_top = -(SAFE_BOTTOM + 156)
	hand_icon.offset_bottom = -(SAFE_BOTTOM + 100)
	hand_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hand_icon.pivot_offset = Vector2(28, 28)
	chrome_layer.add_child(hand_icon)
	var pulse := create_tween()
	pulse.set_loops()
	pulse.tween_property(hand_icon, "scale", Vector2(1.12, 1.12), 0.55).set_trans(Tween.TRANS_SINE)
	pulse.tween_property(hand_icon, "scale", Vector2.ONE, 0.55).set_trans(Tween.TRANS_SINE)
	var row := HBoxContainer.new()
	row.anchor_left = 0.5
	row.anchor_right = 0.5
	row.anchor_top = 1.0
	row.anchor_bottom = 1.0
	row.offset_left = -250
	row.offset_right = 250
	row.offset_top = -(SAFE_BOTTOM + 92)
	row.offset_bottom = -SAFE_BOTTOM
	row.add_theme_constant_override("separation", 14)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	chrome_layer.add_child(row)
	var specs := [
		["skins", "Skins", "skins"],
		["levels", "Levels", "levels"],
		["shop", "Shop", "shop"],
		["settings", "Settings", "settings"],
		["ads", "No Ads", "ads"],
	]
	for spec in specs:
		var b := _icon_button(str(spec[0]), str(spec[1]))
		var screen_name := str(spec[2])
		if screen_name == "ads":
			b.pressed.connect(_confirm_remove_ads)
		else:
			b.pressed.connect(_show_screen.bind(screen_name))
		row.add_child(b)
		chrome_buttons.append(b)
	_refresh_currency()

func _make_pill(_coin: bool) -> Button:
	var l := Button.new()
	l.flat = false
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	l.alignment = HORIZONTAL_ALIGNMENT_CENTER
	if ui_font:
		l.add_theme_font_override("font", ui_font)
	l.add_theme_font_size_override("font_size", 32)
	l.add_theme_color_override("font_color", BRAND_INK)
	l.add_theme_stylebox_override("normal", _pill_style())
	l.add_theme_stylebox_override("hover", _pill_style())
	l.add_theme_stylebox_override("pressed", _pill_style())
	l.add_theme_stylebox_override("disabled", _pill_style())
	l.add_theme_stylebox_override("focus", _pill_style())
	l.text = "0"
	return l

func _icon_button(glyph: String, tip: String) -> Button:
	var b := Button.new()
	b.text = ""
	b.tooltip_text = tip
	b.custom_minimum_size = Vector2(84, 84)
	b.size = Vector2(84, 84)
	var box := _round_style(BRAND_CREAM)
	b.add_theme_stylebox_override("normal", box)
	b.add_theme_stylebox_override("hover", _round_style(Color(1, 1, 1)))
	b.add_theme_stylebox_override("pressed", _round_style(BRAND_CREAM.darkened(0.06)))
	b.add_theme_stylebox_override("focus", box)
	var icon := UiGlyph.new()
	icon.glyph = glyph
	icon.position = Vector2(16, 16)
	icon.size = Vector2(52, 52)
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	b.add_child(icon)
	b.pivot_offset = Vector2(42, 42)
	b.button_down.connect(_bounce_down.bind(b))
	b.button_up.connect(_bounce_up.bind(b))
	b.pressed.connect(_ui_click)
	return b

func _toggle_music() -> void:
	Save.set_music(not Save.music_on)
	_sync_audio()
	_show_screen("settings")

func _toggle_sfx() -> void:
	Save.set_sfx(not Save.sfx_on)
	_sync_audio()
	_show_screen("settings")

func _ui_click() -> void:
	_sfx("click", 1.0, false)

func _panel_style() -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = Color(0.99, 0.97, 0.94, 0.96)
	s.corner_radius_top_left = 28
	s.corner_radius_top_right = 28
	s.corner_radius_bottom_right = 28
	s.corner_radius_bottom_left = 28
	s.shadow_color = Color(0.08, 0.12, 0.22, 0.28)
	s.shadow_size = 18
	s.shadow_offset = Vector2(0, 8)
	s.content_margin_left = 18
	s.content_margin_right = 18
	s.content_margin_top = 16
	s.content_margin_bottom = 16
	return s

func _pill_style() -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = Color(0.99, 0.97, 0.94, 0.94)
	s.corner_radius_top_left = 24
	s.corner_radius_top_right = 24
	s.corner_radius_bottom_right = 24
	s.corner_radius_bottom_left = 24
	s.shadow_color = Color(0.08, 0.12, 0.22, 0.22)
	s.shadow_size = 8
	s.shadow_offset = Vector2(0, 3)
	return s

func _round_style(bg: Color) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	s.corner_radius_top_left = 36
	s.corner_radius_top_right = 36
	s.corner_radius_bottom_right = 36
	s.corner_radius_bottom_left = 36
	s.border_width_left = 3
	s.border_width_top = 3
	s.border_width_right = 3
	s.border_width_bottom = 3
	s.border_color = BRAND_CYAN
	s.shadow_color = Color(0.08, 0.12, 0.22, 0.30)
	s.shadow_size = 10
	s.shadow_offset = Vector2(0, 4)
	return s

func _build_menu_layer() -> void:
	menu_layer = CanvasLayer.new()
	menu_layer.layer = 4
	add_child(menu_layer)

func _show_screen(which: String) -> void:
	if which == "menu" or which == "attract":
		mode = "attract"
		playing = false
		if menu_layer:
			menu_layer.visible = false
			for c in menu_layer.get_children():
				c.queue_free()
		if hud_layer:
			hud_layer.visible = true
		_set_match_hud(false)
		_set_chrome(true)
		return
	mode = which
	playing = false
	_set_chrome(false)
	hud_layer.visible = true
	menu_layer.visible = true
	for c in menu_layer.get_children():
		c.queue_free()
	var dim := ColorRect.new()
	dim.color = Color(0.11, 0.16, 0.29, 0.32)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	menu_layer.add_child(dim)
	var sheet := Panel.new()
	sheet.set_anchors_preset(Control.PRESET_FULL_RECT)
	sheet.offset_left = SAFE_SIDE
	sheet.offset_top = SAFE_TOP
	sheet.offset_right = -SAFE_SIDE
	sheet.offset_bottom = -SAFE_BOTTOM
	sheet.add_theme_stylebox_override("panel", _panel_style())
	sheet.mouse_filter = Control.MOUSE_FILTER_IGNORE
	sheet.modulate.a = 0.0
	sheet.offset_top = SAFE_TOP + 72.0
	menu_layer.add_child(sheet)
	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(sheet, "modulate:a", 1.0, 0.28).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tw.tween_property(sheet, "offset_top", SAFE_TOP, 0.28).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	if which == "levels":
		_screen_levels()
	elif which == "skins":
		_screen_skins()
	elif which == "shop":
		_screen_shop()
	elif which == "settings":
		_screen_settings()
	elif which == "daily":
		_screen_daily()

func _on_play() -> void:
	var i := mini(Save.unlocked_level, CatalogScript.maps().size() - 1)
	start_round(i)

func _screen_levels() -> void:
	_add_currency_pills(18)
	menu_layer.add_child(_menu_label("Levels", Vector2(36, 78), 56))
	var back := _make_button("Back", Vector2(470, 78), Vector2(200, 80), BRAND_INK, 34)
	back.pressed.connect(_show_screen.bind("attract"))
	menu_layer.add_child(back)
	var scroll := ScrollContainer.new()
	scroll.position = Vector2(24, 180)
	scroll.size = Vector2(672, 980)
	menu_layer.add_child(scroll)
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 16)
	grid.add_theme_constant_override("v_separation", 16)
	scroll.add_child(grid)
	var maps: Array = CatalogScript.maps()
	for i in maps.size():
		grid.add_child(_level_card(i, maps[i]))

func _screen_skins() -> void:
	_add_currency_pills(18)
	menu_layer.add_child(_menu_label("Skins", Vector2(36, 78), 56))
	var back := _make_button("Back", Vector2(470, 78), Vector2(200, 80), BRAND_INK, 34)
	back.pressed.connect(_show_screen.bind("attract"))
	menu_layer.add_child(back)
	var scroll := ScrollContainer.new()
	scroll.position = Vector2(28, 180)
	scroll.size = Vector2(664, 1040)
	menu_layer.add_child(scroll)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 12)
	box.custom_minimum_size = Vector2(640, 0)
	scroll.add_child(box)
	for s in CatalogScript.skins():
		box.add_child(_skin_card(s))

func _star_rating(cleared: bool) -> int:
	if not cleared:
		return 1 if _clear_ratio() >= 0.5 else 0
	var personal := float(player_eaten) / float(maxi(clear_total, 1))
	if personal >= 0.60:
		return 3
	return 2

func _fill_result_bars() -> void:
	result_targets.clear()
	var nxt: Dictionary = Save.next_skin()
	if nxt.is_empty():
		_set_result_row(0, "All skins unlocked", 1.0, Color(0.2, 0.75, 0.45))
	else:
		var skin: Dictionary = nxt.skin
		var prog: Dictionary = nxt.progress
		_set_result_row(0, "%s  %s %d/%d" % [str(skin.name), str(prog.get("label", "")), int(prog.cur), int(prog.need)], float(prog.ratio), skin.a)
	_set_result_row(1, "City cleared  %d%%" % int(round(_clear_ratio() * 100.0)), _clear_ratio(), Color(1.0, 0.72, 0.18))
	var buy: Dictionary = Save.next_purchase()
	if buy.is_empty():
		_set_result_row(2, "Coins %d" % Save.coins, 1.0, Color(0.95, 0.78, 0.2))
	else:
		_set_result_row(2, "%s  %d/%d coins" % [str(buy.label), int(buy.cur), int(buy.need)], float(buy.ratio), Color(0.95, 0.62, 0.15))

func _set_result_row(i: int, text: String, ratio: float, color: Color) -> void:
	if i < result_labels.size():
		var lbl: Label = result_labels[i]
		lbl.text = text
	if i < result_fills.size():
		var fill: ColorRect = result_fills[i]
		fill.color = color
		fill.size = Vector2(0, fill.size.y)
	while result_targets.size() <= i:
		result_targets.append(0.0)
	result_targets[i] = clampf(ratio, 0.0, 1.0)

func _draw_star_row(ctrl: Control) -> void:
	var n := int(ctrl.get_meta("stars", 0))
	for i in 3:
		_paint_star(ctrl, Vector2(24.0 + float(i) * 72.0, 24.0), 20.0, i < n)

func _paint_star(ci: CanvasItem, center: Vector2, radius: float, filled: bool) -> void:
	var color := Color(1.0, 0.78, 0.15) if filled else Color(0.75, 0.8, 0.88)
	for i in 5:
		var a0 := -PI * 0.5 + TAU * float(i) / 5.0
		var tip := center + Vector2(cos(a0), sin(a0)) * radius
		var left := center + Vector2(cos(a0 + PI / 5.0), sin(a0 + PI / 5.0)) * radius * 0.42
		var right := center + Vector2(cos(a0 - PI / 5.0), sin(a0 - PI / 5.0)) * radius * 0.42
		ci.draw_colored_polygon(PackedVector2Array([center, right, tip, left]), color)

func _lock_text(unlock: String) -> String:
	var p := Save.progress_for(unlock)
	return "%s %d/%d" % [str(p.get("label", "Challenge")), int(p.cur), int(p.need)]

func _on_try_skin(id: String) -> void:
	if Save.has_skin(id):
		return
	reward_skin = id
	_show_rewarded("skin")

func _on_skin(id: String) -> void:
	if Save.has_skin(id):
		Save.equip(id)
		Save.clear_trial()
		round_trial = ""
		_apply_skin()
		_show_screen("skins")
		return
	var skin: Dictionary = CatalogScript.skin_by_id(id)
	if Save.try_buy_skin(skin):
		Save.equip(id)
		_apply_skin()
		_announce_skins([skin])
	_show_screen("skins")

func _screen_shop() -> void:
	menu_layer.add_child(_menu_label("Shop", Vector2(40, 24), 56))
	menu_layer.add_child(_menu_label("Coins %d" % Save.coins, Vector2(40, 96), 36))
	var back := _make_button("Back", Vector2(470, 28), Vector2(200, 80), BRAND_INK, 34)
	back.pressed.connect(_show_screen.bind("attract"))
	menu_layer.add_child(back)
	_shop_row("Starting size", Save.size_rank, "size", 250)
	_shop_row("Speed", Save.speed_rank, "speed", 400)
	_shop_row("Head start", Save.time_rank, "time", 550)
	menu_layer.add_child(_menu_label("Head start keeps older round-time upgrades.", Vector2(50, 640), 28))
	var ads := "Ads removed" if IapService.no_ads else "Remove Ads  %s" % IapService.price_text()
	var ads_btn := _make_button(ads, Vector2(60, 720), Vector2(600, 96), Color(0.45, 0.18, 0.22), 34)
	ads_btn.disabled = IapService.no_ads
	ads_btn.pressed.connect(_confirm_remove_ads)
	menu_layer.add_child(ads_btn)
	menu_layer.add_child(_menu_label("Test purchase. Removes interstitials only.", Vector2(60, 840), 28))

func _shop_row(title: String, rank: int, which: String, y: float) -> void:
	var cost := Save.next_cost(rank)
	var detail := "%s  %d/5" % [title, rank + 1]
	if cost < 0:
		detail += "    Max"
	else:
		detail += "    %d coins" % cost
	menu_layer.add_child(_menu_label(detail, Vector2(50, y), 36))
	var b := _make_button("Buy", Vector2(470, y - 8), Vector2(190, 80), Color(0.2, 0.48, 0.32), 34)
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
	var msg := _menu_label("Remove ads for %s?\nTest purchase. No charge.\nInterstitials stop. Rewarded ads stay optional." % IapService.price_text(), Vector2(60, 340), 36)
	msg.size = Vector2(600, 140)
	msg.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	msg.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	menu_layer.add_child(msg)
	var yes := _make_button("Confirm", Vector2(80, 640), Vector2(560, 92), Color(0.55, 0.2, 0.22))
	yes.pressed.connect(_do_remove_ads)
	menu_layer.add_child(yes)
	var no := _make_button("Cancel", Vector2(80, 752), Vector2(560, 88), Color(0.2, 0.24, 0.34))
	no.pressed.connect(_show_screen.bind("shop"))
	menu_layer.add_child(no)

func _screen_settings() -> void:
	menu_layer.add_child(_menu_label("Settings", Vector2(48, 78), 56))
	var back := _make_button("Back", Vector2(470, 78), Vector2(200, 80), BRAND_INK, 34)
	back.pressed.connect(_show_screen.bind("attract"))
	menu_layer.add_child(back)
	var music := _make_button("Music: %s" % ("On" if Save.music_on else "Off"), Vector2(60, 240), Vector2(600, 96), BRAND_CYAN if Save.music_on else BRAND_INK)
	music.pressed.connect(_toggle_music)
	menu_layer.add_child(music)
	var sfx_btn := _make_button("SFX: %s" % ("On" if Save.sfx_on else "Off"), Vector2(60, 360), Vector2(600, 96), BRAND_CYAN if Save.sfx_on else BRAND_INK)
	sfx_btn.pressed.connect(_toggle_sfx)
	menu_layer.add_child(sfx_btn)
	var note := _menu_label("Music is a CC0 loop. Sound effects are original.", Vector2(60, 490), 32)
	note.size = Vector2(560, 80)
	note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	menu_layer.add_child(note)

func _screen_daily() -> void:
	menu_layer.add_child(_menu_label("Daily reward", Vector2(48, 78), 56))
	var back := _make_button("Back", Vector2(470, 78), Vector2(200, 80), BRAND_INK, 34)
	back.pressed.connect(_show_screen.bind("attract"))
	menu_layer.add_child(back)
	var amount := Save.DAILY_COINS
	if not Save.daily_claimed():
		menu_layer.add_child(_menu_label("Today: %d coins" % amount, Vector2(60, 260), 44))
		var claim := _make_button("Claim", Vector2(60, 360), Vector2(600, 96), Color(0.16, 0.66, 0.42))
		claim.pressed.connect(_on_claim_daily)
		menu_layer.add_child(claim)
	else:
		menu_layer.add_child(_menu_label("Claimed today: %d coins" % amount, Vector2(60, 260), 40))
		if Save.daily_doubled:
			menu_layer.add_child(_menu_label("Doubled. Come back tomorrow.", Vector2(60, 360), 36))
		else:
			var dbl := _make_button("Double today's reward", Vector2(60, 360), Vector2(600, 96), Color(0.90, 0.62, 0.18))
			dbl.pressed.connect(_on_double_daily)
			menu_layer.add_child(dbl)

func _on_claim_daily() -> void:
	Save.claim_daily()
	_refresh_currency()
	_show_screen("daily")

func _on_double_daily() -> void:
	if not Save.daily_claimed() or Save.daily_doubled:
		return
	_show_rewarded("daily")

func _do_remove_ads() -> void:
	IapService.purchase_remove_ads()
	_show_screen("shop")

func _menu_label(text: String, pos: Vector2, size: int) -> Label:
	var l := Label.new()
	l.text = text
	l.position = pos
	_style(l, size)
	l.add_theme_color_override("font_color", BRAND_INK)
	l.add_theme_constant_override("outline_size", 0)
	return l

func _make_button(text: String, pos: Vector2, size: Vector2, color: Color, font_size: int = 36) -> Button:
	var b := Button.new()
	b.text = text
	b.position = pos
	b.size = size
	b.custom_minimum_size = size
	if ui_font:
		b.add_theme_font_override("font", ui_font)
	b.add_theme_font_size_override("font_size", font_size)
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
	b.pivot_offset = size * 0.5
	b.button_down.connect(_bounce_down.bind(b))
	b.button_up.connect(_bounce_up.bind(b))
	b.pressed.connect(_ui_click)
	return b

func _bounce_down(b: Button) -> void:
	var tw := create_tween()
	tw.tween_property(b, "scale", Vector2(0.94, 0.94), 0.06)

func _bounce_up(b: Button) -> void:
	var tw := create_tween()
	tw.tween_property(b, "scale", Vector2.ONE, 0.12).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)

func _gradient_bg(top: Color, mid: Color, bottom: Color) -> TextureRect:
	var img := Image.create(2, 64, false, Image.FORMAT_RGBA8)
	for y in 64:
		var t := float(y) / 63.0
		var c := top.lerp(mid, clampf(t * 2.0, 0.0, 1.0))
		if t > 0.5:
			c = mid.lerp(bottom, (t - 0.5) * 2.0)
		img.set_pixel(0, y, c)
		img.set_pixel(1, y, c)
	var tex := ImageTexture.create_from_image(img)
	var rect := TextureRect.new()
	rect.texture = tex
	rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	rect.stretch_mode = TextureRect.STRETCH_SCALE
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return rect

func _add_currency_pills(y: float) -> void:
	var coins := _make_button("%d coins" % Save.coins, Vector2(24, y), Vector2(250, 72), Color(0.95, 0.62, 0.16), 32)
	coins.mouse_filter = Control.MOUSE_FILTER_IGNORE
	menu_layer.add_child(coins)
	var star_n := Save.total_stars()
	var stars_btn := _make_button("%d stars" % star_n, Vector2(290, y), Vector2(230, 72), Color(0.98, 0.78, 0.18), 32)
	stars_btn.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stars_btn.add_theme_color_override("font_color", Color(0.35, 0.22, 0.05))
	menu_layer.add_child(stars_btn)

func _level_card(index: int, m: Dictionary) -> Control:
	var locked := index > Save.unlocked_level
	var stars_n := int(Save.stars[index]) if index < Save.stars.size() else 0
	var color: Color = m.horizon
	color.s = minf(color.s * 1.4 + 0.12, 0.85)
	color.v = clampf(color.v, 0.78, 0.95)
	if locked:
		color = color.lerp(Color(0.42, 0.48, 0.58), 0.28)
		color.v = minf(color.v, 0.72)
	var card := Button.new()
	card.custom_minimum_size = Vector2(316, 292)
	card.text = ""
	card.disabled = locked
	var box := _btn_box(color)
	card.add_theme_stylebox_override("normal", box)
	card.add_theme_stylebox_override("hover", _btn_box(color.lightened(0.08)))
	card.add_theme_stylebox_override("pressed", _btn_box(color.darkened(0.08)))
	card.add_theme_stylebox_override("disabled", box)
	card.add_theme_stylebox_override("focus", box)
	card.pivot_offset = Vector2(158, 98)
	card.button_down.connect(_bounce_down.bind(card))
	card.button_up.connect(_bounce_up.bind(card))
	if not locked:
		card.pressed.connect(start_round.bind(index))
	var num := Label.new()
	num.text = str(index + 1)
	num.position = Vector2(16, 8)
	num.size = Vector2(120, 64)
	_style(num, 42)
	num.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(num)
	var name_l := Label.new()
	name_l.text = str(m.name)
	name_l.position = Vector2(16, 78)
	name_l.size = Vector2(284, 52)
	_style(name_l, 36)
	name_l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(name_l)
	var stars := Control.new()
	stars.position = Vector2(16, 136)
	stars.size = Vector2(240, 52)
	stars.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stars.set_meta("stars", 0 if locked else stars_n)
	stars.draw.connect(_draw_star_row.bind(stars))
	card.add_child(stars)
	var sub := Label.new()
	sub.position = Vector2(16, 188)
	sub.size = Vector2(284, 64)
	_style(sub, 24)
	sub.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	sub.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var gate := locked and index > 0 and index == Save.unlocked_level + 1
	if gate:
		var prev := int(Save.stars[index - 1]) if index - 1 < Save.stars.size() else 0
		var need := index * 3
		var have := mini(Save.clears, need)
		sub.text = "3-star previous (%d/3)\nClears %d/%d" % [prev, have, need]
		var ratio := minf(float(prev) / 3.0, float(Save.clears) / float(need))
		var track := ColorRect.new()
		track.position = Vector2(16, 258)
		track.size = Vector2(284, 16)
		track.color = Color(1, 1, 1, 0.35)
		track.mouse_filter = Control.MOUSE_FILTER_IGNORE
		card.add_child(track)
		var fill := ColorRect.new()
		fill.position = Vector2(2, 2)
		fill.size = Vector2(280.0 * clampf(ratio, 0.0, 1.0), 12)
		fill.color = Color(1, 0.95, 0.55)
		fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
		track.add_child(fill)
	elif locked:
		sub.text = "Locked"
	else:
		sub.text = str(m.get("blurb", ""))
	card.add_child(sub)
	return card

func _skin_card(s: Dictionary) -> Control:
	var id := str(s.id)
	var owned := Save.has_skin(id)
	var wrap := Control.new()
	wrap.custom_minimum_size = Vector2(640, 176)
	var status := "Equip"
	if Save.skin_id == id and Save.trial_skin != id:
		status = "Equipped"
	elif Save.trial_skin == id:
		status = "Next round"
	var width := 460.0 if not owned else 640.0
	var label := str(s.name) if not owned else "%s    %s" % [str(s.name), status]
	var b := _make_button(label, Vector2.ZERO, Vector2(width, 88), s.a, 34)
	b.alignment = HORIZONTAL_ALIGNMENT_LEFT
	b.add_theme_color_override("font_color", Color.WHITE)
	b.pressed.connect(_on_skin.bind(id))
	wrap.add_child(b)
	if not owned:
		var try_b := _make_button("Try", Vector2(476, 0), Vector2(164, 88), BRAND_INK, 34)
		try_b.pressed.connect(_on_try_skin.bind(id))
		wrap.add_child(try_b)
	var prog := Save.progress_for(str(s.unlock))
	var line := "Ready"
	if str(s.unlock) != "free":
		if owned:
			line = "%s %d/%d" % [str(prog.get("label", "Challenge")), int(prog.need), int(prog.need)]
		else:
			line = _lock_text(str(s.unlock))
	var lock_l := _menu_label(line, Vector2(8, 96), 30)
	lock_l.size = Vector2(620, 40)
	wrap.add_child(lock_l)
	var track := ColorRect.new()
	track.position = Vector2(16, 142)
	track.size = Vector2(608, 16)
	track.color = Color(1, 1, 1, 0.35)
	track.mouse_filter = Control.MOUSE_FILTER_IGNORE
	wrap.add_child(track)
	var fill := ColorRect.new()
	fill.position = Vector2(2, 2)
	fill.size = Vector2(0, 12)
	fill.color = Color(1, 0.95, 0.55) if not owned else Color(0.45, 0.82, 0.48)
	fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	track.add_child(fill)
	var goal := 604.0 if owned or str(s.unlock) == "free" else 604.0 * float(prog.ratio)
	wrap.tree_entered.connect(func() -> void:
		var tw := fill.create_tween()
		tw.tween_property(fill, "size", Vector2(goal, 12), 0.55).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	, CONNECT_ONE_SHOT)
	return wrap

func _btn_box(color: Color) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = color
	s.corner_radius_top_left = 22
	s.corner_radius_top_right = 22
	s.corner_radius_bottom_left = 22
	s.corner_radius_bottom_right = 22
	s.content_margin_left = 16
	s.content_margin_right = 16
	s.content_margin_top = 8
	s.content_margin_bottom = 8
	s.shadow_color = Color(0.08, 0.12, 0.22, 0.22)
	s.shadow_size = 8
	s.shadow_offset = Vector2(0, 4)
	return s

class UiGlyph extends Control:
	var glyph := "skins"
	func _draw() -> void:
		var c := size * 0.5
		var ink := Color(0.11, 0.16, 0.29)
		var cyan := Color(0.05, 0.74, 0.84)
		if glyph == "skins":
			draw_circle(c + Vector2(-7, 3), 9, Color(0.90, 0.42, 0.52))
			draw_circle(c + Vector2(8, -3), 9, cyan)
		elif glyph == "levels":
			draw_rect(Rect2(c + Vector2(-13, -13), Vector2(11, 11)), ink, false, 2.4)
			draw_rect(Rect2(c + Vector2(2, -13), Vector2(11, 11)), ink, false, 2.4)
			draw_rect(Rect2(c + Vector2(-13, 2), Vector2(11, 11)), cyan, true)
			draw_rect(Rect2(c + Vector2(2, 2), Vector2(11, 11)), ink, false, 2.4)
		elif glyph == "shop":
			draw_colored_polygon(PackedVector2Array([c + Vector2(-9, -2), c + Vector2(9, -2), c + Vector2(6, 12), c + Vector2(-6, 12)]), ink)
			draw_line(c + Vector2(-6, -2), c + Vector2(-3, -12), ink, 2.4)
			draw_line(c + Vector2(6, -2), c + Vector2(3, -12), ink, 2.4)
		elif glyph == "settings":
			draw_arc(c, 7, 0, TAU, 18, ink, 2.6, true)
			for i in 8:
				var a := TAU * float(i) / 8.0
				var dir := Vector2(cos(a), sin(a))
				draw_line(c + dir * 9, c + dir * 14, ink, 2.6)
		elif glyph == "hand":
			draw_circle(c + Vector2(0, 6), 10, Color(1, 1, 1, 0.95))
			draw_rect(Rect2(c + Vector2(-4, -16), Vector2(8, 18)), Color(1, 1, 1, 0.95), true)
			draw_arc(c + Vector2(0, 6), 10, 0, TAU, 16, ink, 2.0, true)
		else:
			draw_arc(c, 13, 0, TAU, 28, ink, 2.4, true)
			draw_line(c + Vector2(-8, 8), c + Vector2(8, -8), Color(0.85, 0.28, 0.32), 2.8)
