extends Node3D

const CITY_HALF := 77.8
const GRID_MIN := -77
const GRID_MAX := 77
const PROP_CAP := 20000
const CHUNK_N := 8
const STATIC_CHUNKS := 64
const SLOT_COUNT := 65
const DENSITY := 10
const ROAD_STEP := 5
const BASE_SPEED := 3.6  # world units / second at full stick, smallest hole; ?speed= multiplies this
const JOY_DEADZONE := 14.0
const JOY_FULL_RADIUS := 56.0
const STOP_RATE := 34.0
const CAM_PITCH_DEG := 62.0
const CAM_PITCH_FAR := 62.0
# Vertical field. A wide lens bent towers inward and opened a big sky band.
const CAM_FOV := 40.0
# Stick speed still uses the previous framing so a pulled-back camera does not race.
const STICK_FOV := 56.0
# A real horizon does not fit in this lens. The hint is a thin screen gradient.
const HAZE_FRAC := 0.05
# Store builds set this false. It is the only switch for ?test=1 and the
# Settings build-hash tap. Tester mode never writes unlocks or skin progress.
const ALLOW_TESTER := true
const CAM_BASE := 7.2
const CAM_PER_RADIUS := 2.15
const SPEED_SCREEN := 1.0
const POOL := 40
const FIT_RATIO := 0.84
# A prop falls when its footprint sits inside the opening, not a smaller inner circle.
const OPEN_FIT := 0.97
# One hole must be this much larger before it can swallow the other.
const EAT_RATIO := 1.18
# Bigger holes are a little faster. The bonus caps near +30% so a large hole
# catches a smaller one slowly instead of racing away.
const SIZE_SPEED_K := 0.14
const SIZE_SPEED_CAP := 0.30
# Spawn and revive only. Tester mode and level select use the same window.
const SPAWN_GRACE := 2.6
const GROW_MULTIPLE := 10.0
const SCREEN_FRAC_START := 0.18
const SCREEN_FRAC_END := 0.36
# d985204 framed the start hole at this distance. Stick speed is measured from it
# so a wider camera does not make a full drag crawl.
const STICK_REF_DIST := 8.275
const RIVAL_CAP := 0.70
const FALL_GRAVITY := 2.15
const PIT_GRAVITY := 8.0
# Large objects tumble under this scale. Small snacks still use the fast pit.
const TUMBLE_GRAVITY := 3.4
const DROP_SNAP := 0.16
const DROP_VY := -8.0
const RIM_MASK := 8
const RIM_COUNT := 16
const COMBO_WINDOW := 3.0
const BUILD_SHA := "__BUILD_SHA__"
const FIRST_AD_SECONDS := 120.0  # cumulative play before the first interstitial; the only first-ad threshold
const AD_COOLDOWN := 90.0
const SAFE_TOP := 58.0
const SAFE_BOTTOM := 40.0
const SAFE_SIDE := 22.0
const MENU_W := 720.0
# Title and Back sit inside the sheet, below the notch and the panel edge.
const MENU_HEADER_Y := SAFE_TOP + 36.0
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
const CLEAR_RATIO := 0.95
# A small pocket of snacks around the hole. Everything else mixes across the map.
const SPAWN_CLEAR := 8.0
const SPAWN_MID := 13.0
const VIEW_TALL_CAP := 3
# Rival name tags sit under the goal line so they cannot cover the pills.
const HUD_TAG_MIN_Y := 232.0
const EDGE_MARKERS := 3
const GOAL_HOLD := 3.0
const GOAL_FADE := 0.45
# Swallow-size rungs. Each band is what "just fits" at the next step from the
# starting hole up to just under a 10x clear, so every radius has new food.
const TIER_LO := [0.05, 0.48, 0.84, 1.20, 1.58, 1.96, 2.34, 2.72, 3.10, 3.48]
const TIER_HI := [0.48, 0.84, 1.20, 1.58, 1.96, 2.34, 2.72, 3.10, 3.48, 3.86]
const TIER_NAME := ["tiny", "small", "compact", "medium", "mid", "large", "big", "huge", "massive", "landmark"]
const TIER_MIN := [240, 360, 260, 200, 150, 120, 96, 72, 56, 40]
const BASE_CAP := 3.86
const COIN_RATE := 0.012
const CLEAR_COIN_BONUS := 100
const RIVAL_GROW := 0.36
const GROUND_SHADER := """shader_type spatial;
render_mode diffuse_lambert, cull_back, shadows_disabled;
uniform sampler2D albedo_tex : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform vec3 openings[8];
uniform float opening_r[8];
uniform float paint_mode = 0.0;
uniform vec3 grade_tint = vec3(1.0);
uniform vec3 band_lo = vec3(-1.0);
uniform vec3 band_hi = vec3(-1.0);
uniform float motif = 0.0;
varying vec3 world_pos;
float thash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}
float vnoise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	float a = thash(i);
	float b = thash(i + vec2(1.0, 0.0));
	float c = thash(i + vec2(0.0, 1.0));
	float d = thash(i + vec2(1.0, 1.0));
	return mix(mix(a, b, f.x), mix(c, d, f.x), f.y);
}
float road_dist(vec2 xz) {
	float best = 90.0;
	float line = -54.0;
	float z_hi = 58.0;
	float x_hi = 58.0;
	line = -54.0; z_hi = 58.0; x_hi = 58.0;
	if (xz.y >= -58.0 && xz.y <= z_hi) best = min(best, abs(xz.x - line));
	if (xz.x >= -58.0 && xz.x <= x_hi) best = min(best, abs(xz.y - line));
	line = -36.0;
	if (xz.y >= -58.0 && xz.y <= z_hi) best = min(best, abs(xz.x - line));
	if (xz.x >= -58.0 && xz.x <= x_hi) best = min(best, abs(xz.y - line));
	line = -18.0; x_hi = -6.0;
	if (xz.y >= -58.0 && xz.y <= z_hi) best = min(best, abs(xz.x - line));
	if (xz.x >= -58.0 && xz.x <= x_hi) best = min(best, abs(xz.y - line));
	line = 18.0; x_hi = 58.0;
	if (xz.y >= -58.0 && xz.y <= z_hi) best = min(best, abs(xz.x - line));
	if (xz.x >= -58.0 && xz.x <= x_hi) best = min(best, abs(xz.y - line));
	line = 36.0; z_hi = 12.0;
	if (xz.y >= -58.0 && xz.y <= z_hi) best = min(best, abs(xz.x - line));
	if (xz.x >= -58.0 && xz.x <= x_hi) best = min(best, abs(xz.y - line));
	line = 54.0; z_hi = 58.0;
	if (xz.y >= -58.0 && xz.y <= z_hi) best = min(best, abs(xz.x - line));
	if (xz.x >= -58.0 && xz.x <= x_hi) best = min(best, abs(xz.y - line));
	if (abs(xz.y) <= 1.15 && xz.x <= -17.0 && xz.x >= -43.0) {
		best = min(best, abs(xz.y));
	}
	if (abs(xz.x) > 40.0 && abs(xz.y) > 40.0) {
		float sx = xz.x > 0.0 ? 1.0 : -1.0;
		float sz = xz.y > 0.0 ? 1.0 : -1.0;
		float curve = abs(length(xz - vec2(sx * 44.0, sz * 44.0)) - 10.0);
		if (abs(xz.x) > 50.0 && abs(xz.y) > 50.0) {
			best = curve;
		} else {
			best = min(best, curve);
		}
	}
	float bowl = length(xz - vec2(18.0, -36.0));
	if (bowl < 4.7) {
		best = 90.0;
	} else if (bowl <= 7.6) {
		best = 0.0;
	}
	if (abs(xz.y - 4.0) <= 1.45 && abs(xz.x) <= 16.5) {
		best = min(best, abs(xz.y - 4.0));
	}
	if (abs(xz.x) < 3.0 && abs(xz.y) < 3.0) {
		best = 90.0;
	} else if (abs(xz.x) < 7.0 && abs(xz.y) < 7.0 && abs(xz.y - 4.0) > 1.45) {
		best = 90.0;
	}
	return best;
}
vec3 themed_road(vec2 xz, vec2 uv, float which) {
	float lane = smoothstep(0.08, 0.0, abs(uv.y - 0.5));
	float edge = smoothstep(0.18, 0.02, min(uv.y, 1.0 - uv.y));
	vec3 col = vec3(0.34, 0.36, 0.4);
	vec3 stripe = vec3(0.85, 0.78, 0.42);
	if (which < 0.5) {
		col = mix(vec3(0.40, 0.28, 0.16), vec3(0.58, 0.42, 0.24), uv.y);
		stripe = vec3(0.32, 0.22, 0.12);
	} else if (which < 1.5) {
		float bar = step(0.5, fract(xz.x * 0.35 + xz.y * 0.35));
		col = mix(vec3(0.16, 0.07, 0.10), vec3(0.86, 0.40, 0.52), bar);
		stripe = vec3(0.96, 0.94, 0.9);
	} else if (which < 2.5) {
		col = mix(vec3(0.30, 0.22, 0.12), vec3(0.46, 0.34, 0.18), uv.y);
		stripe = vec3(0.22, 0.16, 0.08);
	} else if (which < 3.5) {
		float board = step(0.5, fract(xz.x * 0.55));
		col = mix(vec3(0.38, 0.24, 0.12), vec3(0.55, 0.36, 0.18), board);
		stripe = vec3(0.28, 0.18, 0.1);
	} else if (which < 4.5) {
		col = mix(vec3(0.55, 0.62, 0.7), vec3(0.82, 0.88, 0.94), edge);
		stripe = vec3(0.95, 0.84, 0.35);
	} else if (which < 5.5) {
		col = mix(vec3(0.72, 0.54, 0.26), vec3(0.90, 0.72, 0.38), uv.y);
		stripe = vec3(0.55, 0.36, 0.16);
	} else if (which < 6.5) {
		col = vec3(0.18, 0.2, 0.24);
		stripe = mix(vec3(0.75, 0.22, 0.2), vec3(0.2, 0.42, 0.78), step(0.5, fract(xz.x * 0.2)));
	} else if (which < 7.5) {
		col = vec3(0.11, 0.13, 0.17);
		stripe = vec3(0.28, 0.48, 0.55);
	} else if (which < 8.5) {
		vec2 cell = abs(fract(xz * 1.1) - 0.5);
		float seam = step(0.42, max(cell.x, cell.y));
		col = mix(vec3(0.34, 0.32, 0.38), vec3(0.2, 0.18, 0.24), seam);
		stripe = vec3(0.55, 0.5, 0.4);
	} else {
		float bar = step(0.5, fract(xz.x * 0.4));
		col = mix(vec3(0.62, 0.32, 0.22), vec3(0.78, 0.48, 0.28), bar);
		stripe = vec3(0.95, 0.9, 0.7);
	}
	col = mix(col, stripe, lane * 0.75);
	col = mix(col, col * 0.72, edge * 0.35);
	return clamp(col, vec3(0.0), vec3(1.0));
}
vec3 theme_ground(vec3 base, vec2 xz, float which) {
	vec3 col = base;
	float h = thash(floor(xz * 1.4));
	float blot = vnoise(xz * 0.11 + vec2(4.1, 9.3));
	float patch = vnoise(xz * 0.045 + vec2(1.7, 8.2));
	// Same-hue light and dark patches. No furrows or diagonal waves.
	col = mix(col, col * 0.88, smoothstep(0.58, 0.88, blot) * 0.28);
	col = mix(col, col * 1.08, smoothstep(0.55, 0.9, patch) * 0.22);
	col = mix(col, col * vec3(1.04, 1.02, 0.98), h * 0.12);
	if (which > 0.5 && which < 1.5) {
		vec2 cell = fract(xz * 0.55) - vec2(0.5);
		float dots = 1.0 - smoothstep(0.08, 0.16, length(cell));
		col = mix(col, vec3(0.98, 0.78, 0.42), dots * step(0.72, h) * 0.28);
	} else if (which > 3.5 && which < 4.5) {
		float spark = step(0.92, h);
		col = mix(col, vec3(0.9, 0.96, 1.0), spark * 0.28);
	} else if (which > 8.5) {
		float conf = step(0.9, thash(floor(xz * 2.2)));
		vec3 tint = vec3(0.95, 0.42, 0.38);
		if (h > 0.66) {
			tint = vec3(0.35, 0.66, 0.95);
		} else if (h > 0.33) {
			tint = vec3(0.98, 0.84, 0.28);
		}
		col = mix(col, tint, conf * 0.28);
	}
	return clamp(col, vec3(0.0), vec3(1.0));
}
void vertex() {
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	if (paint_mode > 3.5 && paint_mode < 4.5) {
		VERTEX.y += sin(TIME * 1.15 + world_pos.x * 0.85) * 0.028 + cos(TIME * 0.9 + world_pos.z * 0.7) * 0.018;
	}
}
void fragment() {
	// Flat ground. Mesh triangle normals were shading long diagonal seams.
	NORMAL = vec3(0.0, 1.0, 0.0);
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
	float shade = clamp(0.35 + luma * 0.4, 0.0, 1.0);
	if (paint_mode > 0.5) {
		float broad = vnoise(world_pos.xz * 0.07);
		float mid = vnoise(world_pos.xz * 0.31 + vec2(2.7, 8.1));
		shade = mix(0.42, 0.68, clamp(broad * 0.58 + mid * 0.42, 0.0, 1.0));
	}
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
	if (paint_mode > 0.5 && band_lo.r >= 0.0) {
		outc = mix(band_lo, band_hi, shade);
		outc = theme_ground(outc, world_pos.xz, motif);
	}
	vec2 xz = world_pos.xz;
	if (paint_mode < 0.5) {
		vec2 uv = fract(UV);
		outc = themed_road(xz, uv, motif);
		if (motif > 6.5 && motif < 7.5) {
			float glow = smoothstep(0.08, 0.0, abs(uv.y - 0.5));
			outc = mix(outc, vec3(0.22, 0.42, 0.5), glow * 0.28);
		}
	}
	if (paint_mode > 6.5 && paint_mode < 7.5 && motif > 5.5 && motif < 6.5) {
		float wx = step(0.5, fract(xz.x * 2.2));
		float wz = step(0.5, fract(xz.y * 2.2));
		outc = mix(outc * 0.84, outc * 1.05, abs(wx - wz));
		vec2 rc = abs(fract(xz * 0.07) - 0.5);
		float fringe = step(0.4, max(rc.x, rc.y));
		outc = mix(outc, outc * vec3(0.72, 0.55, 0.4), fringe * 0.4);
	} else if ((paint_mode > 0.5 && paint_mode < 1.5) || (paint_mode > 6.5 && paint_mode < 7.5)) {
		if (motif > 1.5 && motif < 2.5) {
			float moss = vnoise(xz * 0.17 + vec2(1.3, 4.4));
			float duff = vnoise(xz * 0.46 + vec2(8.2, 2.1));
			outc = mix(outc, outc * vec3(0.82, 1.02, 0.78), smoothstep(0.32, 0.78, moss) * 0.4);
			outc = mix(outc, vec3(0.2, 0.32, 0.12), smoothstep(0.55, 0.9, duff) * 0.28);
			float litter = smoothstep(0.66, 0.9, vnoise(xz * 1.15 + vec2(5.0, 9.0)));
			vec3 leaf = duff > 0.5 ? vec3(0.36, 0.24, 0.1) : vec3(0.14, 0.34, 0.12);
			outc = mix(outc, leaf, litter * 0.32);
		} else {
		vec2 gc = floor(xz * 0.85);
		float gh = thash(gc);
		vec2 gf = fract(xz * 0.85) - 0.5;
		float tuft = 1.0 - smoothstep(0.1, 0.42, length(gf));
		if (gh > 0.42) {
			vec3 clump = gh > 0.72 ? outc * vec3(1.04, 1.08, 0.96) : outc * vec3(0.86, 0.9, 0.82);
			outc = mix(outc, clump, tuft * 0.4);
		}
		vec2 fc = floor(xz * 0.38 + vec2(2.0, 5.0));
		float fh = thash(fc);
		vec2 ff = fract(xz * 0.38 + vec2(2.0, 5.0)) - 0.5;
		float bloom = 1.0 - smoothstep(0.06, 0.32, length(ff));
		if (fh > 0.9) {
			vec3 flower = vec3(0.9, 0.48, 0.55);
			if (fh > 0.96) {
				flower = vec3(0.88, 0.76, 0.36);
			} else if (fh > 0.94) {
				flower = vec3(0.96, 0.95, 0.92);
			}
			outc = mix(outc, flower, bloom * 0.48);
		}
		if (paint_mode > 6.5 && motif < 0.5) {
			float row = abs(fract(xz.x * 0.42) - 0.5);
			float gap = smoothstep(0.06, 0.16, abs(fract(xz.y * 0.16) - 0.5));
			float stalk = smoothstep(0.2, 0.04, row) * gap;
			outc = mix(outc, vec3(0.62, 0.58, 0.28), stalk * 0.35);
		}
		}
	} else if (paint_mode > 1.5 && paint_mode < 3.5) {
		vec2 pc = floor(xz * 1.5);
		float ph = thash(pc);
		vec2 pf = fract(xz * 1.5) - 0.5;
		float pebble = 1.0 - smoothstep(0.08, 0.28, length(pf));
		if (ph > 0.72) {
			outc = mix(outc, outc * vec3(0.62, 0.58, 0.52), pebble * 0.85);
		}
		if (paint_mode > 2.5 && paint_mode < 3.5) {
			if (motif > 1.5 && motif < 2.5) {
				float lh = vnoise(xz * 0.8);
				float leaf = smoothstep(0.55, 0.88, vnoise(xz * 1.35));
				vec3 litter = mix(vec3(0.4, 0.26, 0.12), vec3(0.16, 0.34, 0.12), step(0.5, lh));
				outc = mix(outc, litter, leaf * 0.32);
			} else {
				vec2 wc = floor(xz * 0.22 + vec2(3.0, 1.0));
				float wh = thash(wc);
				vec2 wf = fract(xz * 0.22 + vec2(3.0, 1.0)) - 0.5;
				float pud = 1.0 - smoothstep(0.04, 0.3, length(wf));
				if (wh > 0.84) {
					outc = mix(outc, vec3(0.18, 0.52, 0.82), pud * 0.8);
				}
			}
		}
		if (paint_mode < 2.5 && motif > 6.5 && motif < 7.5) {
			vec2 cc = floor(xz * 0.2);
			float ch = thash(cc + vec2(8.0, 3.0));
			vec2 cf = fract(xz * 0.2) - 0.5;
			float crater = 1.0 - smoothstep(0.1, 0.4, length(cf));
			if (ch > 0.84) {
				outc = mix(outc, outc * 0.78, crater * 0.35);
			}
		}
		if (paint_mode < 2.5 && motif > 3.5 && motif < 4.5) {
			float drift = vnoise(xz * 0.08);
			outc = mix(outc, vec3(0.84, 0.91, 1.0), (1.0 - drift) * 0.2);
			float flake = step(0.88, ph);
			outc = mix(outc, vec3(0.93, 0.97, 1.0), flake * pebble * 0.4);
		}
	} else if (paint_mode > 3.5 && paint_mode < 4.5) {
		vec2 drift = xz * 0.9 + vec2(TIME * 0.24, -TIME * 0.17);
		float n1 = vnoise(drift * 1.7);
		float n2 = vnoise(drift * 3.2 + vec2(4.0, 1.5));
		outc = mix(outc, outc * vec3(0.74, 0.95, 1.08), n1 * 0.38);
		float glint = smoothstep(0.62, 0.9, n2) * smoothstep(0.2, 0.75, n1);
		outc = mix(outc, vec3(0.84, 0.95, 1.0), glint * 0.35);
	} else if (paint_mode > 4.5 && paint_mode < 5.5) {
		if (motif > 5.5 && motif < 6.5) {
			float wx = step(0.5, fract(xz.x * 1.8));
			float wz = step(0.5, fract(xz.y * 1.8));
			outc = mix(outc * 0.86, outc * 1.04, abs(wx - wz));
		} else if (motif < 0.5) {
			vec2 sc = floor(xz * 1.15);
			float sh = thash(sc);
			vec2 sf = fract(xz * 1.15) - 0.5;
			float edge = smoothstep(0.34, 0.48, max(abs(sf.x), abs(sf.y)));
			outc = mix(outc * mix(0.78, 1.16, sh), outc * 0.52, edge);
		} else {
			vec2 sc = floor(xz * 1.3);
			vec2 sf = abs(fract(xz * 1.3) - 0.5);
			float seam = step(0.46, sf.x) + step(0.46, sf.y);
			outc = mix(outc, outc * 0.78, clamp(seam, 0.0, 1.0) * 0.45);
			vec2 cc = floor(xz * 4.0);
			float ch = thash(cc);
			vec2 cf = abs(fract(xz * 4.0) - 0.5);
			float crack = step(0.97, ch) * step(0.44, cf.y) * step(cf.x, 0.07);
			outc = mix(outc, outc * 0.66, crack);
		}
	} else if (paint_mode > 5.5 && paint_mode < 6.5 && motif > 5.5 && motif < 6.5) {
		float seam = step(0.93, fract(xz.y * 1.05));
		float board = thash(vec2(floor(xz.x * 0.28), floor(xz.y * 1.05)));
		outc *= mix(0.72, 1.12, board);
		outc = mix(outc, vec3(0.28, 0.16, 0.08), seam * 0.85);
	}
	float rd = road_dist(xz);
	float wet = 0.0;
	if (paint_mode > 3.5 && paint_mode < 4.5) {
		wet = 1.0;
	}
	if (wet < 0.5 && paint_mode > 0.5 && rd > 1.15 && rd < 2.65) {
		float band = 1.0 - smoothstep(1.7, 2.6, rd);
		vec3 walk = vec3(0.62, 0.58, 0.5);
		if (motif < 0.5) walk = vec3(0.55, 0.48, 0.36);
		else if (motif < 1.5) walk = vec3(0.9, 0.72, 0.78);
		else if (motif < 2.5) walk = vec3(0.28, 0.36, 0.18);
		else if (motif < 3.5) walk = vec3(0.48, 0.34, 0.2);
		else if (motif < 4.5) walk = vec3(0.86, 0.9, 0.96);
		else if (motif < 5.5) walk = vec3(0.78, 0.62, 0.34);
		else if (motif < 6.5) walk = vec3(0.45, 0.32, 0.22);
		else if (motif < 7.5) walk = vec3(0.28, 0.32, 0.4);
		else if (motif < 8.5) walk = vec3(0.3, 0.28, 0.34);
		else walk = vec3(0.7, 0.5, 0.38);
		outc = mix(outc, walk, band * 0.82);
	}
	if (motif > 1.5 && motif < 2.5) {
		vec2 pond = (xz - vec2(3.6, 8.8)) / vec2(2.5, 1.85);
		float pd = length(pond);
		float water_m = 1.0 - smoothstep(0.78, 1.05, pd);
		float shore = smoothstep(0.92, 1.12, pd) * (1.0 - smoothstep(1.12, 1.45, pd));
		if (water_m > 0.001 && rd > 1.55) {
			vec3 water = mix(vec3(0.05, 0.24, 0.4), vec3(0.14, 0.42, 0.58), shade);
			vec2 drift = xz * 0.85 + vec2(TIME * 0.24, -TIME * 0.17);
			float n1 = vnoise(drift * 1.6);
			float n2 = vnoise(drift * 3.1 + vec2(2.0, 6.0));
			water = mix(water, water * vec3(0.78, 0.96, 1.08), n1 * 0.45);
			float glint = smoothstep(0.68, 0.92, n2) * smoothstep(0.2, 0.8, n1);
			water = mix(water, vec3(0.78, 0.92, 0.98), glint * 0.4);
			outc = mix(outc, water, water_m);
		}
		if (rd > 1.55) {
			outc = mix(outc, vec3(0.36, 0.28, 0.16), shore * 0.75);
		}
		if (paint_mode > 0.5 && paint_mode < 1.5) {
			float moss2 = vnoise(xz * 0.22);
			outc = mix(outc, outc * vec3(0.78, 1.04, 0.74), smoothstep(0.4, 0.82, moss2) * 0.22);
			float litter2 = smoothstep(0.7, 0.92, vnoise(xz * 0.9 + vec2(2.0, 7.0)));
			vec3 leaf2 = vnoise(xz * 0.33) > 0.5 ? vec3(0.4, 0.26, 0.12) : vec3(0.15, 0.36, 0.12);
			outc = mix(outc, leaf2, litter2 * 0.22);
		}
	}
	if (motif > 6.5 && motif < 7.5 && paint_mode > 0.5) {
		vec2 panel = abs(fract(xz * 0.22) - 0.5);
		float seam = smoothstep(0.46, 0.5, max(panel.x, panel.y));
		outc = mix(outc, outc * 0.84, seam * 0.45);
	}
	float edge = max(abs(xz.x), abs(xz.y));
	float rim = smoothstep(70.5, 77.0, edge);
	vec3 border = outc * vec3(0.45, 0.55, 0.42);
	if (motif > 2.5 && motif < 3.5) {
		border = vec3(0.07, 0.26, 0.46);
	} else if (motif > 1.5 && motif < 2.5) {
		border = vec3(0.08, 0.22, 0.16);
	} else if (motif > 4.5 && motif < 5.5) {
		border = vec3(0.62, 0.4, 0.18);
	} else if (motif > 3.5 && motif < 4.5) {
		border = vec3(0.78, 0.88, 0.98);
	} else if (motif > 6.5 && motif < 7.5) {
		border = vec3(0.1, 0.12, 0.18);
	} else if (motif > 7.5 && motif < 8.5) {
		border = vec3(0.16, 0.12, 0.18);
	}
	outc = mix(outc, border, rim);
	outc = mix(outc, vec3(0.004, 0.005, 0.008), cover);
	ALBEDO = clamp(outc * grade_tint, vec3(0.0), vec3(1.0));
	ROUGHNESS = mix(1.0, 0.55, wet);
	METALLIC = 0.0;
	SPECULAR = wet * 0.35;
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
	float fres = pow(1.0 - clamp(abs(dot(NORMAL, VIEW)), 0.0, 1.0), 2.2);
	ALBEDO += ALBEDO * fres * 0.14;
}
"""
const CAR_SHADER := """shader_type spatial;
render_mode diffuse_lambert, cull_back;
uniform sampler2D albedo_tex : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
void fragment() {
	vec3 tex = texture(albedo_tex, UV).rgb;
	float luma = dot(tex, vec3(0.299, 0.587, 0.114));
	float ao = clamp(NORMAL.y * 0.32 + 0.78, 0.64, 1.05);
	float fres = pow(1.0 - clamp(abs(dot(NORMAL, VIEW)), 0.0, 1.0), 2.4);
	ALBEDO = tex * ao * mix(0.94, 1.06, luma) + tex * fres * 0.1;
	ROUGHNESS = mix(0.35, 0.95, luma);
	SPECULAR = 0.08;
}
"""
const KIT_SHADER := """shader_type spatial;
render_mode diffuse_lambert, cull_disabled;
void fragment() {
	vec3 src = clamp(COLOR.rgb, vec3(0.0), vec3(1.0));
	float n = clamp(NORMAL.y, -1.0, 1.0);
	float ao = clamp(n * 0.35 + 0.78, 0.62, 1.0);
	float fres = pow(1.0 - clamp(abs(dot(NORMAL, VIEW)), 0.0, 1.0), 2.4);
	ALBEDO = clamp(src * ao + src * fres * 0.06, vec3(0.0), vec3(1.0));
	ROUGHNESS = 0.72;
	SPECULAR = 0.08;
}
"""
const LIFE_SHADER := """shader_type spatial;
render_mode diffuse_lambert, cull_disabled;
void vertex() {
	float amp = INSTANCE_CUSTOM.r;
	float phase = INSTANCE_CUSTOM.g;
	float spd = max(INSTANCE_CUSTOM.b, 0.8);
	float h = max(VERTEX.y, 0.0);
	float wave = sin(TIME * spd + phase) * amp * h;
	VERTEX.x += wave;
	VERTEX.z += cos(TIME * spd * 0.73 + phase) * amp * h * 0.45;
	VERTEX.y += sin(TIME * spd * 1.25 + phase) * amp * 0.35;
}
void fragment() {
	vec3 src = clamp(COLOR.rgb, vec3(0.0), vec3(1.0));
	float n = clamp(NORMAL.y, -1.0, 1.0);
	float ao = clamp(n * 0.35 + 0.78, 0.62, 1.0);
	float fres = pow(1.0 - clamp(abs(dot(NORMAL, VIEW)), 0.0, 1.0), 2.4);
	ALBEDO = clamp(src * ao + src * fres * 0.06, vec3(0.0), vec3(1.0));
	ROUGHNESS = 0.72;
	SPECULAR = 0.08;
}
"""
const VEG_SHADER := """shader_type spatial;
render_mode diffuse_lambert, cull_disabled;
uniform sampler2D albedo_tex : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform float sway = 0.04;
void vertex() {
	float h = clamp(VERTEX.y, 0.0, 4.0);
	float wave = sin(TIME * 1.25 + VERTEX.x * 1.7 + VERTEX.z * 0.8) * sway * h;
	VERTEX.x += wave;
	VERTEX.z += cos(TIME * 0.9 + VERTEX.z * 1.3) * sway * h * 0.4;
}
void fragment() {
	vec3 tex = clamp(texture(albedo_tex, UV).rgb, vec3(0.0), vec3(1.0));
	float ao = clamp(NORMAL.y * 0.35 + 0.78, 0.62, 1.0);
	float fres = pow(1.0 - clamp(abs(dot(NORMAL, VIEW)), 0.0, 1.0), 2.4);
	ALBEDO = clamp(tex * ao + tex * fres * 0.06, vec3(0.0), vec3(1.0));
	ROUGHNESS = 0.8;
	SPECULAR = 0.04;
}
"""
const LIFE_AMP := {
	"chicken": 0.12, "piglet": 0.08, "cow": 0.05, "sheep": 0.06, "penguin": 0.1, "raptord": 0.06, "trike": 0.04,
	"tyrant": 0.035, "brachio": 0.03, "dcamel": 0.05, "hbat": 0.22, "hcrow": 0.18,
	"teddybear": 0.04, "scare": 0.045, "fernleaf": 0.1, "jpalm": 0.045, "jpalmtall": 0.04,
	"ppalm": 0.045, "dpalm": 0.045, "hpine": 0.04, "htree": 0.05, "dcactus": 0.03,
	"dtallcac": 0.028, "fwheat": 0.1, "fflower": 0.12, "blossom": 0.1, "pflag": 0.16,
	"fballoon": 0.11, "hsnowman": 0.03, "gbread": 0.045, "skier": 0.04,
	"roundtree": 0.035, "jvine": 0.12,
}
const HOLE_SHADER := """shader_type spatial;
render_mode unshaded, cull_disabled, blend_mix, depth_draw_opaque;
uniform vec3 rim_color : source_color = vec3(0.05, 0.86, 1.0);
uniform vec3 rim_color_b : source_color = vec3(0.8, 0.98, 1.0);
uniform int pattern = 0;
uniform float glow = 0.9;
uniform float swirl = 0.28;
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
	vec3 pit = mix(vec3(0.002, 0.003, 0.006), vec3(0.05, 0.055, 0.07), smoothstep(0.0, 0.42, t));
	pit = mix(pit, vec3(0.11, 0.12, 0.15), smoothstep(0.42, 0.82, t));
	pit = mix(pit, vec3(0.02, 0.022, 0.03), smoothstep(0.82, 1.0, t) * 0.35);
	float ang = atan(xz.x, xz.y);
	float spin = ang + TIME * 1.35 - dist * 7.5;
	float arm = pow(clamp(sin(spin * 3.0) * 0.5 + 0.5, 0.0, 1.0), 3.0);
	arm *= smoothstep(0.08, 0.28, dist) * (1.0 - smoothstep(0.78, 0.96, dist));
	pit += rim_color * arm * swirl * 0.22;
	vec3 rim = rim_color;
	if (vertex_rim > 0.5) {
		rim = vcol.rgb;
	} else {
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
	vec3 glow_col = rim * core * glow * 0.28 + rim * inner * 0.22;
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
var joy_id := -2
var web_steer := false
var web_phase_live := false
var _announced_phase := ""
var _steer_cb = null
var forward_tall := 0
var hole_radius := LEVEL_RADIUS[0]
var shown_radius := LEVEL_RADIUS[0]
var shown_vel := 0.0
var level := 0
var score := 0
var playing := true
var edge_probe := false
var latency_probe := false
var lat_arm := false
var lat_sample_now := false
var lat_phase := "slide"
var lat_frame := 0
var lat_prop: Dictionary = {}
var lat_burst: Array = []
var lat_lines: PackedStringArray = []
var lat_trace: PackedStringArray = []
var lat_geo := -1
var lat_fit := -1
var lat_body := -1
var lat_drop := -1
var lat_y0 := 0.0
var lat_hold := 0
var lat_radius := 0.55
var props: Array = []
var movers: Array = []
var road_routes: Array = []
var treats: Array = []
var mile_lbl: Label
var mile_t := 0.0
var mile_pill: Panel
var clear_mark := 0
var tier_use: Dictionary = {}
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
var size_badge: Panel
var size_style: StyleBoxFlat
var score_pill: Panel
var map_pill: Panel
var center_pill: Panel
var next_bg: ColorRect
var goal_hold := 0.0
var goal_until_ms := 0
var goal_seen := ""
var sky_haze: Control
var vignette: Control
var sky_haze_top := Color(0.42, 0.74, 0.98)
var sky_haze_edge := Color(0.78, 0.90, 0.72)
var settings_from := "menu"
var tester_on := false
var hash_taps := 0
var hash_tap_ms := 0
var test_badge: Button
var play_btn: Button
var level_lock_note: Label
var block_start_until_up := false
var hole_swirl := 0.28
var shadow_slide := Vector3(0.28, 0.0, 0.16)
var kept_lbl: Label
var kept_pulse := false
var ui_swallow_frames := 0
var round_stars := 0
var rivals: Array = []
var rival_mm: MultiMesh
var rival_labels: Array = []
var rival_rings: Array = []
var player_invuln := 0.0
var grow_drive := false
var grow_arm := false
var opening_centers := PackedVector3Array()
var opening_radii := PackedFloat32Array()
var kind_multimeshes: Array = []
var kind_mats: Array = []
var kind_by_id := {}
var kit_mat: ShaderMaterial
var life_mat: ShaderMaterial
var tex_cache := {}
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
var hint_pill: Panel
var drag_hint: Label
var drag_pill: Panel
var drag_hint_t := -1.0
var web_audio_unlocked := false
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
var skirt_mat: StandardMaterial3D
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
var level_lbl: Label
var sha_lbl: Label
var over_panel: Control
var over_lbl: Label
var debug_lbl: Label
var debug_on := false
var speed_scale := 1.0
var joy_ui: Control
var shown_score := -1
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
var fill_light: DirectionalLight3D
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
var rival_radius_bonus := 0.0
var round_cover: ColorRect
var load_title: Label
var load_spin: Control
var load_spin_t := 0.0
var level_loading := false
var treat_force := false
var reveal_size := Vector2.ZERO
var reveal_stable := 0
var reveal_since := 0
var boot_frames := 0
var bot_drive := false
var bot_clock := 0.0
var bot_step_ready := false
var play_age := 0.0
var bot_food_dist := 0.0
var bot_lock: Dictionary = {}
var bot_avoid_uid := -1
var bot_stall := 0.0
var bot_best_d := 999.0
var rival_bites := 0
var feet_lock := false
var aspect_lock := 0.0
var map_max_base := 0.4
var final_radius := 2.6
var round_settled := false
var clear_track: ColorRect
var clear_fill: ColorRect
var clear_lbl: Label
var guide_ui: Control
var guide_target := Vector3.ZERO
var guide_targets: Array = []
var guide_on := false
var guide_wait := 0.0
var city_load_ms := 0
var city_mem := 0
var city_tiles := 0
var shot_path := ""
var shot_wait := 0
var cam_hold := false
var mode := "menu"
var round_cleared := false
var coins_earned := 0
var doubled := false
var menu_layer: CanvasLayer
var menu_root: Control
var hud_layer: CanvasLayer
var continue_btn: Button
var next_btn: Button
var double_btn: Button
var keep_btn: Button
var menu_sha: Label
var ui_font: Font
var progress_ring: Control
var name_lbl: Label
var pause_btn: Button
var pause_layer: CanvasLayer
var paused := false
var match_hud := false
var render_warm := 0
var render_blank := 0
var render_ok := false
var render_failed := false
var unlock_layer: CanvasLayer
var unlock_title: Label
var unlock_body: Label
var unlock_ok: Button
var unlock_queue: Array = []
var toast_busy := false
var toast_gen := 0
const PLAYER_NAME := "You"
const RIVAL_NAMES := ["Midge", "Puddle", "Niblet", "Scoot", "Bramble", "Tumble", "Pebble", "Dribble", "Morsel", "Squish", "Nib", "Wobble"]
const RIVAL_COLORS := [
	Color(1.0, 0.32, 0.38), Color(0.25, 0.75, 0.95), Color(0.95, 0.72, 0.18),
	Color(0.35, 0.9, 0.42), Color(0.62, 0.38, 0.95), Color(1.0, 0.48, 0.18),
	Color(0.95, 0.45, 0.72), Color(0.2, 0.8, 0.7), Color(0.55, 0.4, 0.95),
	Color(0.95, 0.55, 0.3), Color(0.4, 0.62, 0.95), Color(0.7, 0.88, 0.32),
]
const RIVAL_RADIUS := [0.34, 0.42, 0.30, 0.48, 0.36, 0.44, 0.32, 0.40, 0.28, 0.46, 0.33, 0.38]
const RIVAL_SPEED := [2.15, 2.25, 2.40, 2.05, 2.20, 2.10, 2.30, 2.18, 2.45, 2.08, 2.35, 2.12]
const CatalogScript = preload("res://catalog.gd")
const RoadScript = preload("res://roads.gd")
const PropKitScript = preload("res://props_kit.gd")
const ThemeMeshScript = preload("res://theme_meshes.gd")

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
	_boot_tester()
	_build_chrome()
	_focus_canvas()
	AdService.interstitial_closed.connect(_after_ad)
	AdService.rewarded_done.connect(_after_reward)
	_prewarm_shaders()
	var start_idx := mini(Save.unlocked_level, CatalogScript.maps().size() - 1)
	var preview := _query_preview()
	if preview == "":
		# Paint a themed loader, then build. A sync build otherwise stays on navy.
		if OS.has_feature("web"):
			JavaScriptBridge.eval("window.__holeBuilding=true;window.__holeEngineStarted=true;", true)
		call_deferred("_request_round", start_idx)
	else:
		_enter_attract(start_idx)
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
	elif preview == "daily2":
		Save.last_daily = Save.today_key()
		Save.daily_doubled = true
		_show_screen("daily")
	elif preview == "skins":
		_show_screen("skins")
	elif preview == "shop":
		_show_screen("shop")
	elif preview == "settings":
		_show_screen("settings")
	elif preview == "home":
		pass
	elif preview == "hud":
		clear_total = 1000
		clear_eaten = 420
		clear_shown = 0.42
		score = 840
		mode = "play"
		playing = false
		_set_chrome(false)
		_set_match_hud(true)
		_refresh_hud()
	elif preview == "ads":
		_show_screen("shop")
		AdService.show_rewarded()
	elif preview == "gate":
		call_deferred("_probe_gate")
	elif preview == "hole" or preview == "street" or preview == "facade":
		call_deferred("_preview_shot", preview)
	elif preview == "small" or preview == "wide":
		call_deferred("_preview_zoom", preview)
	elif preview == "overview":
		call_deferred("_preview_overview")
	elif preview == "probe":
		call_deferred("_probe_maps")
	elif preview == "growth":
		call_deferred("_probe_growth")
	elif preview == "size7":
		call_deferred("_preview_size")
	elif preview == "eat":
		call_deferred("_probe_edge_eat")
	elif preview == "latency":
		call_deferred("_probe_latency")
	elif preview == "growtime":
		call_deferred("_probe_grow_time")
	elif preview == "kinds":
		call_deferred("_probe_kinds")
	elif preview == "tiers":
		call_deferred("_probe_tiers")
	elif preview == "glfail":
		call_deferred("_fail_graphics")
	elif preview == "topple":
		call_deferred("_probe_topple")
	elif preview == "cam":
		call_deferred("_probe_cam")
	elif preview == "feet":
		call_deferred("_probe_feet")
	elif preview == "facing":
		call_deferred("_probe_facing")
	elif preview == "snowmenu":
		call_deferred("_enter_attract", 4)
	elif preview == "toast":
		call_deferred("_preview_toast")
	elif preview == "spaced":
		call_deferred("_preview_spaced")
	elif preview == "lanes":
		call_deferred("_preview_lanes")
	elif preview == "speed":
		call_deferred("_preview_speed")
	elif preview == "treats":
		call_deferred("_preview_treats")
	elif preview.begins_with("road"):
		var road_rest := preview.substr(4)
		var road_idx := 0
		if road_rest.is_valid_int():
			road_idx = int(road_rest)
		call_deferred("_preview_road", road_idx)
	elif preview == "rivalbot":
		call_deferred("_probe_rival_bot")
	elif preview.begins_with("close"):
		var close_rest := preview.substr(5)
		var close_idx := start_idx
		if close_rest.is_valid_int():
			close_idx = int(close_rest)
		call_deferred("_preview_close", close_idx)
	elif preview.begins_with("play"):
		var rest := preview.substr(4)
		var idx := start_idx
		if rest.is_valid_int():
			idx = int(rest)
		call_deferred("start_round", idx)
	_build_pause()

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

func _preview_toast() -> void:
	start_round(0)
	var snacks: Array = []
	for o in props:
		if not bool(o.alive) or int(o.mover) == 2:
			continue
		if float(o.base) > 0.75:
			continue
		var p: Vector3 = o.pos
		if p.length() > 7.5:
			continue
		snacks.append(o)
		if snacks.size() >= 2:
			break
	for o in snacks:
		_swallow_done(o)
	combo_left = 30.0
	mile_t = 30.0
	if combo_lbl:
		combo_lbl.visible = combo >= 2
		combo_lbl.text = "Combo x%.1f" % _combo_mult()
	var mile := ""
	if mile_lbl:
		mile = mile_lbl.text
		mile_lbl.visible = true
		mile_lbl.modulate.a = 1.0
	if mile_pill:
		mile_pill.visible = true
		mile_pill.modulate.a = 1.0
	print("TOAST combo %d snacks %d mile %s" % [combo, snacks.size(), mile])

func _preview_spaced() -> void:
	start_round(1)
	for _i in 66:
		_tick_movers(1.0 / 30.0)
	_report_lane("candy-2.2s")

func _preview_lanes() -> void:
	for idx in [1, 3, 2, 7]:
		start_round(idx)
		_report_lane("%s-0" % str(map.get("layout", "")))
		for _i in 90:
			_tick_movers(1.0 / 30.0)
		_report_lane("%s-3s" % str(map.get("layout", "")))
	print("LANE DONE")

func _preview_speed() -> void:
	start_round(0)
	var start_r := hole_radius
	hole_radius = start_r
	shown_radius = start_r
	var mul1 := _size_speed_mul(start_r)
	var spd1 := _move_speed()
	hole_radius = start_r * 1.5
	shown_radius = start_r * 1.5
	var mul15 := _size_speed_mul(shown_radius)
	var spd15 := _move_speed()
	var mul_max := _size_speed_mul(maxf(final_radius, start_r * GROW_MULTIPLE))
	var small := {"radius": start_r, "speed": 2.22, "fleeing": true}
	var big := {"radius": start_r * 1.5, "speed": 2.22, "fleeing": true}
	var flee_s := _rival_move_speed(small)
	var flee_b := _rival_move_speed(big)
	var player_now := _move_speed()
	var spd_ratio := spd15 / maxf(spd1, 0.001)
	print("SPEED x1 mul %.4f spd %.4f | x1.5 mul %.4f spd %.4f | spd_ratio %.4f | max_mul %.4f | flee_small %.4f flee_big %.4f player %.4f" % [mul1, spd1, mul15, spd15, spd_ratio, mul_max, flee_s, flee_b, player_now])
	var modest := mul15 > mul1 and mul15 <= 1.20 and mul_max >= 1.25 and mul_max <= 1.35
	modest = modest and spd15 > spd1 and spd_ratio < 1.45
	modest = modest and flee_s < player_now and flee_s < flee_b
	modest = modest and absf(flee_b - player_now) / maxf(player_now, 0.001) < 0.04
	tester_on = true
	start_round(3)
	var grace_set := absf(player_invuln - SPAWN_GRACE) < 0.001 and playing and mode == "play"
	print("EAT_PATH tester %s invuln %.3f playing %s mode %s" % [str(grace_set), player_invuln, str(playing), mode])
	var base_r := hole_radius
	for rival in rivals:
		rival.alive = false
	var foe: Dictionary = rivals[0]
	var rr := base_r * 1.40
	var old_line := rr * 0.72
	var reach := _swallow_reach(rr, base_r)
	var dist := (old_line + reach) * 0.5
	foe.alive = true
	foe.radius = rr
	foe.shown = rr
	foe.grace = 0.0
	foe.pos = Vector3(dist, 0.0, 0.0)
	hole_radius = base_r
	shown_radius = base_r
	hole_pos = Vector3.ZERO
	velocity = Vector3.ZERO
	player_invuln = SPAWN_GRACE
	playing = true
	mode = "play"
	round_eaten = ""
	# physics_frame fires before _physics_process, so wait two ticks to see one step.
	await get_tree().physics_frame
	await get_tree().physics_frame
	var blocked := mode == "play" and round_eaten == "" and playing and player_invuln > 2.0 and player_invuln < SPAWN_GRACE
	print("EAT_GRACE blocked %s mode %s eaten '%s' invuln %.3f dist %.3f old %.3f reach %.3f" % [str(blocked), mode, round_eaten, player_invuln, dist, old_line, reach])
	player_invuln = 0.0
	playing = true
	mode = "play"
	round_eaten = ""
	foe.alive = true
	foe.pos = Vector3(dist, 0.0, 0.0)
	hole_pos = Vector3.ZERO
	await get_tree().physics_frame
	var eaten := mode == "results" and round_eaten != "" and not playing
	print("EAT_TOUCH eaten %s mode %s by '%s'" % [str(eaten), mode, round_eaten])
	var past_old := dist > old_line and dist < reach and dist < rr
	var ok := modest and grace_set and blocked and eaten and past_old
	print("SPEED_OK" if ok else "SPEED_FAIL")
	get_tree().quit(0 if ok else 1)

func _preview_treats() -> void:
	var bad := 0
	for idx in CatalogScript.maps().size():
		start_round(idx)
		var opening: Dictionary = {}
		for o in treats:
			if bool(o.get("opening_treat", false)):
				opening = o
				break
		if opening.is_empty():
			bad += 1
			print("TREAT FAIL %s missing" % str(map.get("layout", "")))
			continue
		await get_tree().physics_frame
		await get_tree().physics_frame
		var ground: Vector3 = opening.get("ground", opening.pos)
		var dist := Vector2(ground.x - hole_pos.x, ground.z - hole_pos.z).length()
		var radii := dist / maxf(hole_radius, 0.01)
		var alive := bool(opening.alive) and not bool(opening.in_body)
		var band := radii >= 1.95 and radii <= 3.05
		var screen_ok := true
		if cam != null:
			var hole_s := cam.unproject_position(hole_pos)
			var treat_s := cam.unproject_position(Vector3(ground.x, 0.6, ground.z))
			screen_ok = treat_s.y < hole_s.y - 4.0
		if not alive or not band or not screen_ok:
			bad += 1
			print("TREAT FAIL %s alive %s radii %.2f screen %s" % [str(map.get("layout", "")), str(alive), radii, str(screen_ok)])
		else:
			print("TREAT OK %s radii %.2f" % [str(map.get("layout", "")), radii])
		if str(map.get("layout", "")) == "space":
			var rocket := Vector3.ZERO
			var saw := false
			for o in props:
				if kind_id_of(int(o.kind)) == "stackrocket" and absf(o.pos.z) < 12.0:
					rocket = o.pos
					saw = true
					break
			if not saw or rocket.x < -2.2:
				bad += 1
				print("ROCKET FAIL at %.2f %.2f" % [rocket.x, rocket.z])
			else:
				print("ROCKET OK at %.2f %.2f" % [rocket.x, rocket.z])
	print("TREAT_OK" if bad == 0 else "TREAT_FAIL")
	get_tree().quit(0 if bad == 0 else 1)

func _report_lane(tag: String) -> void:
	var cars: Array = []
	for o in props:
		if _is_road_car(o):
			cars.append(o)
	var worst := 99.0
	var pair := ""
	for i in cars.size():
		for j in range(i + 1, cars.size()):
			var a: Vector3 = cars[i].pos
			var b: Vector3 = cars[j].pos
			var d := Vector2(a.x - b.x, a.z - b.z).length()
			if d < worst:
				worst = d
				pair = "%s/%s" % [kind_id_of(int(cars[i].kind)), kind_id_of(int(cars[j].kind))]
	var road_n := 0
	var shown := 0
	for o in props:
		if int(o.mover) == 2:
			continue
		if _surf_f(o.pos.x, o.pos.z) != SURF_ROAD:
			continue
		road_n += 1
		if shown < 4:
			var rp: Vector3 = o.pos
			print("ROADPROP %s %s at %.1f %.1f" % [tag, kind_id_of(int(o.kind)), rp.x, rp.z])
			shown += 1
	var curb := 99.0
	for o in props:
		if int(o.mover) == 2:
			continue
		var op: Vector3 = o.pos
		if absf(op.z - 4.6) > 3.2 or absf(op.x) > 16.0:
			continue
		var reach := float(o.size)
		var gap := absf(op.z - 4.58) - reach
		curb = minf(curb, gap)
	print("LANE %s cars %d min %.2f pair %s roadprops %d curb %.2f" % [tag, cars.size(), worst, pair, road_n, curb])
	for o in props:
		if not _is_road_car(o):
			continue
		var p: Vector3 = o.pos
		if absf(p.x) < 12.0 and p.z > 1.5 and p.z < 6.5:
			print("LANE CAR %s %s at %.2f %.2f spd %.2f" % [tag, kind_id_of(int(o.kind)), p.x, p.z, float(o.speed)])

func _preview_road(idx: int) -> void:
	quality_locked = true
	_apply_quality(1.5, Viewport.MSAA_4X, false)
	start_round(idx)
	playing = false
	var total := maxi(clear_total, 1)
	player_eaten = int(float(total) * 0.82)
	clear_eaten = player_eaten
	_sync_level()
	shown_radius = hole_radius
	hole_open = hole_radius
	hole_mesh.scale = Vector3(shown_radius, 1.0, shown_radius)
	# Look at a cross street so the grown camera frames the road grid.
	hole_pos = Vector3(18.0, 0.0, -18.0)
	hole_mesh.position = hole_pos
	_snap_camera()
	print("ROADVIEW idx %d radius %.2f dist %.1f pitch %.1f" % [idx, hole_radius, cam_distance, cam_pitch])
	_set_chrome(false)
	_set_match_hud(false)
	if hud_layer:
		hud_layer.visible = false

func _probe_facing() -> void:
	var bad := 0
	var checked := 0
	for mi in CatalogScript.maps().size():
		start_round(mi)
		playing = false
		for _step in 20:
			_tick_movers(1.0 / 60.0)
		var seen := {}
		var small := {}
		for o in props:
			if float(o.base) <= 0.9:
				var sid := kind_id_of(int(o.kind))
				small[sid] = int(small.get(sid, 0)) + 1
		print("VARIETY map %d types %d" % [mi, small.size()])
		for o in movers:
			if not bool(o.alive):
				continue
			var dir: Vector3 = o.dir
			if dir.length_squared() < 0.0001 or float(o.speed) < 0.05:
				continue
			var face := float(o.get("face", 0.0))
			for _settle in 45:
				var target := atan2(dir.x, dir.z) + face
				o.yaw = _turn_toward(float(o.yaw), target, 1.0 / 60.0)
			var nose := _nose_of(float(o.yaw), face)
			var dot := nose.dot(dir.normalized())
			var id := kind_id_of(int(o.kind))
			checked += 1
			if not seen.has(id) or float(seen[id]) > dot:
				seen[id] = dot
			if dot < 0.9:
				bad += 1
				print("FACE FAIL %s map %d dot %.3f" % [id, mi, dot])
		for id in seen.keys():
			print("FACE %s map %d dot %.3f" % [str(id), mi, float(seen[id])])
	if bad == 0 and checked > 0:
		print("FACE_OK %d" % checked)
	else:
		print("FACE_BAD %d checked %d" % [bad, checked])
	get_tree().quit()

func _preview_zoom(kind: String) -> void:
	quality_locked = true
	_apply_quality(1.5, Viewport.MSAA_4X, false)
	start_round(0)
	playing = false
	if kind == "wide":
		var total := maxi(clear_total, 1)
		player_eaten = int(float(total) * 0.55)
		clear_eaten = int(float(total) * 0.97)
		_sync_level()
	shown_radius = hole_radius
	hole_open = hole_radius
	hole_mesh.scale = Vector3(shown_radius, 1.0, shown_radius)
	_snap_camera()
	_set_chrome(false)
	_set_match_hud(false)
	if hud_layer:
		hud_layer.visible = false

func _probe_cam() -> void:
	var bad := 0
	var sizes := [["portrait", 390.0 / 844.0], ["landscape", 844.0 / 390.0]]
	for sz in sizes:
		aspect_lock = float(sz[1])
		for grown in [false, true]:
			start_round(3)
			playing = false
			if grown:
				var total := maxi(clear_total, 1)
				player_eaten = int(float(total) * 0.45)
				clear_eaten = player_eaten
				_sync_level()
				shown_radius = hole_radius
			_snap_camera()
			var frac := _screen_frac(shown_radius, cam_distance)
			var strip := _sky_strip(cam_pitch, cam.fov)
			print("CAM %s aspect %.2f %s fov %.1f pitch %.1f dist %.2f frac %.3f sky %.3f speed %.2f" % [str(sz[0]), aspect_lock, "grown" if grown else "start", cam.fov, cam_pitch, cam_distance, frac, strip, _move_speed()])
			if absf(cam.fov - CAM_FOV) > 0.2 or absf(cam_pitch - CAM_PITCH_DEG) > 0.2 or strip > 0.001:
				bad += 1
	if bad == 0:
		print("CAM_OK")
	else:
		print("CAM_BAD %d" % bad)
	get_tree().quit()

func _quiet_spot() -> Vector3:
	for x in range(-68, 68, 5):
		for z in range(-68, 68, 5):
			var p := Vector3(float(x), 0.0, float(z))
			if _scan_buckets(p, 2.4).is_empty() and _surf_f(p.x, p.z) != SURF_WATER:
				return p
	return Vector3(40.0, 0.0, -40.0)

func _probe_feet() -> void:
	_ensure_models()
	var bad := 0
	var kinds := 0
	for ki in prop_defs.size():
		kinds += 1
		var scale := maxf(float(prop_defs[ki][2]), 0.001)
		var visual := _visual_half(ki) * scale
		var placed := float(kind_base[ki]) * scale
		var role := str(prop_defs[ki][5])
		var id := kind_id_of(ki)
		var ok := placed >= 0.04 and visual >= 0.02
		if role in ["tree", "palm"]:
			ok = ok and placed >= visual * 0.55 and placed <= visual * 0.98
		elif placed > visual * 1.12:
			ok = false
		if not ok:
			bad += 1
			print("FOOT_KIND FAIL %s role=%s base=%.3f visual=%.3f" % [id, role, placed, visual])
		else:
			print("FOOT_KIND %s role=%s base=%.3f visual=%.3f" % [id, role, placed, visual])
	feet_lock = true
	for mi in CatalogScript.maps().size():
		start_round(mi)
		playing = false
		bot_drive = false
		var seen := {}
		var loose := 0
		for o in props:
			if not bool(o.alive):
				continue
			if not o.has("bkey"):
				loose += 1
			var id := kind_id_of(int(o.kind))
			seen[id] = o
			var visual := _visual_half(int(o.kind)) * float(o.scale.x)
			var base := float(o.base)
			var role := str(o.role)
			var fit_ok := base >= 0.04 and base <= visual * 1.12 + 0.02
			if role in ["tree", "palm"]:
				fit_ok = base >= visual * 0.55 and base <= visual * 0.98
			if not fit_ok:
				bad += 1
				print("FOOT_PROP FAIL %s %s base=%.3f visual=%.3f" % [str(map.name), id, base, visual])
		if loose > 0:
			bad += loose
			print("FOOT_BUCKET FAIL %s loose %d" % [str(map.name), loose])
		var other_done := false
		for id in seen.keys():
			var sample: Dictionary = seen[id]
			var role := str(sample.role)
			var plant := role in ["tree", "palm"]
			if not plant and not other_done:
				plant = true
				other_done = true
			if not plant:
				continue
			var spot := _quiet_spot()
			_plant_prop(sample, spot)
			for rival in rivals:
				rival.alive = false
				rival.respawn = 999.0
			var base := float(sample.base)
			hole_pos = spot
			hole_radius = base * 0.72
			shown_radius = hole_radius
			hole_open = hole_radius
			playing = true
			_activate_nearby()
			playing = false
			if bool(sample.in_body) or not bool(sample.alive):
				bad += 1
				print("FOOT_HOLD FAIL %s %s base=%.3f rad=%.3f" % [str(map.name), str(id), base, hole_radius])
			hole_radius = base / OPEN_FIT + 0.16
			shown_radius = hole_radius
			hole_open = hole_radius
			player_invuln = 99.0
			playing = true
			var fell := false
			for _frame in 24:
				await get_tree().physics_frame
				if not bool(sample.alive) or bool(sample.in_body) or bool(sample.get("pit", false)):
					var yy := 0.0
					if sample.body != null:
						yy = (sample.body as RigidBody3D).global_position.y
					if not bool(sample.alive) or yy < -0.12 or bool(sample.get("pit", false)) or float(sample.get("tilt", 0.0)) > 0.25:
						fell = true
						break
			if not fell:
				bad += 1
				print("FOOT_FALL FAIL %s %s base=%.3f rad=%.3f" % [str(map.name), str(id), base, hole_radius])
			else:
				print("FOOT_FALL %s %s ok" % [str(map.name), str(id)])
			playing = false
		print("FOOT_MAP %s kinds %d" % [str(map.name), seen.size()])
	print("FOOT_SUM kinds %d bad %d" % [kinds, bad])
	print("FOOT_OK" if bad == 0 else "FOOT_FAIL")
	get_tree().quit()

func _probe_rival_bot() -> void:
	var maps := [0, 4, 9]
	var trials := 3
	var cap := 100.0
	for mi in maps:
		var firsts: Array = []
		var deaths := 0
		for trial in trials:
			seed(4100 + mi * 19 + trial * 7)
			bot_drive = true
			feet_lock = false
			start_round(mi)
			var min_ratio := 99.0
			for rival in rivals:
				min_ratio = minf(min_ratio, float(rival.radius) / maxf(hole_radius, 0.01))
			var edible := 0
			for rival in rivals:
				if hole_radius > float(rival.radius) * EAT_RATIO:
					edible += 1
			bot_clock = 0.0
			bot_lock = {}
			bot_avoid_uid = -1
			bot_stall = 0.0
			bot_best_d = 999.0
			var first := -1.0
			var dead := false
			var guard := 0
			var mark := 0.0
			while bot_clock < cap and guard < 7000:
				await get_tree().physics_frame
				guard += 1
				if first < 0.0 and rival_bites > 0:
					first = bot_clock
				if bot_clock >= mark:
					mark += 20.0
					print("BOT_TICK level %d trial %d t %.1f hole %.2f bites %d food %.1f" % [mi + 1, trial, bot_clock, hole_radius, rival_bites, bot_food_dist])
				if round_eaten != "" or mode != "play":
					dead = true
					break
			if dead:
				deaths += 1
			firsts.append(first)
			var rival_r := 0.0
			var alive_n := 0
			for rival in rivals:
				if bool(rival.alive):
					alive_n += 1
					rival_r += float(rival.radius)
			if alive_n > 0:
				rival_r /= float(alive_n)
			print("BOT level %d trial %d first %.1f dead %s bites %d hole %.2f rival %.2f spawn_min %.2f edible0 %d" % [mi + 1, trial, first, str(dead), rival_bites, hole_radius, rival_r, min_ratio, edible])
		var caught := 0
		var sum := 0.0
		for f in firsts:
			if float(f) >= 0.0:
				caught += 1
				sum += float(f)
		var avg := sum / float(maxi(caught, 1))
		print("BOT_SUM level %d deaths %d/%d caught %d avg_first %.1f" % [mi + 1, deaths, trials, caught, avg])
	print("BOT_OK")
	get_tree().quit()

func _probe_growth() -> void:
	for i in CatalogScript.maps().size():
		start_round(i)
		var start_r := hole_radius
		var start_dist := _cam_dist_for(start_r)
		var guard := 0
		while clear_total > 0 and _clear_ratio() + 0.0000001 < CLEAR_RATIO and guard < 4000:
			var step := maxi(int(clear_total / 40), 1)
			clear_eaten = mini(clear_eaten + step, int(ceil(float(clear_total) * CLEAR_RATIO)))
			player_eaten = clear_eaten
			_sync_level()
			guard += 1
		shown_radius = hole_radius
		var end_r := hole_radius
		var end_dist := _cam_dist_for(end_r)
		var rival_cap := minf(final_radius * RIVAL_CAP, 0.48 * GROW_MULTIPLE)
		var fits := map_max_base < end_r * FIT_RATIO
		print("GROW %s start %.3f end %.3f x%.2f size %d final %.3f maxb %.3f fits %s rival %.2f screen %.0f%% -> %.0f%%" % [str(map.name), start_r, end_r, end_r / maxf(start_r, 0.001), level + 1, final_radius, map_max_base, "yes" if fits else "NO", rival_cap, _screen_frac(start_r, start_dist) * 100.0, _screen_frac(end_r, end_dist) * 100.0])
	get_tree().quit()

func _probe_grow_time() -> void:
	start_round(0)
	playing = true
	player_invuln = 999.0
	var start_r := hole_radius
	grow_drive = true
	player_invuln = 999.0
	var max_err := 0.0
	for _frame in 900:
		await get_tree().physics_frame
		await get_tree().process_frame
		var ideal := hole_pos + _camera_offset(cam_distance)
		max_err = maxf(max_err, cam.position.distance_to(ideal))
	var x15 := hole_radius / maxf(start_r, 0.001)
	print("GROWTIME start %.3f final %.3f xFinal %.2f maxb %.3f t15 eaten %d clear %.1f%% hole %.3f x%.2f shown %.3f size %d camErr %.4f" % [start_r, final_radius, final_radius / maxf(start_r, 0.001), map_max_base, clear_eaten, _clear_ratio() * 100.0, hole_radius, x15, shown_radius, level + 1, max_err])
	for ratio in [0.30, 0.60, 0.65, 0.70, CLEAR_RATIO]:
		clear_eaten = int(round(float(clear_total) * ratio))
		player_eaten = clear_eaten
		_sync_level()
		var mult := hole_radius / maxf(start_r, 0.001)
		print("GROWTIME clear %.0f%% progress %.1f%% hole %.3f x%.2f size %d" % [ratio * 100.0, _player_progress() * 100.0, hole_radius, mult, level + 1])
	get_tree().quit(0 if max_err < 0.001 else 1)

func _grow_drive_step(delta: float) -> void:
	var spd := _move_speed()
	var aim := _nearest_edible()
	var step := aim - hole_pos
	step.y = 0.0
	if step.length_squared() < 0.04:
		step = Vector3(1.0, 0.0, 0.0)
	var nxt := hole_pos + step.normalized() * spd * delta
	if _surf_f(nxt.x, hole_pos.z) != SURF_WATER:
		hole_pos.x = nxt.x
	if _surf_f(hole_pos.x, nxt.z) != SURF_WATER:
		hole_pos.z = nxt.z
	var lim := CITY_HALF - 2.0
	hole_pos.x = clampf(hole_pos.x, -lim, lim)
	hole_pos.z = clampf(hole_pos.z, -lim, lim)

func _nearest_edible() -> Vector3:
	var best := INF
	var at := hole_pos + Vector3(1.0, 0.0, 0.0)
	var reach := hole_radius + 22.0
	for o in _scan_buckets(hole_pos, reach):
		if bool(o.in_body) or not bool(o.alive):
			continue
		if not _fits_r(float(o.base), hole_radius):
			continue
		var d := _xz_dist(o.pos, hole_pos)
		if d < best:
			best = d
			at = o.pos
	return at

func _probe_edge_eat() -> void:
	start_round(0)
	playing = false
	edge_probe = true
	velocity = Vector3.ZERO
	for rv in rivals:
		rv.alive = false
	var lines: PackedStringArray = []
	var ok := true
	for rad in [0.55, 4.0]:
		var inside: Dictionary = await _probe_one_eat(rad, true)
		lines.append(str(inside.text))
		ok = ok and bool(inside.ok)
		var outside: Dictionary = await _probe_one_eat(rad, false)
		lines.append(str(outside.text))
		ok = ok and bool(outside.ok)
	print("EAT_PROBE %s" % " | ".join(lines))
	get_tree().quit(0 if ok else 1)

func _probe_latency() -> void:
	start_round(0)
	playing = true
	velocity = Vector3.ZERO
	joy_held = false
	for rv in rivals:
		rv.alive = false
		rv.respawn = 99999.0
	_latency_begin_slide(0.55)
	latency_probe = true
	for _i in 180:
		await get_tree().physics_frame
		if lat_phase == "done":
			break
	print("LAT " + " || ".join(lat_lines))
	get_tree().quit(0 if lat_phase == "done" else 1)

func _latency_begin_slide(rad: float) -> void:
	var sample := _probe_small_prop(rad)
	lat_prop = sample
	lat_phase = "slide"
	lat_frame = 0
	lat_geo = -1
	lat_fit = -1
	lat_body = -1
	lat_drop = -1
	lat_trace = PackedStringArray()
	lat_hold = 0
	if sample.is_empty():
		lat_lines.append("slide r=%.2f no-prop" % rad)
		lat_phase = "burst" if rad < 1.0 else "partial"
		return
	var base := float(sample.base)
	var at := Vector3(18.0, 0.0, 14.0)
	_plant_prop(sample, at)
	lat_radius = rad
	hole_radius = rad
	shown_radius = rad
	hole_open = rad
	hole_pos = at + Vector3(-(rad - base * 0.16) - 0.2, 0.0, 0.0)
	lat_y0 = _visual_y(sample)

func _latency_advance() -> void:
	lat_frame += 1
	lat_sample_now = true
	hole_radius = lat_radius
	shown_radius = lat_radius
	hole_open = lat_radius
	if lat_phase == "slide":
		hole_pos.x += 0.06
	elif lat_phase == "burst":
		if lat_frame == 1:
			_latency_plant_burst()

func _latency_sample() -> void:
	if lat_phase == "slide":
		_latency_sample_slide()
	elif lat_phase == "burst":
		_latency_sample_burst()
	elif lat_phase == "partial":
		_latency_sample_partial()

func _latency_sample_slide() -> void:
	if lat_prop.is_empty():
		return
	var base := float(lat_prop.base)
	var dist := _xz_dist(lat_prop.pos if lat_prop.body == null else (lat_prop.body as RigidBody3D).global_position, hole_pos)
	var y := _visual_y(lat_prop)
	if lat_geo < 0 and dist < hole_radius:
		lat_geo = lat_frame
	if lat_fit < 0 and _center_in_opening(base, dist, hole_radius):
		lat_fit = lat_frame
	if lat_body < 0 and bool(lat_prop.in_body):
		lat_body = lat_frame
	if lat_drop < 0 and lat_fit >= 0 and (y < lat_y0 - 0.05 or not bool(lat_prop.alive)):
		lat_drop = lat_frame
	if lat_trace.size() < 16:
		var by := -9.0
		if lat_prop.body != null:
			by = (lat_prop.body as RigidBody3D).global_position.y
		lat_trace.append("%.2f/%.2f" % [y, by])
	if lat_drop >= 0:
		lat_hold += 1
	if lat_hold >= 2 or lat_frame >= 28:
		var vis := (lat_drop - lat_fit) if lat_drop >= 0 and lat_fit >= 0 else -1
		var geo := (lat_drop - lat_geo) if lat_drop >= 0 and lat_geo >= 0 else -1
		var act := (lat_body - lat_fit) if lat_body >= 0 and lat_fit >= 0 else -1
		lat_lines.append("slide r=%.2f base=%.3f geo=%d fit=%d body=%d drop=%d visFrames=%d geoFrames=%d actFrames=%d ys=%s" % [hole_radius, base, lat_geo, lat_fit, lat_body, lat_drop, vis, geo, act, ",".join(lat_trace)])
		if hole_radius < 1.0:
			_latency_begin_slide(4.0)
		else:
			_latency_begin_burst()

func _latency_begin_burst() -> void:
	lat_phase = "burst"
	lat_frame = 0
	lat_burst = []
	lat_fit = -1
	lat_drop = -1
	lat_hold = 0
	lat_radius = 1.8
	hole_radius = 1.8
	shown_radius = 1.8
	hole_open = 1.8
	hole_pos = Vector3(-22.0, 0.0, 16.0)

func _latency_plant_burst() -> void:
	var used := {}
	var n := 0
	for o in props:
		if n >= 12:
			break
		if bool(o.get("in_body", false)) or not bool(o.get("alive", false)):
			continue
		var base := float(o.base)
		if base < 0.08 or base > 0.35:
			continue
		var uid := int(o.get("uid", n))
		if used.has(uid):
			continue
		used[uid] = true
		var ang := TAU * float(n) / 12.0
		_plant_prop(o, hole_pos + Vector3(cos(ang) * 0.45, 0.0, sin(ang) * 0.45))
		o["lat_y0"] = _visual_y(o)
		o["lat_drop"] = -1
		lat_burst.append(o)
		n += 1

func _latency_sample_burst() -> void:
	if lat_burst.is_empty():
		if lat_frame > 2:
			lat_lines.append("burst no-props")
			_latency_begin_partial()
		return
	if lat_fit < 0:
		lat_fit = lat_frame
	var pending := 0
	var worst := 0
	for o in lat_burst:
		var y := _visual_y(o)
		var dropped := int(o.lat_drop)
		if dropped < 0 and (y < float(o.lat_y0) - 0.05 or not bool(o.alive)):
			o.lat_drop = lat_frame
			dropped = lat_frame
		if dropped < 0:
			pending += 1
		else:
			worst = maxi(worst, dropped - lat_fit)
	if pending == 0 or lat_frame >= 36:
		lat_lines.append("burst n=%d fit=%d pending=%d worstFrames=%d" % [lat_burst.size(), lat_fit, pending, worst])
		_latency_begin_partial()

func _latency_begin_partial() -> void:
	lat_phase = "partial"
	lat_frame = 0
	lat_hold = 0
	lat_prop = _probe_small_prop(1.2)
	lat_radius = 1.2
	hole_radius = 1.2
	shown_radius = 1.2
	hole_open = 1.2
	if lat_prop.is_empty():
		lat_lines.append("partial no-prop")
		lat_phase = "done"
		return
	var base := float(lat_prop.base)
	var at := Vector3(-8.0, 0.0, -12.0)
	_plant_prop(lat_prop, at)
	hole_pos = at + Vector3(-(hole_radius + base * 0.45), 0.0, 0.0)
	lat_prop.sink = -1
	_take_body(lat_prop)
	lat_y0 = _visual_y(lat_prop)

func _latency_sample_partial() -> void:
	if lat_prop.is_empty():
		lat_phase = "done"
		return
	lat_hold += 1
	var y := _visual_y(lat_prop)
	var mask := -1
	if lat_prop.body != null:
		mask = int((lat_prop.body as RigidBody3D).collision_mask)
	if lat_hold >= 6:
		var snapped := mask == 0 or y < lat_y0 - 0.12
		lat_lines.append("partial base=%.3f y=%.3f mask=%d instant=%s" % [float(lat_prop.base), y, mask, str(snapped)])
		lat_phase = "done"

func _plant_prop(o: Dictionary, at: Vector3) -> void:
	o.pos = at
	o.vel = Vector3.ZERO
	o.alive = true
	o.shown_y = at.y
	var basis := Basis(Vector3.UP, float(o.yaw)).scaled(o.scale)
	var xf := Transform3D(basis, at)
	o.xform = xf
	if bool(o.in_mesh):
		var mm := _mm_of(o)
		if mm:
			mm.set_instance_transform(int(o.index), xf)
	_bucket_move(o)
	_set_shadow(o)

func _visual_y(o: Dictionary) -> float:
	if not bool(o.get("alive", false)):
		return -3.0
	if o.has("shown_y"):
		return float(o.shown_y)
	return float((o.pos as Vector3).y)

func _probe_one_eat(rad: float, want_fall: bool) -> Dictionary:
	hole_radius = rad
	hole_open = rad
	shown_radius = rad
	hole_pos = Vector3(12.0, 0.0, -6.0)
	var player_ring := {"root": rim_root, "bodies": rim_bodies, "radius": -1.0}
	_place_ring(player_ring, rad, hole_pos, true)
	rim_radius = rad
	var sample := _probe_small_prop(rad)
	if sample.is_empty():
		return {"ok": false, "text": "r=%.2f %s no-prop" % [rad, "in" if want_fall else "out"]}
	var base := float(sample.base)
	var dist := (rad - base * 0.16 - 0.05) if want_fall else (rad + base * 0.85 + 0.12)
	sample.pos = hole_pos + Vector3(dist, 0.0, 0.0)
	sample.vel = Vector3.ZERO
	sample.sink = -1
	if not _take_body(sample):
		return {"ok": false, "text": "r=%.2f take-fail base=%.3f" % [rad, base]}
	var b: RigidBody3D = sample.body
	var min_y := b.global_position.y
	var mask0 := int(b.collision_mask)
	for _f in 48:
		await get_tree().physics_frame
		if sample.body == null:
			min_y = -3.0
			break
		min_y = minf(min_y, (sample.body as RigidBody3D).global_position.y)
	var fell := min_y < -0.35 or sample.body == null
	if sample.body != null:
		_release_body(sample, (sample.body as RigidBody3D).global_position)
	var good := fell == want_fall
	var label := "in" if want_fall else "out"
	return {
		"ok": good,
		"text": "r=%.2f %s base=%.3f dist=%.3f mask=%d minY=%.2f fell=%s %s" % [rad, label, base, dist, mask0, min_y, str(fell), "ok" if good else "FAIL"],
	}

func _probe_small_prop(rad: float) -> Dictionary:
	var best: Dictionary = {}
	var best_base := 99.0
	var limit := rad * FIT_RATIO * 0.92
	for o in props:
		if bool(o.get("in_body", false)) or not bool(o.get("alive", false)):
			continue
		var base := float(o.base)
		if base < 0.08 or base > limit or base > 0.55:
			continue
		if base < best_base:
			best = o
			best_base = base
	return best

func _preview_size() -> void:
	quality_locked = true
	_apply_quality(1.5, Viewport.MSAA_4X, false)
	start_round(0)
	playing = false
	var total := maxi(clear_total, 1)
	clear_eaten = int(ceil(float(total) * CLEAR_RATIO * 0.86))
	player_eaten = clear_eaten
	_sync_level()
	shown_radius = hole_radius
	hole_open = hole_radius
	hole_mesh.scale = Vector3(shown_radius, 1.0, shown_radius)
	size_banner_t = 0.0
	kept_pulse = false
	if size_lbl:
		size_lbl.text = "Size %d" % (level + 1)
	_snap_camera()
	_set_chrome(false)
	_set_match_hud(true)
	_refresh_hud()
	if _web_search().find("topple=1") != -1:
		playing = true
		player_invuln = 99.0
		for rv in rivals:
			rv.alive = false
		_hide_drag_hint()
		var target := _topple_shot_target()
		if not target.is_empty():
			var base := float(target.base)
			var rad := clampf(base / FIT_RATIO + 0.55, 2.0, 3.6)
			hole_radius = rad
			shown_radius = rad
			shown_vel = 0.0
			hole_open = rad
			var at: Vector3 = target.pos
			var dist := rad + base * 0.62
			hole_pos = Vector3(at.x - dist, 0.0, at.z)
			velocity = Vector3.ZERO
			hole_mesh.position = hole_pos
			hole_mesh.scale = Vector3(rad, 1.0, rad)
			_snap_camera()

func _topple_shot_target() -> Dictionary:
	var best: Dictionary = {}
	var best_d := 80.0
	for o in props:
		if not bool(o.get("alive", false)):
			continue
		var role := str(o.get("role", ""))
		if not (role in ["barn", "building", "house", "tower", "wide", "landmark"]):
			continue
		if float(o.get("height", 0.0)) < 1.8:
			continue
		var d := (o.pos as Vector3).length()
		if d < 10.0 or d > 36.0:
			continue
		if d < best_d:
			best = o
			best_d = d
	return best

func _probe_topple() -> void:
	start_round(0)
	playing = false
	for rv in rivals:
		rv.alive = false
	var building: Dictionary = {}
	var best_h := 0.0
	for o in props:
		if not bool(o.get("alive", false)) or bool(o.get("in_body", false)):
			continue
		var role := str(o.get("role", ""))
		if not (role in ["barn", "building", "house", "tower", "wide", "landmark"]):
			continue
		var h := float(o.get("height", 0.0))
		if h > best_h:
			best_h = h
			building = o
	if building.is_empty():
		print("TOPPLE_FAIL none")
		get_tree().quit()
		return
	var base := float(building.base)
	var rad := maxf(base / FIT_RATIO + 0.35, 2.6)
	hole_radius = rad
	shown_radius = rad
	hole_open = rad
	var at := Vector3(8.0, 0.0, 3.0)
	_plant_prop(building, at)
	var dist0 := rad + base * 0.72
	hole_pos = at + Vector3(-dist0, 0.0, 0.0)
	building.sink = -1
	if not _take_body(building):
		print("TOPPLE_FAIL take")
		get_tree().quit()
		return
	var max_step := 0.0
	var min_y := 0.0
	var max_tilt := 0.0
	var tipped_before_drop := false
	var prev := (building.body as RigidBody3D).global_position
	for i in 220:
		if i < 110:
			hole_pos.x += 0.034
		await get_tree().physics_frame
		if building.body == null or not bool(building.get("alive", false)):
			print("TOPPLE f=%d swallowed minY %.3f maxStep %.3f maxTilt %.3f tipped %s" % [i, min_y, max_step, max_tilt, str(tipped_before_drop)])
			print("TOPPLE_OK" if max_tilt > 0.2 and tipped_before_drop and max_step < 0.75 else "TOPPLE_FAIL")
			get_tree().quit()
			return
		var xf := (building.body as RigidBody3D).global_transform
		var step := xf.origin.distance_to(prev)
		if i > 0:
			max_step = maxf(max_step, step)
		prev = xf.origin
		min_y = minf(min_y, xf.origin.y)
		var lean := 1.0 - xf.basis.y.dot(Vector3.UP)
		if lean > 0.2 and xf.origin.y > -0.25:
			tipped_before_drop = true
		max_tilt = maxf(max_tilt, lean)
		if i % 20 == 0:
			print("TOPPLE f=%d y=%.3f lean=%.3f step=%.3f perch=%s pit=%s" % [i, xf.origin.y, lean, step, str(building.get("perch", false)), str(building.get("pit", false))])
	print("TOPPLE timeout minY %.3f maxStep %.3f maxTilt %.3f tipped %s" % [min_y, max_step, max_tilt, str(tipped_before_drop)])
	print("TOPPLE_OK" if max_tilt > 0.35 and max_step < 0.75 else "TOPPLE_FAIL")
	get_tree().quit()

func _probe_kinds() -> void:
	_ensure_models()
	var ids: Array = kind_by_id.keys()
	ids.sort()
	for id in ids:
		var ki: int = int(kind_by_id[id])
		var scale := float(prop_defs[ki][2])
		var placed := float(kind_base[ki]) * scale
		var native: Vector3 = kind_native[ki]
		print("KIND %s role=%s kbase=%.3f scale=%.2f placed=%.3f foot=%.2f h=%.2f" % [str(id), str(prop_defs[ki][5]), float(kind_base[ki]), scale, placed, maxf(native.x, native.z), native.y])
	get_tree().quit()

func _probe_tiers() -> void:
	for i in CatalogScript.maps().size():
		start_round(i)
		var counts := _tier_counts()
		var max_in: Array = []
		var min_in: Array = []
		var districts: Array = []
		max_in.resize(TIER_NAME.size())
		min_in.resize(TIER_NAME.size())
		districts.resize(TIER_NAME.size())
		for t in TIER_NAME.size():
			max_in[t] = 0.0
			min_in[t] = 99.0
			districts[t] = {}
		var near_tiny := 0
		var near_small := 0
		for o in props:
			if not bool(o.get("alive", true)):
				continue
			var base := float(o.base)
			var t := _tier_of(base)
			max_in[t] = maxf(float(max_in[t]), base)
			min_in[t] = minf(float(min_in[t]), base)
			var d := _district(int(round((o.pos as Vector3).x)), int(round((o.pos as Vector3).z)))
			(districts[t] as Dictionary)[d] = int((districts[t] as Dictionary).get(d, 0)) + 1
			var home := (o.pos as Vector3).length()
			if home < 30.0 and t == 0:
				near_tiny += 1
			elif home < 30.0 and t == 1:
				near_small += 1
		var unfit := 0
		var limit := final_radius * FIT_RATIO
		for o in props:
			if float(o.base) > limit:
				unfit += 1
		var id_name := {}
		for key in kind_by_id.keys():
			id_name[int(kind_by_id[key])] = str(key)
		var mixes: Array = []
		mixes.resize(TIER_NAME.size())
		for t in TIER_NAME.size():
			mixes[t] = {}
		for o in props:
			if not bool(o.get("alive", true)):
				continue
			var t := _tier_of(float(o.base))
			var nm := str(id_name.get(int(o.kind), "?"))
			(mixes[t] as Dictionary)[nm] = int((mixes[t] as Dictionary).get(nm, 0)) + 1
		var inner_large := 0
		var outer_small := 0
		var mover_n := 0
		for o in props:
			if not bool(o.get("alive", true)):
				continue
			var home := (o.pos as Vector3).length()
			var t := _tier_of(float(o.base))
			if t >= 4 and home < 36.0:
				inner_large += 1
			if t <= 1 and home > 40.0:
				outer_small += 1
			if int(o.mover) != 0:
				mover_n += 1
		print("TIERMAP %s props %d final %.3f maxb %.3f limit %.3f unfit %d near30 tiny %d small %d innerLarge %d outerSmall %d movers %d" % [str(map.name), props.size(), final_radius, map_max_base, limit, unfit, near_tiny, near_small, inner_large, outer_small, mover_n])
		for t in TIER_NAME.size():
			var pairs: Array = []
			for nm in (mixes[t] as Dictionary).keys():
				pairs.append({"id": str(nm), "n": int((mixes[t] as Dictionary)[nm])})
			pairs.sort_custom(func(a, b): return int(a.n) > int(b.n))
			var bits: PackedStringArray = []
			for k in mini(4, pairs.size()):
				bits.append("%s %d" % [str(pairs[k].id), int(pairs[k].n)])
			print("MIX %s %s %s" % [str(map.name), str(TIER_NAME[t]), " ".join(bits)])
		for t in TIER_NAME.size():
			var n := int(counts[t])
			var mx := float(max_in[t])
			var unlock := mx / FIT_RATIO if n > 0 else 0.0
			var mult := unlock / maxf(_start_radius(), 0.001)
			var edible := n > 0 and unlock < final_radius - 0.02
			var dist_n := (districts[t] as Dictionary).size()
			print("TIER %s %-9s n=%4d band=%.2f-%.2f max=%.2f unlock=%.2f x%.2f %s dist=%d" % [str(map.name), str(TIER_NAME[t]), n, float(TIER_LO[t]), float(TIER_HI[t]), mx, unlock, mult, "edible" if edible else "SHORT", dist_n])
	get_tree().quit()

func _probe_maps() -> void:
	for i in CatalogScript.maps().size():
		start_round(i)
		var max_base := 0.0
		var roles := {}
		for o in props:
			max_base = maxf(max_base, float(o.base))
			var role := str(o.role)
			roles[role] = int(roles.get(role, 0)) + 1
		var unfit := 0
		var limit := final_radius * FIT_RATIO
		for o in props:
			if float(o.base) > limit:
				unfit += 1
		var nodes := 0
		if city_root != null:
			nodes = city_root.get_child_count()
		var mem := int(OS.get_static_memory_usage())
		var clear_tall := 0
		var clear_snack := 0
		var corridor_tall := 0
		var corridor_hi := 0
		for o in props:
			var home := (o.pos as Vector3).length()
			var tall := float(o.height) > 1.7 or str(o.role) in ["barn", "tower", "building", "wide", "house", "landmark", "tank", "boat"]
			if home < SPAWN_CLEAR:
				if tall:
					clear_tall += 1
				else:
					clear_snack += 1
			if tall and _in_view_corridor(o.pos):
				corridor_tall += 1
				if float(o.height) > 2.2:
					corridor_hi += 1
		print("MAP %s props %d total %d tiles %d nodes %d load %d ms mem %d maxb %.3f final %.3f unfit %d clear_tall %d clear_snack %d corridor_tall %d corridor_hi %d %s" % [str(map.name), props.size(), clear_total, city_tiles, nodes, city_load_ms, mem, max_base, final_radius, unfit, clear_tall, clear_snack, corridor_tall, corridor_hi, str(roles)])
	get_tree().quit()

func _preview_close(idx: int) -> void:
	start_round(idx)
	playing = false
	cam_hold = true
	_set_match_hud(false)
	if hud_layer:
		hud_layer.visible = false
	if hole_mesh:
		hole_mesh.visible = false
	var look := Vector3(0.0, 0.8, -8.0)
	var best_score := -1.0
	var best_id := ""
	for o in props:
		var p: Vector3 = o.pos
		if p.z > -3.5 or p.length() > 20.0:
			continue
		var role := str(o.role)
		if role == "clutter":
			continue
		var weight := float(o.base)
		if role in ["barn", "ride", "boat", "stall"]:
			weight += 1.6
		var band := 1.0 - clampf(Vector2(p.x, p.z + 9.0).length() / 10.0, 0.0, 1.0)
		var score := weight * (0.45 + band)
		if score > best_score:
			best_score = score
			best_id = kind_id_of(int(o.kind))
			look = p + Vector3(0.0, maxf(float(o.height) * 0.4, 0.35), 0.0)
	print("CLOSE %s %s" % [str(map.get("name", "")), best_id])
	if cam:
		cam.fov = 44.0
		cam.position = look + Vector3(2.1, 2.15, 4.9)
		cam.look_at(look, Vector3.UP)

func _preview_overview() -> void:
	quality_locked = true
	_apply_quality(1.0, Viewport.MSAA_2X, false)
	start_round(0)
	playing = false
	_set_chrome(false)
	_set_match_hud(false)
	if hud_layer:
		hud_layer.visible = false
	hole_mesh.visible = false
	cam_hold = true
	cam.position = Vector3(0.0, 168.0, 78.0)
	cam.look_at(Vector3(0.0, 0.0, 8.0), Vector3.UP)

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
	playing = true
	_present_eaten("Scoot")

func _focus_canvas() -> void:
	if not OS.has_feature("web"):
		return
	# Desktop browsers drop the first mousedown when the canvas takes focus.
	# A capture-phase tracker records the press point itself, and setPointerCapture
	# keeps the gesture alive. Steering then reads that offset every frame.
	_steer_cb = JavaScriptBridge.create_callback(_on_web_steer)
	var window := JavaScriptBridge.get_interface("window")
	window.__holeSteerCb = _steer_cb
	JavaScriptBridge.eval("(function(){var c=document.getElementById('canvas');if(!c||c.__holeSteer)return;c.__holeSteer=1;c.setAttribute('tabindex','0');var focus=function(){if(document.activeElement===c)return;try{c.focus({preventScroll:true});}catch(e){c.focus();}};c.addEventListener('pointerover',focus,true);var send=function(down,ax,ay,x,y){var r=c.getBoundingClientRect();var cb=window.__holeSteerCb;if(!cb)return;cb(down,ax,ay,x,y,r.width,r.height);};window.addEventListener('pointerdown',function(e){if(e.target&&e.target.closest&&e.target.closest('#update-pill'))return;if(e.pointerType==='touch'||e.button!==0)return;var r=c.getBoundingClientRect();if(e.clientX<r.left||e.clientY<r.top||e.clientX>r.right||e.clientY>r.bottom)return;try{c.setPointerCapture(e.pointerId);}catch(err){}var x=e.clientX-r.left,y=e.clientY-r.top;window.__holeAX=x;window.__holeAY=y;send(1,x,y,x,y);},true);window.addEventListener('pointermove',function(e){if(e.pointerType==='touch')return;if((e.buttons&1)===0)return;var r=c.getBoundingClientRect();var x=e.clientX-r.left,y=e.clientY-r.top;if(window.__holeAX===undefined){window.__holeAX=x;window.__holeAY=y;}send(1,window.__holeAX,window.__holeAY,x,y);},true);var up=function(e){if(e.pointerType==='touch')return;if(window.__holeAX===undefined)return;var r=c.getBoundingClientRect();var x=e.clientX-r.left,y=e.clientY-r.top;send(0,window.__holeAX,window.__holeAY,x,y);window.__holeAX=undefined;};window.addEventListener('pointerup',up,true);window.addEventListener('pointercancel',up,true);focus();})();", true)
	web_steer = true

func _css_to_view(p: Vector2, css: Vector2) -> Vector2:
	var vp := get_viewport().get_visible_rect().size
	return Vector2(p.x * vp.x / maxf(css.x, 1.0), p.y * vp.y / maxf(css.y, 1.0))

func _on_web_steer(args: Array) -> void:
	if args.size() < 7:
		return
	if mode != "play" and mode != "attract":
		return
	if mode == "play" and not playing:
		return
	var css := Vector2(float(args[5]), float(args[6]))
	var anchor := _css_to_view(Vector2(float(args[1]), float(args[2])), css)
	var finger := _css_to_view(Vector2(float(args[3]), float(args[4])), css)
	var down := int(args[0]) != 0
	if down:
		_unlock_audio()
	if block_start_until_up:
		if not down:
			block_start_until_up = false
			joy_held = false
			ui_swallow_frames = maxi(ui_swallow_frames, 8)
			_refresh_joystick()
		return
	if not down:
		if joy_id == -1 and joy_held:
			if mode == "attract" and joy_finger.distance_to(joy_anchor) <= JOY_DEADZONE:
				_begin_play()
			joy_held = false
			_refresh_joystick()
		return
	if not joy_held or joy_id != -1:
		if _blocks_world(finger):
			return
		joy_held = true
		joy_id = -1
		joy_anchor = anchor
		joy_finger = finger
	else:
		joy_finger = finger
		if mode == "attract" and joy_finger.distance_to(joy_anchor) > JOY_DEADZONE:
			_begin_play()
	_refresh_joystick()

func _poll_pointer_steer() -> void:
	# Web drags are delivered by _on_web_steer. Elsewhere, sample the cursor
	# every frame so a held offset keeps moving even when events are sparse.
	if web_steer:
		return
	if mode != "play" and mode != "attract":
		return
	if mode == "play" and not playing:
		return
	if not Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		return
	var mp := get_viewport().get_mouse_position()
	if not joy_held or joy_id != -1:
		if _blocks_world(mp):
			return
		joy_held = true
		joy_id = -1
		joy_anchor = mp
		joy_finger = mp
		return
	joy_finger = mp
	if mode == "attract" and joy_finger.distance_to(joy_anchor) > JOY_DEADZONE:
		_begin_play()

func _probe_gate() -> void:
	var kept := Save.unlocked_level
	Save.unlocked_level = 4
	for i in Save.maps_cleared.size():
		Save.maps_cleared[i] = 0
	Save.stars[0] = 3
	Save.clears = 12
	Save._refresh_unlocks()
	print("GATE keep %d" % Save.unlocked_level)
	Save.unlocked_level = 0
	Save._refresh_unlocks()
	print("GATE stars-only %d" % Save.unlocked_level)
	Save.maps_cleared[0] = 1
	Save._refresh_unlocks()
	print("GATE after-clear0 %d" % Save.unlocked_level)
	Save.maps_cleared[1] = 1
	Save._refresh_unlocks()
	print("GATE after-clear1 %d" % Save.unlocked_level)
	Save.unlocked_level = kept
	get_tree().quit()

func _short_sha() -> String:
	var s := BUILD_SHA.strip_edges()
	if s.length() < 7 or s.begins_with("__"):
		return "dev"
	return s.substr(0, 7)

func _web_search() -> String:
	if OS.has_feature("web"):
		return str(JavaScriptBridge.eval("window.location.search", true))
	var extra := OS.get_environment("HOLE_QUERY")
	if extra == "":
		return ""
	return extra if extra.begins_with("?") else "?" + extra

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
	# The variable file's default master is weight 300, and a runtime
	# FontVariation does not rebake the MSDF, so the web build drew the light
	# master. This file is that family instanced at weight 700.
	var file := load("res://assets/fonts/FredokaBold.ttf") as Font
	if file == null:
		file = load("res://assets/fonts/Fredoka.ttf") as Font
	if file == null:
		ui_font = ThemeDB.fallback_font
		return
	ui_font = file

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
	# A synchronous force_draw during startup can stall the web loader at 100%.
	# The navy cover hides the first real frames while materials compile.
	return

func _ensure_cover() -> void:
	if round_cover != null:
		return
	var layer := CanvasLayer.new()
	layer.layer = 40
	add_child(layer)
	round_cover = ColorRect.new()
	round_cover.color = Color(0.16, 0.34, 0.28, 1)
	round_cover.set_anchors_preset(Control.PRESET_FULL_RECT)
	round_cover.mouse_filter = Control.MOUSE_FILTER_STOP
	layer.add_child(round_cover)
	load_title = Label.new()
	load_title.text = "Loading"
	load_title.set_anchors_preset(Control.PRESET_CENTER)
	load_title.offset_left = -320
	load_title.offset_right = 320
	load_title.offset_top = -36
	load_title.offset_bottom = 48
	load_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	load_title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_style(load_title, 48)
	round_cover.add_child(load_title)
	load_spin = Control.new()
	load_spin.set_anchors_preset(Control.PRESET_CENTER)
	load_spin.offset_left = -48
	load_spin.offset_right = 48
	load_spin.offset_top = -140
	load_spin.offset_bottom = -44
	load_spin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	load_spin.draw.connect(_draw_load_spin)
	round_cover.add_child(load_spin)
	round_cover.visible = false

func _draw_load_spin() -> void:
	if load_spin == null:
		return
	var c := load_spin.size * 0.5
	var n := 8
	for i in n:
		var ang := load_spin_t * 5.5 + TAU * float(i) / float(n)
		var dot := c + Vector2(cos(ang), sin(ang)) * 26.0
		var a := 0.28 + 0.72 * float(i) / float(n)
		load_spin.draw_circle(dot, 5.5, Color(1.0, 0.97, 0.88, a))

func _present_level_load(index: int) -> void:
	var maps: Array = CatalogScript.maps()
	var idx := clampi(index, 0, maps.size() - 1)
	var entry: Dictionary = maps[idx]
	var bg: Color = entry.get("ground", Color(0.16, 0.34, 0.22))
	bg = bg.lerp(entry.get("horizon", bg), 0.35)
	_ensure_cover()
	round_cover.color = bg
	round_cover.visible = true
	if load_title:
		load_title.text = "Loading %s" % str(entry.get("name", "level"))
		load_title.add_theme_color_override("font_color", entry.get("sun", Color(1, 0.97, 0.9)))
	if load_spin:
		load_spin.queue_redraw()
	reveal_size = Vector2.ZERO
	reveal_stable = 0
	reveal_since = Time.get_ticks_msec()
	if OS.has_feature("web"):
		var hex := "#" + bg.to_html(false)
		var title := "Loading %s" % str(entry.get("name", "level"))
		JavaScriptBridge.eval("window.__holeBuilding=true;if(window.__holeHoldLoader)window.__holeHoldLoader(true,%s,%s);" % [JSON.stringify(title), JSON.stringify(hex)], true)

func _request_round(index: int) -> void:
	if DisplayServer.get_name() == "headless":
		start_round(index)
		return
	level_loading = true
	_present_level_load(index)
	# Draw the loader, then let the browser paint it, before the build blocks.
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	if OS.has_feature("web"):
		# Two frames: the first paints the loader, the second runs after that paint.
		JavaScriptBridge.eval("window.__holeLoaderPainted=false;requestAnimationFrame(function(){requestAnimationFrame(function(){window.__holeLoaderPainted=true;});});", true)
		var guard := 0
		while guard < 8:
			var painted = JavaScriptBridge.eval("window.__holeLoaderPainted===true", true)
			if bool(painted):
				break
			await get_tree().process_frame
			guard += 1
	start_round(index)
	level_loading = false

func _warm_view() -> void:
	# The city is drawn on the following frames. Forcing those draws here
	# blocked the browser on the first visit and left the loader at 100%.
	if DisplayServer.get_name() == "headless":
		return
	_ensure_cover()

func _hold_for_reveal() -> void:
	if DisplayServer.get_name() == "headless":
		return
	_ensure_cover()
	round_cover.visible = true
	reveal_size = Vector2.ZERO
	reveal_stable = 0
	reveal_since = Time.get_ticks_msec()

func _hide_boot_loader() -> void:
	if not OS.has_feature("web"):
		return
	JavaScriptBridge.eval("window.__holeBuilding=false;if(window.__holeReveal)window.__holeReveal();", true)

func _tick_reveal() -> void:
	if boot_frames < 3:
		boot_frames += 1
	if round_cover != null and round_cover.visible and load_spin != null:
		load_spin_t += 0.08
		load_spin.queue_redraw()
	# The city build blocks the main thread. Leave the painted card up until it returns.
	if level_loading:
		return
	if round_cover == null or not round_cover.visible:
		return
	var sz := get_viewport().get_visible_rect().size
	if sz.y > 64.0 and sz.distance_to(reveal_size) < 1.0:
		reveal_stable += 1
	else:
		reveal_size = sz
		reveal_stable = 0
		if sz.y > 64.0:
			_snap_camera()
	var waited := Time.get_ticks_msec() - reveal_since
	# Viewport size can keep changing on a phone. Never wait on that signal.
	if (reveal_stable >= 6 and waited >= 280) or waited > 2500:
		round_cover.visible = false
		_hide_boot_loader()

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

func _style_hud(l: Label, size: int) -> void:
	_style(l, size)
	l.add_theme_color_override("font_outline_color", Color(0.0, 0.0, 0.0, 0.92))
	# Kept inside the bold font's MSDF range so the ring is not clipped on web.
	l.add_theme_constant_override("outline_size", maxi(6, int(float(size) / 4.5)))

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
	e.ambient_light_color = Color(0.93, 0.91, 0.87)
	e.ambient_light_energy = 0.4
	e.tonemap_mode = Environment.TONE_MAPPER_ACES
	e.tonemap_exposure = 1.02
	e.adjustment_enabled = true
	e.adjustment_brightness = 1.0
	e.adjustment_contrast = 1.06
	e.adjustment_saturation = 1.08
	e.fog_enabled = false
	world_env = e
	env.environment = e
	add_child(env)
	sun = DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-62, 32, 0)
	sun.light_color = Color(1.0, 0.86, 0.68)
	sun.light_energy = 1.12
	sun.shadow_enabled = false
	sun.shadow_bias = 0.5
	sun.shadow_normal_bias = 4.0
	sun.shadow_blur = 0.0
	sun.shadow_opacity = 0.0
	add_child(sun)
	fill_light = DirectionalLight3D.new()
	fill_light.rotation_degrees = Vector3(-24, 200, 0)
	fill_light.light_color = Color(0.95, 0.92, 0.86)
	fill_light.light_energy = 0.12
	fill_light.shadow_enabled = false
	fill_light.shadow_bias = 0.5
	fill_light.shadow_normal_bias = 4.0
	fill_light.shadow_opacity = 0.0
	add_child(fill_light)
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
	var skirt := MeshInstance3D.new()
	var skirt_plane := PlaneMesh.new()
	skirt_plane.size = Vector2(240, 240)
	skirt.mesh = skirt_plane
	skirt_mat = StandardMaterial3D.new()
	skirt_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	skirt_mat.albedo_color = Color(0.42, 0.68, 0.36)
	skirt_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	skirt.material_override = skirt_mat
	skirt.position = Vector3(0, -0.08, 0)
	skirt.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(skirt)
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
	pit_mat.set_shader_parameter("swirl", hole_swirl)
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
	_snap_camera()

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

func _view_aspect() -> float:
	if aspect_lock > 0.05:
		return aspect_lock
	var vp := get_viewport()
	if vp == null:
		return 720.0 / 1280.0
	var sz := vp.get_visible_rect().size
	if sz.y < 2.0:
		return 720.0 / 1280.0
	return sz.x / sz.y

func _wide_blend() -> float:
	# 0 on a tall phone, 1 on a 16:10 desktop. The blend starts once the
	# window is wider than it is tall.
	return clampf((_view_aspect() - 0.8) / 0.6, 0.0, 1.0)

func _hfov_half_tan() -> float:
	return tan(deg_to_rad(CAM_FOV) * 0.5) * _view_aspect()

func _framed_aspect() -> float:
	# Framing a wide monitor on its full width pulls the camera into a
	# top-down close-up. Ease landscape back toward a narrower aspect.
	var aspect := _view_aspect()
	return lerpf(aspect, minf(aspect, 1.15), _wide_blend())

func _frame_half_tan() -> float:
	return tan(deg_to_rad(CAM_FOV) * 0.5) * _framed_aspect()

func _stick_half_tan() -> float:
	return tan(deg_to_rad(STICK_FOV) * 0.5) * _framed_aspect()

func _screen_frac(radius: float, dist: float) -> float:
	return (2.0 * radius / maxf(dist, 0.001)) / _hfov_half_tan()

func _dist_for_frac(radius: float, frac: float) -> float:
	return (2.0 * radius) / maxf(frac * _frame_half_tan(), 0.001)

func _stick_dist_for_frac(radius: float, frac: float) -> float:
	return (2.0 * radius) / maxf(frac * _stick_half_tan(), 0.001)

func _cam_ref_dist() -> float:
	return _dist_for_frac(LEVEL_RADIUS[0], SCREEN_FRAC_START)

func _cam_dist_for(radius: float) -> float:
	# Zoom out lags the radius. The hole starts smaller than a quarter of the
	# screen so the fields read, then grows toward about a third.
	var r := maxf(radius, 0.12)
	var start_r := maxf(_start_radius(), 0.12)
	var end_r := maxf(final_radius, start_r + 0.2)
	var grow := clampf((r - start_r) / (end_r - start_r), 0.0, 1.0)
	# Front-load the on-screen size so early radius gains are not cancelled by zoom.
	var shaped := 0.0 if grow <= 0.0 else pow(grow, 0.45)
	var frac := lerpf(SCREEN_FRAC_START, SCREEN_FRAC_END, shaped)
	return _dist_for_frac(r, frac) * cam_dist_mul

func _cam_frac_for(radius: float) -> float:
	var r := maxf(radius, 0.12)
	var start_r := maxf(_start_radius(), 0.12)
	var end_r := maxf(final_radius, start_r + 0.2)
	var grow := clampf((r - start_r) / (end_r - start_r), 0.0, 1.0)
	var shaped := 0.0 if grow <= 0.0 else pow(grow, 0.45)
	return lerpf(SCREEN_FRAC_START, SCREEN_FRAC_END, shaped)

func _cam_fov_for() -> float:
	return CAM_FOV

func _cam_pitch_for(_radius: float) -> float:
	return lerpf(CAM_PITCH_DEG, CAM_PITCH_FAR, 0.0)

func _sky_strip(pitch: float, fov: float) -> float:
	# Share of the frame above the horizon. Zero means the sky sits just off the top.
	var top_down := pitch - fov * 0.5
	if top_down >= 0.0:
		return 0.0
	return clampf((-top_down) / maxf(fov, 0.001), 0.0, 1.0)

func _snap_camera() -> void:
	if cam_dist_mul > 0.9:
		cam_pitch = _cam_pitch_for(shown_radius)
	cam_distance = _cam_dist_for(shown_radius)
	shown_vel = 0.0
	cam_look = hole_pos + Vector3(0.0, cam_look_lift, 0.0)
	if cam == null:
		return
	cam.fov = _cam_fov_for()
	cam.position = hole_pos + _camera_offset(cam_distance)
	cam.look_at(cam_look, Vector3.UP)

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
	# Thin ground shelf outside the opening. Its inner face sits a hair past
	# the lip so a small footprint already inside the hole is not perched on it.
	var reach := maxf(1.6, radius * 1.35)
	var height := 0.12
	var chord := maxf(TAU * radius / float(RIM_COUNT) * 1.12, 0.14)
	var inner := radius + 0.04
	var mid := inner + reach * 0.5
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
	var show_player := (playing or edge_probe) and hole_open > 0.05
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

func _load_model(path: String, bake_tex: bool = false) -> Dictionary:
	var scene := load(path) as PackedScene
	if scene == null:
		push_error("missing model %s" % path)
		var empty := BoxMesh.new()
		return {"mesh": empty, "size": Vector3(1, 1, 1), "base": 0.5}
	var inst := scene.instantiate()
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	_collect_mesh(inst, Transform3D.IDENTITY, st, bake_tex)
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

func _flat_ground(mesh: Mesh) -> Mesh:
	# Tile diagonals were shading as long dark stripes. Force every normal up.
	if mesh == null or mesh.get_surface_count() < 1:
		return mesh
	var arrays: Array = mesh.surface_get_arrays(0)
	var verts: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	if verts.is_empty():
		return mesh
	var norms := PackedVector3Array()
	norms.resize(verts.size())
	norms.fill(Vector3.UP)
	arrays[Mesh.ARRAY_NORMAL] = norms
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

func _bake_image(tex: Texture2D) -> Image:
	var key := tex.get_instance_id()
	if tex_cache.has(key):
		return tex_cache[key]
	var img := tex.get_image()
	if img != null and img.is_compressed():
		img.decompress()
	tex_cache[key] = img
	return img

func _collect_mesh(n: Node, parent: Transform3D, st: SurfaceTool, bake_tex: bool = false) -> void:
	var xform := parent
	if n is Node3D:
		xform = parent * (n as Node3D).transform
	if n is MeshInstance3D:
		var mi := n as MeshInstance3D
		if mi.mesh:
			for s in mi.mesh.get_surface_count():
				var tint := Color.WHITE
				var img: Image = null
				var surf_mat := mi.mesh.surface_get_material(s)
				if surf_mat == null:
					surf_mat = mi.get_surface_override_material(s)
				if surf_mat is StandardMaterial3D:
					var sm := surf_mat as StandardMaterial3D
					if sm.albedo_texture == null:
						tint = sm.albedo_color
					elif bake_tex:
						img = _bake_image(sm.albedo_texture)
						tint = sm.albedo_color
				_append_surface(st, mi.mesh, s, xform, tint, img)
	for c in n.get_children():
		_collect_mesh(c, xform, st, bake_tex)

func _append_surface(st: SurfaceTool, mesh: Mesh, surface: int, xform: Transform3D, color: Color, image: Image = null) -> void:
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
	var tw := 1
	var th := 1
	if image != null:
		tw = maxi(image.get_width() - 1, 1)
		th = maxi(image.get_height() - 1, 1)
	for idx in ids:
		var use := color
		if image != null and idx < uvs.size():
			var uv: Vector2 = uvs[idx]
			var uu: float = uv.x - floorf(uv.x)
			var vv: float = uv.y - floorf(uv.y)
			var px := clampi(int(uu * float(tw)), 0, tw)
			var py := clampi(int(vv * float(th)), 0, th)
			var samp := image.get_pixel(px, py)
			use = Color(samp.r * color.r, samp.g * color.g, samp.b * color.b, 1.0)
		else:
			use.a = 1.0
		st.set_color(use)
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
	var src := str(spec[0])
	if role in ["tree", "palm"] or src.contains("plant_bush") or src.contains("tree"):
		return _textured_shader(VEG_SHADER, spec[1])
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

func _life_amp(id: String) -> float:
	return float(LIFE_AMP.get(id, 0.0))

func _prop_material(id: String) -> Material:
	if _life_amp(id) > 0.0 and life_mat != null:
		return life_mat
	return kit_mat

func _register_kit_item(item: Dictionary) -> void:
	var mat := _prop_material(str(item.id))
	var spec := ["", mat, 1.0, 1.0, int(item.points), str(item.role), int(item.mover), 0.0]
	prop_defs.append(spec)
	kind_lists.append(_empty_slots())
	kind_meshes.append(item.mesh)
	kind_native.append(item.size)
	kind_base.append(float(item.base))
	kind_mats.append(mat)
	kind_multimeshes.append(null)
	kind_by_id[str(item.id)] = prop_defs.size() - 1

func _plant_baked(mesh: Mesh) -> Dictionary:
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

func _register_scaled(id: String, info: Dictionary, target: float, role: String, points: int) -> void:
	var size: Vector3 = info.size
	var measured := maxf(float(info.base), 0.02)
	# Thin tips (cones, sticks) report a tiny contact. Swallow against the body instead.
	var half_vis := maxf(size.x, size.z) * 0.42
	var basis := maxf(measured, half_vis)
	var scale := target / basis
	var hcap := 6.5
	if role in ["barn", "ride", "boat", "tank"]:
		hcap = 12.0
	elif role in ["tree", "palm"]:
		hcap = 9.0
	if size.y * scale > hcap:
		scale = hcap / maxf(size.y, 0.05)
	var mat := _prop_material(id)
	var spec := ["theme", mat, scale, scale, points, role, 0, 0.0]
	prop_defs.append(spec)
	kind_lists.append(_empty_slots())
	kind_meshes.append(info.mesh)
	kind_native.append(info.size)
	kind_base.append(basis)
	kind_mats.append(mat)
	kind_multimeshes.append(null)
	kind_by_id[id] = prop_defs.size() - 1

func _register_glb(id: String, path: String, target: float, role: String, points: int) -> void:
	var info := _load_model(path, true)
	if id in ["jpalm", "jpalmtall", "ppalm", "dpalm"]:
		info = _palm_trunk(info, target)
	_register_scaled(id, info, target, role, points)

func _palm_trunk(info: Dictionary, target: float) -> Dictionary:
	# Kenney palms read as flat green shards from above. A thick warm trunk
	# is added in mesh space so the top-down camera sees bark, not a sliver.
	var mesh := info.mesh as ArrayMesh
	if mesh == null or mesh.get_surface_count() < 1:
		return info
	var arrays: Array = mesh.surface_get_arrays(0)
	var vert_var = arrays[Mesh.ARRAY_VERTEX]
	if not (vert_var is PackedVector3Array):
		return info
	var verts: PackedVector3Array = vert_var
	if verts.is_empty():
		return info
	var indices := PackedInt32Array()
	var index_var = arrays[Mesh.ARRAY_INDEX]
	if index_var is PackedInt32Array:
		indices = index_var
	if indices.is_empty():
		indices.resize(verts.size())
		for vi in verts.size():
			indices[vi] = vi
	var norms := PackedVector3Array()
	var norm_var = arrays[Mesh.ARRAY_NORMAL]
	if norm_var is PackedVector3Array:
		norms = norm_var
	var cols := PackedColorArray()
	var col_var = arrays[Mesh.ARRAY_COLOR]
	if col_var is PackedColorArray:
		cols = col_var
	var uvs := PackedVector2Array()
	var uv_var = arrays[Mesh.ARRAY_TEX_UV]
	if uv_var is PackedVector2Array:
		uvs = uv_var
	var tangents := PackedFloat32Array()
	var tan_var = arrays[Mesh.ARRAY_TANGENT]
	if tan_var is PackedFloat32Array:
		tangents = tan_var
	if cols.size() != verts.size():
		cols = PackedColorArray()
		cols.resize(verts.size())
		cols.fill(Color(0.32, 0.52, 0.2, 1.0))
	var has_n := norms.size() == verts.size()
	var has_u := uvs.size() == verts.size()
	var has_t := tangents.size() == verts.size() * 4
	var size: Vector3 = info.size
	var measured := maxf(float(info.base), 0.02)
	var half_vis := maxf(size.x, size.z) * 0.42
	var basis := maxf(measured, half_vis)
	var scale := target / basis
	if size.y * scale > 9.0:
		scale = 9.0 / maxf(size.y, 0.05)
	scale = maxf(scale, 0.05)
	# Thick enough that a short palm still shows bark under the crown.
	var radius := 0.88 / scale
	var y0 := minf(0.04, size.y * 0.04)
	var y1 := size.y * 0.9
	var lean := Vector3(0.55, 0.0, 0.28) / scale
	var sides := 8
	var bark_lo := Color(0.55, 0.30, 0.12, 1.0)
	var bark_hi := Color(0.68, 0.40, 0.16, 1.0)
	var base_v := verts.size()
	for i in sides:
		var ang := TAU * float(i) / float(sides)
		var dir := Vector3(cos(ang), 0.0, sin(ang))
		verts.append(dir * radius * 1.3 + Vector3(0.0, y0, 0.0))
		verts.append(dir * radius * 0.76 + Vector3(0.0, y1, 0.0) + lean)
		if has_n:
			norms.append(dir)
			norms.append(dir)
		cols.append(bark_lo)
		cols.append(bark_hi)
		if has_u:
			var u := float(i) / float(sides)
			uvs.append(Vector2(u, 0.02))
			uvs.append(Vector2(u, 0.84))
		if has_t:
			for _n in 2:
				tangents.append(dir.z)
				tangents.append(0.0)
				tangents.append(-dir.x)
				tangents.append(1.0)
	for i in sides:
		var i0 := base_v + i * 2
		var i1 := i0 + 1
		var j0 := base_v + ((i + 1) % sides) * 2
		var j1 := j0 + 1
		indices.append(i0)
		indices.append(j0)
		indices.append(i1)
		indices.append(i1)
		indices.append(j0)
		indices.append(j1)
	# A brown cap so the top-down camera sees trunk, not only fronds.
	var cap_i := verts.size()
	var cap_c := Vector3(0.0, y1, 0.0) + lean
	verts.append(cap_c)
	if has_n:
		norms.append(Vector3.UP)
	cols.append(bark_hi)
	if has_u:
		uvs.append(Vector2(0.5, 0.9))
	if has_t:
		tangents.append(1.0)
		tangents.append(0.0)
		tangents.append(0.0)
		tangents.append(1.0)
	for i in sides:
		var i1c := base_v + i * 2 + 1
		var j1c := base_v + ((i + 1) % sides) * 2 + 1
		indices.append(cap_i)
		indices.append(j1c)
		indices.append(i1c)
	arrays[Mesh.ARRAY_VERTEX] = verts
	arrays[Mesh.ARRAY_INDEX] = indices
	arrays[Mesh.ARRAY_COLOR] = cols
	if has_n:
		arrays[Mesh.ARRAY_NORMAL] = norms
	if has_u:
		arrays[Mesh.ARRAY_TEX_UV] = uvs
	if has_t:
		arrays[Mesh.ARRAY_TANGENT] = tangents
	var out := ArrayMesh.new()
	out.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	var aabb := out.get_aabb()
	info.mesh = out
	info.size = aabb.size
	info.base = _contact_half(out)
	return info

func _register_stack(id: String, paths: Array, target: float, role: String, points: int) -> void:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var y := 0.0
	for path in paths:
		var info := _load_model(str(path), true)
		st.append_from(info.mesh, 0, Transform3D(Basis(), Vector3(0, y, 0)))
		y += float(info.size.y) * 0.9
	_register_scaled(id, _plant_baked(st.commit()), target, role, points)

func _register_theme_models() -> void:
	for item in ThemeMeshScript.defs():
		_register_kit_item(item)
	var root := "res://assets/kenney/theme/"
	var glbs := [
		["fapple", "food/apple.glb", 0.20, "small", 2],
		["fwheat", "nature/crops_wheatStageB.glb", 0.32, "small", 2],
		["fflower", "nature/flower_redA.glb", 0.18, "small", 1],
		["haybale", "grave/hay-bale.glb", 0.62, "small", 5],
		["railfence", "nature/fence_planks.glb", 0.85, "small", 3],
		["farmmill", "fantasy/windmill.glb", 1.90, "barn", 52],
		["lollypop", "food/lollypop.glb", 0.34, "small", 3],
		["donut", "food/donut-sprinkles.glb", 0.42, "small", 3],
		["canecandy", "holiday/candy-cane-red.glb", 0.55, "small", 3],
		["gbread", "holiday/gingerbread-man.glb", 0.62, "small", 4],
		["sweetcup", "food/cupcake.glb", 0.78, "small", 5],
		["coneic", "food/ice-cream-cne.glb", 0.95, "small", 6],
		["partycake", "food/cake-birthday.glb", 1.30, "ride", 14],
		["dinoegg", "food/egg.glb", 0.24, "small", 2],
		["fernleaf", "nature/grass_leafs.glb", 0.36, "palm", 2],
		["redshroom", "nature/mushroom_red.glb", 0.55, "small", 4],
		["jrock", "nature/rock_largeA.glb", 0.90, "small", 4],
		["jpalm", "nature/tree_palmDetailedShort.glb", 1.15, "palm", 8],
		["jpalmtall", "nature/tree_palmDetailedTall.glb", 1.55, "palm", 10],
		["pbarrel", "pirate/barrel.glb", 0.32, "small", 4],
		["pcrate", "pirate/crate.glb", 0.52, "small", 4],
		["pchest", "pirate/chest.glb", 0.70, "small", 6],
		["pcannon", "pirate/cannon.glb", 0.95, "small", 8],
		["ppalm", "pirate/palm-detailed-straight.glb", 1.25, "palm", 8],
		["prowboat", "pirate/boat-row-small.glb", 1.35, "boat", 16],
		["pdock", "pirate/structure-platform-dock.glb", 1.55, "boat", 12],
		["pship", "pirate/ship-pirate-medium.glb", 2.15, "boat", 40],
		["plight", "pirate/tower-complete-large.glb", 2.30, "barn", 60],
		["pflag", "pirate/flag-pirate.glb", 0.40, "small", 2],
		["hpresent", "holiday/present-a-cube.glb", 0.36, "small", 4],
		["hsled", "holiday/sled.glb", 0.68, "small", 5],
		["hsnowman", "holiday/snowman.glb", 0.92, "small", 6],
		["hpine", "nature/tree_pineRoundC.glb", 1.30, "tree", 8],
		["iceblock", "platformer/block-snow.glb", 0.78, "small", 4],
		["drock", "nature/rock_smallA.glb", 0.20, "small", 1],
		["dcactus", "nature/cactus_short.glb", 0.48, "palm", 3],
		["dpot", "nature/pot_large.glb", 0.62, "small", 4],
		["dtallcac", "nature/cactus_tall.glb", 0.95, "palm", 6],
		["dtent", "nature/tent_detailedClosed.glb", 1.20, "stall", 10],
		["dpalm", "nature/tree_palmDetailedShort.glb", 1.40, "palm", 8],
		["dstall", "fantasy/stall.glb", 1.50, "stall", 12],
		["tblock", "platformer/brick.glb", 0.26, "small", 2],
		["tracer", "toycar/vehicle-racer.glb", 0.72, "ride", 8],
		["ttruck", "toycar/vehicle-truck.glb", 1.05, "ride", 12],
		["toytrain", "train/train-locomotive-a.glb", 1.65, "ride", 18],
		["twagon", "train/train-carriage-box.glb", 1.35, "ride", 12],
		["moonlet", "space/meteor_detailed.glb", 0.28, "small", 2],
		["spacecrate", "space/barrel.glb", 0.48, "small", 4],
		["astro", "space/astronautA.glb", 0.54, "ride", 6],
		["spacerover", "space/rover.glb", 0.76, "ride", 12],
		["satdish", "space/satelliteDish_detailed.glb", 1.50, "ride", 14],
		["habitat", "space/hangar_roundA.glb", 2.00, "barn", 36],
		["hcandle", "grave/candle.glb", 0.30, "small", 2],
		["hpumpkin", "grave/pumpkin-tall-carved.glb", 0.55, "small", 4],
		["htomb", "grave/gravestone-cross.glb", 0.85, "small", 6],
		["hghost", "grave/character-ghost.glb", 1.05, "small", 8],
		["htree", "grave/pine-crooked.glb", 1.35, "tree", 8],
		["hcart", "fantasy/cart.glb", 1.10, "small", 8],
		["hcrypt", "grave/crypt.glb", 1.80, "barn", 32],
		["hmansion", "grave/crypt-large.glb", 2.40, "barn", 60],
		["fbench", "coaster/bench.glb", 0.75, "small", 4],
		["fpop", "coaster/stall-food.glb", 1.10, "stall", 10],
		["fteacup", "food/cup-tea.glb", 0.40, "small", 3],
		["coastertrain", "coaster/coaster-train.glb", 1.35, "ride", 16],
		["coasterhill", "coaster/coaster-steel-straight-hill-complete.glb", 1.90, "ride", 28],
		["coasterloop", "coaster/coaster-steel-looping.glb", 2.20, "ride", 36],
	]
	for row in glbs:
		_register_glb(str(row[0]), root + str(row[1]), float(row[2]), str(row[3]), int(row[4]))
	_register_stack("stackrocket", [
		root + "space/rocket_baseA.glb",
		root + "space/rocket_sidesA.glb",
		root + "space/rocket_topA.glb",
	], 2.35, "barn", 48)

func _ensure_models() -> void:
	if not prop_defs.is_empty():
		return
	var kit_shader := Shader.new()
	kit_shader.code = KIT_SHADER
	kit_mat = ShaderMaterial.new()
	kit_mat.shader = kit_shader
	var life_shader := Shader.new()
	life_shader.code = LIFE_SHADER
	life_mat = ShaderMaterial.new()
	life_mat.shader = life_shader
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
		["res://assets/kenney/cars/sedan.glb", mat_cars, 1.40, 1.40, 12, "car", 2, 0.0],
		["res://assets/kenney/cars/taxi.glb", mat_cars, 1.25, 1.25, 12, "car", 2, 0.0],
		["res://assets/kenney/cars/hatchback-sports.glb", mat_cars, 1.25, 1.25, 14, "car", 2, 0.0],
		["res://assets/kenney/cars/van.glb", mat_cars, 1.65, 1.65, 16, "car", 2, 0.0],
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
	_register_theme_models()
	_clone_kind("raptord", "miniraptor", "small", 4, 0.46)
	_clone_small_variants()
	_normalize_footprints()
	ground_meshes = [
		_flat_ground(_load_model("res://assets/kenney/roads/road-straight.glb").mesh),
		_flat_ground(_load_model("res://assets/kenney/roads/road-crossing.glb").mesh),
		_flat_ground(_load_model("res://assets/kenney/roads/road-crossroad.glb").mesh),
		_flat_ground(_load_model("res://assets/kenney/roads/tile-low.glb").mesh),
	]

func _add_city(n: Node) -> void:
	if city_root == null or not is_instance_valid(city_root):
		city_root = Node3D.new()
		city_root.name = "City"
		add_child(city_root)
	city_root.add_child(n)

func _spawn_city() -> void:
	var t0 := Time.get_ticks_msec()
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
	city_tiles = 0
	_spawn_ground()
	_populate()
	for ki in kind_meshes.size():
		_build_kind_multimesh(ki)
	_build_shadows()
	city_load_ms = Time.get_ticks_msec() - t0
	city_mem = int(OS.get_static_memory_usage())
	print("CITY %s props %d tiles %d load %d ms mem %d movers %d" % [str(map.get("name", "")), props.size(), city_tiles, city_load_ms, city_mem, movers.size()])

func _spawn_ground() -> void:
	_build_surfaces()
	var straight: Array = []
	var crosses: Array = []
	var piles := {}
	for surf in range(0, 10):
		piles[surf] = []
	var n := GRID_MAX - GRID_MIN + 1
	var taken := PackedByteArray()
	taken.resize(n * n)
	for j in n:
		for i in n:
			var x := GRID_MIN + i
			var z := GRID_MIN + j
			var surf := int(surfaces[j * n + i])
			if surf != SURF_ROAD:
				continue
			taken[j * n + i] = 1
			var at := Vector3(float(x), 0.0, float(z))
			var ex := _surf_i(x - 1, z) == SURF_ROAD or _surf_i(x + 1, z) == SURF_ROAD
			var ez := _surf_i(x, z - 1) == SURF_ROAD or _surf_i(x, z + 1) == SURF_ROAD
			if ex and ez:
				crosses.append(at)
			elif ex:
				straight.append({"at": at, "yaw": 0.0})
			else:
				straight.append({"at": at, "yaw": PI * 0.5})
	_paint_blocks(piles, taken, n, 4, 4.0, 1.5)
	_paint_blocks(piles, taken, n, 2, 2.0, 0.5)
	for j in n:
		for i in n:
			if taken[j * n + i] != 0:
				continue
			var surf := int(surfaces[j * n + i])
			if surf == SURF_ROAD:
				continue
			var at := Vector3(float(GRID_MIN + i), 0.0, float(GRID_MIN + j))
			(piles[surf] as Array).append({"at": at, "scale": 1.0})
	_tile_multimesh(ground_meshes[0], straight, true, ground_mat)
	_tile_multimesh(ground_meshes[2], crosses, false, ground_mat)
	for surf in range(1, 10):
		var items: Array = piles[surf]
		if items.is_empty():
			continue
		_tile_multimesh(ground_meshes[3], items, false, ground_mats[surf])

func _paint_blocks(piles: Dictionary, taken: PackedByteArray, n: int, step: int, scale: float, center: float) -> void:
	var j := 0
	while j + step - 1 < n:
		var i := 0
		while i + step - 1 < n:
			var surf := _open_block(taken, n, i, j, step)
			if surf >= 0:
				var at := Vector3(float(GRID_MIN + i) + center, 0.0, float(GRID_MIN + j) + center)
				(piles[surf] as Array).append({"at": at, "scale": scale})
				_take_block(taken, n, i, j, step)
			i += step
		j += step

func _open_block(taken: PackedByteArray, n: int, i: int, j: int, step: int) -> int:
	var surf := -1
	for dz in step:
		for dx in step:
			var idx := (j + dz) * n + (i + dx)
			if taken[idx] != 0:
				return -1
			var cell := int(surfaces[idx])
			if cell == SURF_ROAD:
				return -1
			if surf < 0:
				surf = cell
			elif cell != surf:
				return -1
	return surf

func _take_block(taken: PackedByteArray, n: int, i: int, j: int, step: int) -> void:
	for dz in step:
		for dx in step:
			taken[(j + dz) * n + (i + dx)] = 1

func _build_surfaces() -> void:
	var n := GRID_MAX - GRID_MIN + 1
	surfaces = PackedByteArray()
	surfaces.resize(n * n)
	var layout := str(map.get("layout", "grid"))
	for j in n:
		for i in n:
			var x := GRID_MIN + i
			var z := GRID_MIN + j
			var surf := _surface_at(layout, x, z)
			# Road tiles stay road on every theme, including where a basin
			# crosses a street. Water sits beside the road, not on it.
			if RoadScript.cell(x, z) == 1:
				surf = SURF_ROAD
			surfaces[j * n + i] = surf
	road_routes = RoadScript.routes()

func _district(x: int, z: int) -> int:
	var cell := (CITY_HALF * 2.0) / 3.0
	var u := clampi(int((float(x) + CITY_HALF) / cell), 0, 2)
	var v := clampi(int((float(z) + CITY_HALF) / cell), 0, 2)
	return v * 3 + u

func _district_center(d: int) -> Vector3:
	var cell := (CITY_HALF * 2.0) / 3.0
	var u := d % 3
	var v := int(d / 3)
	return Vector3(-CITY_HALF + (float(u) + 0.5) * cell, 0.0, -CITY_HALF + (float(v) + 0.5) * cell)

func _pond(x: int, z: int, cx: float, cz: float, rx: float, rz: float) -> bool:
	var dx := (float(x) - cx) / rx
	var dz := (float(z) - cz) / rz
	return dx * dx + dz * dz < 1.0

func _track_band(x: int, z: int, cx: float, cz: float, inner: float, outer: float) -> int:
	var dx := float(x) - cx
	var dz := float(z) - cz
	var ring := sqrt(dx * dx + dz * dz)
	if ring <= inner:
		return 2
	if ring < outer:
		return 1
	return 0

func _surf_farm(x: int, z: int) -> int:
	if _pond(x, z, 48.0, -36.0, 14.0, 11.0):
		return SURF_WATER
	if _pond(x, z, 48.0, -36.0, 18.0, 15.0):
		return SURF_DIRT
	if _pond(x, z, 14.0, -18.0, 6.5, 5.0):
		return SURF_WATER
	if _pond(x, z, 14.0, -18.0, 9.0, 7.2):
		return SURF_DIRT
	if absi(x) <= 2 or absi(z) <= 2:
		return SURF_DIRT
	if x >= 9 and x <= 11 and z >= -34 and z <= 24:
		return SURF_CONCRETE
	if _pond(x, z, -46.0, 28.0, 22.0, 18.0):
		return SURF_GRASS
	var qx := int(floor(float(x + 80) / 16.0))
	var qz := int(floor(float(z + 80) / 16.0))
	if (qx + qz) % 2 == 0:
		return SURF_FIELD
	return SURF_GRASS

func _surf_candy(x: int, z: int) -> int:
	var fx := float(x)
	var fz := float(z)
	var plazas: Array = [Vector2(0, 0), Vector2(40, 28), Vector2(-36, 22), Vector2(24, -40), Vector2(-28, -34)]
	for p in plazas:
		var at: Vector2 = p
		if _pond(x, z, at.x, at.y, 8.0, 8.0):
			return SURF_CONCRETE
	if absf(fz - sin(fx * 0.05) * 16.0) < 2.4 and fx > -50.0:
		return SURF_WATER
	var ang := atan2(fz, fx)
	var rad := sqrt(fx * fx + fz * fz)
	var arm := fposmod(rad - ang * 7.5, 16.0)
	if arm < 2.0 and rad > 10.0 and rad < 74.0:
		return SURF_TRACK
	if _pond(x, z, -8.0, 46.0, 16.0, 12.0):
		return SURF_FIELD
	return SURF_GRASS

func _surf_jungle(x: int, z: int) -> int:
	var fx := float(x)
	var fz := float(z)
	var pond_dx := (fx - 3.6) / 2.15
	var pond_dz := (fz - 8.8) / 1.45
	if pond_dx * pond_dx + pond_dz * pond_dz < 1.0:
		return SURF_WATER
	var shore_dx := (fx - 3.6) / 2.9
	var shore_dz := (fz - 8.8) / 2.05
	if shore_dx * shore_dx + shore_dz * shore_dz < 1.0:
		return SURF_SAND
	if absf(fx - 24.0 - sin(fz * 0.045) * 5.0) < 3.2 and fz > -52.0 and fz < 28.0:
		return SURF_WATER
	if absf(fx - 4.4 - sin(fz * 0.16) * 0.7) < 0.62 and fz > -40.0 and fz < 24.0:
		return SURF_DIRT
	if absf(fz + 22.0 - cos(fx * 0.05) * 3.0) < 1.2 and fx > -36.0 and fx < 20.0:
		return SURF_DIRT
	if fx * fx + fz * fz < 50.0 * 50.0:
		return SURF_GRASS
	if _pond(x, z, -28.0, -30.0, 12.0, 10.0) or _pond(x, z, 8.0, -40.0, 10.0, 9.0) or _pond(x, z, -40.0, 16.0, 14.0, 12.0):
		return SURF_GRASS
	return SURF_FIELD

func _surf_pirate(x: int, z: int) -> int:
	var fx := float(x)
	var fz := float(z)
	# A dock cross sits in the play area. Water fills the basin around it.
	if absi(x) <= 6 and absi(z) <= 4:
		return SURF_WOOD
	if absi(z) <= 2 and absi(x) < 56:
		return SURF_WOOD
	if absi(x) <= 2 and absi(z) < 42:
		return SURF_WOOD
	if absf(absf(fz) - 12.2) < 1.15 and absf(fx) < 58.0:
		return SURF_WOOD
	var canal := false
	if absf(fz) < 11.0 and absf(fx) < 58.0:
		canal = true
	if absf(fz - 24.0) < 2.4 or absf(fz + 26.0) < 2.4:
		canal = true
	if absf(fx - 16.0) < 2.4 or absf(fx + 22.0) < 2.4:
		canal = true
	if canal and absi(x) < 62 and absi(z) < 62:
		return SURF_WATER
	var coast := 6.0 + sin(fx * 0.06) * 18.0
	if fz > coast + 8.0 and fz > 40.0:
		return SURF_WATER
	if fz > coast - 4.0 and fz > 34.0:
		return SURF_SAND
	if _pond(x, z, -28.0, -40.0, 10.0, 8.0):
		return SURF_CONCRETE
	return SURF_GRASS

func _surf_snow(x: int, z: int) -> int:
	var fx := float(x)
	var fz := float(z)
	if _pond(x, z, 18.0, 34.0, 16.0, 12.0):
		return SURF_WATER
	if absf(fx - sin(fz * 0.055) * 24.0) < 1.8:
		return SURF_DIRT
	var huts: Array = [Vector2(-30, -20), Vector2(8, -8), Vector2(36, -28), Vector2(-12, 48), Vector2(44, 16)]
	for h in huts:
		var at: Vector2 = h
		if _pond(x, z, at.x, at.y, 7.0, 6.0):
			return SURF_CONCRETE
	if _pond(x, z, -48.0, -40.0, 18.0, 14.0):
		return SURF_GRASS
	return SURF_SAND

func _surf_desert(x: int, z: int) -> int:
	if _pond(x, z, 16.0, -18.0, 5.0, 4.0):
		return SURF_WATER
	if _pond(x, z, 16.0, -18.0, 9.0, 7.5):
		return SURF_GRASS
	if _pond(x, z, -28.0, 22.0, 11.0, 9.0):
		return SURF_WATER
	if _pond(x, z, -28.0, 22.0, 18.0, 16.0):
		return SURF_GRASS
	var fx := float(x)
	var fz := float(z)
	if absf(fz + fx * 0.78) < 1.5 and fx > -32.0 and fx < 8.0:
		return SURF_CONCRETE
	var dune := sin(fx * 0.075 + fz * 0.04)
	if dune > 0.25:
		return SURF_DIRT
	return SURF_SAND

func _surf_toy(x: int, z: int) -> int:
	if absi(x) >= 70 or absi(z) >= 70:
		return SURF_WOOD
	# Rug in front of the hole, and a smaller carpet off to the side.
	if _pond(x, z, 0.0, -10.0, 12.0, 8.5):
		return SURF_FIELD
	if _pond(x, z, 18.0, -8.0, 6.5, 5.0):
		return SURF_CONCRETE
	var fx := float(x)
	var fz := float(z)
	var ring := sqrt(fx * fx + fz * fz)
	if ring < 56.0:
		return SURF_WOOD
	if ring > 62.0 and ring < 66.0:
		return SURF_FIELD
	var bx := int(floor((fx + 66.0) / 12.0))
	var bz := int(floor((fz + 66.0) / 12.0))
	if (bx + bz) % 2 == 0:
		return SURF_FIELD
	return SURF_WOOD

func _surf_space(x: int, z: int) -> int:
	if _pond(x, z, 22.0, -26.0, 5.2, 4.0):
		return SURF_WATER
	if _pond(x, z, 22.0, -26.0, 7.4, 6.0):
		return SURF_DIRT
	var pads: Array = [Vector2(0, -16), Vector2(32, 24), Vector2(-36, 12), Vector2(18, -46), Vector2(-22, -40), Vector2(48, -18)]
	for p in pads:
		var at: Vector2 = p
		if _pond(x, z, at.x, at.y, 6.5, 6.5):
			return SURF_CONCRETE
		if _pond(x, z, at.x, at.y, 10.0, 10.0):
			return SURF_DIRT
	if _pond(x, z, -48.0, 42.0, 8.0, 8.0):
		return SURF_WATER
	var fx := float(x)
	var fz := float(z)
	if absf(fz - sin(fx * 0.04) * 26.0) < 2.2:
		return SURF_CONCRETE
	return SURF_SAND

func _surf_haunt(x: int, z: int) -> int:
	if _pond(x, z, 34.0, -22.0, 14.0, 10.0) or _pond(x, z, -42.0, 26.0, 12.0, 16.0):
		return SURF_WATER
	var fx := float(x)
	var fz := float(z)
	var crooked := sin(fx * 0.08) * 12.0 + sin(fx * 0.021) * 18.0
	if absf(fz - crooked) < 1.7:
		return SURF_DIRT
	if _pond(x, z, -18.0, -30.0, 20.0, 16.0):
		var h := int(absf(sin(float(x * 13 + z * 7))) * 1000.0) % 5
		if h == 0:
			return SURF_DIRT
		return SURF_GRASS
	if _pond(x, z, 22.0, 36.0, 16.0, 14.0):
		return SURF_FIELD
	return SURF_GRASS

func _surf_fair(x: int, z: int) -> int:
	var fx := float(x)
	var fz := float(z)
	var rad := sqrt(fx * fx + fz * fz)
	if rad < 11.0:
		return SURF_CONCRETE
	if rad > 26.0 and rad < 31.0:
		return SURF_DIRT
	if absi(x) <= 2 and z < -8:
		return SURF_DIRT
	if _track_band(x, z, 38.0, 16.0, 8.0, 14.0) == 1:
		return SURF_TRACK
	if _pond(x, z, -46.0, -28.0, 14.0, 11.0):
		return SURF_WATER
	if _pond(x, z, -10.0, 42.0, 12.0, 9.0):
		return SURF_CONCRETE
	return SURF_GRASS

func _surface_at(layout: String, x: int, z: int) -> int:
	match layout:
		"candy":
			return _surf_candy(x, z)
		"jungle":
			return _surf_jungle(x, z)
		"pirate":
			return _surf_pirate(x, z)
		"snow":
			return _surf_snow(x, z)
		"desert":
			return _surf_desert(x, z)
		"toy":
			return _surf_toy(x, z)
		"space":
			return _surf_space(x, z)
		"haunt":
			return _surf_haunt(x, z)
		"fair":
			return _surf_fair(x, z)
		_:
			return _surf_farm(x, z)

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

func _tile_pos(raw, has_yaw: bool) -> Vector3:
	if has_yaw or raw is Dictionary:
		return (raw as Dictionary).at
	return raw

func _tile_multimesh(mesh: Mesh, items: Array, has_yaw: bool, mat: Material) -> void:
	if items.is_empty() or mat == null:
		return
	var bins: Array = []
	bins.resize(STATIC_CHUNKS)
	for c in STATIC_CHUNKS:
		bins[c] = []
	for n in items.size():
		var pos := _tile_pos(items[n], has_yaw)
		(bins[_static_chunk(pos)] as Array).append(n)
	for c in STATIC_CHUNKS:
		var bin: Array = bins[c]
		if bin.is_empty():
			continue
		var mm := MultiMesh.new()
		mm.transform_format = MultiMesh.TRANSFORM_3D
		mm.mesh = mesh
		mm.instance_count = bin.size()
		city_tiles += bin.size()
		for n in bin.size():
			var src: int = bin[n]
			var pos: Vector3
			var yaw := 0.0
			var tile_scale := 1.0
			if has_yaw:
				var item: Dictionary = items[src]
				pos = item.at
				yaw = float(item.yaw)
				tile_scale = float(item.get("scale", 1.0))
			else:
				var raw = items[src]
				if raw is Dictionary:
					pos = raw.at
					tile_scale = float(raw.get("scale", 1.0))
				else:
					pos = raw
			var basis := Basis(Vector3.UP, yaw).scaled(Vector3(tile_scale, 1.0, tile_scale))
			mm.set_instance_transform(n, Transform3D(basis, pos))
		var inst := MultiMeshInstance3D.new()
		inst.multimesh = mm
		inst.material_override = mat
		inst.custom_aabb = _chunk_aabb(c, -4.0, 20.0)
		_no_shadow(inst)
		_add_city(inst)

func _tier_of(base: float) -> int:
	var b := clampf(base, 0.0, BASE_CAP)
	for t in range(TIER_LO.size() - 1, -1, -1):
		if b >= float(TIER_LO[t]) - 0.0001:
			return t
	return 0

func _tier_counts() -> Array:
	var counts: Array = []
	counts.resize(TIER_NAME.size())
	counts.fill(0)
	for o in props:
		if not bool(o.get("alive", true)):
			continue
		counts[_tier_of(float(o.base))] += 1
	return counts

func _natural_base(id: String) -> float:
	if not kind_by_id.has(id):
		return 0.0
	var ki: int = int(kind_by_id[id])
	return float(kind_base[ki]) * float(prop_defs[ki][2])

func _scale_cap(id: String) -> float:
	if id in ["scooter", "kiosk", "cart", "fountain", "bigtree", "cabana", "gazebo", "warehouse", "shop", "silo", "apartment", "crane", "windmill", "landmark"]:
		return 1.18
	if id == "planter":
		return 3.20
	if id == "van":
		return 1.50
	if id in ["sedan", "taxi", "hatch"]:
		return 1.35
	if id in ["police", "forklift", "tractor"]:
		return 2.40
	if id == "bus":
		return 2.20
	if id == "truck":
		return 2.35
	if not kind_by_id.has(id):
		return 1.0
	var role := str(prop_defs[int(kind_by_id[id])][5])
	if role in ["tower", "barn", "ride"]:
		return 2.55
	if role in ["building", "wide", "house", "tank", "boat"]:
		return 2.15
	if role in ["tree", "palm"]:
		return 1.80
	return 1.45

func _can_reach(id: String, lo: float, hi: float) -> bool:
	var natural := _natural_base(id)
	if natural < 0.02:
		return false
	var min_b := natural * 0.80
	var max_b := minf(natural * _scale_cap(id), BASE_CAP)
	return max_b >= lo and min_b <= hi

func _target_base(id: String, lo: float, hi: float) -> float:
	var natural := _natural_base(id)
	if natural < 0.02:
		return -1.0
	var min_b := natural * 0.80
	var max_b := minf(natural * _scale_cap(id), BASE_CAP)
	var a := maxf(lo, min_b)
	var b := minf(hi, max_b)
	if a > b:
		return -1.0
	return randf_range(a, b)

func _ladder_ids(layout: String) -> Array:
	var themed := _theme_ids(layout)
	var ids: Array = []
	ids.append_array(themed)
	ids.append_array(themed)
	return ids

func _tier_surface_ok(p: Vector3, tier: int) -> bool:
	if _layout_blocked(p):
		return false
	if tier >= 4 and p.length() < SPAWN_CLEAR:
		return false
	var s := _surf_f(p.x, p.z)
	if s == SURF_WATER or s == SURF_TRACK:
		return false
	if tier >= 2 and s == SURF_ROAD:
		return false
	return true

func _tier_pool(ids: Array, lo: float, hi: float) -> Array:
	var pool: Array = []
	for id in ids:
		var key := str(id)
		if _can_reach(key, lo, hi):
			pool.append(key)
	return pool

func _try_tier_place(pool: Array, tier: int, p: Vector3) -> bool:
	if not _tier_surface_ok(p, tier):
		return false
	var lo := float(TIER_LO[tier])
	var hi := float(TIER_HI[tier]) - 0.008
	var cap := maxi(int(ceil(float(TIER_MIN[tier]) * 0.12)), 1)
	var pick := ""
	var least := 999999
	var start := randi() % pool.size()
	for n in pool.size():
		var cand := str(pool[(start + n) % pool.size()])
		var have := int(tier_use.get("%d:%s" % [tier, cand], 0))
		if have >= cap:
			continue
		if have < least:
			least = have
			pick = cand
			if have == 0 and n > 2:
				break
	if pick == "":
		return false
	var mid := (lo + hi) * 0.5
	var half := (hi - lo) * 0.28
	var target := _target_base(pick, maxf(lo, mid - half), minf(hi, mid + half))
	if target < 0.0:
		return false
	var grow := target / _natural_base(pick)
	if not _place_id(pick, p, Vector3.ZERO, randf() * TAU, grow):
		return false
	var key := "%d:%s" % [tier, pick]
	tier_use[key] = int(tier_use.get(key, 0)) + 1
	return true

func _district_point(d: int) -> Vector3:
	var center := _district_center(d)
	var reach := (CITY_HALF * 2.0) / 3.0 * 0.46
	var ang := randf() * TAU
	var rr := reach * sqrt(randf())
	return center + Vector3(cos(ang) * rr, 0.0, sin(ang) * rr)

func _scatter_tier(ids: Array, tier: int, need: int, near_spawn: bool) -> int:
	var lo := float(TIER_LO[tier])
	var hi := float(TIER_HI[tier]) - 0.008
	var pool := _tier_pool(ids, lo, hi)
	if pool.is_empty() or need <= 0:
		return 0
	var made := 0
	if near_spawn:
		var tries := 0
		var inner := 3.1
		var outer := maxf(SPAWN_CLEAR - 0.45, inner + 0.8)
		while made < need and tries < need * 40 and props.size() < PROP_CAP:
			tries += 1
			var ang := randf() * TAU
			var rr := sqrt(randf_range(inner * inner, outer * outer))
			var p := Vector3(cos(ang) * rr, 0.0, sin(ang) * rr)
			if _try_tier_place(pool, tier, p):
				made += 1
		return made
	var share := maxi(int(ceil(float(need) / 9.0)), 1)
	for d in 9:
		var got := 0
		var tries := 0
		while got < share and made < need and tries < share * 48 and props.size() < PROP_CAP:
			tries += 1
			if _try_tier_place(pool, tier, _district_point(d)):
				got += 1
				made += 1
	var extra := 0
	while made < need and extra < need * 50 and props.size() < PROP_CAP:
		extra += 1
		var span := CITY_HALF - 3.0
		var p := Vector3(randf_range(-span, span), 0.0, randf_range(-span, span))
		if _try_tier_place(pool, tier, p):
			made += 1
	return made

func _balance_tiers() -> void:
	var ids := _ladder_ids(str(map.get("layout", "grid")))
	var counts := _tier_counts()
	for t in TIER_NAME.size():
		var need := int(TIER_MIN[t]) - int(counts[t])
		if need > 0:
			_scatter_tier(ids, t, need, false)

func _seed_ladder() -> void:
	# Every district gets a mix of rungs. Large footprints land first so the
	# small snacks can still fill the gaps between them.
	var ids := _ladder_ids(str(map.get("layout", "grid")))
	var left: Array = []
	left.resize(TIER_NAME.size())
	for t in TIER_NAME.size():
		left[t] = int(TIER_MIN[t])
	for _round in 4:
		for t in range(TIER_NAME.size() - 1, -1, -1):
			if int(left[t]) <= 0:
				continue
			var chunk := mini(int(ceil(float(TIER_MIN[t]) / 4.0)), int(left[t]))
			left[t] = int(left[t]) - _scatter_tier(ids, t, chunk, false)
	_scatter_tier(ids, 0, 56, true)

func _theme_ids(layout: String) -> Array:
	match layout:
		"candy":
			return ["lollypop", "lollyblue", "lollygold", "donut", "donutchoc", "canecandy", "canegreen", "gbread", "breadpink", "sweetcup", "coneic", "blossom", "pebbles", "fflower", "partycake", "candybench", "ghouse", "ccastle"]
		"jungle":
			return ["spottedegg", "eggblue", "egggold", "dinonest", "dinobone", "fernleaf", "fernwide", "jvine", "redshroom", "shroomgold", "miniraptor", "fflower", "floweryel", "blossom", "pebbles", "raptord", "jpalm", "trike", "jpalmtall", "jhut", "tyrant", "brachio", "lavacone"]
		"pirate":
			return ["pbarrel", "pcrate", "pchest", "chestgold", "pflag", "panchor", "pebbles", "blossom", "fflower", "fapple", "applegreen", "donut", "pcannon", "ppalm", "prowboat", "pdock", "tavern", "pship", "plight"]
		"snow":
			return ["hpresent", "giftgold", "hsled", "iceblock", "iceblue", "hsnowman", "snowtiny", "pebbles", "fflower", "flowerwht", "fapple", "tblock", "blockred", "skier", "hpine", "hcabin", "skilift", "icecastle"]
		"desert":
			return ["drock", "rockred", "rockgold", "dcactus", "cactusflower", "dpot", "pebbles", "blossom", "fflower", "fapple", "tball", "ballblue", "dtallcac", "dcamel", "dtent", "dpalm", "dstall", "dadobe", "dpyramid", "dsphinx"]
		"toy":
			return ["tblock", "blockred", "blockgold", "tball", "ballblue", "teddybear", "bearblue", "fballoon", "balloonyel", "donut", "lollypop", "lollyblue", "canecandy", "toybench", "tracer", "ttruck", "bot", "toytrain", "twagon", "toyhouse", "blockfort"]
		"space":
			return ["satprobe", "probeamber", "moonlet", "meteorhot", "pebbles", "tblock", "blockred", "iceblock", "fapple", "drock", "rockred", "astro", "antenna", "solarpanel", "spacerover", "satdish", "habitat", "stackrocket", "gantry"]
		"haunt":
			return ["hcandle", "hbat", "hcrow", "hpumpkin", "pumpkingold", "pebbles", "blossom", "fflower", "hpresent", "giftgold", "drock", "tblock", "htomb", "hghost", "htree", "hcart", "hhouse", "hcrypt", "hmansion"]
		"fair":
			return ["fballoon", "balloonyel", "fteacup", "cupgold", "fbench", "lollypop", "lollyblue", "donut", "donutchoc", "canecandy", "tball", "ballblue", "fapple", "blossom", "fbumper", "fpop", "teacups", "coastertrain", "coasterhill", "coasterloop", "carousel", "ferris"]
		_:
			return ["fapple", "applegreen", "applegold", "chicken", "fwheat", "wheatgold", "fflower", "floweryel", "flowerwht", "blossom", "pebbles", "piglet", "haybale", "tblock", "blockred", "cow", "railfence", "scare", "farmtractor", "pickup", "grainsilo", "redbarn", "farmmill"]

func _populate() -> void:
	forward_tall = 0
	tier_use = {}
	treats = []
	var layout := str(map.get("layout", "farm"))
	_dress_opening(layout)
	_dress_jungle_canopy()
	_place_signatures(layout)
	_place_near_icons(layout)
	_spawn_life()
	_seed_ladder()
	_scatter_theme(layout)
	_dress_districts()
	_dress_border()
	_dress_vista(layout)
	_balance_tiers()
	_dress_streets(layout)
	_place_treats(layout)
	_tint_animals()
	_audit_opening()

func _is_rare_treat(id: String) -> bool:
	return id.find("gold") >= 0 or id == "meteorhot" or id == "cupgold"

func _treat_id(layout: String) -> String:
	match layout:
		"candy":
			return "lollygold"
		"jungle":
			return "egggold"
		"pirate":
			return "chestgold"
		"snow":
			return "giftgold"
		"desert":
			return "rockgold"
		"toy":
			return "blockgold"
		"space":
			return "meteorhot"
		"haunt":
			return "pumpkingold"
		"fair":
			return "cupgold"
		_:
			return "applegold"

func _opening_treat_dist() -> float:
	var hole_r := maxf(_start_radius(), 0.45)
	return clampf(hole_r * 2.5, hole_r * 2.0, hole_r * 3.0)

func _treat_ground_ok(p: Vector3) -> bool:
	var surf := _surf_f(p.x, p.z)
	if surf == SURF_WATER or surf == SURF_ROAD or surf == SURF_TRACK:
		return false
	if not _clear_of_road(p, 0.55):
		return false
	if _overlaps(p, 0.5):
		return false
	return true

func _opening_treat_spot() -> Vector3:
	# Camera sits on +Z, so -Z is up the screen, away from the hint pill.
	var dist := _opening_treat_dist()
	var hole_r := maxf(_start_radius(), 0.45)
	for extra in [0.0, 0.35, -0.28, 0.55]:
		var d := clampf(dist + hole_r * extra, hole_r * 2.0, hole_r * 3.0)
		for ox in [0.0, 0.42, -0.42, 0.8, -0.8]:
			var p := Vector3(ox, 0.0, -d)
			if _treat_ground_ok(p):
				return p
	return Vector3(0.0, 0.0, -dist)

func _mark_treat(o: Dictionary, p: Vector3, opening: bool) -> void:
	o["treat"] = true
	o["opening_treat"] = opening
	o["ground"] = Vector3(p.x, 0.0, p.z)
	var lifted := Vector3(p.x, 0.72 if opening else 0.4, p.z)
	o.pos = lifted
	o.xform = Transform3D(Basis(Vector3.UP, float(o.yaw)).scaled(o.scale), lifted)
	if opening:
		o.color = Color(1.0, 0.78, 0.08)
	treats.append(o)

func _spawn_one_treat(id: String, p: Vector3, grow: float, opening: bool) -> bool:
	if not kind_by_id.has(id):
		print("TREAT MISS %s missing %s" % [str(map.get("layout", "")), id])
		return false
	treat_force = opening
	var ok := _place_id(id, p, Vector3.ZERO, 0.6, grow, Color(1.0, 0.82, 0.12), -1, -1, [], true)
	treat_force = false
	if not ok:
		print("TREAT MISS %s %s at %.2f %.2f" % [str(map.get("layout", "")), id, p.x, p.z])
		return false
	var o: Dictionary = props[props.size() - 1]
	_mark_treat(o, p, opening)
	print("TREAT SPAWN %s %s at %.2f %.2f grow %.2f opening %s dist %.2f" % [str(map.get("layout", "")), id, p.x, p.z, grow, str(opening), p.length()])
	return true

func _place_treats(layout: String) -> void:
	var id := _treat_id(layout)
	# Always one opening treat. No random roll, and inside the 1.6 m place gate.
	var spot := _opening_treat_spot()
	if not _spawn_one_treat(id, spot, 2.7, true):
		treat_force = true
		_spawn_one_treat(id, Vector3(0.0, 0.0, -_opening_treat_dist()), 2.7, true)
		treat_force = false
	var far: Array = [Vector3(16.0, 0, 14.0), Vector3(-20.0, 0, -24.0), Vector3(28.0, 0, -18.0), Vector3(-14.0, 0, 22.0)]
	var made := 0
	for p in far:
		if made >= 3 or props.size() >= PROP_CAP:
			break
		var at: Vector3 = p
		if not _treat_ground_ok(at):
			continue
		if _spawn_one_treat(id, at, 1.15, false):
			made += 1

func _seat_opening_treat() -> void:
	if cam == null:
		return
	var hole_s := cam.unproject_position(hole_pos + Vector3(0, 0.4, 0))
	for o in treats:
		if not bool(o.get("opening_treat", false)) or not bool(o.get("alive", true)):
			continue
		var ground: Vector3 = o.get("ground", Vector3(o.pos.x, 0.0, o.pos.z))
		var screen := cam.unproject_position(Vector3(ground.x, 0.4, ground.z))
		# Smaller screen y is above the hole. Flip Z if this side fell under the hint.
		if screen.y > hole_s.y - 4.0:
			ground.z = -ground.z
			var lift := 0.72
			o["ground"] = ground
			o.pos = Vector3(ground.x, lift, ground.z)
			o.xform = Transform3D(Basis(Vector3.UP, float(o.yaw)).scaled(o.scale), o.pos)
			var mm := _mm_of(o)
			if mm != null:
				mm.set_instance_transform(int(o.index), o.xform)
			_bucket_move(o)
			screen = cam.unproject_position(Vector3(ground.x, 0.4, ground.z))
		var dist := Vector2(ground.x - hole_pos.x, ground.z - hole_pos.z).length()
		var above := screen.y < hole_s.y - 4.0
		print("TREAT SCREEN %s world %.2f %.2f dist %.2f radii %.2f hole_px %.0f %.0f treat_px %.0f %.0f above %s alive %s" % [str(map.get("layout", "")), ground.x, ground.z, dist, dist / maxf(hole_radius, 0.01), hole_s.x, hole_s.y, screen.x, screen.y, str(above), str(bool(o.alive) and not bool(o.in_body))])

func _block_house(layout: String) -> String:
	match layout:
		"candy":
			return "ghouse"
		"jungle":
			return "jhut"
		"pirate":
			return "tavern"
		"snow":
			return "hcabin"
		"desert":
			return "dadobe"
		"toy":
			return "toyhouse"
		"space":
			return "habitat"
		"haunt":
			return "hhouse"
		"fair":
			return "fpop"
		_:
			return "house_a"

func _block_fence(layout: String) -> String:
	match layout:
		"candy":
			return "canecandy"
		"jungle":
			return "fernleaf"
		"pirate":
			return "pbarrel"
		"snow":
			return "iceblock"
		"desert":
			return "dcactus"
		"toy":
			return "tblock"
		"space":
			return "solarpanel"
		"haunt":
			return "htomb"
		"fair":
			return "fbench"
		_:
			return "railfence"

func _parked_id(layout: String) -> String:
	match layout:
		"candy":
			return "van"
		"jungle":
			return "raptord"
		"snow":
			return "snowmobile"
		"desert":
			return "dcamel"
		"toy":
			return "tracer"
		"space":
			return "spacerover"
		"haunt":
			return "hcart"
		"fair":
			return "fbumper"
		"pirate":
			return "skiff"
		_:
			return "farmtractor"

func _along_road(p: Vector3) -> Vector3:
	var best_x := 18.0
	var best_dx := 999.0
	var best_z := 18.0
	var best_dz := 999.0
	for line in [-54.0, -36.0, -18.0, 18.0, 36.0, 54.0]:
		var dx := absf(p.x - line)
		var dz := absf(p.z - line)
		if dx < best_dx:
			best_dx = dx
			best_x = line
		if dz < best_dz:
			best_dz = dz
			best_z = line
	if best_dx <= best_dz:
		return Vector3(0.0, 0.0, 1.0 if p.z >= 0.0 else -1.0)
	return Vector3(1.0 if p.x >= 0.0 else -1.0, 0.0, 0.0)

func _toward_road(p: Vector3) -> Vector3:
	var best := Vector3(18.0, 0.0, p.z)
	var best_d := 999.0
	for line in [-54.0, -36.0, -18.0, 18.0, 36.0, 54.0]:
		var dx := absf(p.x - line)
		var dz := absf(p.z - line)
		if dx < best_d:
			best_d = dx
			best = Vector3(line, 0.0, p.z)
		if dz < best_d:
			best_d = dz
			best = Vector3(p.x, 0.0, line)
	var dir := best - Vector3(p.x, 0.0, p.z)
	if dir.length_squared() < 0.01:
		return Vector3(0.0, 0.0, 1.0)
	return dir.normalized()

func _dress_streets(layout: String) -> void:
	var house := _block_house(layout)
	var fence := _block_fence(layout)
	var parked := _parked_id(layout)
	var lamps := 0
	var houses := 0
	var fences := 0
	var parks := 0
	var signs := 0
	var x := -56
	while x <= 56:
		var z := -56
		while z <= 56:
			if RoadScript.cell(x, z) == 2:
				var p := Vector3(float(x), 0.0, float(z))
				var surf := _surf_f(p.x, p.z)
				var open := absf(p.x) < 14.0 and absf(p.z) < 14.0
				if not open and surf != SURF_WATER and surf != SURF_ROAD and surf != SURF_TRACK:
					var slot := posmod(x + z * 3, 48)
					if lamps < 70 and posmod(x + z, 16) == 0:
						if _place_id("lamp", p, Vector3.ZERO, 0.0):
							lamps += 1
					elif signs < 6 and slot == 4:
						if _place_id("sign", p, _toward_road(p), -1.0):
							signs += 1
					elif parks < 6 and slot == 10 and parked != "skiff":
						if _place_id(parked, p, _along_road(p), -1.0):
							parks += 1
					elif houses < 7 and slot == 18:
						if _place_id(house, p, _toward_road(p), -1.0):
							houses += 1
					elif fences < 36 and (slot == 26 or slot == 30):
						var yaw := 0.0 if posmod(z, 18) < 9 else PI * 0.5
						if _place_id(fence, p, Vector3.ZERO, yaw):
							fences += 1
			z += 4
		x += 4
	if layout == "pirate":
		for i in 4:
			var bp := Vector3(12.0, 0.0, -8.0 + float(i) * 7.0)
			_place_id("skiff", bp, Vector3(1.0, 0.0, 0.0), -1.0, 1.0, Color.WHITE, -1, 0, [SURF_WATER])

func _audit_opening() -> void:
	var layout := str(map.get("layout", ""))
	print("OPEN ROAD %s cell %d surf %d" % [layout, RoadScript.cell(0, 4), _surf_f(0.0, 4.0)])
	if layout == "jungle":
		print("OPEN POND %s water %d old %d" % [layout, _surf_f(3.6, 8.8), _surf_f(2.2, 5.4)])
	var cars := 0
	for o in props:
		if int(o.mover) != 2:
			continue
		var p: Vector3 = o.pos
		if absf(p.x) < 6.5 and p.z > 2.0 and p.z < 6.2:
			cars += 1
			print("OPEN CAR %s %s at %.1f %.1f route %d" % [layout, kind_id_of(int(o.kind)), p.x, p.z, int(o.route)])
	if cars < 1:
		print("OPEN MISS %s car" % layout)
	var treat_near := false
	for o in treats:
		var tp: Vector3 = o.pos
		if absf(tp.x) < 6.0 and tp.z > -8.0 and tp.z < 6.0:
			treat_near = true
			print("OPEN TREAT %s %s at %.1f %.1f" % [layout, kind_id_of(int(o.kind)), tp.x, tp.z])
			break
	if not treat_near:
		print("OPEN MISS %s treat" % layout)
	var want: Array = []
	if layout == "jungle":
		want = ["tyrant", "lavacone", "miniraptor", "trike", "raptord", "jpalmtall", "jpalm", "fernleaf"]
	elif layout == "space":
		want = ["stackrocket", "habitat", "astro", "spacerover"]
	elif layout == "pirate":
		want = ["pier", "skiff"]
	elif layout == "farm":
		want = ["chicken"]
	elif layout == "toy":
		want = ["tracer", "ttruck"]
	else:
		return
	for id in want:
		var hit := false
		var shown := 0
		for o in props:
			if kind_id_of(int(o.kind)) != str(id):
				continue
			var p: Vector3 = o.pos
			if absf(p.x) < 6.5 and p.z > -15.5 and p.z < 12.0:
				hit = true
				shown += 1
				print("OPEN %s %s at %.1f %.1f base %.2f h %.2f" % [layout, id, p.x, p.z, float(o.base), float(o.height)])
				if shown >= 3:
					break
		if not hit:
			var any := 0
			for o2 in props:
				if kind_id_of(int(o2.kind)) != str(id):
					continue
				var q: Vector3 = o2.pos
				print("OPEN FAR %s %s at %.1f %.1f base %.2f h %.2f" % [layout, id, q.x, q.z, float(o2.base), float(o2.height)])
				any += 1
				if any >= 3:
					break
			if any == 0:
				print("OPEN MISS %s %s" % [layout, id])

func _path_dir(p: Vector3, surfs: Array) -> Vector3:
	for ang in [0.0, PI * 0.5, PI, -PI * 0.5]:
		var d := Vector3(cos(ang), 0.0, sin(ang))
		if _surf_ok(p + d * 1.6, surfs):
			return d
	var yaw := randf() * TAU
	return Vector3(cos(yaw), 0.0, sin(yaw))

func _spawn_wander(ids: Array, count: int, surfs: Array, near: bool) -> void:
	_spawn_movers(ids, count, surfs, near, 1)

func _spawn_drive(ids: Array, count: int, surfs: Array) -> void:
	_spawn_movers(ids, count, surfs, false, 2)

func _path_spots(surfs: Array) -> Array:
	var near_spots: Array = []
	var far_spots: Array = []
	var x := GRID_MIN + 2
	while x < GRID_MAX - 1:
		var z := GRID_MIN + 2
		while z < GRID_MAX - 1:
			var p := Vector3(float(x), 0.0, float(z))
			if _surf_ok(p, surfs) and not _layout_blocked(p):
				var home := p.length()
				if home > 6.0 and home < 24.0:
					near_spots.append(p)
				elif home >= 24.0:
					far_spots.append(p)
			z += 3
		x += 3
	near_spots.shuffle()
	far_spots.shuffle()
	near_spots.append_array(far_spots)
	return near_spots

func _spawn_movers(ids: Array, count: int, surfs: Array, near: bool, mover: int) -> void:
	if ids.is_empty() or count <= 0:
		return
	if mover == 2 and not road_routes.is_empty():
		_spawn_on_roads(ids, count)
		return
	if mover == 1:
		surfs = _sidewalk_surfs(surfs)
	var spots: Array = _path_spots(surfs)
	var made := 0
	var spot_i := 0
	var relaxed := false
	while made < count and props.size() < PROP_CAP:
		if spot_i >= spots.size():
			if relaxed:
				break
			relaxed = true
			spot_i = 0
			continue
		var p: Vector3 = spots[spot_i]
		spot_i += 1
		var home := p.length()
		if not relaxed:
			if mover == 1 and near and (home < 5.0 or home > 26.0):
				continue
			if mover == 1 and not near and home < 16.0:
				continue
		var id := str(ids[made % ids.size()])
		var dir := _path_dir(p, surfs) if mover == 2 else Vector3(cos(randf() * TAU), 0.0, sin(randf() * TAU))
		if _place_id(id, p, dir, -1.0, 1.0, Color.WHITE, -1, mover, surfs):
			props[props.size() - 1]["walk"] = surfs
			if id in ["prowboat", "pship", "boat"]:
				props[props.size() - 1].speed = randf_range(0.45, 0.75)
			elif mover == 1 and id in ["cow", "sheep", "dcamel", "brachio", "tyrant"]:
				props[props.size() - 1].speed = randf_range(0.32, 0.55)
			made += 1

func _spawn_life() -> void:
	var layout := str(map.get("layout", "farm"))
	var people := ["person_a", "person_b", "person_c"]
	var cars := ["sedan", "taxi", "hatch", "van"]
	match layout:
		"candy":
			_spawn_wander(["gbread"], 8, [SURF_GRASS, SURF_CONCRETE, SURF_FIELD], true)
			_spawn_wander(people, 6, [SURF_CONCRETE, SURF_GRASS], true)
			_spawn_drive(cars, 6, [SURF_TRACK])
		"jungle":
			_spawn_wander(["raptord", "trike", "raptord"], 7, [SURF_GRASS, SURF_FIELD, SURF_DIRT], true)
			_spawn_wander(["tyrant", "brachio"], 3, [SURF_FIELD, SURF_GRASS], false)
			_spawn_wander(people, 4, [SURF_DIRT, SURF_GRASS], true)
		"pirate":
			_spawn_drive(["prowboat", "prowboat", "pship"], 5, [SURF_WATER])
			_spawn_wander(people, 7, [SURF_WOOD, SURF_SAND, SURF_GRASS], true)
		"snow":
			_spawn_wander(["penguin", "penguin", "skier"], 8, [SURF_SAND, SURF_GRASS], true)
			_spawn_drive(["snowmobile", "hsled"], 5, [SURF_DIRT])
			_spawn_wander(people, 4, [SURF_CONCRETE, SURF_SAND], true)
		"desert":
			_spawn_wander(["dcamel", "dcamel", "person_a"], 8, [SURF_SAND, SURF_DIRT], true)
			_spawn_wander(people, 4, [SURF_CONCRETE, SURF_GRASS], true)
		"toy":
			_spawn_drive(["tracer", "ttruck", "tracer"], 7, [SURF_WOOD, SURF_FIELD, SURF_CONCRETE])
			_spawn_wander(["bot", "bot", "teddybear"], 6, [SURF_WOOD, SURF_CONCRETE, SURF_FIELD], true)
		"space":
			_spawn_drive(["spacerover"], 5, [SURF_SAND, SURF_CONCRETE, SURF_DIRT])
			_spawn_wander(["astro"], 7, [SURF_SAND, SURF_CONCRETE, SURF_DIRT], true)
		"haunt":
			_spawn_wander(["hghost", "hghost", "person_a"], 7, [SURF_GRASS, SURF_DIRT], true)
			_spawn_wander(["hbat", "hcrow", "hbat"], 8, [SURF_GRASS, SURF_FIELD, SURF_DIRT], true)
		"fair":
			_spawn_wander(people, 8, [SURF_CONCRETE, SURF_DIRT, SURF_GRASS], true)
			_spawn_drive(["fbumper", "hcart", "fbumper"], 6, [SURF_DIRT, SURF_CONCRETE])
		_:
			_spawn_wander(["chicken", "piglet", "sheep", "chicken"], 10, [SURF_GRASS, SURF_FIELD], true)
			_spawn_wander(["cow", "sheep", "piglet", "chicken"], 12, [SURF_GRASS, SURF_FIELD], false)
			_spawn_wander(people, 6, [SURF_DIRT, SURF_GRASS], true)

func _scatter_theme(layout: String) -> void:
	match layout:
		"candy":
			_scatter_on(["lollypop", "lollyblue", "lollygold", "donut", "donutchoc", "canecandy", "canegreen", "gbread", "breadpink", "sweetcup", "coneic", "blossom", "pebbles", "fflower"], 10, [SURF_GRASS, SURF_FIELD, SURF_CONCRETE], 1.0)
			_scatter_on(["ghouse"], 2, [SURF_GRASS], 1.0)
		"jungle":
			_scatter_on(["spottedegg", "eggblue", "egggold", "dinonest", "fernleaf", "fernwide", "jvine", "redshroom", "shroomgold", "miniraptor", "fflower", "floweryel", "blossom", "dinobone", "pebbles"], 12, [SURF_DIRT, SURF_FIELD, SURF_GRASS], 1.0)
			_scatter_on(["jpalm", "raptord"], 4, [SURF_DIRT, SURF_GRASS], 1.0)
			_scatter_on(["jhut"], 2, [SURF_DIRT, SURF_GRASS], 1.0)
		"pirate":
			_scatter_on(["pbarrel", "pcrate", "pchest", "chestgold", "pflag", "panchor", "pebbles", "blossom", "fflower", "floweryel", "canecandy", "fapple", "applegreen", "donut"], 10, [SURF_SAND, SURF_WOOD, SURF_GRASS], 1.0)
			_scatter_on(["pcannon", "ppalm"], 3, [SURF_SAND, SURF_WOOD], 1.0)
			_scatter_on(["tavern"], 2, [SURF_GRASS, SURF_DIRT], 1.0)
		"snow":
			_scatter_on(["hpresent", "giftgold", "hsled", "hsnowman", "snowtiny", "iceblock", "iceblue", "pebbles", "fflower", "flowerwht", "fapple", "applegold", "canecandy", "tblock", "blockred"], 10, [SURF_SAND, SURF_GRASS], 1.0)
			_scatter_on(["hpine"], 3, [SURF_SAND, SURF_GRASS], 1.0)
			_scatter_on(["hcabin"], 2, [SURF_SAND, SURF_CONCRETE], 1.0)
		"desert":
			_scatter_on(["drock", "rockred", "rockgold", "dcactus", "cactusflower", "dpot", "pebbles", "blossom", "fflower", "floweryel", "fapple", "applegold", "tball", "ballblue"], 10, [SURF_SAND, SURF_DIRT], 1.0)
			_scatter_on(["dtallcac", "dpalm"], 3, [SURF_SAND], 1.0)
			_scatter_on(["dstall"], 2, [SURF_SAND, SURF_DIRT], 1.0)
		"toy":
			_scatter_on(["tblock", "blockred", "blockgold", "tball", "ballblue", "teddybear", "bearblue", "toybench", "fballoon", "balloonyel", "donut", "donutchoc", "lollypop", "lollyblue", "canecandy"], 10, [SURF_WOOD, SURF_FIELD, SURF_CONCRETE], 1.0)
			_scatter_on(["bot", "twagon"], 3, [SURF_WOOD, SURF_CONCRETE, SURF_FIELD], 1.0)
			_scatter_on(["toyhouse"], 2, [SURF_WOOD, SURF_FIELD], 1.0)
		"space":
			_scatter_on(["satprobe", "probeamber", "moonlet", "meteorhot", "solarpanel", "pebbles", "tblock", "blockred", "iceblock", "iceblue", "fapple", "applegold", "antenna", "drock", "rockred"], 8, [SURF_SAND, SURF_DIRT, SURF_CONCRETE], 1.0)
			_scatter_on(["spacerover", "satdish"], 3, [SURF_SAND, SURF_CONCRETE], 1.0)
			_scatter_on(["habitat"], 2, [SURF_CONCRETE, SURF_SAND], 1.0)
		"haunt":
			_scatter_on(["hcandle", "hbat", "hcrow", "hpumpkin", "pumpkingold", "pebbles", "blossom", "fflower", "floweryel", "hpresent", "giftgold", "drock", "rockred", "tblock", "iceblock"], 10, [SURF_GRASS, SURF_DIRT, SURF_FIELD], 1.0)
			_scatter_on(["htomb", "hghost"], 3, [SURF_GRASS, SURF_DIRT], 1.0)
			_scatter_on(["hcart"], 2, [SURF_GRASS], 1.0)
		"fair":
			_scatter_on(["fballoon", "balloonyel", "fteacup", "cupgold", "fbench", "lollypop", "lollyblue", "donut", "donutchoc", "canecandy", "tball", "ballblue", "fapple", "applegold", "blossom"], 10, [SURF_GRASS, SURF_DIRT, SURF_CONCRETE], 1.0)
			_scatter_on(["fbumper", "fpop"], 3, [SURF_GRASS, SURF_CONCRETE], 1.0)
			_scatter_on(["teacups"], 2, [SURF_GRASS], 1.0)
		_:
			_scatter_on(["fapple", "applegreen", "applegold", "chicken", "piglet", "fflower", "floweryel", "flowerwht", "fwheat", "wheatgold", "blossom", "pebbles", "tblock", "blockred", "haybale"], 12, [SURF_FIELD, SURF_GRASS], 1.0)
			_scatter_on(["railfence"], 4, [SURF_GRASS, SURF_DIRT, SURF_FIELD], 1.0)
			_scatter_on(["cow", "scare"], 2, [SURF_GRASS, SURF_FIELD], 1.0)
			_scatter_on(["redbarn"], 2, [SURF_DIRT, SURF_GRASS], 1.0)
	_scatter_detail(layout)

func _scatter_detail(layout: String) -> void:
	var land := [SURF_GRASS, SURF_FIELD, SURF_DIRT]
	match layout:
		"candy":
			_scatter_on(["blossom", "pebbles"], 8, [SURF_GRASS, SURF_CONCRETE, SURF_FIELD], 1.0)
		"jungle":
			_scatter_on(["blossom", "pebbles"], 8, land, 1.0)
			_scatter_on(["puddle"], 3, [SURF_GRASS, SURF_DIRT], 1.0, Color(0.45, 0.78, 0.58))
		"pirate":
			_scatter_on(["pebbles"], 6, [SURF_SAND, SURF_WOOD, SURF_GRASS], 1.0)
			_scatter_on(["puddle"], 3, [SURF_SAND, SURF_WOOD], 1.0, Color(0.5, 0.72, 0.9))
		"snow":
			_scatter_on(["pebbles"], 6, [SURF_SAND, SURF_GRASS], 1.0, Color(0.94, 0.96, 1.0))
		"desert":
			_scatter_on(["pebbles", "blossom"], 7, [SURF_SAND, SURF_DIRT], 1.0)
			_scatter_on(["puddle"], 2, [SURF_SAND], 1.0, Color(0.35, 0.72, 0.78))
		"toy":
			_scatter_on(["blossom", "pebbles"], 7, [SURF_WOOD, SURF_FIELD, SURF_CONCRETE], 1.0)
		"space":
			_scatter_on(["pebbles"], 6, [SURF_SAND, SURF_DIRT, SURF_CONCRETE], 1.0, Color(0.42, 0.46, 0.54))
		"haunt":
			_scatter_on(["pebbles"], 6, [SURF_GRASS, SURF_DIRT], 1.0, Color(0.42, 0.4, 0.36))
			_scatter_on(["puddle"], 3, [SURF_GRASS, SURF_DIRT], 1.0, Color(0.32, 0.42, 0.3))
		"fair":
			_scatter_on(["blossom", "pebbles"], 8, [SURF_GRASS, SURF_CONCRETE, SURF_DIRT], 1.0)
		_:
			_scatter_on(["blossom", "pebbles"], 8, land, 1.0)
			_scatter_on(["puddle"], 3, [SURF_GRASS, SURF_DIRT, SURF_FIELD], 1.0, Color(0.58, 0.8, 0.96))

func _signature_ids(layout: String) -> Array:
	match layout:
		"candy":
			return ["sweetcup", "coneic", "partycake", "ghouse"]
		"jungle":
			return ["tyrant", "brachio", "trike", "jpalmtall"]
		"pirate":
			return ["pcannon", "ppalm", "prowboat", "pship"]
		"snow":
			return ["hsnowman", "hpine", "skier", "hcabin"]
		"desert":
			return ["dtallcac", "dcamel", "dtent", "dadobe"]
		"toy":
			return ["tracer", "teddybear", "bot", "toytrain"]
		"space":
			return ["stackrocket", "habitat", "satdish", "spacerover"]
		"haunt":
			return ["hpumpkin", "htomb", "hghost", "hhouse"]
		"fair":
			return ["fpop", "teacups", "carousel", "ferris"]
		_:
			return ["cow", "farmtractor", "scare", "redbarn"]

func _finale_id(layout: String) -> String:
	match layout:
		"candy":
			return "ccastle"
		"jungle":
			return "lavacone"
		"pirate":
			return "plight"
		"snow":
			return "icecastle"
		"desert":
			return "dsphinx"
		"toy":
			return "blockfort"
		"space":
			return "gantry"
		"haunt":
			return "hmansion"
		"fair":
			return "ferris"
		_:
			return "farmmill"

func _near_icons(layout: String) -> Array:
	# Small bites only. Tall heroes are placed further out.
	match layout:
		"candy":
			return ["lollypop", "donut", "gbread", "canecandy", "candybench"]
		"jungle":
			return ["spottedegg", "dinobone", "fernleaf", "redshroom"]
		"pirate":
			return ["pbarrel", "pcrate", "pflag", "pchest"]
		"snow":
			return ["hpresent", "hsled", "iceblock"]
		"desert":
			return ["drock", "dpot", "dcactus"]
		"toy":
			return ["tblock", "tball", "toybench"]
		"space":
			return ["satprobe", "solarpanel"]
		"haunt":
			return ["hcandle", "hbat", "hcrow", "hpumpkin"]
		"fair":
			return ["fballoon", "fteacup"]
		_:
			return ["fapple", "chicken", "fwheat", "fflower", "piglet"]

func _place_near_icons(layout: String) -> void:
	# The camera looks toward -Z. Keep this arc inside the clear radius.
	var ids: Array = _near_icons(layout)
	var made := 0
	var tries := 0
	while made < 12 and tries < 120 and props.size() < PROP_CAP:
		tries += 1
		var ang := randf_range(-PI * 0.82, -PI * 0.18)
		var rr := randf_range(5.4, 13.5)
		var p := Vector3(cos(ang) * rr, 0.0, sin(ang) * rr)
		var id := str(ids[tries % ids.size()])
		if _place_id(id, p, Vector3.ZERO, randf() * TAU, 1.0):
			made += 1

func _place_signatures(layout: String) -> void:
	var ids: Array = _signature_ids(layout)
	# Flank the opening view. The center corridor stays open so the horizon reads.
	var spots: Array = [
		Vector3(24.0, 0, -32.0),
		Vector3(-26.0, 0, -30.0),
		Vector3(36.0, 0, -16.0),
		Vector3(-38.0, 0, -14.0),
	]
	for i in mini(ids.size(), spots.size()):
		var base: Vector3 = spots[i]
		if _place_id(str(ids[i]), base, Vector3.ZERO, 0.4, 1.0):
			continue
		_place_id(str(ids[i]), base * 1.22, Vector3.ZERO, 0.7, 1.0)
	var finale := _finale_id(layout)
	var far: Array = [Vector3(46, 0, -32), Vector3(-40, 0, 36), Vector3(28, 0, 48), Vector3(-52, 0, -24)]
	for spot in far:
		if _place_id(finale, spot, Vector3.ZERO, 0.35, 1.0):
			break

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
			var id := _district_building(str(ids[n % ids.size()]), ix, iz, n)
			if id != "":
				_place_id(id, Vector3(ix, 0, iz), Vector3.ZERO, (PI * 0.5) * float(n % 4), randf_range(grow_min, grow_max))
			n += 1

func _scatter_on(ids: Array, count: int, surfs: Array, grow: float, tint: Color = Color.WHITE, points: int = -1) -> void:
	count *= DENSITY
	var made := 0
	var tries := 0
	var limit := count * 28
	var used := {}
	var last := ""
	var run := 0
	var cap := maxi(int(ceil(float(count) * 0.12)), 1)
	var order: Array = ids.duplicate()
	order.shuffle()
	var cursor := 0
	while made < count and tries < limit and props.size() < PROP_CAP:
		tries += 1
		var span := CITY_HALF - 1.2
		var p := Vector3(randf_range(-span, span), 0, randf_range(-span, span))
		if not _surf_ok(p, surfs):
			continue
		if _layout_blocked(p):
			continue
		var id := ""
		var guard := 0
		while guard < order.size():
			var pick := str(order[cursor % order.size()])
			cursor += 1
			guard += 1
			if _is_rare_treat(pick):
				continue
			if int(used.get(pick, 0)) >= cap:
				continue
			if pick == last and run >= 2 and order.size() > 1:
				continue
			id = pick
			break
		if id == "":
			break
		var yaw := randf() * TAU
		if _place_id(id, p, Vector3.ZERO, yaw, grow * randf_range(0.92, 1.08), tint, points):
			used[id] = int(used.get(id, 0)) + 1
			run = run + 1 if id == last else 1
			last = id
			made += 1

func _grid_ids(ids: Array, step: int, surfs: Array, cap: int, grow: float, with_mail: bool) -> void:
	cap *= DENSITY
	var made := 0
	var x := GRID_MIN + 2
	while x < GRID_MAX - 1 and made < cap and props.size() < PROP_CAP:
		var z := GRID_MIN + 2
		while z < GRID_MAX - 1 and made < cap and props.size() < PROP_CAP:
			var p := Vector3(float(x), 0, float(z))
			if str(map.get("layout", "")) == "suburb" and _district(x, z) in [0, 8]:
				z += step
				continue
			if _surf_ok(p, surfs) and not _layout_blocked(p) and not _near_road(x, z):
				var id := str(ids[absi(x + z) % ids.size()])
				if _place_id(id, p, Vector3.ZERO, (PI * 0.5) * float(absi(x) % 4), grow):
					made += 1
					if with_mail:
						_place_id("mailbox", p + Vector3(1.15, 0, 0.7), Vector3.ZERO, 0.0, 1.0)
			z += step
		x += step

func _edge_props(ids: Array, step: int, cap: int) -> void:
	cap *= DENSITY
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
	count *= DENSITY
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
	moving *= DENSITY
	parked *= DENSITY
	var ids := ["sedan", "taxi", "hatch", "van", "police", "sedan", "taxi", "hatch", "truck", "bus"]
	var spots: Array = []
	var n := GRID_MAX - GRID_MIN + 1
	for j in range(2, n - 2):
		for i in range(2, n - 2):
			if ((i + j) % 2) != 0:
				continue
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
		if traffic_id == "bus":
			traffic_grow = 1.80
		elif traffic_id == "truck":
			traffic_grow = 1.95
		elif traffic_id == "police":
			traffic_grow = 2.20
		if _place_id(traffic_id, at, use_dir, -1.0, traffic_grow, Color.WHITE, -1, mover):
			made += 1

func _lamps(cap: int) -> void:
	cap *= DENSITY
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
	var made := 0
	var n := GRID_MAX - GRID_MIN + 1
	for j in range(0, n, 2):
		for i in n:
			if made >= 180:
				return
			var x := GRID_MIN + i
			var z := GRID_MIN + j
			if _surf_i(x, z) != SURF_DOCK:
				continue
			if _place_id("boat", Vector3(float(x), 0, float(z)), Vector3.ZERO, 0.0, 1.0):
				made += 1

func _vista_spot(id: String, p: Vector3, yaw: float = -1.0) -> void:
	var use := yaw if yaw >= 0.0 else randf() * TAU
	if _place_id(id, p, Vector3.ZERO, use):
		return
	_place_id(id, p + Vector3(1.7, 0.0, 1.1), Vector3.ZERO, use)

func _vista_mover(id: String, p: Vector3, surfs: Array, yaw: float = -1.0) -> void:
	var use := yaw if yaw >= 0.0 else randf() * TAU
	var dir := Vector3(sin(use), 0.0, cos(use))
	if not _place_id(id, p, dir, use, 1.0, Color.WHITE, -1, 1, surfs):
		p += Vector3(1.7, 0.0, 1.1)
		if not _place_id(id, p, dir, use, 1.0, Color.WHITE, -1, 1, surfs):
			return
	props[props.size() - 1]["walk"] = surfs

func _vista_boat(id: String, p: Vector3, yaw: float) -> void:
	var dir := Vector3(sin(yaw), 0.0, cos(yaw))
	if _place_id(id, p, dir, yaw, 1.0, Color.WHITE, -1, 2, [SURF_WATER]):
		props[props.size() - 1]["walk"] = [SURF_WATER]
		props[props.size() - 1].speed = 0.55

func _dress_farm_vista() -> void:
	var x0 := -26.0
	var x1 := -14.0
	var z0 := -22.0
	var z1 := -10.0
	var t := x0
	while t <= x1:
		_vista_spot("railfence", Vector3(t, 0.0, z0), 0.0)
		_vista_spot("railfence", Vector3(t, 0.0, z1), 0.0)
		t += 2.4
	var u := z0 + 2.4
	while u < z1:
		_vista_spot("railfence", Vector3(x0, 0.0, u), PI * 0.5)
		_vista_spot("railfence", Vector3(x1, 0.0, u), PI * 0.5)
		u += 2.4
	_vista_spot("sheep", Vector3(-20.0, 0.0, -16.0))
	_vista_spot("sheep", Vector3(-17.0, 0.0, -18.0))
	_vista_spot("cow", Vector3(-22.0, 0.0, -14.0))
	_vista_spot("piglet", Vector3(-16.0, 0.0, -13.0))
	_vista_spot("piglet", Vector3(-19.0, 0.0, -19.0))
	_vista_spot("chicken", Vector3(-15.5, 0.0, -16.5))
	_vista_spot("chicken", Vector3(6.4, 0.0, -6.6))
	_vista_spot("chicken", Vector3(9.6, 0.0, -11.2))
	_vista_spot("redbarn", Vector3(-28.0, 0.0, -16.0), 0.6)
	_vista_spot("farmtractor", Vector3(20.0, 0.0, -8.0), 0.9)
	_vista_spot("haybale", Vector3(7.0, 0.0, 12.0))
	_vista_spot("haybale", Vector3(-8.0, 0.0, 16.0))
	_vista_spot("haybale", Vector3(24.0, 0.0, -12.0))
	_vista_spot("roundtree", Vector3(-18.0, 0.0, -28.0))
	_vista_spot("roundtree", Vector3(26.0, 0.0, -22.0))
	_vista_spot("roundtree", Vector3(-30.0, 0.0, 8.0))
	_vista_spot("tree_large", Vector3(18.0, 0.0, 16.0))
	_vista_spot("fflower", Vector3(6.0, 0.0, -12.0))
	_vista_spot("fflower", Vector3(-8.0, 0.0, -8.0))
	_vista_spot("fwheat", Vector3(-6.0, 0.0, 18.0))
	_vista_spot("scare", Vector3(12.0, 0.0, -28.0))

func _opening_car_ids(layout: String) -> Array:
	match layout:
		"candy":
			return ["van", "taxi"]
		"pirate":
			return ["sedan", "van"]
		"snow":
			return ["snowmobile", "sedan"]
		"desert":
			return ["sedan", "hatch"]
		"toy":
			return ["tracer", "ttruck"]
		"space":
			return ["spacerover", "spacerover"]
		"haunt":
			return ["hcart", "sedan"]
		"fair":
			return ["fbumper", "sedan"]
		"jungle":
			return ["sedan", "hatch"]
		_:
			return ["sedan", "hatch"]

func _opening_bite(layout: String) -> String:
	match layout:
		"candy":
			return "lollypop"
		"jungle":
			return "spottedegg"
		"pirate":
			return "pbarrel"
		"snow":
			return "hpresent"
		"desert":
			return "drock"
		"toy":
			return "tblock"
		"space":
			return "moonlet"
		"haunt":
			return "hcandle"
		"fair":
			return "fteacup"
		_:
			return "fapple"

func _place_opening_cars(layout: String) -> void:
	# Placed while the city is built, not from a frame counter, so a slow
	# machine still has cars in the first painted frame.
	if road_routes.is_empty():
		return
	var ri := road_routes.size() - 1
	var route: Dictionary = road_routes[ri]
	var ids: Array = _opening_car_ids(layout)
	# Same direction and a fixed gap, so they cannot meet head-on.
	var spots: Array = [
		{"x": -6.4, "lane": 0.58},
		{"x": 1.2, "lane": 0.58},
	]
	for i in spots.size():
		var spot: Dictionary = spots[i]
		var prog := float(spot.x) + 14.0
		var lane := float(spot.lane)
		var sample := _sample_route(route, prog)
		var dir: Vector3 = sample.dir
		if lane < 0.0:
			dir = -dir
		var side := Vector3(-dir.z, 0.0, dir.x)
		var pos: Vector3 = sample.pos + side * absf(lane)
		if _place_id(str(ids[i]), pos, dir, -1.0, 1.0, Color.WHITE, -1, 2, [SURF_ROAD], true):
			var o: Dictionary = props[props.size() - 1]
			o["route"] = ri
			o["prog"] = prog
			o["lane"] = lane
			o["walk"] = [SURF_ROAD]
			o["speed"] = 1.22
			o["vel"] = dir * 1.22

func _place_opening_bites(layout: String) -> void:
	var id := _opening_bite(layout)
	var spots: Array = [
		Vector3(2.2, 0, -2.4), Vector3(-2.4, 0, -2.6), Vector3(0.6, 0, -3.4),
		Vector3(-0.8, 0, -4.2), Vector3(3.4, 0, -4.6), Vector3(-3.6, 0, -3.6),
	]
	for p in spots:
		if _surf_f(p.x, p.z) == SURF_WATER or _surf_f(p.x, p.z) == SURF_ROAD:
			continue
		_place_id(id, p, Vector3.ZERO, randf() * TAU, 1.0, Color.WHITE, -1, -1, [], true)

func _place_open(id: String, p: Vector3, yaw: float = -1.0, grow: float = 1.0) -> bool:
	if _place_id(id, p, Vector3.ZERO, yaw, grow, Color.WHITE, -1, -1, [], true):
		return true
	return _place_id(id, p + Vector3(0.7, 0, -0.5), Vector3.ZERO, yaw, grow, Color.WHITE, -1, -1, [], true)

func _dress_jungle_canopy() -> void:
	if str(map.get("layout", "")) != "jungle":
		return
	var ids: Array = ["jpalmtall", "jpalm", "jpalm", "fernleaf"]
	var made := 0
	var n := 0
	var x := -56
	while x <= 56 and made < 28:
		var z := -56
		while z <= 56 and made < 28:
			n += 1
			var p := Vector3(float(x) + float(n % 3) - 1.0, 0.0, float(z))
			var surf := _surf_f(p.x, p.z)
			var close := absf(p.x) < 12.0 and p.z > -16.0 and p.z < 12.0
			if not close and surf != SURF_WATER and surf != SURF_ROAD:
				var id := str(ids[made % ids.size()])
				var grow := 1.12
				if id == "jpalmtall":
					grow = 1.2
				elif id == "fernleaf":
					grow = 2.35
				if _place_id(id, p, Vector3.ZERO, float(n) * 0.7, grow):
					made += 1
			z += 13
		x += 16

func _dress_opening(layout: String) -> void:
	# Round start frames only x ±5 and z -13 to +9. Heroes go in that window.
	_place_opening_cars(layout)
	var land := [SURF_DIRT, SURF_GRASS, SURF_FIELD]
	match layout:
		"jungle":
			_place_open("jpalmtall", Vector3(-4.2, 0, -7.2), 0.4, 1.28)
			_place_open("jpalm", Vector3(3.8, 0, -5.8), 1.1, 1.22)
			_place_open("jpalm", Vector3(-1.6, 0, -10.4), 0.6, 1.16)
			_place_open("fernleaf", Vector3(2.6, 0, -3.0), 0.2, 4.2)
			_place_open("fernleaf", Vector3(-3.2, 0, -2.5), 1.2, 3.8)
			_place_open("jvine", Vector3(0.5, 0, -6.4), 0.8, 3.4)
			_place_open("fernwide", Vector3(3.4, 0, -4.2), 0.5, 3.3)
			_vista_mover("tyrant", Vector3(-4.4, 0, -12.6), land, 1.2)
			_vista_spot("lavacone", Vector3(4.7, 0, -12.5), 0.35)
			_vista_mover("brachio", Vector3(2.6, 0, -14.4), land, 0.7)
			_vista_mover("trike", Vector3(1.4, 0, -8.8), land, 0.4)
			_vista_mover("raptord", Vector3(3.3, 0, -8.5), land, 1.4)
			_vista_mover("raptord", Vector3(-3.5, 0, -8.3), land, 0.5)
			_vista_spot("miniraptor", Vector3(1.7, 0, -2.8), 0.8)
			_vista_spot("miniraptor", Vector3(-2.0, 0, -3.1), 1.4)
			_vista_spot("miniraptor", Vector3(2.4, 0, 2.2), 0.3)
			_vista_spot("dinonest", Vector3(-2.3, 0, -4.0), 0.4)
			_vista_spot("spottedegg", Vector3(1.5, 0, -2.5))
			_vista_spot("spottedegg", Vector3(-1.4, 0, 2.6))
			_vista_spot("dinobone", Vector3(3.2, 0, -5.2), 0.6)
			_vista_spot("fernleaf", Vector3(-3.8, 0, -5.4))
			_vista_spot("fernleaf", Vector3(0.6, 0, -6.4))
			_vista_spot("fflower", Vector3(2.8, 0, -2.4))
			_vista_spot("fflower", Vector3(-3.0, 0, -2.6))
			_vista_spot("blossom", Vector3(0.9, 0, 1.8))
		"space":
			var pad := [SURF_SAND, SURF_CONCRETE, SURF_DIRT]
			# Centered and a little further up-screen so the wide rocket stays
			# inside the opening and clear of the astronauts.
			_place_id("stackrocket", Vector3(0.0, 0, -6.2), Vector3.ZERO, 0.2, 1.0, Color.WHITE, -1, -1, [], true)
			_place_id("habitat", Vector3(3.5, 0, -4.1), Vector3.ZERO, 0.5, 1.0, Color.WHITE, -1, -1, [], true)
			if _place_id("astro", Vector3(1.45, 0, -2.45), Vector3(0.2, 0, 1.0), -1.0, 1.0, Color.WHITE, -1, 1, pad, true):
				props[props.size() - 1]["walk"] = pad
			if _place_id("astro", Vector3(-1.4, 0, -2.6), Vector3(-0.2, 0, 1.0), -1.0, 1.0, Color.WHITE, -1, 1, pad, true):
				props[props.size() - 1]["walk"] = pad
			_vista_spot("solarpanel", Vector3(4.4, 0, -3.2), 0.4)
			_vista_spot("solarpanel", Vector3(-4.2, 0, -3.4), 1.0)
			_vista_spot("satdish", Vector3(2.8, 0, -13.5), 0.6)
			_vista_spot("antenna", Vector3(-2.6, 0, -13.6), 0.3)
			_vista_spot("satprobe", Vector3(1.6, 0, -2.6), 0.4)
		"pirate":
			_vista_spot("pier", Vector3(0.2, 0, 7.6), 0.0)
			_vista_spot("pier", Vector3(-4.6, 0, 1.2), 1.57)
			_vista_spot("pier", Vector3(4.4, 0, -1.5), 1.57)
			_vista_spot("pier", Vector3(-1.2, 0, -8.0), 0.2)
			_place_id("skiff", Vector3(2.2, 0, 8.6), Vector3.ZERO, 0.3, 1.0, Color.WHITE, -1, 0, [SURF_WATER])
			_vista_spot("pflag", Vector3(3.6, 0, -1.4))
		"candy":
			_vista_spot("candybench", Vector3(2.2, 0, -5.0), 0.25)
			_vista_spot("candybench", Vector3(-2.6, 0, -6.2), 0.1)
			_vista_spot("canecandy", Vector3(-1.4, 0, -3.8))
			_vista_spot("donut", Vector3(3.2, 0, -3.6))
		"toy":
			_vista_spot("toybench", Vector3(2.4, 0, -5.2), 0.3)
			_vista_spot("teddybear", Vector3(-2.2, 0, -6.4))
			_vista_spot("tblock", Vector3(-3.4, 0, -4.2))
			_vista_mover("tracer", Vector3(3.1, 0, -8.6), [SURF_WOOD, SURF_FIELD, SURF_CONCRETE], 0.2)
			_vista_mover("ttruck", Vector3(-2.4, 0, -9.6), [SURF_WOOD, SURF_FIELD, SURF_CONCRETE], 2.4)
		"farm":
			_vista_spot("chicken", Vector3(1.8, 0, -4.0))
			_vista_spot("chicken", Vector3(-2.2, 0, -4.8))
			_vista_spot("chicken", Vector3(3.2, 0, 6.8))
			_vista_spot("chicken", Vector3(-2.4, 0, 7.0))
		_:
			pass
	_place_opening_bites(layout)

func _dress_vista(layout: String) -> void:
	match layout:
		"candy":
			for spot in [Vector3(16, 0, -16), Vector3(-16, 0, -14), Vector3(18, 0, 8), Vector3(-14, 0, 12), Vector3(8, 0, -22), Vector3(-22, 0, -6)]:
				_vista_spot("lollypop", spot)
			_vista_spot("ghouse", Vector3(-20, 0, -18))
			_vista_spot("donut", Vector3(12, 0, -10))
			_vista_spot("canecandy", Vector3(-10, 0, -20))
			_vista_spot("sweetcup", Vector3(22, 0, -8))
			_vista_spot("coneic", Vector3(-8, 0, 16))
			_vista_spot("candybench", Vector3(10, 0, -12), 0.4)
			_vista_spot("candybench", Vector3(-14, 0, -8), 0.2)
		"jungle":
			_vista_mover("tyrant", Vector3(-18, 0, -16), [SURF_DIRT, SURF_GRASS, SURF_FIELD], 1.4)
			_vista_mover("brachio", Vector3(-28, 0, -20), [SURF_DIRT, SURF_GRASS, SURF_FIELD], 1.2)
			_vista_mover("trike", Vector3(12, 0, -15), [SURF_DIRT, SURF_GRASS, SURF_FIELD], 0.3)
			_vista_mover("raptord", Vector3(-10, 0, -12), [SURF_DIRT, SURF_GRASS, SURF_FIELD], 1.6)
			_vista_mover("raptord", Vector3(8, 0, -22), [SURF_DIRT, SURF_GRASS, SURF_FIELD], 0.8)
			_vista_spot("dinonest", Vector3(-7, 0, -9), 0.4)
			_vista_spot("spottedegg", Vector3(5.5, 0, -8), 0.2)
			_vista_spot("spottedegg", Vector3(7.2, 0, -7.2), 1.1)
			_vista_spot("dinobone", Vector3(14, 0, -10), 0.6)
			_vista_spot("dinobone", Vector3(-6, 0, -18), 0.9)
			_vista_spot("fernleaf", Vector3(-12, 0, -8))
			_vista_spot("fernleaf", Vector3(6, 0, -16))
			_vista_spot("fernleaf", Vector3(16, 0, -20))
			_vista_spot("jpalm", Vector3(-16, 0, -22))
			_vista_spot("jpalmtall", Vector3(16, 0, -26))
			_vista_spot("jvine", Vector3(-14, 0, -10))
			_vista_spot("jvine", Vector3(10, 0, -12))
			_vista_spot("redshroom", Vector3(4, 0, -14))
			_vista_spot("jhut", Vector3(-26, 0, -14))
			_vista_spot("lavacone", Vector3(30, 0, -32), 0.5)
		"pirate":
			_vista_spot("pdock", Vector3(17.5, 0, -16), 1.57)
			_vista_spot("pdock", Vector3(-17.5, 0, -22), 1.57)
			_vista_spot("pdock", Vector3(17.5, 0, -26), 1.57)
			_vista_boat("prowboat", Vector3(12, 0, -16), 0.4)
			_vista_boat("prowboat", Vector3(-12, 0, -24), 2.6)
			_vista_spot("ppalm", Vector3(24, 0, -14))
			_vista_spot("ppalm", Vector3(-24, 0, -16))
			_vista_spot("pbarrel", Vector3(20, 0, -12))
			_vista_spot("pflag", Vector3(26, 0, -20))
			_vista_spot("tavern", Vector3(-26, 0, -12))
		"snow":
			_vista_spot("hpine", Vector3(16, 0, -16))
			_vista_spot("hpine", Vector3(-18, 0, -14))
			_vista_spot("hsnowman", Vector3(12, 0, -8))
			_vista_spot("hcabin", Vector3(-24, 0, -16))
			_vista_spot("hpresent", Vector3(-10, 0, -20))
			_vista_spot("iceblock", Vector3(22, 0, -10))
		"desert":
			_vista_spot("dpalm", Vector3(12, 0, -14))
			_vista_spot("dpalm", Vector3(20, 0, -22))
			_vista_spot("dcactus", Vector3(-16, 0, -14))
			_vista_spot("dtallcac", Vector3(-22, 0, -8))
			_vista_spot("dtent", Vector3(24, 0, -8))
			_vista_spot("drock", Vector3(-10, 0, -22))
		"toy":
			_vista_spot("tblock", Vector3(14, 0, -14))
			_vista_spot("tblock", Vector3(-14, 0, -16))
			_vista_spot("tball", Vector3(10, 0, -8))
			_vista_spot("teddybear", Vector3(-18, 0, -8))
			_vista_spot("toyhouse", Vector3(22, 0, -18))
			_vista_spot("bot", Vector3(-10, 0, -12))
			_vista_spot("toybench", Vector3(8, 0, -16), 0.3)
		"space":
			_vista_spot("habitat", Vector3(-22, 0, -16), 0.6)
			_vista_mover("spacerover", Vector3(14, 0, -12), [SURF_SAND, SURF_CONCRETE, SURF_DIRT], 0.8)
			_vista_spot("satdish", Vector3(-16, 0, -24), 0.4)
			_vista_spot("stackrocket", Vector3(24, 0, -18), 0.3)
			_vista_mover("astro", Vector3(10, 0, -14), [SURF_SAND, SURF_CONCRETE, SURF_DIRT], 2.4)
			_vista_spot("antenna", Vector3(18, 0, -14), 0.2)
			_vista_spot("solarpanel", Vector3(-12, 0, -14), 0.5)
			_vista_spot("solarpanel", Vector3(8, 0, -20), 0.9)
			_vista_spot("satprobe", Vector3(6, 0, -9), 0.7)
		"haunt":
			_vista_spot("htree", Vector3(16, 0, -16))
			_vista_spot("htree", Vector3(-18, 0, -14))
			_vista_spot("hpumpkin", Vector3(10, 0, -10))
			_vista_spot("htomb", Vector3(-12, 0, -20))
			_vista_spot("hhouse", Vector3(-24, 0, -12))
			_vista_spot("hcandle", Vector3(20, 0, -8))
		"fair":
			_vista_spot("fballoon", Vector3(14, 0, -12))
			_vista_spot("fballoon", Vector3(-14, 0, -16))
			_vista_spot("fteacup", Vector3(10, 0, -20))
			_vista_spot("carousel", Vector3(-22, 0, -14))
			_vista_spot("teacups", Vector3(22, 0, -18))
			_vista_spot("fbench", Vector3(-8, 0, 12))
		_:
			_dress_farm_vista()

func _coat_for(id: String) -> Color:
	if id.find("gold") >= 0:
		return Color(1.08, 0.9, 0.42)
	match id:
		"piglet":
			return Color(1.02, 0.96, 0.98)
		"sheep":
			return Color(0.96, 0.96, 0.94)
		"cow":
			return Color(1.02, 1.0, 0.98)
		"chicken":
			return Color(1.05, 0.94, 0.72)
		"farmtractor":
			return Color(0.9, 1.06, 0.88)
		"redbarn":
			return Color(1.06, 0.98, 0.96)
		"haybale":
			return Color(0.8, 0.74, 0.6)
		"fwheat":
			return Color(0.82, 0.76, 0.62)
		"railfence":
			return Color(1.04, 1.03, 1.0)
		"roundtree":
			return Color(0.92, 1.04, 0.9)
		"applegreen":
			return Color(0.62, 1.02, 0.48)
		"floweryel":
			return Color(1.05, 0.92, 0.35)
		"flowerwht":
			return Color(0.98, 0.98, 0.94)
		"lollyblue":
			return Color(0.45, 0.7, 1.05)
		"donutchoc":
			return Color(0.62, 0.42, 0.28)
		"eggblue":
			return Color(0.7, 0.86, 1.02)
		"rockred":
			return Color(0.85, 0.4, 0.32)
		"blockred":
			return Color(0.9, 0.28, 0.26)
		"ballblue":
			return Color(0.32, 0.5, 1.0)
		"balloonyel":
			return Color(1.05, 0.88, 0.28)
		"iceblue":
			return Color(0.7, 0.86, 1.02)
		"canegreen":
			return Color(0.4, 0.85, 0.42)
		"breadpink":
			return Color(1.02, 0.62, 0.72)
		"bearblue":
			return Color(0.4, 0.55, 0.95)
		"meteorhot":
			return Color(1.02, 0.5, 0.22)
		"probeamber":
			return Color(1.02, 0.68, 0.28)
		"cactusflower":
			return Color(0.35, 0.8, 0.38)
		"fernwide":
			return Color(0.55, 1.0, 0.5)
		"snowtiny":
			return Color(0.9, 0.95, 1.0)
		"animal":
			return Color(1.02, 0.96, 0.98)
		_:
			return Color.WHITE

func _tint_animals() -> void:
	for o in props:
		var coat := _coat_for(kind_id_of(int(o.kind)))
		if coat != Color.WHITE:
			o.color = coat
		if bool(o.get("opening_treat", false)):
			o.color = Color(1.0, 0.78, 0.08)
		elif bool(o.get("treat", false)):
			o.color = Color(1.08, 0.94, 0.46)

func _swallow_bucket(id: String) -> String:
	if id in ["sedan", "taxi", "hatch", "van", "police", "truck", "bus", "tractor", "forklift", "rover", "toycar", "bumper", "farmtractor", "pickup", "tracer", "ttruck", "spacerover", "fbumper", "snowmobile", "hsled"]:
		return "cars"
	if id in ["tree_small", "tree_large", "tree_simple", "palm", "pine", "fern", "cactus", "jpalm", "jpalmtall", "ppalm", "hpine", "dcactus", "dtallcac", "dpalm", "fernleaf", "htree", "roundtree", "jvine"]:
		return "trees"
	if id in ["bld_a", "bld_b", "bld_c", "bld_d", "wide", "house_a", "house_b", "house_c", "tower_a", "tower_c", "barn", "shop", "apartment", "warehouse", "gazebo", "cabana", "landmark", "windmill", "crane", "silo", "coop", "candyhouse", "candycastle", "cabin", "igloo", "chapel", "pyramid", "oasisgate", "dollhouse", "brickfort", "dome", "station", "crypt", "mansion", "fort", "volcano", "booth", "redbarn", "grainsilo", "farmmill", "ghouse", "ccastle", "jhut", "lavacone", "tavern", "plight", "hcabin", "skilift", "icecastle", "dadobe", "dpyramid", "dsphinx", "toyhouse", "blockfort", "habitat", "stackrocket", "gantry", "hhouse", "hcrypt", "hmansion", "carousel", "ferris"]:
		return "buildings"
	if id == "bigtree":
		return "trees"
	if id in ["person_a", "person_b", "person_c", "astro", "skier"]:
		return "people"
	if id in ["boat", "rowboat", "galleon", "prowboat", "pship", "pdock"]:
		return "boats"
	if id == "lamp":
		return "lamps"
	if id in ["animal", "raptor", "trex", "camel", "chicken", "piglet", "cow", "sheep", "penguin", "raptord", "trike", "tyrant", "brachio", "dcamel"]:
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
	if str(map.get("layout", "")) != "campus":
		return false
	if _pond(int(round(p.x)), int(round(p.z)), 48.0, -40.0, 14.0, 14.0):
		return true
	if _pond(int(round(p.x)), int(round(p.z)), -42.0, 38.0, 11.0, 11.0):
		return true
	return false

func _district_building(fallback: String, x: float, z: float, n: int) -> String:
	var surf := _surf_f(x, z)
	if surf == SURF_WATER or surf == SURF_TRACK:
		return ""
	var layout := str(map.get("layout", "grid"))
	var d := _district(int(round(x)), int(round(z)))
	if layout == "grid":
		if d == 0:
			return ""
		if d == 4:
			return ["tower_a", "tower_c", "wide", "tower_a"][n % 4]
		if d == 2:
			return ["tower_c", "bld_c", "tower_a", "wide"][n % 4]
		if d == 8:
			return ["bld_a", "bld_b", "wide", "bld_d"][n % 4]
	elif layout == "campus":
		if d == 2 or d == 8:
			return ""
		if d == 0:
			return ["house_a", "house_b", "house_c", "wide"][n % 4]
	elif layout == "industrial":
		if d == 1 or d == 0:
			return ""
		if d == 4:
			return ["wide", "bld_b", "wide", "bld_c"][n % 4]
	elif layout == "skyline":
		if d == 0 or d == 6:
			return ""
		if d == 4:
			return ["tower_a", "tower_c", "tower_a", "tower_c"][n % 4]
	return fallback

func _dress_districts() -> void:
	var layout := str(map.get("layout", "farm"))
	var land := [SURF_GRASS, SURF_FIELD, SURF_DIRT]
	match layout:
		"candy":
			_place_landmark("ccastle", [SURF_GRASS, SURF_FIELD, SURF_CONCRETE])
			_cluster(["lollypop", "donut", "canecandy", "sweetcup", "candybench"], 32, _district_center(4), 12.0, [SURF_GRASS, SURF_CONCRETE, SURF_FIELD])
			_cluster(["ghouse", "partycake", "coneic", "lamp"], 14, _district_center(0), 11.0, [SURF_GRASS, SURF_FIELD])
			_cluster(["candybench", "sweetcup", "donut"], 16, _district_center(8), 10.0, [SURF_CONCRETE, SURF_GRASS])
		"jungle":
			_place_landmark("lavacone", land)
			_cluster(["fernleaf", "jpalm", "jvine", "redshroom", "dinonest", "spottedegg"], 28, _district_center(4), 13.0, [SURF_DIRT, SURF_GRASS, SURF_FIELD])
			_cluster(["jhut", "jpalmtall", "raptord", "trike", "dinobone"], 14, _district_center(2), 12.0, [SURF_DIRT, SURF_GRASS])
			_cluster(["jpalm", "fernleaf", "jvine"], 14, _district_center(6), 12.0, [SURF_GRASS, SURF_FIELD, SURF_DIRT])
		"pirate":
			_place_landmark("plight", [SURF_SAND, SURF_GRASS, SURF_WOOD, SURF_DIRT])
			_cluster(["pbarrel", "pcrate", "pchest", "pcannon", "pdock"], 26, _district_center(4), 12.0, [SURF_SAND, SURF_WOOD, SURF_GRASS])
			_cluster(["ppalm", "pflag", "pbarrel"], 14, _district_center(2), 12.0, [SURF_SAND, SURF_GRASS])
			_cluster(["tavern", "panchor", "lamp"], 10, _district_center(6), 11.0, [SURF_GRASS, SURF_DIRT, SURF_WOOD])
		"snow":
			_place_landmark("icecastle", [SURF_SAND, SURF_GRASS, SURF_CONCRETE])
			_cluster(["hpine", "hsnowman", "hpresent", "bench"], 24, _district_center(4), 12.0, [SURF_SAND, SURF_GRASS])
			_cluster(["hcabin", "hsled", "lamp"], 12, _district_center(0), 11.0, [SURF_SAND, SURF_CONCRETE])
			_cluster(["iceblock", "tree_small"], 12, _district_center(8), 11.0, [SURF_SAND, SURF_GRASS])
		"desert":
			_place_landmark("dsphinx", [SURF_SAND, SURF_DIRT])
			_cluster(["dcactus", "dtallcac", "drock", "dpot"], 24, _district_center(4), 13.0, [SURF_SAND, SURF_DIRT])
			_cluster(["dpalm", "dtent", "dstall"], 12, _district_center(2), 12.0, [SURF_SAND, SURF_GRASS])
			_cluster(["dadobe", "crate", "lamp"], 10, _district_center(8), 11.0, [SURF_DIRT, SURF_CONCRETE, SURF_SAND])
		"toy":
			_place_landmark("blockfort", [SURF_WOOD, SURF_FIELD, SURF_CONCRETE])
			_cluster(["tblock", "tball", "teddybear", "toybench"], 26, _district_center(4), 12.0, [SURF_WOOD, SURF_FIELD, SURF_CONCRETE])
			_cluster(["toyhouse", "twagon", "toybench"], 12, _district_center(0), 11.0, [SURF_WOOD, SURF_FIELD, SURF_CONCRETE])
			_cluster(["bot", "tblock", "lamp"], 12, _district_center(8), 10.0, [SURF_WOOD, SURF_CONCRETE])
		"space":
			_place_landmark("gantry", [SURF_SAND, SURF_CONCRETE, SURF_DIRT])
			_cluster(["satdish", "solarpanel", "antenna", "satprobe"], 20, _district_center(4), 12.0, [SURF_SAND, SURF_CONCRETE, SURF_DIRT])
			_cluster(["habitat", "spacerover", "astro"], 12, _district_center(2), 11.0, [SURF_CONCRETE, SURF_SAND, SURF_DIRT])
			_cluster(["antenna", "solarpanel", "satprobe"], 12, _district_center(6), 10.0, [SURF_CONCRETE, SURF_DIRT, SURF_SAND])
		"haunt":
			_place_landmark("hmansion", [SURF_GRASS, SURF_DIRT, SURF_FIELD])
			_cluster(["htomb", "hpumpkin", "hcandle", "htree"], 24, _district_center(4), 12.0, [SURF_GRASS, SURF_DIRT])
			_cluster(["hhouse", "hcart", "bench"], 12, _district_center(0), 11.0, [SURF_GRASS, SURF_DIRT])
			_cluster(["hcrypt", "lamp", "crate"], 10, _district_center(8), 10.0, [SURF_GRASS, SURF_CONCRETE])
		"fair":
			_place_landmark("ferris", [SURF_GRASS, SURF_CONCRETE, SURF_DIRT])
			_cluster(["fballoon", "fteacup", "fbench", "stall"], 26, _district_center(4), 12.0, [SURF_GRASS, SURF_CONCRETE, SURF_DIRT])
			_cluster(["teacups", "fpop", "lamp"], 12, _district_center(8), 11.0, [SURF_CONCRETE, SURF_GRASS])
			_cluster(["carousel", "bench", "planter"], 10, _district_center(2), 10.0, [SURF_GRASS, SURF_DIRT])
		_:
			_place_landmark("farmmill", [SURF_DIRT, SURF_GRASS, SURF_FIELD])
			_cluster(["redbarn", "haybale", "farmtractor", "railfence"], 18, _district_center(4), 13.0, [SURF_DIRT, SURF_GRASS, SURF_FIELD])
			_cluster(["fflower", "fwheat", "bush", "bench"], 22, _district_center(0), 12.0, [SURF_GRASS, SURF_FIELD])
			_cluster(["tree_large", "tree_small", "scare", "crate"], 16, _district_center(8), 12.0, [SURF_GRASS, SURF_DIRT])

func _place_landmark(id: String, surfs: Array) -> void:
	var spots: Array = [
		Vector3(18.0, 0.0, -16.0),
		Vector3(-18.0, 0.0, -18.0),
		Vector3(24.0, 0.0, 8.0),
		Vector3(-22.0, 0.0, 12.0),
	]
	for spot in spots:
		var p: Vector3 = spot
		if not _surf_ok(p, surfs):
			continue
		if _place_id(id, p, Vector3.ZERO, randf() * TAU, randf_range(0.96, 1.08)):
			return

func _border_ids(layout: String) -> Array:
	match layout:
		"candy":
			return ["tree_small", "planter", "lollypop", "lamp"]
		"jungle":
			return ["jpalm", "jpalmtall", "fernleaf", "tree_large"]
		"pirate":
			return ["ppalm", "pflag", "pbarrel", "tree_small"]
		"snow":
			return ["hpine", "tree_small", "hsnowman"]
		"desert":
			return ["dpalm", "dcactus", "dtallcac", "drock"]
		"toy":
			return ["tblock", "tree_small", "planter"]
		"space":
			return ["moonlet", "satdish", "spacecrate"]
		"haunt":
			return ["htree", "htomb", "hpumpkin", "tree_small"]
		"fair":
			return ["tree_large", "fballoon", "fbench", "lamp"]
		_:
			return ["tree_large", "tree_small", "railfence", "bush"]

func _dress_border() -> void:
	var ids: Array = _border_ids(str(map.get("layout", "farm")))
	var span := CITY_HALF - 2.4
	var cursor := -span
	while cursor < span and props.size() < PROP_CAP:
		var step := randf_range(5.4, 8.6)
		var grow := randf_range(0.88, 1.16)
		var id := str(ids[randi() % ids.size()])
		_try_border(id, Vector3(cursor, 0.0, -span), grow)
		_try_border(id, Vector3(cursor + step * 0.35, 0.0, span), grow)
		_try_border(id, Vector3(-span, 0.0, cursor), grow)
		_try_border(id, Vector3(span, 0.0, cursor + step * 0.2), grow)
		cursor += step

func _try_border(id: String, p: Vector3, grow: float) -> void:
	var surf := _surf_f(p.x, p.z)
	if surf == SURF_WATER or surf == SURF_ROAD:
		return
	_place_id(id, p, Vector3.ZERO, randf() * TAU, grow)

func _cluster(ids: Array, count: int, center: Vector3, radius: float, surfs: Array) -> void:
	var made := 0
	var tries := 0
	while made < count and tries < count * 16 and props.size() < PROP_CAP:
		tries += 1
		var ang := randf() * TAU
		var rad := radius * sqrt(randf())
		var p := center + Vector3(cos(ang) * rad, 0.0, sin(ang) * rad)
		if not _surf_ok(p, surfs) or _layout_blocked(p):
			continue
		var pick := str(ids[made % ids.size()])
		if _place_id(pick, p, Vector3.ZERO, randf() * TAU, randf_range(0.92, 1.08)):
			made += 1

func _overlap_foot(ki: int, sxz: float) -> float:
	var role := str(prop_defs[ki][5])
	if role in ["tree", "lamp", "palm", "umbrella"]:
		return maxf(float(kind_base[ki]) * sxz, 0.08)
	var native: Vector3 = kind_native[ki]
	return maxf(native.x, native.z) * sxz * 0.45

func _visual_half(ki: int) -> float:
	var native: Vector3 = kind_native[ki]
	return maxf(native.x, native.z) * 0.5

func _clone_kind(src: String, id: String, role: String, points: int, scale: float) -> void:
	if not kind_by_id.has(src) or kind_by_id.has(id):
		return
	var ki := int(kind_by_id[src])
	var spec: Array = (prop_defs[ki] as Array).duplicate()
	spec[2] = scale
	spec[3] = scale
	spec[4] = points
	spec[5] = role
	prop_defs.append(spec)
	kind_lists.append(_empty_slots())
	kind_meshes.append(kind_meshes[ki])
	kind_native.append(kind_native[ki])
	kind_base.append(kind_base[ki])
	kind_mats.append(kind_mats[ki])
	kind_multimeshes.append(null)
	kind_by_id[id] = prop_defs.size() - 1

func _clone_small_variants() -> void:
	var rows := [
		["fapple", "applegold", "small", 28, 1.0],
		["fapple", "applegreen", "small", 3, 0.9],
		["fflower", "floweryel", "small", 2, 0.85],
		["fflower", "flowerwht", "small", 2, 1.05],
		["fwheat", "wheatgold", "small", 3, 1.1],
		["lollypop", "lollyblue", "small", 4, 0.9],
		["lollypop", "lollygold", "small", 30, 1.15],
		["donut", "donutchoc", "small", 4, 0.95],
		["spottedegg", "eggblue", "small", 3, 0.9],
		["spottedegg", "egggold", "small", 32, 1.2],
		["fernleaf", "fernwide", "palm", 3, 1.25],
		["redshroom", "shroomgold", "small", 26, 1.15],
		["drock", "rockred", "small", 2, 1.1],
		["drock", "rockgold", "small", 28, 1.3],
		["tblock", "blockred", "small", 3, 1.05],
		["tblock", "blockgold", "small", 30, 1.2],
		["tball", "ballblue", "small", 2, 0.85],
		["fballoon", "balloonyel", "small", 3, 1.1],
		["hpresent", "giftgold", "small", 34, 1.25],
		["hpumpkin", "pumpkingold", "small", 36, 1.2],
		["pchest", "chestgold", "small", 40, 1.15],
		["moonlet", "meteorhot", "small", 8, 1.2],
		["satprobe", "probeamber", "small", 6, 0.9],
		["canecandy", "canegreen", "small", 4, 0.85],
		["gbread", "breadpink", "small", 5, 0.9],
		["iceblock", "iceblue", "small", 4, 0.8],
		["hsnowman", "snowtiny", "small", 6, 0.55],
		["dcactus", "cactusflower", "palm", 4, 0.8],
		["teddybear", "bearblue", "small", 8, 0.7],
		["fteacup", "cupgold", "small", 24, 1.15],
	]
	for row in rows:
		_clone_kind(str(row[0]), str(row[1]), str(row[2]), int(row[3]), float(row[4]))

func _normalize_footprints() -> void:
	# Swallow size tracks the mesh the player sees. A crown wider than `base`
	# sat inside the ring without falling. A trunk-only base ate a whole tree.
	for ki in prop_defs.size():
		var scale := maxf(float(prop_defs[ki][2]), 0.001)
		var visual := _visual_half(ki) * scale
		if visual < 0.02:
			continue
		var placed := float(kind_base[ki]) * scale
		var role := str(prop_defs[ki][5])
		var want := placed
		if role in ["tree", "palm"]:
			want = clampf(visual * 0.78, visual * 0.62, visual * 0.92)
		elif placed > visual * 1.12:
			want = visual * 0.96
		elif placed < visual * 0.22 and role in ["small", "clutter", "lamp", "umbrella"]:
			want = placed
		kind_base[ki] = maxf(want, 0.04) / scale

func _prop_metrics(id: String, grow: float) -> Dictionary:
	var ki: int = int(kind_by_id[id])
	var sxz := float(prop_defs[ki][2]) * grow
	var sy := float(prop_defs[ki][3]) * grow
	var native: Vector3 = kind_native[ki]
	return {
		"role": str(prop_defs[ki][5]),
		"base": float(kind_base[ki]) * sxz,
		"height": native.y * sy,
	}

func _is_snack(role: String, base: float, height: float) -> bool:
	if base > 0.72 or height > 1.55:
		return false
	return role in ["small", "clutter", "person"]

func _is_structure(role: String, base: float, height: float) -> bool:
	if role in ["barn", "tower", "building", "wide", "house", "landmark", "tank", "boat"]:
		return true
	if role == "stall" and height > 1.8:
		return true
	if role == "ride" and (height > 2.2 or base > 1.05):
		return true
	if role in ["tree", "palm"] and height > 2.4:
		return true
	return height > 2.8 or base > 1.45

func _blocks_horizon(role: String, base: float, height: float) -> bool:
	if _is_structure(role, base, height):
		return true
	return height > 1.75

func _view_angle(p: Vector3) -> float:
	if p.z > -8.0:
		return 4.0
	return absf(atan2(p.x, -p.z))

func _in_view_corridor(p: Vector3) -> bool:
	# Center of the opening view, where the horizon has to stay visible.
	if p.z > -8.0:
		return false
	return _view_angle(p) < 0.72 and Vector2(p.x, p.z).length() < 72.0

func _spawn_ok(id: String, p: Vector3, grow: float) -> bool:
	var m := _prop_metrics(id, grow)
	var role := str(m.role)
	var base := float(m.base)
	var height := float(m.height)
	var home := Vector2(p.x, p.z).length()
	if home < SPAWN_CLEAR and not _is_snack(role, base, height):
		return false
	var structure := _is_structure(role, base, height)
	if home < SPAWN_MID and structure:
		return false
	if _blocks_horizon(role, base, height):
		var ang := _view_angle(p)
		# Keep a narrow lane in front of the hole open. Larger props still
		# sit in the same neighborhoods as the small ones.
		if ang < 0.16 and home < 18.0:
			return false
		if ang < 0.55 and home < 58.0 and forward_tall >= 8:
			return false
	return true

func _place_id(id: String, p: Vector3, dir: Vector3 = Vector3.ZERO, yaw: float = -1.0, grow: float = 1.0, tint: Color = Color.WHITE, points: int = -1, mover: int = -1, allow: Array = [], opening: bool = false) -> bool:
	if props.size() >= PROP_CAP or not kind_by_id.has(id):
		return false
	if not treat_force and p.length() < (1.6 if opening else 2.15):
		return false
	if not opening and not treat_force and not _spawn_ok(id, p, grow):
		return false
	if absf(p.x) > CITY_HALF - 0.45 or absf(p.z) > CITY_HALF - 0.45:
		return false
	var surf := _surf_f(p.x, p.z)
	if surf == SURF_WATER or surf == SURF_TRACK:
		var allowed := false
		for a in allow:
			if surf == int(a):
				allowed = true
				break
		if not allowed:
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
	if not treat_force and not _road_drive(mover, allow):
		if surf == SURF_ROAD or not _clear_of_road(p, foot):
			return false
	if not treat_force and _overlaps(p, foot):
		return false
	var use_yaw := yaw if yaw >= 0.0 else randf() * TAU
	_add_prop(ki, p, dir, use_yaw, spec)
	if tint != Color.WHITE:
		props[props.size() - 1].color = tint
	var placed := _prop_metrics(id, grow)
	if _blocks_horizon(str(placed.role), float(placed.base), float(placed.height)) and _in_view_corridor(p):
		forward_tall += 1
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
	else:
		sxz *= randf_range(0.94, 1.08)
		sy *= randf_range(0.94, 1.08)
	var base := maxf(float(kind_base[ki]) * sxz, 0.05)
	if base > BASE_CAP:
		var cut := BASE_CAP / base
		sxz *= cut
		sy *= cut
		base = BASE_CAP
	var yaw_off := float(spec[7])
	var face := _face_offset(kind_id_of(ki))
	var yaw := yaw_in
	if dir.length_squared() > 0.001:
		yaw = atan2(dir.x, dir.z) + face + yaw_off
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
	elif mover == 4:
		spd = randf_range(0.4, 0.75)
	var tint := Color.WHITE
	var role := str(spec[5])
	var coat := _coat_for(kind_id_of(ki))
	if coat != Color.WHITE:
		tint = coat
	elif role in ["building", "wide", "house", "tower"]:
		var palette: Array = map.get("palette", [])
		if palette.is_empty():
			palette = [Color(0.76, 0.36, 0.36), Color(0.84, 0.70, 0.34), Color(0.36, 0.60, 0.64), Color(0.78, 0.48, 0.52), Color(0.40, 0.50, 0.72)]
		tint = palette[randi() % palette.size()]
		tint = Color(tint.r * randf_range(0.94, 1.06), tint.g * randf_range(0.94, 1.06), tint.b * randf_range(0.94, 1.06))
	else:
		tint = Color(randf_range(0.92, 1.08), randf_range(0.92, 1.08), randf_range(0.92, 1.08))
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
		"face": face,
		"route": -1,
		"prog": 0.0,
		"lane": 0.7,
		"wait": 0.0,
		"waited": false,
		"xform": xform,
		"in_mesh": true,
		"in_body": false,
		"alive": true,
		"body": null,
		"sink": -1,
		"faded": false,
		"uid": prop_seq,
		"phase": randf() * TAU,
		"lspd": randf_range(1.15, 2.35),
		"fadeable": role in ["building", "wide", "house", "tower", "barn", "ride", "tank", "bus", "boat", "truck", "landmark"],
	}
	prop_seq += 1
	o.pi = props.size()
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
	if mover == 2:
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
	var kid := kind_id_of(ki)
	var amp := _life_amp(kid)
	for c in SLOT_COUNT:
		var list: Array = slots[c]
		if list.is_empty():
			mms[c] = null
			continue
		any = true
		var mm := MultiMesh.new()
		mm.transform_format = MultiMesh.TRANSFORM_3D
		mm.use_colors = true
		if amp > 0.0:
			mm.use_custom_data = true
		mm.mesh = kind_meshes[ki]
		mm.instance_count = list.size()
		mm.visible_instance_count = list.size()
		for obj in list:
			mm.set_instance_transform(obj.index, obj.xform)
			mm.set_instance_color(obj.index, obj.color)
			if amp > 0.0:
				mm.set_instance_custom_data(obj.index, Color(amp, float(obj.phase), float(obj.lspd), 1.0))
		var inst := MultiMeshInstance3D.new()
		inst.multimesh = mm
		inst.material_override = kind_mats[ki]
		inst.custom_aabb = _chunk_aabb(c, -6.0, 36.0)
		# Keep the whole chunk once it is near the view. A distance cutoff
		# made props pop in during the opening seconds.
		inst.extra_cull_margin = 24.0
		_no_shadow(inst)
		_add_city(inst)
		mms[c] = mm
	kind_multimeshes[ki] = mms if any else null

func _wants_impostor(id: String) -> bool:
	return id in ["jpalm", "jpalmtall", "ppalm", "dpalm", "hpine", "htree"]

func _impostor_color(id: String) -> Color:
	if id == "htree":
		return Color(0.34, 0.3, 0.26)
	if id == "hpine":
		return Color(0.1, 0.4, 0.2)
	return Color(0.14, 0.52, 0.22)

func _card_quad(st: SurfaceTool, w: float, h: float, yaw: float, top: Color, bot: Color) -> void:
	var c := cos(yaw)
	var s := sin(yaw)
	var dx := c * w
	var dz := s * w
	var a := Vector3(-dx, 0.0, -dz)
	var b := Vector3(dx, 0.0, dz)
	var c0 := Vector3(dx, h, dz)
	var d := Vector3(-dx, h, -dz)
	var nrm := Vector3(-s, 0.72, c).normalized()
	var pts := [a, b, c0, a, c0, d]
	var cols := [bot, bot, top, bot, top, top]
	for i in pts.size():
		st.set_normal(nrm)
		st.set_color(cols[i])
		st.add_vertex(pts[i])
	var back := -nrm
	var pts_b := [a, d, c0, a, c0, b]
	var cols_b := [bot, top, top, bot, top, bot]
	for i in pts_b.size():
		st.set_normal(back)
		st.set_color(cols_b[i])
		st.add_vertex(pts_b[i])

func _cross_card(size: Vector3, col: Color) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var h := maxf(size.y, 0.5)
	var w := maxf(maxf(size.x, size.z) * 0.42, 0.25)
	var bot := Color(col.r * 0.45, col.g * 0.45, col.b * 0.42)
	_card_quad(st, w, h, 0.0, col, bot)
	_card_quad(st, w, h, PI * 0.5, col, bot)
	return st.commit()

func _build_impostors(ki: int, slots: Array, id: String) -> void:
	var mesh := _cross_card(kind_native[ki], _impostor_color(id))
	for c in SLOT_COUNT:
		if c >= STATIC_CHUNKS:
			continue
		var list: Array = slots[c]
		if list.is_empty():
			continue
		var mm := MultiMesh.new()
		mm.transform_format = MultiMesh.TRANSFORM_3D
		mm.use_colors = true
		mm.mesh = mesh
		mm.instance_count = list.size()
		mm.visible_instance_count = list.size()
		for obj in list:
			mm.set_instance_transform(obj.index, obj.xform)
			mm.set_instance_color(obj.index, obj.color)
		var inst := MultiMeshInstance3D.new()
		inst.multimesh = mm
		inst.material_override = kit_mat
		inst.custom_aabb = _chunk_aabb(c, -6.0, 36.0)
		inst.extra_cull_margin = 0.0
		inst.visibility_range_begin = 34.0
		inst.visibility_range_begin_margin = 10.0
		inst.visibility_range_fade_mode = GeometryInstance3D.VISIBILITY_RANGE_FADE_DISABLED
		_no_shadow(inst)
		_add_city(inst)

func _lod_end(role: String, id: String) -> float:
	if _wants_impostor(id):
		return 48.0
	if role == "clutter":
		return 22.0
	if role in ["building", "wide", "house", "tower", "barn", "ride", "tank", "boat", "landmark"]:
		return 0.0
	if role in ["tree", "palm", "lamp", "truck", "bus", "dumpster"]:
		return 56.0
	return 30.0

func _refresh_shadow_slide() -> void:
	# Soft contact discs, slid along the key light. Real shadow maps on the
	# city striped and cost too much on phones.
	var yaw := deg_to_rad(float(map.get("sun_yaw", 32.0))) if not map.is_empty() else deg_to_rad(32.0)
	var basis := Basis.from_euler(Vector3(deg_to_rad(-58.0), yaw, 0.0))
	var ray := -basis.z
	var flat := Vector3(ray.x, 0.0, ray.z)
	if flat.length_squared() < 0.0001:
		shadow_slide = Vector3(0.28, 0.0, 0.16)
	else:
		shadow_slide = flat.normalized() * 0.46

func _build_shadows() -> void:
	_refresh_shadow_slide()
	var sh := Shader.new()
	sh.code = """shader_type spatial;
render_mode unshaded, cull_disabled, depth_draw_never, shadows_disabled, blend_mix;
void fragment() {
	vec2 p = UV * 2.0 - 1.0;
	float d = dot(p, p);
	float a = smoothstep(1.05, 0.12, d);
	ALBEDO = vec3(0.06, 0.08, 0.1);
	ALPHA = a * 0.42;
}
"""
	var mat := ShaderMaterial.new()
	mat.shader = sh
	mat.render_priority = 1
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
	var s := float(o.size) * 2.45
	var basis := Basis()
	basis.x *= s
	basis.z *= s
	var at := Vector3(p.x, 0.055, p.z) + shadow_slide * clampf(float(o.size), 0.25, 2.4)
	return Transform3D(basis, at)

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
	sky_haze = Control.new()
	sky_haze.mouse_filter = Control.MOUSE_FILTER_IGNORE
	sky_haze.set_anchors_preset(Control.PRESET_TOP_WIDE)
	sky_haze.anchor_bottom = HAZE_FRAC
	sky_haze.offset_bottom = 0
	sky_haze.visible = false
	sky_haze.draw.connect(_draw_sky_haze)
	sky_haze.resized.connect(sky_haze.queue_redraw)
	ui.add_child(sky_haze)
	vignette = null
	var hud_ink := Color(0.14, 0.18, 0.30, 0.90)
	score_pill = _make_hud_panel(hud_ink, 22)
	score_pill.anchor_left = 0.0
	score_pill.anchor_right = 0.0
	score_pill.offset_left = 16
	score_pill.offset_right = 214
	score_pill.offset_top = 12
	score_pill.offset_bottom = 68
	score_pill.visible = false
	ui.add_child(score_pill)
	score_lbl = Label.new()
	score_lbl.set_anchors_preset(Control.PRESET_FULL_RECT)
	score_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	score_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	score_lbl.clip_text = true
	_style_hud(score_lbl, 28)
	score_pill.add_child(score_lbl)
	map_pill = _make_hud_panel(hud_ink, 22)
	map_pill.anchor_left = 1.0
	map_pill.anchor_right = 1.0
	map_pill.offset_left = -276
	map_pill.offset_right = -16
	map_pill.offset_top = 12
	map_pill.offset_bottom = 68
	map_pill.visible = false
	ui.add_child(map_pill)
	level_lbl = Label.new()
	level_lbl.set_anchors_preset(Control.PRESET_FULL_RECT)
	level_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	level_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	level_lbl.clip_text = true
	_style_hud(level_lbl, 26)
	map_pill.add_child(level_lbl)
	center_pill = _make_hud_panel(hud_ink, 26)
	center_pill.anchor_left = 0.5
	center_pill.anchor_right = 0.5
	center_pill.offset_left = -330
	center_pill.offset_right = 330
	center_pill.offset_top = 78
	center_pill.offset_bottom = 170
	center_pill.visible = false
	ui.add_child(center_pill)
	size_style = _hud_pill(Color(0.11, 0.16, 0.29, 0.96), 18)
	size_badge = Panel.new()
	size_badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	size_badge.add_theme_stylebox_override("panel", size_style)
	size_badge.position = Vector2(12, 12)
	size_badge.size = Vector2(150, 68)
	size_badge.pivot_offset = Vector2(75, 34)
	center_pill.add_child(size_badge)
	size_lbl = Label.new()
	size_lbl.text = "Size 1"
	size_lbl.set_anchors_preset(Control.PRESET_FULL_RECT)
	size_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	size_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	size_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_style_hud(size_lbl, 26)
	size_badge.add_child(size_lbl)
	clear_lbl = Label.new()
	clear_lbl.position = Vector2(196, 8)
	clear_lbl.size = Vector2(448, 42)
	clear_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	clear_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	clear_lbl.clip_text = true
	clear_lbl.text = "Clear the map  0% / 95%"
	_style_hud(clear_lbl, 24)
	center_pill.add_child(clear_lbl)
	clear_track = ColorRect.new()
	clear_track.position = Vector2(196, 56)
	clear_track.size = Vector2(448, 16)
	clear_track.color = Color(0.05, 0.07, 0.12, 0.72)
	clear_track.mouse_filter = Control.MOUSE_FILTER_IGNORE
	center_pill.add_child(clear_track)
	clear_fill = ColorRect.new()
	clear_fill.position = Vector2(2, 3)
	clear_fill.size = Vector2(0, 10)
	clear_fill.color = BRAND_CYAN
	clear_fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	clear_track.add_child(clear_fill)
	next_lbl = Label.new()
	next_lbl.anchor_left = 0.5
	next_lbl.anchor_right = 0.5
	next_lbl.offset_left = -340
	next_lbl.offset_right = 340
	next_lbl.offset_top = 178
	next_lbl.offset_bottom = 214
	next_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	next_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	next_lbl.visible = false
	next_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_style_hud(next_lbl, 22)
	ui.add_child(next_lbl)
	next_bg = ColorRect.new()
	next_bg.anchor_left = 0.5
	next_bg.anchor_right = 0.5
	next_bg.offset_left = -180
	next_bg.offset_right = 180
	next_bg.offset_top = 214
	next_bg.offset_bottom = 226
	next_bg.color = Color(0.05, 0.07, 0.12, 0.55)
	next_bg.visible = false
	next_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui.add_child(next_bg)
	next_fill = ColorRect.new()
	next_fill.position = Vector2(2, 2)
	next_fill.size = Vector2(0, 8)
	next_fill.color = Color(1.0, 0.45, 0.7)
	next_fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	next_bg.add_child(next_fill)
	combo_lbl = Label.new()
	combo_lbl.position = Vector2(160, 248)
	combo_lbl.size = Vector2(400, 56)
	combo_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	combo_lbl.visible = false
	_style(combo_lbl, 44)
	combo_lbl.modulate = Color(1, 0.86, 0.2)
	ui.add_child(combo_lbl)
	mile_pill = Panel.new()
	mile_pill.position = Vector2(170, 186)
	mile_pill.size = Vector2(380, 52)
	mile_pill.visible = false
	mile_pill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	mile_pill.add_theme_stylebox_override("panel", _ink_pill())
	ui.add_child(mile_pill)
	mile_lbl = Label.new()
	mile_lbl.position = Vector2(170, 186)
	mile_lbl.size = Vector2(380, 52)
	mile_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	mile_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	mile_lbl.visible = false
	mile_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_style_hud(mile_lbl, 32)
	mile_lbl.modulate = Color(1.0, 0.95, 0.72)
	ui.add_child(mile_lbl)
	kept_lbl = Label.new()
	kept_lbl.anchor_left = 0.5
	kept_lbl.anchor_right = 0.5
	kept_lbl.offset_left = -180
	kept_lbl.offset_right = 180
	kept_lbl.offset_top = 300
	kept_lbl.offset_bottom = 348
	kept_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	kept_lbl.visible = false
	kept_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	kept_lbl.text = "Kept going!"
	_style(kept_lbl, 28)
	kept_lbl.modulate = Color(1, 0.92, 0.45)
	ui.add_child(kept_lbl)
	name_lbl = Label.new()
	name_lbl.text = PLAYER_NAME
	name_lbl.size = Vector2(100, 28)
	name_lbl.visible = false
	name_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_style(name_lbl, 20)
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
	sha_lbl.visible = debug_on
	sha_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
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
		cap.position = Vector2(36, 236 + i * 96)
		cap.size = Vector2(588, 60)
		_style(cap, 28)
		cap.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		cap.add_theme_color_override("font_color", BRAND_INK)
		cap.add_theme_constant_override("outline_size", 0)
		result_card.add_child(cap)
		result_labels.append(cap)
		var track := ColorRect.new()
		track.position = Vector2(36, 286 + i * 96)
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
	so_close_lbl.position = Vector2(36, 512)
	so_close_lbl.size = Vector2(588, 48)
	so_close_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	so_close_lbl.visible = false
	_style(so_close_lbl, 40)
	so_close_lbl.add_theme_color_override("font_color", Color(0.75, 0.22, 0.16))
	so_close_lbl.add_theme_constant_override("outline_size", 0)
	result_card.add_child(so_close_lbl)
	double_btn = _make_button("Watch ad for 2x coins", Vector2(40, 596), Vector2(580, 76), Color(0.90, 0.62, 0.18), 32)
	double_btn.pressed.connect(_on_double_coins)
	result_card.add_child(double_btn)
	keep_btn = _make_button("Watch ad to keep going", Vector2(40, 680), Vector2(580, 72), Color(0.20, 0.48, 0.86), 30)
	keep_btn.pressed.connect(_on_keep_going)
	keep_btn.visible = false
	result_card.add_child(keep_btn)
	next_btn = _make_button("Next", Vector2(40, 760), Vector2(580, 124), Color(0.16, 0.66, 0.42), 52)
	next_btn.pressed.connect(_on_primary_result)
	result_card.add_child(next_btn)
	continue_btn = _make_button("Home", Vector2(40, 896), Vector2(580, 76), BRAND_INK, 32)
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
	drag_pill = Panel.new()
	drag_pill.anchor_left = 0.5
	drag_pill.anchor_right = 0.5
	drag_pill.anchor_top = 0.5
	drag_pill.anchor_bottom = 0.5
	drag_pill.offset_left = -280
	drag_pill.offset_right = 280
	drag_pill.offset_top = 168
	drag_pill.offset_bottom = 262
	drag_pill.visible = false
	drag_pill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	drag_pill.add_theme_stylebox_override("panel", _ink_pill())
	ui.add_child(drag_pill)
	drag_hint = Label.new()
	drag_hint.text = "Drag to move"
	drag_hint.anchor_left = 0.5
	drag_hint.anchor_right = 0.5
	drag_hint.anchor_top = 0.5
	drag_hint.anchor_bottom = 0.5
	drag_hint.offset_left = -340
	drag_hint.offset_right = 340
	drag_hint.offset_top = 150
	drag_hint.offset_bottom = 280
	drag_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	drag_hint.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	drag_hint.visible = false
	_style_hud(drag_hint, 72)
	ui.add_child(drag_hint)
	_refresh_hud()
	_build_unlock_popup()
	shot_path = OS.get_environment("HOLE_SHOT")
	if shot_path != "":
		shot_wait = 24

func _draw_guide() -> void:
	if guide_ui == null or not guide_on or cam == null:
		return
	var n := guide_targets.size()
	for i in n:
		_draw_marker(guide_targets[i], i, n)

func _draw_marker(target: Vector3, index: int, count: int) -> void:
	var world := target + Vector3(0.0, 1.4, 0.0)
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
		var side_nudge := Vector2(-dir.y, dir.x)
		pos += side_nudge * (float(index) - float(count - 1) * 0.5) * 34.0
	var tip := pos + dir * 28.0
	var side := Vector2(-dir.y, dir.x)
	var col := Color(1.0, 0.92, 0.35, 0.95).lerp(Color(1.0, 0.55, 0.2, 0.95), float(index) / 8.0)
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
	if name_lbl == null:
		return
	if cam == null or hole_mesh == null or not hole_mesh.visible or mode != "play" or not playing or paused:
		name_lbl.visible = false
		return
	var p := hole_pos + Vector3(0.0, 1.05, 0.0)
	if cam.is_position_behind(p):
		name_lbl.visible = false
		return
	var sp := cam.unproject_position(p)
	name_lbl.visible = true
	name_lbl.position = sp - Vector2(50, 30)

func _event_pos(event: InputEvent) -> Vector2:
	if event is InputEventMouseButton:
		return (event as InputEventMouseButton).position
	if event is InputEventMouseMotion:
		return (event as InputEventMouseMotion).position
	if event is InputEventScreenTouch:
		return (event as InputEventScreenTouch).position
	if event is InputEventScreenDrag:
		return (event as InputEventScreenDrag).position
	return Vector2(-1.0, -1.0)

func _rect_hit(ctrl: Control, pos: Vector2, pad: float) -> bool:
	if ctrl == null or not is_instance_valid(ctrl) or not ctrl.visible:
		return false
	return ctrl.get_global_rect().grow(pad).has_point(pos)

func _chrome_hit(pos: Vector2) -> bool:
	if pos.x < 0.0:
		return false
	if _rect_hit(pause_btn, pos, 10.0):
		return true
	if chrome_layer != null and chrome_layer.visible:
		if _rect_hit(daily_btn, pos, 10.0):
			return true
		if _rect_hit(play_btn, pos, 8.0):
			return true
		if _rect_hit(level_pill, pos, 8.0):
			return true
		for b in chrome_buttons:
			if _rect_hit(b as Control, pos, 16.0):
				return true
	return false

func _ui_hit(pos: Vector2) -> bool:
	if pos.x < 0.0:
		return false
	if pause_layer != null and pause_layer.visible:
		return true
	if menu_layer != null and menu_layer.visible:
		return true
	if over_panel != null and over_panel.visible:
		return true
	return _chrome_hit(pos)

func _blocks_world(pos: Vector2) -> bool:
	if ui_swallow_frames > 0:
		return true
	if _chrome_hit(pos):
		return true
	if paused or render_failed or (pause_layer != null and pause_layer.visible):
		return true
	if pause_btn != null and pause_btn.visible and pos.x >= 0.0 and pause_btn.get_global_rect().has_point(pos):
		return true
	if mode != "attract":
		return false
	var hovered := get_viewport().gui_get_hovered_control()
	if hovered == null or not hovered.is_visible_in_tree():
		return false
	if hovered.mouse_filter == Control.MOUSE_FILTER_IGNORE:
		return false
	var node: Node = hovered
	while node != null:
		if node is BaseButton or node == chrome_layer or node == menu_layer:
			return true
		node = node.get_parent()
	return false

func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch or event is InputEventMouseButton:
		if event.pressed:
			_unlock_audio()

func _unhandled_input(event: InputEvent) -> void:
	if ad_hold:
		return
	# A picker or menu sheet is up. A missed button must not fall through into a round.
	if menu_layer != null and menu_layer.visible and (event is InputEventMouseButton or event is InputEventScreenTouch or event is InputEventScreenDrag or event is InputEventMouseMotion):
		get_viewport().set_input_as_handled()
		ui_swallow_frames = 4
		joy_held = false
		return
	if block_start_until_up:
		var released := false
		if event is InputEventMouseButton:
			released = not (event as InputEventMouseButton).pressed
		elif event is InputEventScreenTouch:
			released = not (event as InputEventScreenTouch).pressed
		if released:
			block_start_until_up = false
			joy_held = false
			ui_swallow_frames = maxi(ui_swallow_frames, 8)
		return
	var pos := _event_pos(event)
	if (event is InputEventScreenTouch or event is InputEventScreenDrag) and _ui_hit(pos):
		get_viewport().set_input_as_handled()
		ui_swallow_frames = 4
		return
	if _blocks_world(pos):
		return
	if mode != "play" and mode != "attract":
		return
	if mode == "play" and not playing:
		return
	# Menu buttons consume the emulated mouse event. The raw touch arrives
	# first and would start a round from the same tap.
	if mode == "attract" and (event is InputEventScreenTouch or event is InputEventScreenDrag):
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
	elif web_steer and (event is InputEventMouseButton or event is InputEventMouseMotion):
		return
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		# Desktop clicks stay mouse events. Touch emulation was eating the first menu tap.
		if event.pressed:
			joy_held = true
			joy_id = -1
			joy_anchor = event.position
			joy_finger = event.position
		elif joy_id == -1:
			if mode == "attract" and joy_finger.distance_to(joy_anchor) <= JOY_DEADZONE:
				_begin_play()
			joy_held = false
		_refresh_joystick()
	elif event is InputEventMouseMotion and (event.button_mask & MOUSE_BUTTON_MASK_LEFT) != 0:
		# A desktop browser can drop the first mousedown while it focuses the
		# canvas. A held move still steers, same as a touch drag.
		if not joy_held or joy_id != -1:
			if _blocks_world(event.position):
				return
			joy_held = true
			joy_id = -1
			# relative is 0 on the web export, so it cannot rebuild the press point.
			joy_anchor = event.position
			joy_finger = event.position
		else:
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

func _screen_speed_factor(radius: float) -> float:
	# Stick speed stays on the 56 degree framing distance. Pulling the camera
	# back for the narrower lens must not make a full drag race across the map.
	var dist := _stick_dist_for_frac(maxf(radius, 0.12), _cam_frac_for(radius))
	var wide := maxf(_view_aspect() / (720.0 / 1280.0), 1.0)
	return pow(maxf(dist, 0.001) / STICK_REF_DIST, SPEED_SCREEN) * wide

func _size_ratio(radius: float) -> float:
	return maxf(radius, 0.12) / maxf(_start_radius(), 0.12)

func _size_speed_mul(radius: float) -> float:
	var bonus := SIZE_SPEED_K * (_size_ratio(radius) - 1.0)
	return 1.0 + clampf(bonus, -0.08, SIZE_SPEED_CAP)

func _move_speed() -> float:
	# Follow the eased radius so a size-up does not kick the stick ahead of the zoom.
	# The size term is a small extra on that framing speed, shared with rivals.
	return BASE_SPEED * speed_scale * Save.speed_mul() * _screen_speed_factor(shown_radius) * _size_speed_mul(shown_radius)

func _bot_food_fits(o: Dictionary) -> bool:
	if o.is_empty() or not bool(o.get("alive", false)):
		return false
	return _fits_r(float(o.get("base", 99.0)), hole_radius)

func _bot_food_ok(o: Dictionary) -> bool:
	# A perch already grabbed this prop. Keep the lock, but do not pick a new one.
	return _bot_food_fits(o) and not bool(o.get("in_body", false))

func _bot_food_cost(o: Dictionary) -> float:
	var d := _xz_dist(hole_pos, o.pos)
	if int(o.get("mover", 0)) != 0:
		d += 14.0
	if int(o.get("uid", -2)) == bot_avoid_uid:
		d += 36.0
	return d

func _bot_seek_food(reach: float) -> Dictionary:
	var pool: Array = _scan_buckets(hole_pos, reach) if reach > 0.0 else props
	var best: Dictionary = {}
	var best_c := INF
	for o in pool:
		if not _bot_food_ok(o):
			continue
		var c := _bot_food_cost(o)
		if c < best_c:
			best_c = c
			best = o
	return best

func _bot_food_aim() -> Vector3:
	var step := 1.0 / 60.0
	if _bot_food_fits(bot_lock):
		var locked := _xz_dist(hole_pos, bot_lock.pos)
		if locked + 0.2 < bot_best_d:
			bot_best_d = locked
			bot_stall = 0.0
		else:
			bot_stall += step
		if bot_stall > 1.6:
			bot_avoid_uid = int(bot_lock.get("uid", -1))
			bot_lock = {}
			bot_stall = 0.0
			bot_best_d = 999.0
	if not _bot_food_fits(bot_lock):
		var pick := _bot_seek_food(26.0)
		if pick.is_empty():
			pick = _bot_seek_food(0.0)
		bot_lock = pick
		bot_best_d = 999.0
		bot_stall = 0.0
	if not _bot_food_fits(bot_lock):
		bot_food_dist = -1.0
		return Vector3.ZERO
	var at: Vector3 = bot_lock.pos
	bot_food_dist = _xz_dist(hole_pos, at)
	return at - hole_pos

func _bot_heading(dir: Vector3) -> Vector3:
	var step := maxf(_move_speed() / 60.0, 0.2)
	var ahead := hole_pos + dir * step
	if _surf_f(ahead.x, ahead.z) != SURF_WATER:
		return dir
	var best := dir
	var best_s := -2.0
	for i in 7:
		var ang := float(i + 1) * PI / 8.0
		for sign in [-1.0, 1.0]:
			var cand := dir.rotated(Vector3.UP, ang * sign)
			var p := hole_pos + cand * step
			if _surf_f(p.x, p.z) == SURF_WATER:
				continue
			var score := cand.dot(dir)
			if score > best_s:
				best_s = score
				best = cand
	return best

func _bot_velocity() -> Vector3:
	var threat := Vector3.ZERO
	var threat_d := 9999.0
	var prey := Vector3.ZERO
	var prey_d := 9999.0
	for rival in rivals:
		if not bool(rival.alive):
			continue
		var d := _xz_dist(hole_pos, rival.pos)
		var rr := float(rival.radius)
		if player_invuln <= 0.0 and rr > hole_radius * EAT_RATIO and d < rr + 10.0:
			if d < threat_d:
				threat_d = d
				threat = rival.pos
		elif hole_radius > rr * EAT_RATIO and d < prey_d:
			prey_d = d
			prey = rival.pos
	var aim := Vector3.ZERO
	if threat_d < 9000.0:
		aim = hole_pos - threat
	elif prey_d < 9000.0:
		aim = prey - hole_pos
	else:
		aim = _bot_food_aim()
	if aim.length_squared() < 0.0001:
		aim = Vector3(cos(play_age * 0.7), 0.0, sin(play_age * 0.7))
	aim = _bot_heading(aim.normalized())
	return aim * _move_speed()

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
	if bot_drive:
		velocity = _bot_velocity()
	elif joy_held:
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

func _crit_damp(current: float, target: float, vel: float, smooth_time: float, delta: float) -> Vector2:
	# Critically damped spring. No overshoot, so a swallow cannot kick the zoom.
	smooth_time = maxf(smooth_time, 0.0001)
	var omega := 2.0 / smooth_time
	var x := omega * delta
	var expf := 1.0 / (1.0 + x + 0.48 * x * x + 0.235 * x * x * x)
	var change := current - target
	var temp := (vel + omega * change) * delta
	vel = (vel - omega * temp) * expf
	return Vector2(target + (change + temp) * expf, vel)

func _smooth_camera(delta: float) -> void:
	var sprung := _crit_damp(shown_radius, hole_radius, shown_vel, 0.45, delta)
	shown_radius = maxf(sprung.x, 0.05)
	shown_vel = sprung.y
	cam_distance = _cam_dist_for(shown_radius)
	if cam_dist_mul > 0.9:
		cam_pitch = _cam_pitch_for(shown_radius)
	if cam_hold or cam == null:
		return
	cam.fov = _cam_fov_for()
	cam_look = hole_pos + Vector3(0.0, cam_look_lift, 0.0)
	cam.position = hole_pos + _camera_offset(cam_distance)
	cam.look_at(cam_look, Vector3.UP)

func _fits(size: float) -> bool:
	return size < hole_radius * OPEN_FIT

func _mostly_over(size: float, dist: float) -> bool:
	return _center_in_opening(size, dist, hole_radius)

func _center_in_opening(size: float, dist: float, radius: float) -> bool:
	# Center is inside the opening. The lip inset is a small fraction of the
	# footprint, capped so it is less than one frame of travel.
	var lip := minf(size * 0.08, 0.04)
	return dist < radius - lip

func _clear_ratio() -> float:
	if clear_total <= 0:
		return 0.0
	return clampf(float(clear_eaten) / float(clear_total), 0.0, 1.0)

func _player_progress() -> float:
	if clear_total <= 0:
		return 0.0
	return clampf(_clear_ratio() / CLEAR_RATIO, 0.0, 1.0)

func _rival_progress(rival: Dictionary) -> float:
	var total := float(maxi(clear_total, 1))
	return clampf(float(rival.get("eaten", 0)) / (total * RIVAL_GROW), 0.0, 1.0)

func _growth_weight(progress: float) -> float:
	# Smooth and front-loaded. pow(t, exp) is 7/9 at 65% of the city, which is
	# 8x when the clear radius is 10x, and 1 at the clear.
	var t := clampf(progress, 0.0, 1.0)
	if t <= 0.0:
		return 0.0
	var eight_t := 0.65 / CLEAR_RATIO
	var exp := log(7.0 / 9.0) / log(eight_t)
	var base := pow(t, exp)
	# Extra lift in the first few percent of a clear. It has faded by the 8x mark.
	var early := 7.5 * t * exp(-t / 0.028)
	return clampf(base + early, 0.0, 1.0)

func _radius_for(start_r: float, progress: float, cap: float = -1.0) -> float:
	var end_r := final_radius if cap < 0.0 else cap
	end_r = maxf(end_r, start_r + 0.2)
	return lerpf(start_r, end_r, _growth_weight(progress))

func _size_index(progress: float) -> int:
	var w := _growth_weight(progress)
	var steps := 7
	var n := 0
	for i in range(1, steps):
		if w + 0.0001 >= float(i) / float(steps):
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
	var start := _start_radius()
	var fit_need := map_max_base / FIT_RATIO * 1.04
	final_radius = maxf(start * GROW_MULTIPLE, fit_need)
	rival_radius_bonus = 0.0

func _sync_level() -> void:
	if feet_lock:
		return
	var progress := _player_progress()
	var n := _size_index(progress)
	var grew := n > level
	if grew:
		level = n
		size_banner_t = 1.15
		kept_pulse = false
		if playing:
			_toast("Size %d!" % (level + 1))
		_sfx("fanfare", 1.0, false)
		if size_lbl:
			size_lbl.text = "Size %d" % (level + 1)
	if not latency_probe:
		var start_r := _start_radius()
		var curve := maxf(_radius_for(start_r, progress), start_r)
		var cap := final_radius
		# Rival bites can nudge the hole, but not past 8x before two-thirds
		# of the clear, and not past the 10x clear radius.
		if progress < 0.65 / CLEAR_RATIO:
			cap = minf(cap, start_r * 8.0)
		hole_radius = minf(curve + rival_radius_bonus, cap)
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
		var inner := maxf(clear_track.size.x - 4.0, 0.0)
		var toward := clampf(clear_shown / CLEAR_RATIO, 0.0, 1.0)
		clear_fill.size = Vector2(inner * toward, maxf(clear_track.size.y - 6.0, 4.0))
	if clear_lbl:
		clear_lbl.text = _clear_caption()
	guide_wait = maxf(0.0, guide_wait - delta)
	if guide_wait <= 0.0:
		guide_wait = 0.15
		_update_guide()

func _clear_caption() -> String:
	var pct := int(round(clear_shown * 100.0))
	var goal := int(round(CLEAR_RATIO * 100.0))
	if clear_total > 0 and clear_shown + 0.001 >= CLEAR_RATIO:
		return "Map clear"
	var remain := maxi(clear_total - clear_eaten, 0)
	if playing and remain > 0 and _clear_ratio() >= 0.88:
		return "Clear the map  %d%% / %d%%   %d left" % [pct, goal, remain]
	return "Clear the map  %d%% / %d%%" % [pct, goal]

func _update_guide() -> void:
	var was := guide_on
	guide_on = false
	guide_targets.clear()
	if guide_ui == null or not playing:
		if guide_ui and was:
			guide_ui.queue_redraw()
		return
	var remain := clear_total - clear_eaten
	if remain <= 0 or (remain > 36 and _clear_ratio() < 0.90):
		if was:
			guide_ui.queue_redraw()
		return
	var best: Array = []
	for o in props:
		if not bool(o.alive):
			continue
		var d := _xz_dist(hole_pos, o.pos)
		var at: Vector3 = o.pos
		var placed := false
		for i in best.size():
			if d < float(best[i].d):
				best.insert(i, {"d": d, "at": at})
				placed = true
				break
		if not placed and best.size() < 8:
			best.append({"d": d, "at": at})
		if best.size() > 8:
			best.resize(8)
	if best.is_empty():
		if was:
			guide_ui.queue_redraw()
		return
	for item in best:
		guide_targets.append(item.at)
	guide_target = guide_targets[0]
	guide_on = true
	guide_ui.queue_redraw()

func _refresh_hud() -> void:
	if score_lbl:
		score_lbl.text = "%d pts" % score
	if level_lbl:
		level_lbl.text = str(map.get("name", ""))
	if size_lbl:
		size_lbl.text = "Size %d" % (level + 1)
	if clear_lbl:
		clear_lbl.text = _clear_caption()
	_refresh_next_skin()
	if combo_lbl:
		combo_lbl.visible = combo >= 2 and combo_left > 0.0
		combo_lbl.text = "Combo x%.1f" % _combo_mult()
	shown_score = score
	shown_level = level

func _wake_goal() -> void:
	goal_until_ms = Time.get_ticks_msec() + int(GOAL_HOLD * 1000.0)
	goal_hold = GOAL_HOLD
	if next_lbl:
		next_lbl.modulate.a = 1.0
	if next_bg:
		next_bg.modulate.a = 1.0

func _skin_goal_banner(p: Dictionary) -> String:
	var label := str(p.get("label", "Challenge"))
	var cur := int(p.get("cur", 0))
	var need := maxi(int(p.get("need", 1)), 1)
	if str(p.get("unit", "")) == "" or need <= 1:
		return "Skin goal: %s" % label
	return "Skin goal: %s %s / %s" % [label, _grouped(mini(cur, need)), _grouped(need)]

func _refresh_next_skin() -> void:
	if next_lbl == null:
		return
	if not match_hud:
		next_lbl.visible = false
		if next_bg:
			next_bg.visible = false
		if next_fill:
			next_fill.visible = false
		return
	var nxt: Dictionary = Save.next_skin()
	if nxt.is_empty():
		next_lbl.visible = false
		if next_bg:
			next_bg.visible = false
		if next_fill:
			next_fill.visible = false
		return
	var skin: Dictionary = nxt.skin
	var prog: Dictionary = nxt.progress
	var line := _skin_goal_banner(prog)
	var key := "%s|%d" % [line, int(round(float(prog.ratio) * 100.0))]
	if key != goal_seen:
		goal_seen = key
		_wake_goal()
	next_lbl.visible = true
	next_lbl.text = line
	if next_bg:
		next_bg.visible = true
	if next_fill:
		next_fill.visible = true
		var track := next_fill.get_parent() as ColorRect
		var inner := 400.0
		if track:
			inner = maxf(track.size.x - 4.0, 0.0)
		next_fill.size = Vector2(inner * float(prog.ratio), next_fill.size.y)
		next_fill.color = skin.a

func _tick_goal(_delta: float) -> void:
	if not match_hud:
		return
	# The cover can sit up for a few seconds. The 3 seconds start when the round is visible.
	if round_cover != null and round_cover.visible:
		_wake_goal()
		return
	_refresh_next_skin()
	if next_lbl == null or not next_lbl.visible:
		return
	var left := float(goal_until_ms - Time.get_ticks_msec()) / 1000.0
	goal_hold = maxf(left, 0.0)
	var alpha := 1.0
	if left < GOAL_FADE:
		alpha = clampf(left / GOAL_FADE, 0.0, 1.0)
	next_lbl.modulate.a = alpha
	if next_bg:
		next_bg.modulate.a = alpha

func _tick_feedback(delta: float) -> void:
	if combo_left > 0.0:
		combo_left = maxf(0.0, combo_left - delta)
		if combo_left <= 0.0 and combo_lbl:
			combo_lbl.visible = false
	if mile_t > 0.0:
		mile_t = maxf(0.0, mile_t - delta)
		var mile_a := 1.0 if mile_t > 0.4 else clampf(mile_t / 0.4, 0.0, 1.0)
		if mile_lbl:
			mile_lbl.modulate.a = mile_a
			mile_lbl.visible = mile_t > 0.02 and match_hud
		if mile_pill:
			mile_pill.modulate.a = mile_a
			mile_pill.visible = mile_t > 0.02 and match_hud
	if size_badge:
		if size_banner_t > 0.0 and match_hud:
			size_banner_t = maxf(0.0, size_banner_t - delta)
			var u := clampf(size_banner_t / 1.45, 0.0, 1.0)
			var pop := 1.0 + u * 0.16
			size_badge.scale = Vector2(pop, pop)
			if size_style:
				var ink := Color(0.11, 0.16, 0.29).lerp(Color(0.92, 0.62, 0.12), u)
				ink.a = 0.96
				size_style.bg_color = ink
			if kept_lbl:
				kept_lbl.visible = kept_pulse and u > 0.04
				kept_lbl.modulate.a = u
		else:
			size_banner_t = 0.0
			size_badge.scale = Vector2.ONE
			if size_style:
				size_style.bg_color = Color(0.11, 0.16, 0.29, 0.96)
			if kept_lbl:
				kept_lbl.visible = false
			kept_pulse = false
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

func _rival_spawn_radius(i: int) -> float:
	var start_r := maxf(_start_radius(), 0.2)
	var span := maxf(RIVAL_RADIUS[RIVAL_RADIUS.size() - 1] - RIVAL_RADIUS[0], 0.001)
	var u := clampf((RIVAL_RADIUS[i] - RIVAL_RADIUS[0]) / span, 0.0, 1.0)
	var t := _rival_diff()
	var lo := lerpf(1.10, 1.16, t)
	var hi := lerpf(1.18, 1.22, t)
	return start_r * lerpf(lo, hi, u)

func _spawn_rivals() -> void:
	rivals.clear()
	var n := RIVAL_NAMES.size()
	for i in n:
		var ang := TAU * float(i) / float(n) + 0.41
		var ring := 38.0 + float(i % 6) * 6.5
		var spot := Vector3(cos(ang) * ring, 0.0, sin(ang) * ring)
		var guard := 0
		while _surf_f(spot.x, spot.z) == SURF_WATER and guard < 8:
			ang += 0.55
			spot = Vector3(cos(ang) * ring, 0.0, sin(ang) * ring)
			guard += 1
		var rad := _rival_spawn_radius(i)
		rivals.append({
			"name": RIVAL_NAMES[i],
			"color": RIVAL_COLORS[i],
			"pos": spot,
			"radius": rad,
			"shown": rad,
			"base_radius": rad,
			"speed": RIVAL_SPEED[i],
			"score": 0,
			"eaten": 0,
			"alive": true,
			"respawn": 0.0,
			"wander": ang + 1.7,
			"aim": Vector3(cos(ang + 2.0), 0.0, sin(ang + 2.0)),
			"think": randf() * 0.2,
			"pulse": 0.0,
			"grace": 2.4,
			"fleeing": false,
			"band_debt": 0.0,
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
		rival.grace = maxf(0.0, float(rival.get("grace", 0.0)) - delta)
		rival.think = float(rival.think) - delta
		var threatened := _rival_threatened(rival)
		if float(rival.think) <= 0.0 or threatened:
			if not threatened:
				rival.think = _rival_think_time() + randf() * 0.05
			else:
				rival.think = 0.12
			var nxt_aim := _rival_aim(i)
			var prev_aim: Vector3 = rival.aim
			var blend := 0.92 if threatened else lerpf(0.42, 0.78, _rival_diff())
			if prev_aim.length_squared() < 0.0001:
				rival.aim = nxt_aim
			else:
				var mixed := prev_aim.lerp(nxt_aim, blend)
				rival.aim = mixed.normalized() if mixed.length_squared() > 0.0001 else nxt_aim
		var aim: Vector3 = rival.aim
		if aim.length_squared() < 0.0001:
			aim = Vector3(1.0, 0.0, 0.0)
		var pos: Vector3 = rival.pos
		var step := aim.normalized() * _rival_move_speed(rival) * delta
		var nxt := pos + step
		if _surf_f(nxt.x, nxt.z) == SURF_WATER:
			var side := step.rotated(Vector3.UP, PI * 0.5)
			if _surf_f((pos + side).x, (pos + side).z) != SURF_WATER:
				nxt = pos + side
			elif _surf_f((pos - side).x, (pos - side).z) != SURF_WATER:
				nxt = pos - side
			else:
				nxt = pos
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
		_rival_catchup(rival, delta)
	_resolve_eats()

func _rival_diff() -> float:
	return clampf(float(map_index) / 9.0, 0.0, 1.0)

func _rival_think_time() -> float:
	return lerpf(0.62, 0.30, _rival_diff())

func _rival_threatened(rival: Dictionary) -> bool:
	var radius := float(rival.radius)
	if hole_radius <= radius * 1.08:
		return false
	return _xz_dist(rival.pos, hole_pos) < hole_radius + lerpf(16.0, 22.0, _rival_diff())

func _rival_move_speed(rival: Dictionary) -> float:
	# Same size curve as the player, on this rival's radius. The screen factor
	# stays the player's, so a small hole is not several times slower just
	# because the camera has pulled back. Pace and cruise stay within a few
	# percent. Size is what lets a bigger hole catch a smaller one.
	var pace := lerpf(0.98, 1.02, clampf((float(rival.get("speed", 2.2)) - 2.05) / 0.40, 0.0, 1.0))
	var speed := BASE_SPEED * speed_scale * Save.speed_mul() * _screen_speed_factor(shown_radius) * _size_speed_mul(float(rival.radius)) * pace
	if not bool(rival.get("fleeing", false)):
		speed *= lerpf(0.97, 0.99, _rival_diff())
	return speed

func _rival_avoid(i: int) -> Vector3:
	var rival: Dictionary = rivals[i]
	var pos: Vector3 = rival.pos
	var radius := float(rival.radius)
	var push := Vector3.ZERO
	for j in rivals.size():
		if j == i or not bool(rivals[j].alive):
			continue
		var other: Dictionary = rivals[j]
		var other_r := float(other.radius)
		if radius > other_r * EAT_RATIO or other_r > radius * EAT_RATIO:
			continue
		var gap := _xz_dist(pos, other.pos)
		if gap < 3.2 and gap > 0.001:
			var away: Vector3 = pos - other.pos
			push += away.normalized() * ((3.2 - gap) / 3.2)
	if push.length_squared() < 0.0001:
		return Vector3.ZERO
	return push.normalized()

func _rival_cluster_aim(pos: Vector3, radius: float, sense: float) -> Vector3:
	var bins := {}
	var x0 := int(floor((pos.x - sense) / 4.0))
	var x1 := int(floor((pos.x + sense) / 4.0))
	var z0 := int(floor((pos.z - sense) / 4.0))
	var z1 := int(floor((pos.z + sense) / 4.0))
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
				if fd > sense or fd < 0.04:
					continue
				var bk := int(floor(float(o.pos.x) / 6.0)) * 128 + int(floor(float(o.pos.z) / 6.0))
				if not bins.has(bk):
					bins[bk] = [0, Vector3.ZERO]
				var rec: Array = bins[bk]
				rec[0] = int(rec[0]) + 1
				rec[1] = (rec[1] as Vector3) + (o.pos as Vector3)
	var best := -1.0
	var at := Vector3.ZERO
	var found := false
	for bk in bins:
		var rec2: Array = bins[bk]
		var n := int(rec2[0])
		if n <= 0:
			continue
		var centroid: Vector3 = (rec2[1] as Vector3) / float(n)
		var d := _xz_dist(pos, centroid)
		var score := float(n) / pow(1.4 + d, 1.12)
		if score > best:
			best = score
			at = centroid
			found = true
	if not found:
		return Vector3.ZERO
	var bite := at - pos
	bite.y = 0.0
	if bite.length_squared() < 0.0001:
		return Vector3.ZERO
	return bite.normalized()

func _steer_blend(primary: Vector3, extra: Vector3, extra_w: float) -> Vector3:
	var mixed := primary + extra * extra_w
	if mixed.length_squared() < 0.0001:
		if primary.length_squared() > 0.0001:
			return primary.normalized()
		return Vector3(1.0, 0.0, 0.0)
	return mixed.normalized()

func _rival_aim(i: int) -> Vector3:
	var rival: Dictionary = rivals[i]
	var pos: Vector3 = rival.pos
	var radius := float(rival.radius)
	var t := _rival_diff()
	var grace := float(rival.get("grace", 0.0)) > 0.0
	var flee_ratio := lerpf(1.08, 1.05, t)
	var flee_extra := lerpf(16.0, 22.0, t)
	var chase_ratio := lerpf(1.34, 1.18, t)
	var chase_range := lerpf(4.2, 8.2, t)
	var sense := lerpf(8.5, 16.0, t)
	var band := _rival_band(rival)
	if band > 1.15:
		sense *= lerpf(1.0, 1.45, clampf((band - 1.15) / 1.0, 0.0, 1.0))
	var avoid := _rival_avoid(i)
	var flee_from := Vector3.ZERO
	var fleeing := false
	var flee_d := 999.0
	if hole_radius > radius * flee_ratio:
		var d := _xz_dist(pos, hole_pos)
		if d < hole_radius + flee_extra and d < flee_d:
			flee_d = d
			flee_from = hole_pos
			fleeing = true
	for j in rivals.size():
		if j == i or not bool(rivals[j].alive):
			continue
		var other: Dictionary = rivals[j]
		if float(other.radius) <= radius * flee_ratio:
			continue
		var od := _xz_dist(pos, other.pos)
		if od < float(other.radius) + flee_extra and od < flee_d:
			flee_d = od
			flee_from = other.pos
			fleeing = true
	rival.fleeing = fleeing
	if fleeing:
		var away := pos - flee_from
		if away.length_squared() < 0.01:
			away = Vector3(1.0, 0.0, 0.0)
		return _steer_blend(away, avoid, 0.35)
	if not grace:
		var chase_at := Vector3.ZERO
		var chasing := false
		var chase_d := 999.0
		if player_invuln <= 0.0 and radius > hole_radius * chase_ratio:
			var pd := _xz_dist(pos, hole_pos)
			if pd < chase_range and pd < chase_d:
				chase_d = pd
				chase_at = hole_pos
				chasing = true
		for j in rivals.size():
			if j == i or not bool(rivals[j].alive):
				continue
			var other2: Dictionary = rivals[j]
			if radius <= float(other2.radius) * chase_ratio:
				continue
			var cd := _xz_dist(pos, other2.pos)
			if cd < chase_range and cd < chase_d:
				chase_d = cd
				chase_at = other2.pos
				chasing = true
		if chasing:
			var toward := chase_at - pos
			if toward.length_squared() > 0.0001:
				return _steer_blend(toward, avoid, 0.25)
	rival.fleeing = false
	var food := _rival_cluster_aim(pos, radius, sense)
	if food.length_squared() > 0.0001:
		return _steer_blend(food, avoid, 0.85)
	rival.wander = float(rival.wander) + randf_range(-0.7, 0.7)
	var wander := Vector3(cos(float(rival.wander)), 0.0, sin(float(rival.wander)))
	return _steer_blend(wander, avoid, 0.6)

func _separate_hole(pos: Vector3, radius: float, ignore: int) -> Vector3:
	var out := pos
	var can_eat_player := radius > hole_radius * EAT_RATIO
	var player_can_eat := hole_radius > radius * EAT_RATIO
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
		var bigger := radius > other_r * EAT_RATIO or other_r > radius * EAT_RATIO
		var need := radius + other_r + 0.35
		if not bigger and _xz_dist(out, other.pos) < need:
			var push2: Vector3 = out - other.pos
			if push2.length_squared() < 0.0001:
				push2 = Vector3(0.0, 0.0, 1.0)
			out = other.pos + push2.normalized() * (need + 0.05)
	return out

func _swallow_reach(eater_r: float, prey_r: float) -> float:
	# The player swallows a rival at 0.72 of the eater radius. A rival swallows
	# the player on that same depth, or once the player's center is inside the
	# rival by half the player radius, whichever reaches farther. A small lip
	# still counts a center that has crossed into the rival hole.
	var deep := eater_r - prey_r * 0.5
	var inside := eater_r - minf(prey_r * 0.12, 0.4)
	return maxf(eater_r * 0.72, maxf(deep, inside))

func _resolve_player_threat() -> void:
	if not playing or player_invuln > 0.0:
		return
	for rival in rivals:
		if not playing:
			return
		if not bool(rival.alive):
			continue
		var rr := float(rival.radius)
		if rr < hole_radius * EAT_RATIO:
			continue
		var dist := _xz_dist(hole_pos, rival.pos)
		if dist < _swallow_reach(rr, hole_radius):
			_rival_eats_player(rival)
			return

func _resolve_eats() -> void:
	if not playing:
		return
	_resolve_player_threat()
	if not playing:
		return
	var i := 0
	while i < rivals.size() and playing:
		var rival: Dictionary = rivals[i]
		if bool(rival.alive):
			var dist := _xz_dist(hole_pos, rival.pos)
			if hole_radius > float(rival.radius) * EAT_RATIO and dist < hole_radius * 0.72:
				_player_eats_rival(rival)
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
			if float(left.radius) > float(right.radius) * EAT_RATIO and gap < float(left.radius) * 0.72:
				_credit_rival(left, 6 + int(float(right.radius) * 4.0))
				left.pulse = 0.18
				_kill_rival(right)
			elif float(right.radius) > float(left.radius) * EAT_RATIO and gap < float(right.radius) * 0.72:
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
	_grant_rival_growth()
	_sync_level()
	_burst(rival.pos, bonus, rival.color, "Bonus +%d" % bonus)
	_feel(bonus, true, false)
	_sfx("sting_win", 1.0, true)
	rivals_bitten[str(rival.name)] = true
	_announce_skins(Save.note_rival_eat())
	_refresh_hud()
	rival_bites += 1
	_kill_rival(rival)

func _rival_eats_player(rival: Dictionary) -> void:
	_sfx("sting_lose", 1.0, false)
	_present_eaten(str(rival.name))

func _kill_rival(rival: Dictionary) -> void:
	rival.alive = false
	rival.respawn = 2.1
	rival.pulse = 0.0

func _respawn_rival(rival: Dictionary) -> void:
	var ang := randf() * TAU
	var ring := 16.0 + randf() * 42.0
	var pos := Vector3(cos(ang) * ring, 0.0, sin(ang) * ring)
	var guard := 0
	while _surf_f(pos.x, pos.z) == SURF_WATER and guard < 6:
		ring *= 0.7
		pos = Vector3(cos(ang) * ring, 0.0, sin(ang) * ring)
		guard += 1
	rival.pos = pos
	var live := maxf(hole_radius, 0.2)
	var restart := live * randf_range(1.04, 1.14)
	restart = minf(restart, live * (EAT_RATIO - 0.03))
	rival.radius = restart
	rival.shown = restart
	rival.base_radius = restart
	rival.score = 0
	rival.eaten = 0
	rival.band_debt = 0.0
	rival.fleeing = false
	rival.alive = true
	rival.wander = ang
	rival.aim = Vector3(cos(ang), 0.0, sin(ang))
	rival.grace = 1.6
	rival.think = _rival_think_time()

func _rival_band(rival: Dictionary) -> float:
	var rr := maxf(float(rival.get("radius", 0.2)), 0.05)
	var ratio := hole_radius / rr
	if ratio >= 1.18:
		return lerpf(1.8, 7.5, clampf((ratio - 1.18) / 0.7, 0.0, 1.0))
	if ratio <= 0.82:
		return lerpf(0.65, 0.28, clampf((0.82 - ratio) / 0.28, 0.0, 1.0))
	return 1.0

func _rival_catchup(rival: Dictionary, delta: float) -> void:
	# Pull a rival toward just under the eat line when the player pulls ahead.
	# The rate lags, so a good run can still open an 18 percent lead.
	var rr := maxf(float(rival.get("radius", 0.2)), 0.05)
	# Early on, hold rivals just under the eat line. The hold relaxes so a
	# steady player can open a lead in the first minute, sooner on later levels.
	var guard_t := lerpf(32.0, 48.0, _rival_diff())
	var lead := 1.10
	if play_age > guard_t:
		lead = lerpf(1.10, 1.24, clampf((play_age - guard_t) / 36.0, 0.0, 1.0))
	var goal := hole_radius / lead
	if rr >= goal:
		return
	var gap := (goal - rr) / goal
	var rate := lerpf(10.0, 48.0, clampf(gap / 0.35, 0.0, 1.0))
	var debt := float(rival.get("catch_debt", 0.0)) + rate * delta
	var whole := int(floor(debt))
	rival.catch_debt = debt - float(whole)
	if whole <= 0:
		return
	rival.eaten = int(rival.get("eaten", 0)) + whole
	rival.score = int(rival.score) + whole
	_apply_rival_radius(rival)

func _credit_rival(rival: Dictionary, bites: int) -> void:
	var gained := float(maxi(bites, 1)) * _rival_band(rival)
	var debt := float(rival.get("band_debt", 0.0)) + gained
	var whole := int(floor(debt))
	rival.band_debt = debt - float(whole)
	if whole <= 0:
		return
	rival.eaten = int(rival.get("eaten", 0)) + whole
	rival.score = int(rival.score) + whole
	_apply_rival_radius(rival)

func _apply_rival_radius(rival: Dictionary) -> void:
	var start_r := float(rival.get("base_radius", 0.34))
	var cap := minf(final_radius * RIVAL_CAP, maxf(start_r * GROW_MULTIPLE, start_r + 0.2))
	var rad := _radius_for(start_r, _rival_progress(rival), cap)
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

func _grant_rival_growth() -> void:
	# One rival is about one or two mid bites: enough to see, not a size tier.
	var start_r := maxf(_start_radius(), 0.12)
	var progress := _player_progress()
	var curve := maxf(_radius_for(start_r, progress), start_r)
	var cap := final_radius
	if progress < 0.65 / CLEAR_RATIO:
		cap = minf(cap, start_r * 8.0)
	var bite := clampf(hole_radius * 0.06, 0.06, 0.15)
	var room := cap - curve - rival_radius_bonus
	if room <= 0.0:
		return
	rival_radius_bonus += minf(bite, room)

func _tag_limits(tag: Label) -> Rect2:
	var vp := get_viewport().get_visible_rect().size
	var left := SAFE_SIDE
	var top := HUD_TAG_MIN_Y
	var right := maxf(left + 4.0, vp.x - SAFE_SIDE - tag.size.x)
	var bottom := maxf(top + 4.0, vp.y - SAFE_BOTTOM - 96.0 - tag.size.y)
	return Rect2(left, top, right - left, bottom - top)

func _tag_on_edge(bounds: Rect2, dir: Vector2) -> Vector2:
	var center := bounds.position + bounds.size * 0.5
	var t := 100000.0
	if absf(dir.x) > 0.0001:
		var tx := ((bounds.position.x - center.x) / dir.x) if dir.x < 0.0 else ((bounds.end.x - center.x) / dir.x)
		if tx > 0.0:
			t = minf(t, tx)
	if absf(dir.y) > 0.0001:
		var ty := ((bounds.position.y - center.y) / dir.y) if dir.y < 0.0 else ((bounds.end.y - center.y) / dir.y)
		if ty > 0.0:
			t = minf(t, ty)
	var at := center + dir * t
	return Vector2(
		clampf(at.x, bounds.position.x, bounds.end.x),
		clampf(at.y, bounds.position.y, bounds.end.y)
	)

func _place_rival_tag(tag: Label, world: Vector3, who: String) -> Dictionary:
	var vp := get_viewport().get_visible_rect().size
	var limits := _tag_limits(tag)
	var behind := cam.is_position_behind(world)
	var raw := cam.unproject_position(world)
	var sp := raw - Vector2(tag.size.x * 0.5, 46.0)
	var off := behind or sp.x < limits.position.x - 8.0 or sp.y < limits.position.y - 8.0 or sp.x > limits.end.x + 8.0 or sp.y > limits.end.y + 8.0
	if not off:
		tag.text = who
		return {
			"at": Vector2(
				clampf(sp.x, limits.position.x, limits.end.x),
				clampf(sp.y, limits.position.y, limits.end.y)
			),
			"edge": false,
		}
	var dir := raw - vp * 0.5
	if behind:
		dir = -dir
	if dir.length_squared() < 1.0:
		dir = Vector2(1.0, 0.0)
	dir = dir.normalized()
	if absf(dir.x) >= absf(dir.y):
		tag.text = ("< " + who) if dir.x < 0.0 else (who + " >")
	elif dir.y < 0.0:
		tag.text = "^ " + who
	else:
		tag.text = who + " v"
	return {"at": _tag_on_edge(limits, dir), "edge": true}

func _sync_rival_visuals() -> void:
	if rival_mm == null:
		return
	var shown: Array = []
	var edges: Array = []
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
		if s < 0.05 or cam == null:
			tag.visible = false
		else:
			var placed: Dictionary = _place_rival_tag(tag, above, str(rival.name))
			var at: Vector2 = placed.at
			tag.position = at
			var dist := cam.global_position.distance_squared_to(rival.pos)
			var item := {"i": i, "d": dist, "p": at}
			if bool(placed.edge):
				tag.visible = false
				edges.append(item)
			else:
				tag.visible = true
				shown.append(item)
	shown.sort_custom(func(a, b): return float(a.d) < float(b.d))
	var kept: Array = []
	var tag_size := Vector2(220, 48)
	for item in shown:
		var sp: Vector2 = item.p
		var rect := Rect2(sp, tag_size)
		var clash := false
		for prev in kept:
			if (prev as Rect2).grow(10.0).intersects(rect):
				clash = true
				break
		var tag: Label = rival_labels[int(item.i)]
		if clash:
			tag.visible = false
		else:
			kept.append(rect)
	edges.sort_custom(func(a, b): return float(a.d) < float(b.d))
	var edge_n := 0
	var edge_used: Array = []
	for item in edges:
		var tag: Label = rival_labels[int(item.i)]
		if edge_n >= EDGE_MARKERS:
			tag.visible = false
			continue
		var at: Vector2 = item.p
		var limits := _tag_limits(tag)
		for _step in 6:
			var rect := Rect2(at, tag.size)
			var hit := false
			for prev in edge_used:
				if (prev as Rect2).grow(8.0).intersects(rect):
					hit = true
					break
			if not hit:
				break
			at.y = minf(at.y + tag.size.y + 6.0, limits.end.y)
			at.x = clampf(at.x, limits.position.x, limits.end.x)
		tag.position = at
		tag.visible = true
		edge_used.append(Rect2(at, tag.size))
		edge_n += 1

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
	# Alpha-hash fades speckled the ground in front of the camera. Props stay solid.
	return
	if cam == null:
		return
	var eye := cam.global_position
	var ab := Vector2(hole_pos.x - eye.x, hole_pos.z - eye.z)
	var ab_len2 := ab.length_squared()
	if ab_len2 < 0.04:
		return
	var near := {}
	for c in STATIC_CHUNKS:
		if _mover_hot(c):
			near[c] = true
	for o in fadeables:
		if not bool(o.in_mesh) or not bool(o.alive):
			continue
		var chunk := int(o.get("chunk", STATIC_CHUNKS))
		if chunk < STATIC_CHUNKS and not near.has(chunk):
			if bool(o.faded):
				o.faded = false
				var far_mm := _mm_of(o)
				if far_mm:
					far_mm.set_instance_color(int(o.index), o.color)
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
	HapticService.pulse(heavy or points >= 14)
	if not sound:
		return
	var kind := "pop"
	if points >= 18:
		kind = "crunch"
	elif points >= 8:
		kind = "clunk"
	var pitch := 1.0 + float(mini(combo, 10)) * 0.08
	_sfx(kind, pitch, heavy or points >= 14)

func _announce_web_phase() -> void:
	if not web_phase_live or not OS.has_feature("web"):
		return
	var phase := "menu"
	if mode == "play":
		phase = "play"
	elif mode == "results":
		phase = "results"
	if phase == _announced_phase:
		return
	_announced_phase = phase
	JavaScriptBridge.eval("if(window.__holeSetPhase)window.__holeSetPhase('%s');" % phase, true)

func _mark_web_phase() -> void:
	web_phase_live = true
	_announce_web_phase()

func _process(delta: float) -> void:
	_announce_web_phase()
	_tick_reveal()
	if ui_swallow_frames > 0:
		ui_swallow_frames -= 1
	if shot_wait > 0:
		shot_wait -= 1
		if shot_wait == 0 and shot_path != "":
			call_deferred("_save_shot")
	_watch_render()
	_sync_pause_button()
	var frame_delta := delta
	if bot_drive:
		if not bot_step_ready:
			return
		bot_step_ready = false
		frame_delta = 1.0 / 60.0
		bot_clock += frame_delta
	_tick_quality(frame_delta)
	# Hole steering uses the real frame time. A 20fps cap made a slow machine crawl.
	var steer_delta := frame_delta if bot_drive else minf(frame_delta, 0.5)
	delta = frame_delta if bot_drive else minf(delta, 1.0 / 20.0)
	if mode == "play" or mode == "attract":
		_poll_pointer_steer()
	_tick_drag_hint(frame_delta)
	if mode != "play" and mode != "results" and mode != "attract":
		if debug_on:
			_update_debug(frame_delta)
		return
	if playing:
		if not bot_drive:
			Save.add_play_time(delta)
			play_save_wait += delta
			if play_save_wait >= 5.0:
				play_save_wait = 0.0
				Save.save_game()
		play_age += delta
		if _maybe_first_ad():
			pass
		elif clear_total > 0 and _clear_ratio() >= CLEAR_RATIO:
			_finish_round(true)
		else:
			if latency_probe:
				if lat_arm:
					lat_arm = false
					_latency_advance()
			elif grow_drive:
				if grow_arm:
					grow_arm = false
					_grow_drive_step(delta)
			else:
				_move_hole(steer_delta)
			_tick_movers(delta)
			_tick_rivals(delta)
			_activate_nearby()
	elif cam_hold:
		_tick_movers(delta)
	_smooth_camera(delta)
	hole_open = shown_radius
	hole_mesh.position = hole_pos
	hole_mesh.scale = Vector3(shown_radius, 1.0, shown_radius)
	_sync_rival_visuals()
	_push_openings()
	_tick_floaters(delta)
	_place_name_tag()
	if playing:
		_fade_blockers()
	_tick_feedback(delta)
	_tick_clear_bar(delta)
	_tick_goal(delta)
	if hole_swirl > 0.28:
		hole_swirl = maxf(0.28, hole_swirl - frame_delta * 0.65)
		if pit_mat:
			pit_mat.set_shader_parameter("swirl", hole_swirl)
	if score != shown_score or level != shown_level:
		_refresh_hud()
	if debug_on:
		_update_debug(frame_delta)
	if latency_probe and lat_sample_now:
		lat_sample_now = false
		_latency_sample()

func _tick_floaters(delta: float) -> void:
	for f in floaters:
		if not match_hud or float(f.age) < 0.0:
			if f.lbl and not match_hud:
				(f.lbl as CanvasItem).visible = false
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

func _mover_hot(chunk: int) -> bool:
	if chunk >= STATIC_CHUNKS:
		return true
	var cell := (CITY_HALF * 2.0) / float(CHUNK_N)
	var ix := chunk % CHUNK_N
	var iz := int(chunk / CHUNK_N)
	var cx := -CITY_HALF + (float(ix) + 0.5) * cell
	var cz := -CITY_HALF + (float(iz) + 0.5) * cell
	var reach := cell * 2.4
	var reach2 := reach * reach
	if Vector2(cx - hole_pos.x, cz - hole_pos.z).length_squared() <= reach2:
		return true
	for rv in rivals:
		if not bool(rv.alive):
			continue
		var rp: Vector3 = rv.pos
		if Vector2(cx - rp.x, cz - rp.z).length_squared() <= reach2:
			return true
	return false

func _chunk_bounds(chunk: int) -> Vector4:
	var cell := (CITY_HALF * 2.0) / float(CHUNK_N)
	var ix := chunk % CHUNK_N
	var iz := int(chunk / CHUNK_N)
	var x0 := -CITY_HALF + float(ix) * cell + 0.55
	var z0 := -CITY_HALF + float(iz) * cell + 0.55
	return Vector4(x0, z0, x0 + cell - 1.1, z0 + cell - 1.1)

func _walk_ok(p: Vector3, walk: Array) -> bool:
	if absf(p.x) > CITY_HALF - 0.8 or absf(p.z) > CITY_HALF - 0.8:
		return false
	var s := _surf_f(p.x, p.z)
	if walk.is_empty():
		return s != SURF_WATER and s != SURF_TRACK
	for w in walk:
		if s == int(w):
			return true
	return false

func _mover_blocked(p: Vector3, self_uid: int) -> bool:
	var key := _bkey(p.x, p.z)
	if not buckets.has(key):
		return false
	for o in buckets[key]:
		if int(o.uid) == self_uid or not bool(o.alive) or bool(o.in_body):
			continue
		var role := str(o.role)
		if role in ["small", "clutter", "person"] or float(o.size) < 0.55:
			continue
		var op: Vector3 = o.pos
		if Vector2(op.x - p.x, op.z - p.z).length() < float(o.size) * 0.5 + 0.32:
			return true
	return false

func _face_offset(id: String) -> float:
	# Toy cars are modeled with the nose on -Z. Everything else we drive faces +Z.
	if id in ["tracer", "ttruck"]:
		return PI
	return 0.0

func _nose_of(yaw: float, face: float) -> Vector3:
	var local := Vector3(0.0, 0.0, -1.0 if absf(face) > 0.5 else 1.0)
	return Basis(Vector3.UP, yaw) * local

func _turn_toward(yaw: float, target: float, delta: float) -> float:
	var diff := wrapf(target - yaw, -PI, PI)
	var step := 3.4 * delta
	if absf(diff) <= step:
		return target
	return yaw + signf(diff) * step

func _sidewalk_surfs(surfs: Array) -> Array:
	var out: Array = surfs.duplicate()
	for s in [SURF_GRASS, SURF_SAND, SURF_DIRT, SURF_CONCRETE, SURF_WOOD, SURF_FIELD, SURF_DOCK]:
		if not out.has(s):
			out.append(s)
	return out

func _road_drive(mover: int, allow: Array) -> bool:
	if mover != 2:
		return false
	for a in allow:
		if int(a) == SURF_ROAD:
			return true
	return false

func _clear_of_road(p: Vector3, foot: float) -> bool:
	var pad := foot + 0.7
	var x0 := int(floor(p.x - pad))
	var x1 := int(ceil(p.x + pad))
	var z0 := int(floor(p.z - pad))
	var z1 := int(ceil(p.z + pad))
	var lim := pad * pad
	for x in range(x0, x1 + 1):
		for z in range(z0, z1 + 1):
			if RoadScript.cell(x, z) != 1:
				continue
			var dx := float(x) - p.x
			var dz := float(z) - p.z
			if dx * dx + dz * dz < lim:
				return false
	return true

func _is_road_car(o: Dictionary) -> bool:
	if int(o.mover) != 2 or not bool(o.alive):
		return false
	var walk: Array = o.get("walk", [])
	if walk.is_empty():
		return true
	for w in walk:
		if int(w) == SURF_ROAD:
			return true
	return false

func _traffic_close(pos: Vector3, dir: Vector3) -> bool:
	var side := Vector3(-dir.z, 0.0, dir.x)
	for o in props:
		if not _is_road_car(o):
			continue
		var delta: Vector3 = (o.pos as Vector3) - pos
		delta.y = 0.0
		var dist := delta.length()
		if dist < 3.2:
			return true
		var along := delta.dot(dir)
		if absf(delta.dot(side)) < 1.25 and absf(along) < 5.8:
			return true
	return false

func _spawn_on_roads(ids: Array, count: int) -> void:
	var made := 0
	var guard := 0
	while made < count and guard < count * 14 and props.size() < PROP_CAP:
		guard += 1
		var ri := (made + guard) % road_routes.size()
		var route: Dictionary = road_routes[ri]
		var length := float(route.len)
		var dist := randf() * length
		var sample := _sample_route(route, dist)
		var pos: Vector3 = sample.pos
		var dir: Vector3 = sample.dir
		if made % 2 == 1:
			dir = -dir
			dist = length - dist
		var lane := 0.92 if made % 2 == 0 else -0.92
		var side := Vector3(-dir.z, 0.0, dir.x)
		pos += side * lane
		if _traffic_close(pos, dir):
			continue
		var id := str(ids[made % ids.size()])
		if _place_id(id, pos, dir, -1.0, 1.0, Color.WHITE, -1, 2, [SURF_ROAD, SURF_WOOD, SURF_CONCRETE, SURF_DIRT, SURF_GRASS, SURF_SAND, SURF_FIELD]):
			var o: Dictionary = props[props.size() - 1]
			o["route"] = ri
			o["prog"] = dist
			o["lane"] = lane
			o["walk"] = [SURF_ROAD]
			made += 1

func _sample_route(route: Dictionary, dist: float) -> Dictionary:
	var pts: PackedVector3Array = route.pts
	var cum: PackedFloat32Array = route.cum
	var length := float(route.len)
	var closed := bool(route.closed)
	if pts.size() < 2:
		return {"pos": Vector3.ZERO, "dir": Vector3(0, 0, 1)}
	var d := dist
	if closed:
		d = fposmod(dist, length)
	else:
		d = clampf(dist, 0.0, length)
	var i := 1
	while i < cum.size() - 1 and cum[i] < d:
		i += 1
	var a: Vector3 = pts[i - 1]
	var b: Vector3 = pts[i]
	var span := maxf(cum[i] - cum[i - 1], 0.001)
	var t := clampf((d - cum[i - 1]) / span, 0.0, 1.0)
	var pos := a.lerp(b, t)
	var dir := b - a
	if dir.length_squared() < 0.0001:
		dir = Vector3(0, 0, 1)
	return {"pos": pos, "dir": dir.normalized()}

func _route_slow(route: Dictionary, dist: float) -> float:
	var stops: PackedFloat32Array = route.stops
	var length := float(route.len)
	var best := 99.0
	for s in stops:
		var gap := absf(float(s) - dist)
		if bool(route.closed):
			gap = minf(gap, length - gap)
		best = minf(best, gap)
	if best < 1.1:
		return 0.15
	if best < 3.2:
		return 0.4
	return 1.0

func _car_must_wait(o: Dictionary, pos: Vector3, dir: Vector3) -> bool:
	var side := Vector3(-dir.z, 0.0, dir.x)
	for other in movers:
		if other == o or not _is_road_car(other):
			continue
		var delta: Vector3 = (other.pos as Vector3) - pos
		delta.y = 0.0
		var dist := delta.length()
		if dist < 0.08 or dist > 5.6:
			continue
		var odir: Vector3 = other.dir
		if odir.length_squared() < 0.0001:
			odir = Vector3(0.0, 0.0, 1.0)
		var heading := clampf(dir.dot(odir.normalized()), -1.0, 1.0)
		var along := delta.dot(dir)
		var lat := absf(delta.dot(side))
		if lat < 1.25 and along > 0.15 and along < 4.8:
			return true
		if absf(heading) < 0.45 and dist < 3.35 and int(o.uid) > int(other.uid):
			return true
	return false

func _advance_mover(o: Dictionary, delta: float) -> void:
	var mover := int(o.mover)
	if mover == 2 and int(o.get("route", -1)) >= 0:
		_advance_car(o, delta)
		return
	var dir: Vector3 = o.dir
	if dir.length_squared() < 0.0001:
		dir = Vector3(0.0, 0.0, 1.0)
	dir.y = 0.0
	dir = dir.normalized()
	var walk: Array = o.get("walk", [])
	var spd := float(o.speed)
	if mover == 1 and randf() < delta * 0.35:
		dir = dir.rotated(Vector3.UP, randf_range(-0.7, 0.7))
	if mover == 1 and _surf_f(o.pos.x, o.pos.z) == SURF_ROAD:
		dir = dir.rotated(Vector3.UP, 1.2)
	var step := maxf(spd * delta, 0.04)
	var ahead: Vector3 = (o.pos as Vector3) + dir * (step + 0.35)
	if not _walk_ok(ahead, walk) or _mover_blocked(ahead, int(o.uid)) or _surf_f(ahead.x, ahead.z) == SURF_ROAD:
		var turned := false
		for ang in [0.8, -0.8, 1.6, -1.6, PI]:
			var nd := dir.rotated(Vector3.UP, ang)
			var np: Vector3 = (o.pos as Vector3) + nd * 0.55
			if _walk_ok(np, walk) and not _mover_blocked(np, int(o.uid)) and _surf_f(np.x, np.z) != SURF_ROAD:
				dir = nd
				turned = true
				break
		if not turned:
			dir = -dir
			o.dir = dir
			o.vel = dir * spd
			return
	var p: Vector3 = (o.pos as Vector3) + dir * spd * delta
	if mover == 1 and int(o.chunk) < STATIC_CHUNKS:
		var box := _chunk_bounds(int(o.chunk))
		if p.x < box.x or p.x > box.z or p.z < box.y or p.z > box.w:
			dir = -dir
			p = o.pos
	elif absf(p.x) > CITY_HALF - 1.1 or absf(p.z) > CITY_HALF - 1.1 or not _walk_ok(p, walk):
		dir = -dir
		p = o.pos
	o.dir = dir
	o.pos = p
	o.vel = dir * spd

func _advance_car(o: Dictionary, delta: float) -> void:
	var ri := int(o.route)
	if ri < 0 or ri >= road_routes.size():
		return
	var route: Dictionary = road_routes[ri]
	var length := float(route.len)
	var closed := bool(route.closed)
	var spd := float(o.speed) * _route_slow(route, float(o.prog))
	if float(o.wait) > 0.0:
		o.wait = maxf(0.0, float(o.wait) - delta)
		spd = 0.0
	elif _route_slow(route, float(o.prog)) < 0.2 and not bool(o.waited):
		o.wait = 0.35
		o.waited = true
		spd = 0.0
	if _route_slow(route, float(o.prog)) > 0.5:
		o.waited = false
	var lane := float(o.lane)
	var signed := spd * delta
	if lane < 0.0 and not closed:
		signed = -signed
	var prog := float(o.prog) + signed
	var next_lane := lane
	if not closed and (prog >= length - 0.2 or prog <= 0.2):
		next_lane = -lane
		prog = clampf(prog, 0.25, length - 0.25)
	var sample := _sample_route(route, prog)
	var dir: Vector3 = sample.dir
	if next_lane < 0.0 and not closed:
		dir = -dir
	var side := Vector3(-dir.z, 0.0, dir.x)
	var pos: Vector3 = sample.pos + side * absf(next_lane)
	if spd > 0.01 and _car_must_wait(o, pos, dir):
		o.wait = maxf(float(o.wait), 0.08)
		return
	o.lane = next_lane
	o.prog = fposmod(prog, length) if closed else clampf(prog, 0.0, length)
	o.dir = dir
	o.pos = pos
	o.vel = dir * maxf(spd, 0.0)

func _tick_movers(delta: float) -> void:
	if latency_probe:
		return
	var hot := {}
	for o in movers:
		if bool(o.in_body) or not bool(o.alive):
			continue
		var chunk := int(o.chunk)
		if not hot.has(chunk):
			hot[chunk] = _mover_hot(chunk)
		if not bool(hot[chunk]):
			continue
		if int(o.mover) == 4:
			o.yaw = float(o.yaw) + float(o.speed) * delta
			var spin_basis := Basis(Vector3.UP, float(o.yaw)).scaled(o.scale)
			var spin_xf := Transform3D(spin_basis, o.pos)
			o.xform = spin_xf
			if bool(o.in_mesh):
				var spin_mm := _mm_of(o)
				if spin_mm:
					spin_mm.set_instance_transform(int(o.index), spin_xf)
			continue
		_advance_mover(o, delta)
		var face := float(o.get("face", 0.0))
		var travel: Vector3 = o.dir
		if travel.length_squared() < 0.0001:
			travel = Vector3(0.0, 0.0, 1.0)
		var target := atan2(travel.x, travel.z) + face
		o.yaw = _turn_toward(float(o.yaw), target, delta)
		var basis := Basis(Vector3.UP, float(o.yaw)).scaled(o.scale)
		var xform := Transform3D(basis, o.pos)
		o.xform = xform
		if bool(o.in_mesh):
			var mm := _mm_of(o)
			if mm:
				mm.set_instance_transform(int(o.index), xform)
			_set_shadow(o)
		_bucket_move(o)
	_tick_treats()

func _combo_mult() -> float:
	return 1.0 + 0.2 * float(mini(maxi(combo - 1, 0), 6))

func _toast(text: String) -> void:
	if mile_lbl == null or not match_hud:
		return
	mile_lbl.text = text
	mile_lbl.visible = true
	mile_t = 1.8
	if mile_pill:
		mile_pill.visible = true
		mile_pill.modulate.a = 1.0
	mile_lbl.modulate.a = 1.0

func _note_clear_mark() -> void:
	if not playing:
		return
	var ratio := _clear_ratio()
	var mark := 0
	if ratio >= 0.75:
		mark = 75
	elif ratio >= 0.5:
		mark = 50
	elif ratio >= 0.25:
		mark = 25
	if mark > clear_mark:
		clear_mark = mark
		_toast("%d%% cleared!" % mark)

func _tick_treats() -> void:
	if treats.is_empty():
		return
	var t := float(Time.get_ticks_msec()) / 1000.0
	for o in treats:
		if not bool(o.get("alive", false)) or not bool(o.get("in_mesh", false)):
			continue
		var mm := _mm_of(o)
		if mm == null:
			continue
		var phase := float(o.get("phase", 0.0))
		var ground: Vector3 = o.get("ground", Vector3(o.pos.x, 0.0, o.pos.z))
		var opening := bool(o.get("opening_treat", false))
		var bob_y := (0.78 + 0.32 * sin(t * 2.6 + phase)) if opening else (0.38 + 0.14 * sin(t * 2.4 + phase))
		var bob := Vector3(ground.x, bob_y, ground.z)
		o.pos = bob
		var pulse := 0.5 + 0.5 * sin(t * 5.2 + phase)
		var scl: Vector3 = o.scale
		if opening:
			var pop := 1.0 + pulse * 0.12
			scl = Vector3(scl.x * pop, scl.y * pop, scl.z * pop)
		var basis := Basis(Vector3.UP, float(o.yaw)).scaled(scl)
		var xform := Transform3D(basis, bob)
		o.xform = xform
		mm.set_instance_transform(int(o.index), xform)
		var base: Color = o.color
		var hot := base.lerp(Color(1.0, 0.98, 0.55), 0.35 + pulse * 0.65) if opening else base.lerp(Color(1.0, 0.98, 0.72), 0.4 + pulse * 0.6)
		mm.set_instance_color(int(o.index), hot)

func _update_debug(delta: float) -> void:
	var frame_ms := delta * 1000.0
	var phys_ms := Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS) * 1000.0
	var draws := int(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME))
	var bodies := int(Performance.get_monitor(Performance.PHYSICS_3D_ACTIVE_OBJECTS))
	var fps := Engine.get_frames_per_second()
	var win := DisplayServer.window_get_size()
	var mem_mb := float(OS.get_static_memory_usage()) / 1048576.0
	debug_lbl.text = "FPS %d\nframe %.1f ms\nphysics %.2f ms\ndraws %d\nbodies %d\nview %dx%d\nspeed x%.2f\nscale %.2f render %.2f msaa %d\nload %d ms  mem %.0f MB\n%s" % [fps, frame_ms, phys_ms, draws, bodies, win.x, win.y, speed_scale, quality_scale, quality_render, quality_msaa, city_load_ms, mem_mb, _short_sha()]
	if OS.has_feature("web"):
		JavaScriptBridge.eval("window.__godotStats={fps:%d,frameMs:%.2f,physMs:%.2f,draws:%d,bodies:%d,vw:%d,vh:%d,coins:%d,level:%d,skin:%s,noAds:%d,music:%d,sfx:%d,size:%d,speed:%d,time:%d,cars:%d,stars:%d,clears:%d,daily:%s,doubled:%d,dist:%.2f,radius:%.3f,pitch:%.1f,move:%.2f,loadMs:%d,memMb:%.1f,props:%d}" % [fps, frame_ms, phys_ms, draws, bodies, win.x, win.y, Save.coins, Save.unlocked_level, JSON.stringify(str(Save.skin_id)), 1 if Save.no_ads else 0, 1 if Save.music_on else 0, 1 if Save.sfx_on else 0, Save.size_rank, Save.speed_rank, Save.time_rank, int(Save.tallies.get("cars", 0)), Save.total_stars(), Save.clears, JSON.stringify(str(Save.last_daily)), 1 if Save.daily_doubled else 0, cam_distance, shown_radius, cam_pitch, _move_speed(), city_load_ms, mem_mb, props.size()], true)

func _save_shot() -> void:
	var img := get_viewport().get_texture().get_image()
	if img == null:
		return
	img.save_png(shot_path)
	var video := int(Performance.get_monitor(Performance.RENDER_VIDEO_MEM_USED))
	var draws := int(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME))
	var fps := Engine.get_frames_per_second()
	print("SHOT %s load %d mem %d video %d draws %d fps %d props %d dist %.1f" % [shot_path, city_load_ms, city_mem, video, draws, fps, props.size(), cam_distance])
	get_tree().quit()

func _physics_process(delta: float) -> void:
	if bot_drive:
		bot_step_ready = true
	_sync_rim()
	if playing:
		if player_invuln > 0.0:
			player_invuln = maxf(0.0, player_invuln - delta)
		# Every physics tick, including tester mode and a level picked from the menu.
		_resolve_player_threat()
		_activate_nearby()
	var i := active.size() - 1
	while i >= 0:
		_drive_body(active[i])
		i -= 1
	if latency_probe:
		lat_arm = true
	if grow_drive:
		grow_arm = true

func _flat_dist(p: Vector3) -> float:
	var dx := p.x - hole_pos.x
	var dz := p.z - hole_pos.z
	return sqrt(dx * dx + dz * dz)

func _fits_r(size: float, radius: float) -> bool:
	return size < radius * OPEN_FIT

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
	if edge_probe:
		return
	if not pool_free.is_empty():
		var centers: Array = [hole_pos]
		var radii: Array = [hole_radius]
		var sinks: Array = [-1]
		for i in rivals.size():
			var rv: Dictionary = rivals[i]
			if bool(rv.alive):
				centers.append(rv.pos)
				radii.append(float(rv.radius))
				sinks.append(i)
		for s in centers.size():
			_take_covered(centers[s], float(radii[s]), int(sinks[s]))
			if pool_free.is_empty():
				break
		if not pool_free.is_empty():
			_take_partials(centers, radii, sinks)
	_commit_active_covers()

func _scan_buckets(sp: Vector3, reach: float) -> Array:
	var found: Array = []
	var x0 := int(floor((sp.x - reach) / 4.0))
	var x1 := int(floor((sp.x + reach) / 4.0))
	var z0 := int(floor((sp.z - reach) / 4.0))
	var z1 := int(floor((sp.z + reach) / 4.0))
	for gx in range(x0, x1 + 1):
		for gz in range(z0, z1 + 1):
			var key := gx * 128 + gz + 8192
			if buckets.has(key):
				found.append_array(buckets[key])
	return found

func _take_covered(sp: Vector3, rad: float, sink: int) -> void:
	var reach := rad + 0.2
	for o in _scan_buckets(sp, reach):
		if pool_free.is_empty():
			return
		if bool(o.in_body) or not bool(o.alive):
			continue
		if bool(o.get("opening_treat", false)) and _xz_dist(o.pos, sp) > rad * 0.92:
			continue
		var base := float(o.base)
		if not _fits_r(base, rad):
			continue
		if not _center_in_opening(base, _xz_dist(o.pos, sp), rad):
			continue
		o.sink = sink
		_take_body(o)

func _take_partials(centers: Array, radii: Array, sinks: Array) -> void:
	var budget := 2
	while budget > 0 and not pool_free.is_empty():
		budget -= 1
		var best: Dictionary = {}
		var best_d := INF
		var best_sink := -2
		var seen := {}
		for s in centers.size():
			var sp: Vector3 = centers[s]
			var rad := float(radii[s])
			for o in _scan_buckets(sp, rad + maxf(1.4, rad * 0.35)):
				var uid := int(o.get("uid", -1))
				if seen.has(uid) or bool(o.in_body) or not bool(o.alive):
					continue
				if bool(o.get("opening_treat", false)) and _xz_dist(o.pos, sp) > rad * 0.92:
					continue
				seen[uid] = true
				var base := float(o.base)
				if not _fits_r(base, rad):
					continue
				var dist := _xz_dist(o.pos, sp)
				if _center_in_opening(base, dist, rad):
					continue
				if dist >= rad + maxf(base * 0.85, 0.2):
					continue
				if dist < best_d:
					best = o
					best_d = dist
					best_sink = int(sinks[s])
		if best.is_empty():
			return
		best.sink = best_sink
		if not _take_body(best):
			return

func _commit_active_covers() -> void:
	for o in active:
		if bool(o.get("pit", false)) or o.body == null:
			continue
		var b: RigidBody3D = o.body
		var sink := int(o.get("sink", -1))
		var hr := _sink_radius(sink)
		var dist := _xz_dist(b.global_position, _sink_pos(sink))
		if hr > 0.05 and _fits_r(float(o.base), hr) and _center_in_opening(float(o.base), dist, hr):
			if _drops_instant(o):
				_commit_fall(o, b)

func _take_body(o: Dictionary) -> bool:
	if pool_free.is_empty() or bool(o.in_body):
		return false
	var b: RigidBody3D = pool_free.pop_back()
	var cs := b.get_node("Shape") as CollisionShape3D
	var native: Vector3 = kind_native[int(o.kind)]
	var sc: Vector3 = o.scale
	var box := cs.shape as BoxShape3D
	if box == null:
		box = BoxShape3D.new()
		cs.shape = box
	var foot_w := maxf(float(o.base) * 2.0, 0.08)
	box.size = Vector3(foot_w, maxf(native.y * sc.y, 0.08), foot_w)
	cs.position = Vector3(0, box.size.y * 0.5, 0)
	b.mass = clampf(foot_w * foot_w * box.size.y * 1.6, 0.35, 6.0)
	var p: Vector3 = o.pos
	b.freeze = true
	b.global_transform = Transform3D(Basis(Vector3.UP, float(o.yaw)), Vector3(p.x, 0.0, p.z))
	b.freeze = false
	b.can_sleep = false
	b.gravity_scale = FALL_GRAVITY
	b.linear_velocity = o.vel
	b.angular_velocity = Vector3.ZERO
	b.sleeping = false
	o.pit = false
	o.perch = false
	o.tilt = 0.0
	o.spin = 0.0
	o.body = b
	o.in_body = true
	active.append(o)
	var sink_at := _sink_pos(int(o.get("sink", -1)))
	var sink_r := _sink_radius(int(o.get("sink", -1)))
	var covered := _center_in_opening(float(o.base), _xz_dist(Vector3(p.x, 0.0, p.z), sink_at), sink_r)
	if covered and _drops_instant(o):
		_commit_fall(o, b)
	elif covered:
		# The footprint is inside the opening. Tip in immediately instead of sitting upright.
		_begin_perch(o, b, Vector3(p.x, 0.0, p.z))
		_handoff_tumble(o, b, sink_at, 1.35)
	elif not _drops_instant(o):
		_begin_perch(o, b, Vector3(p.x, 0.0, p.z))
	else:
		b.collision_mask = RIM_MASK
		_push_prop_visual(o, b.global_transform)
	return true

func _drops_instant(o: Dictionary) -> bool:
	var base := float(o.base)
	var height := float(o.get("height", 0.0))
	if base < 0.55 and height < 1.15:
		return true
	var role := str(o.get("role", ""))
	return role in ["small", "clutter", "person"] and height < 1.4 and base < 0.7

func _overhang_ratio(base: float, dist: float, radius: float) -> float:
	var span := maxf(base * 2.0, 0.001)
	return clampf((radius + base - dist) / span, 0.0, 1.0)

func _lip_frame(from: Vector3, hole: Vector3) -> Dictionary:
	var inward := Vector3(hole.x - from.x, 0.0, hole.z - from.z)
	if inward.length_squared() < 0.0004:
		inward = Vector3(0.0, 0.0, -1.0)
	else:
		inward = inward.normalized()
	var axis := Vector3.UP.cross(inward)
	if axis.length_squared() < 0.0004:
		axis = Vector3.RIGHT
	else:
		axis = axis.normalized()
	return {"inward": inward, "axis": axis}

func _begin_perch(o: Dictionary, b: RigidBody3D, center: Vector3) -> void:
	o.perch = true
	o.pit = false
	o.tilt = 0.0
	o.spin = 0.0
	o.perch_pos = Vector3(center.x, 0.0, center.z)
	b.freeze = true
	b.gravity_scale = 0.0
	b.collision_mask = 0
	b.linear_velocity = Vector3.ZERO
	b.angular_velocity = Vector3.ZERO
	b.sleeping = false
	_pose_topple(o, b, o.perch_pos, _sink_pos(int(o.get("sink", -1))), _sink_radius(int(o.get("sink", -1))), 0.0)

func _pose_topple(o: Dictionary, b: RigidBody3D, center: Vector3, hole: Vector3, radius: float, theta: float) -> void:
	var frame := _lip_frame(center, hole)
	var inward: Vector3 = frame.inward
	var axis: Vector3 = frame.axis
	var pivot := Vector3(hole.x, 0.0, hole.z) - inward * radius
	var rel := Vector3(center.x - pivot.x, 0.0, center.z - pivot.z)
	var swung: Vector3 = Basis(axis, theta) * rel
	var basis := Basis(axis, theta) * Basis(Vector3.UP, float(o.yaw))
	var xf := Transform3D(basis, pivot + swung)
	b.freeze = true
	b.global_transform = xf
	_push_prop_visual(o, xf)

func _tick_perch(o: Dictionary, b: RigidBody3D) -> void:
	var delta := get_physics_process_delta_time()
	var sink := int(o.get("sink", -1))
	var hp := _sink_pos(sink)
	var hr := _sink_radius(sink)
	var base := float(o.base)
	var height := maxf(float(o.get("height", base)), 0.2)
	var center := Vector3(float(o.perch_pos.x), 0.0, float(o.perch_pos.z))
	var dist := _xz_dist(center, hp)
	if hr < 0.05 or not _fits_r(base, hr):
		_release_body(o, center)
		return
	var ratio := _overhang_ratio(base, dist, hr)
	var over := _center_in_opening(base, dist, hr)
	var reaching := dist < hr + maxf(base * 0.45, 0.2)
	var theta := float(o.get("tilt", 0.0))
	var omega := float(o.get("spin", 0.0))
	var phase := float(o.get("uid", 0)) * 1.7
	var clock := float(Time.get_ticks_msec()) * 0.001
	if ratio >= 0.22 or over:
		var accel := (maxf(ratio, 0.22) - 0.10) * (2.6 + clampf(height, 0.3, 9.0) * 0.48)
		if over:
			accel += 1.6
		# Tall pieces pick up more lean, so a barn topples instead of dropping flat.
		accel *= clampf(0.75 + height * 0.08, 0.85, 1.45)
		omega = minf(omega + accel * delta, 3.1)
		theta += omega * delta
		if ratio > 0.20:
			var frame := _lip_frame(center, hp)
			var creep := minf((0.28 + ratio * 0.55) * delta, 0.02)
			center += (frame.inward as Vector3) * creep
			o.perch_pos = center
	else:
		var amp := clampf((ratio - 0.02) * 0.55, 0.0, 0.11)
		var target := sin(clock * 6.4 + phase) * amp
		var back := 1.0 - exp(-4.2 * delta)
		theta = lerpf(theta, target, back)
		omega *= 0.9
		if not reaching and ratio < 0.05 and absf(theta) < 0.045:
			_release_body(o, center)
			return
	o.tilt = theta
	o.spin = omega
	_pose_topple(o, b, center, hp, hr, theta)
	var unsupported := dist + base < hr - 0.02
	if theta > 0.48 or unsupported or (over and theta > 0.16) or ratio > 0.84:
		_handoff_tumble(o, b, hp, omega)

func _handoff_tumble(o: Dictionary, b: RigidBody3D, hole: Vector3, omega: float) -> void:
	if bool(o.get("pit", false)):
		return
	var xf := b.global_transform
	var frame := _lip_frame(xf.origin, hole)
	var axis: Vector3 = frame.axis
	var inward: Vector3 = frame.inward
	var hr := _sink_radius(int(o.get("sink", -1)))
	var pivot := Vector3(hole.x, 0.0, hole.z) - inward * hr
	var height := maxf(float(o.get("height", 1.0)), 0.2)
	var com := xf.origin + xf.basis.y.normalized() * height * 0.5
	var spin := maxf(omega, 1.05)
	var w := axis * spin
	var vel := w.cross(com - pivot)
	if xf.origin.y < 0.05:
		vel.y = minf(vel.y, -0.35)
	vel += inward * 0.22
	o.perch = false
	o.pit = true
	b.freeze = false
	b.collision_mask = 0
	b.gravity_scale = TUMBLE_GRAVITY
	b.can_sleep = false
	b.sleeping = false
	b.linear_velocity = vel
	b.angular_velocity = w
	var rid := b.get_rid()
	PhysicsServer3D.body_set_state(rid, PhysicsServer3D.BODY_STATE_TRANSFORM, xf)
	PhysicsServer3D.body_set_state(rid, PhysicsServer3D.BODY_STATE_LINEAR_VELOCITY, vel)
	PhysicsServer3D.body_set_state(rid, PhysicsServer3D.BODY_STATE_ANGULAR_VELOCITY, w)
	PhysicsServer3D.body_set_state(rid, PhysicsServer3D.BODY_STATE_SLEEPING, false)
	_push_prop_visual(o, xf)

func _commit_fall(o: Dictionary, b: RigidBody3D) -> void:
	if bool(o.get("pit", false)):
		return
	o.perch = false
	o.pit = true
	var sink := int(o.get("sink", -1))
	var hp := _sink_pos(sink)
	var p := b.global_position
	var inward := Vector3(hp.x - p.x, 0.0, hp.z - p.z)
	if inward.length_squared() < 0.0004:
		inward = Vector3(0.0, 0.0, -1.0)
	else:
		inward = inward.normalized()
	var axis := Vector3.UP.cross(inward)
	if axis.length_squared() < 0.0004:
		axis = Vector3.RIGHT
	else:
		axis = axis.normalized()
	var basis := Basis(axis, 0.42) * Basis(Vector3.UP, float(o.yaw))
	var dropped := Vector3(p.x, minf(p.y, 0.0) - DROP_SNAP, p.z)
	var xf := Transform3D(basis, dropped)
	var vel := Vector3(inward.x * 1.4, DROP_VY, inward.z * 1.4)
	var spin := axis * 2.6
	b.collision_mask = 0
	b.gravity_scale = PIT_GRAVITY
	b.can_sleep = false
	b.freeze = false
	b.global_transform = xf
	b.linear_velocity = vel
	b.angular_velocity = spin
	b.sleeping = false
	var rid := b.get_rid()
	PhysicsServer3D.body_set_state(rid, PhysicsServer3D.BODY_STATE_TRANSFORM, xf)
	PhysicsServer3D.body_set_state(rid, PhysicsServer3D.BODY_STATE_LINEAR_VELOCITY, vel)
	PhysicsServer3D.body_set_state(rid, PhysicsServer3D.BODY_STATE_ANGULAR_VELOCITY, spin)
	PhysicsServer3D.body_set_state(rid, PhysicsServer3D.BODY_STATE_SLEEPING, false)
	_push_prop_visual(o, xf)

func _push_prop_visual(o: Dictionary, xf: Transform3D) -> void:
	var sc: Vector3 = o.scale
	var src := xf.basis
	var basis := Basis(src.x.normalized() * sc.x, src.y.normalized() * sc.y, src.z.normalized() * sc.z)
	var vis := Transform3D(basis, xf.origin)
	o.xform = vis
	o.shown_y = vis.origin.y
	if bool(o.in_mesh):
		var mm := _mm_of(o)
		if mm:
			mm.set_instance_transform(int(o.index), vis)
	_set_shadow(o)

func _pool_body(b: RigidBody3D) -> void:
	b.freeze = true
	b.collision_mask = 1
	b.gravity_scale = FALL_GRAVITY
	b.linear_velocity = Vector3.ZERO
	b.angular_velocity = Vector3.ZERO
	b.position = Vector3(0, -50, 0)
	pool_free.append(b)

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
	var base := float(o.base)
	var gone := hr < 0.05 or not _fits_r(base, hr)
	if gone:
		if bool(o.get("pit", false)) and p.y < -0.15:
			b.collision_mask = 0
			b.gravity_scale = TUMBLE_GRAVITY if not _drops_instant(o) else PIT_GRAVITY
			_push_prop_visual(o, b.global_transform)
			return
		var back := p
		if bool(o.get("perch", false)):
			back = o.perch_pos
		_release_body(o, back)
		return
	if bool(o.get("perch", false)):
		_tick_perch(o, b)
		return
	if not bool(o.get("pit", false)) and not _drops_instant(o):
		_begin_perch(o, b, Vector3(p.x, 0.0, p.z))
		_tick_perch(o, b)
		return
	if b.sleeping:
		b.sleeping = false
	var dx := p.x - hp.x
	var dz := p.z - hp.z
	var dist := sqrt(dx * dx + dz * dz)
	var upright := b.global_transform.basis.y.dot(Vector3.UP)
	var tilt := 1.0 - upright
	var reaching := dist < hr + maxf(base * 0.45, 0.2)
	var falling := p.y < -0.2
	var tipped := tilt > 0.1 or p.y < -0.04
	var over := _center_in_opening(base, dist, hr)
	if over and not bool(o.get("pit", false)):
		_commit_fall(o, b)
	elif bool(o.get("pit", false)):
		b.collision_mask = 0
		b.gravity_scale = PIT_GRAVITY if _drops_instant(o) else TUMBLE_GRAVITY
		b.can_sleep = false
		b.sleeping = false
	elif reaching or tipped:
		b.gravity_scale = FALL_GRAVITY
		b.collision_mask = RIM_MASK
	elif not falling:
		_release_body(o, p)
		return
	_push_prop_visual(o, b.global_transform)

func _burst(at: Vector3, points: int, tint: Color, caption: String = "") -> void:
	pop_fx.global_position = at + Vector3(0, 0.45, 0)
	var pm := pop_fx.material_override as StandardMaterial3D
	pm.albedo_color = Color(tint.r, tint.g, tint.b, 0.95).lerp(Color(1, 0.95, 0.4, 0.95), 0.45)
	pop_fx.restart()
	pop_fx.emitting = true
	hole_swirl = 1.0
	if pit_mat:
		pit_mat.set_shader_parameter("swirl", hole_swirl)
	for f in floaters:
		if float(f.age) < 0.0:
			f.age = 0.0
			f.pos = at + Vector3(0, 0.7, 0)
			var lbl: Label = f.lbl
			lbl.text = caption if caption != "" else "+%d" % points
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
		_note_clear_mark()
		var sink := int(o.get("sink", -1))
		if sink >= 0 and sink < rivals.size() and bool(rivals[sink].alive):
			_credit_rival(rivals[sink], 1)
			_sync_level()
		else:
			if combo_left > 0.0:
				combo += 1
			else:
				combo = 1
			combo_left = COMBO_WINDOW
			var gained := int(round(float(int(o.points)) * _combo_mult()))
			score += gained
			player_eaten += 1
			_sync_level()
			if combo == 2:
				_toast("Combo x%.1f" % _combo_mult())
			elif player_eaten == 8 and level == 0:
				_toast("8 bites!")
			_announce_skins(Save.note_swallow(_swallow_bucket(kind_id_of(int(o.kind)))))
			_burst(at, gained, o.color)
			_feel(gained, gained >= 14)
			_refresh_hud()
	o.alive = false
	_drop_prop(o)
	if o.body != null:
		_pool_body(o.body)
		o.body = null
	o.in_body = false
	o.pit = false
	_unmesh(o)
	active.erase(o)

func _drop_prop(o: Dictionary) -> void:
	var i := int(o.get("pi", -1))
	var n := props.size()
	if i < 0 or i >= n or props[i] != o:
		props.erase(o)
		return
	var last: Dictionary = props[n - 1]
	props[i] = last
	last.pi = i
	props.pop_back()

func _release_body(o: Dictionary, p: Vector3) -> void:
	if o.body != null:
		_pool_body(o.body)
		o.body = null
	o.in_body = false
	o.pit = false
	o.perch = false
	o.tilt = 0.0
	o.spin = 0.0
	var grounded := Vector3(p.x, 0, p.z)
	o.pos = grounded
	o.shown_y = 0.0
	active.erase(o)
	if bool(o.in_mesh):
		var basis := Basis(Vector3.UP, float(o.yaw)).scaled(o.scale)
		var xform := Transform3D(basis, grounded)
		o.xform = xform
		var mm := _mm_of(o)
		if mm:
			mm.set_instance_transform(int(o.index), xform)
		_set_shadow(o)

func _set_music_rate(rate: float) -> void:
	if not OS.has_feature("web"):
		return
	JavaScriptBridge.eval("if(window.__holeSetMusicRate)window.__holeSetMusicRate(%.3f);" % clampf(rate, 0.84, 1.16), true)

func _motif_for(layout: String) -> float:
	match layout:
		"candy":
			return 1.0
		"jungle":
			return 2.0
		"pirate":
			return 3.0
		"snow":
			return 4.0
		"desert":
			return 5.0
		"toy":
			return 6.0
		"space":
			return 7.0
		"haunt":
			return 8.0
		"fair":
			return 9.0
		_:
			return 0.0

func _theme_light(layout: String) -> Dictionary:
	match layout:
		"candy":
			return {"sun_e": 1.06, "amb": Color(0.96, 0.92, 0.94), "amb_e": 0.34, "fill": Color(0.98, 0.9, 0.92), "fill_e": 0.08, "grade": Vector3(1.0, 0.99, 1.0), "sat": 1.1, "contrast": 1.06, "bright": 1.0, "expo": 1.02}
		"jungle":
			return {"sun_e": 1.02, "amb": Color(0.88, 0.94, 0.86), "amb_e": 0.32, "fill": Color(0.9, 0.94, 0.84), "fill_e": 0.08, "grade": Vector3(0.98, 1.02, 0.97), "sat": 1.08, "contrast": 1.06, "bright": 1.0, "expo": 1.02}
		"pirate":
			return {"sun_e": 1.06, "amb": Color(0.94, 0.9, 0.84), "amb_e": 0.32, "fill": Color(0.96, 0.9, 0.82), "fill_e": 0.08, "grade": Vector3(1.02, 1.0, 0.97), "sat": 1.08, "contrast": 1.06, "bright": 1.0, "expo": 1.02}
		"snow":
			return {"sun_e": 0.98, "amb": Color(0.94, 0.96, 1.0), "amb_e": 0.34, "fill": Color(0.94, 0.96, 1.0), "fill_e": 0.08, "grade": Vector3(0.99, 1.0, 1.02), "sat": 1.02, "contrast": 1.02, "bright": 1.0, "expo": 1.02}
		"desert":
			return {"sun_e": 1.06, "amb": Color(0.96, 0.9, 0.82), "amb_e": 0.32, "fill": Color(0.96, 0.9, 0.8), "fill_e": 0.06, "grade": Vector3(1.02, 1.0, 0.96), "sat": 1.08, "contrast": 1.06, "bright": 1.0, "expo": 1.02}
		"toy":
			return {"sun_e": 1.04, "amb": Color(0.96, 0.93, 0.88), "amb_e": 0.34, "fill": Color(0.96, 0.92, 0.86), "fill_e": 0.08, "grade": Vector3(1.0, 1.0, 0.99), "sat": 1.1, "contrast": 1.06, "bright": 1.0, "expo": 1.02}
		"space":
			return {"sun_e": 1.08, "amb": Color(0.90, 0.92, 0.97), "amb_e": 0.44, "fill": Color(0.88, 0.91, 0.98), "fill_e": 0.12, "grade": Vector3(0.98, 0.99, 1.02), "sat": 1.02, "contrast": 1.02, "bright": 1.02, "expo": 1.04}
		"haunt":
			return {"sun_e": 0.94, "amb": Color(0.84, 0.8, 0.88), "amb_e": 0.3, "fill": Color(0.82, 0.78, 0.86), "fill_e": 0.06, "grade": Vector3(1.0, 0.99, 0.99), "sat": 1.04, "contrast": 1.06, "bright": 1.0, "expo": 1.0}
		"fair":
			return {"sun_e": 1.06, "amb": Color(0.96, 0.92, 0.86), "amb_e": 0.34, "fill": Color(0.96, 0.9, 0.84), "fill_e": 0.08, "grade": Vector3(1.01, 1.0, 0.98), "sat": 1.1, "contrast": 1.06, "bright": 1.0, "expo": 1.02}
		_:
			return {"sun_e": 0.94, "amb": Color(0.93, 0.91, 0.86), "amb_e": 0.32, "fill": Color(0.95, 0.92, 0.86), "fill_e": 0.07, "grade": Vector3(1.01, 1.01, 0.99), "sat": 1.06, "contrast": 1.04, "bright": 1.0, "expo": 1.0}

func _draw_sky_haze() -> void:
	if sky_haze == null:
		return
	var h := sky_haze.size.y
	var w := sky_haze.size.x
	if h < 2.0 or w < 2.0:
		return
	var steps := 24
	var band := h / float(steps)
	for i in steps:
		var t := (float(i) + 0.5) / float(steps)
		var col := sky_haze_top.lerp(sky_haze_edge, t)
		var fade := (1.0 - t) * (1.0 - t)
		col.a = fade * 0.22
		sky_haze.draw_rect(Rect2(0.0, float(i) * band, w, band + 1.0), col, true)

func _sync_vignette() -> void:
	if vignette:
		vignette.visible = mode == "play" or mode == "attract"

func _tint_sky_haze(m: Dictionary) -> void:
	sky_haze_top = m.sky_top
	sky_haze_edge = m.horizon
	if sky_haze:
		sky_haze.queue_redraw()

func _apply_theme(m: Dictionary) -> void:
	sky_mat.sky_top_color = m.sky_top
	sky_mat.sky_horizon_color = m.horizon
	sky_mat.ground_horizon_color = m.horizon
	sky_mat.ground_bottom_color = m.ground
	_tint_sky_haze(m)
	var look := _theme_light(str(m.layout))
	world_env.adjustment_saturation = clampf(float(look.sat), 1.0, 1.12)
	world_env.adjustment_contrast = float(look.contrast)
	world_env.adjustment_brightness = float(look.bright)
	world_env.tonemap_exposure = float(look.expo)
	if skirt_mat:
		skirt_mat.albedo_color = m.ground.darkened(0.42)
	var warm := Color(1.0, 0.84, 0.62)
	sun.light_color = (m.sun as Color).lerp(warm, 0.22)
	sun.light_energy = float(look.sun_e)
	sun.rotation_degrees = Vector3(-58, float(m.sun_yaw), 0)
	_refresh_shadow_slide()
	world_env.ambient_light_color = look.amb
	world_env.ambient_light_energy = float(look.amb_e)
	if fill_light:
		fill_light.light_color = look.fill
		fill_light.light_energy = float(look.fill_e)
		fill_light.rotation_degrees = Vector3(-22, float(m.sun_yaw) + 168.0, 0)
	var paints: Array = m.get("paints", [])
	var grade: Vector3 = look.grade
	for i in ground_mats.size():
		var mat := ground_mats[i] as ShaderMaterial
		mat.set_shader_parameter("grade_tint", grade)
		mat.set_shader_parameter("motif", _motif_for(str(m.layout)))
		if i < paints.size():
			var pair: Array = paints[i]
			var lo: Color = pair[0]
			var hi: Color = pair[1]
			mat.set_shader_parameter("band_lo", Vector3(lo.r, lo.g, lo.b))
			mat.set_shader_parameter("band_hi", Vector3(hi.r, hi.g, hi.b))
	world_env.fog_enabled = true
	world_env.fog_mode = Environment.FOG_MODE_EXPONENTIAL
	world_env.fog_light_color = m.horizon
	world_env.fog_density = float(m.get("fog_density", 0.0024)) * 0.28
	world_env.fog_aerial_perspective = 0.0
	world_env.fog_sky_affect = 0.05
	_set_music_rate(float(m.get("rate", 1.0)))

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
	Save.practice = _practice_level(map_index)
	map = CatalogScript.maps()[map_index]
	target_score = int(map.target)
	_apply_theme(map)
	_apply_skin()
	score = 0
	level = 0
	combo = 0
	combo_left = 0.0
	clear_mark = 0
	mile_t = 0.0
	size_banner_t = 0.0
	hole_radius = _start_radius()
	shown_radius = hole_radius
	hole_open = hole_radius
	hole_pos = Vector3.ZERO
	velocity = Vector3.ZERO
	joy_held = false
	round_cleared = false
	round_settled = false
	coins_earned = 0
	doubled = false
	shown_score = -1
	shown_level = -1
	_spawn_city()
	_spawn_rivals()
	_tally_clear()
	_sync_level()
	player_invuln = SPAWN_GRACE
	continue_used = false
	rivals_bitten = {}
	round_eaten = ""
	rival_bites = 0
	play_age = 0.0
	_arm_trial()
	_close_continue_layer()
	hole_mesh.visible = true
	hole_mesh.position = hole_pos
	_snap_camera()
	_seat_opening_treat()
	_warm_view()
	_hold_for_reveal()
	over_panel.visible = false
	hud_layer.visible = true
	menu_layer.visible = false
	paused = false
	if pause_layer:
		pause_layer.visible = false
	mode = "play"
	playing = true
	ad_hold = false
	_mark_web_phase()
	_set_match_hud(true)
	_set_chrome(false)
	_refresh_hud()
	_sync_audio()
	_sync_pause_button()
	_arm_drag_hint()

func _enter_attract(index: int) -> void:
	_clear_city()
	Save.practice = false
	map_index = clampi(index, 0, CatalogScript.maps().size() - 1)
	map = CatalogScript.maps()[map_index]
	target_score = int(map.target)
	_apply_theme(map)
	_apply_skin()
	score = 0
	level = 0
	combo = 0
	combo_left = 0.0
	size_banner_t = 0.0
	hole_radius = _start_radius()
	shown_radius = hole_radius
	hole_open = hole_radius
	hole_pos = Vector3.ZERO
	velocity = Vector3.ZERO
	joy_held = false
	round_cleared = false
	round_settled = false
	coins_earned = 0
	doubled = false
	shown_score = -1
	shown_level = -1
	ad_hold = false
	if _light_preview():
		clear_total = 0
		clear_eaten = 0
		clear_shown = 0.0
	else:
		_spawn_city()
		_spawn_rivals()
		_tally_clear()
		_sync_level()
	player_invuln = 0.0
	hole_mesh.visible = true
	hole_mesh.position = hole_pos
	_snap_camera()
	_warm_view()
	over_panel.visible = false
	hud_layer.visible = true
	if menu_layer:
		menu_layer.visible = false
	paused = false
	if pause_layer:
		pause_layer.visible = false
	mode = "attract"
	playing = false
	_mark_web_phase()
	_apply_skin()
	_set_match_hud(false)
	_set_chrome(true)
	_refresh_level_pill()
	_refresh_hud()
	_hide_drag_hint()

func _begin_play() -> void:
	if ui_swallow_frames > 0 or block_start_until_up:
		return
	if mode != "attract" or playing or ad_hold or paused or render_failed:
		return
	if menu_layer != null and menu_layer.visible:
		return
	if _blocks_world(get_viewport().get_mouse_position()):
		return
	mode = "play"
	playing = true
	_mark_web_phase()
	score = 0
	level = 0
	combo = 0
	combo_left = 0.0
	hole_radius = _start_radius()
	shown_radius = hole_radius
	hole_open = hole_radius
	round_settled = false
	player_invuln = SPAWN_GRACE
	continue_used = false
	rivals_bitten = {}
	round_eaten = ""
	_arm_trial()
	_tally_clear()
	shown_score = -1
	shown_level = -1
	_set_chrome(false)
	_set_match_hud(true)
	_sync_level()
	_refresh_hud()
	_sync_audio()
	_sync_pause_button()
	_arm_drag_hint()

func _build_pause() -> void:
	if pause_btn != null or hud_layer == null:
		return
	pause_btn = _make_button("Pause", Vector2.ZERO, Vector2(168, 72), BRAND_INK, 30)
	pause_btn.anchor_left = 1.0
	pause_btn.anchor_right = 1.0
	pause_btn.anchor_top = 1.0
	pause_btn.anchor_bottom = 1.0
	pause_btn.offset_left = -(SAFE_SIDE + 168.0)
	pause_btn.offset_right = -SAFE_SIDE
	pause_btn.offset_top = -(SAFE_BOTTOM + 88.0)
	pause_btn.offset_bottom = -SAFE_BOTTOM
	pause_btn.visible = false
	pause_btn.mouse_filter = Control.MOUSE_FILTER_STOP
	pause_btn.pressed.connect(_open_pause)
	hud_layer.add_child(pause_btn)
	pause_layer = CanvasLayer.new()
	pause_layer.layer = 30
	pause_layer.visible = false
	add_child(pause_layer)
	var dim := ColorRect.new()
	dim.color = Color(0.11, 0.16, 0.29, 0.62)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	dim.gui_input.connect(_eat_menu_pointer)
	pause_layer.add_child(dim)
	var card := Panel.new()
	card.anchor_left = 0.5
	card.anchor_right = 0.5
	card.anchor_top = 0.5
	card.anchor_bottom = 0.5
	card.offset_left = -310.0
	card.offset_right = 310.0
	card.offset_top = -250.0
	card.offset_bottom = 310.0
	card.mouse_filter = Control.MOUSE_FILTER_STOP
	card.add_theme_stylebox_override("panel", _panel_style())
	pause_layer.add_child(card)
	var title := Label.new()
	title.text = "Paused"
	title.position = Vector2(40, 24)
	title.size = Vector2(540, 68)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_style(title, 52)
	title.add_theme_color_override("font_color", BRAND_INK)
	title.add_theme_constant_override("outline_size", 0)
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(title)
	var resume := _make_button("Resume", Vector2(40, 104), Vector2(540, 78), Color(0.16, 0.66, 0.42))
	resume.pressed.connect(_resume_pause)
	card.add_child(resume)
	var restart := _make_button("Restart", Vector2(40, 194), Vector2(540, 78), BRAND_CYAN)
	restart.pressed.connect(_restart_pause)
	card.add_child(restart)
	var settings_b := _make_button("Settings", Vector2(40, 284), Vector2(540, 78), Color(0.28, 0.36, 0.52))
	settings_b.pressed.connect(_open_settings_from_pause)
	card.add_child(settings_b)
	var exit_b := _make_button("Exit to menu", Vector2(40, 374), Vector2(540, 78), BRAND_INK)
	exit_b.pressed.connect(_exit_pause)
	card.add_child(exit_b)
	_sync_pause_button()

func _sync_pause_button() -> void:
	if pause_btn == null:
		return
	pause_btn.visible = mode == "play" and playing and not paused and not ad_hold and not render_failed

func _open_pause() -> void:
	if mode != "play" or not playing or paused or ad_hold:
		return
	paused = true
	playing = false
	joy_held = false
	_refresh_joystick()
	if name_lbl:
		name_lbl.visible = false
	_sync_pause_button()
	if pause_layer:
		pause_layer.visible = true

func _resume_pause() -> void:
	if not paused or mode != "play":
		return
	paused = false
	playing = true
	joy_held = false
	if pause_layer:
		pause_layer.visible = false
	_sync_pause_button()

func _restart_pause() -> void:
	paused = false
	if pause_layer:
		pause_layer.visible = false
	_request_round(map_index)

func _exit_pause() -> void:
	paused = false
	if pause_layer:
		pause_layer.visible = false
	# The same tap that closed the card must not count as "tap to start".
	block_start_until_up = true
	joy_held = false
	ui_swallow_frames = 24
	_enter_attract(map_index)

func _watch_render() -> void:
	if render_failed or render_ok or not OS.has_feature("web"):
		return
	if props.is_empty() and _query_preview() != "renderblank":
		return
	render_warm += 1
	var objects := 0
	var draws := 0
	if _query_preview() != "renderblank":
		var vp := get_viewport()
		objects = vp.get_render_info(Viewport.RENDER_INFO_TYPE_VISIBLE, Viewport.RENDER_INFO_OBJECTS_IN_FRAME)
		draws = vp.get_render_info(Viewport.RENDER_INFO_TYPE_VISIBLE, Viewport.RENDER_INFO_DRAW_CALLS_IN_FRAME)
	if render_warm >= 8 and (objects > 0 or draws > 0):
		render_ok = true
		return
	if render_warm < 8:
		return
	render_blank += 1
	if render_blank < 12:
		return
	if _query_preview() != "renderblank" and not _framebuffer_blank():
		render_ok = true
		return
	_fail_graphics()

func _framebuffer_blank() -> bool:
	var tex := get_viewport().get_texture()
	if tex == null:
		return true
	var img := tex.get_image()
	if img == null or img.is_empty():
		return true
	var w := img.get_width()
	var h := img.get_height()
	if w < 2 or h < 2:
		return true
	# The HUD sits on the edges. Sample the middle, where a blank world is one color.
	var x0 := int(float(w) * 0.28)
	var x1 := int(float(w) * 0.72)
	var y0 := int(float(h) * 0.32)
	var y1 := int(float(h) * 0.68)
	var first := img.get_pixel((x0 + x1) / 2, (y0 + y1) / 2)
	var acc := 0.0
	for y in 6:
		for x in 6:
			var px := x0 + int(float(x1 - x0) * (float(x) + 0.5) / 6.0)
			var py := y0 + int(float(y1 - y0) * (float(y) + 0.5) / 6.0)
			var sample := img.get_pixel(clampi(px, 0, w - 1), clampi(py, 0, h - 1))
			acc += absf(sample.r - first.r) + absf(sample.g - first.g) + absf(sample.b - first.b)
	return acc < 0.45

func _fail_graphics() -> void:
	if render_failed:
		return
	render_failed = true
	render_ok = false
	playing = false
	paused = true
	joy_held = false
	_sync_pause_button()
	if not OS.has_feature("web"):
		return
	JavaScriptBridge.eval("if(window.__holeGraphicsFailed)window.__holeGraphicsFailed();", true)

func _arm_trial() -> void:
	round_trial = Save.trial_skin
	_apply_skin()

func _maybe_first_ad() -> bool:
	if bot_drive:
		return false
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
	if web_audio_unlocked or not OS.has_feature("web"):
		return
	web_audio_unlocked = true
	JavaScriptBridge.eval("if(window.__holeUnlock)window.__holeUnlock();", true)

func _sync_audio() -> void:
	if not OS.has_feature("web"):
		return
	var music := "true" if Save.music_on else "false"
	var sfx_on := "true" if Save.sfx_on else "false"
	var haptics := "true" if Save.haptics_on else "false"
	JavaScriptBridge.eval("if(window.__holeSetAudio)window.__holeSetAudio(%s,%s);" % [music, sfx_on], true)
	JavaScriptBridge.eval("if(window.__holeSetHaptics)window.__holeSetHaptics(%s);" % haptics, true)

func _paint_button(b: Button, color: Color) -> void:
	var normal := _btn_box(color)
	var hover := _btn_box(color.lightened(0.12))
	var pressed := _btn_box(color.darkened(0.12))
	b.add_theme_stylebox_override("normal", normal)
	b.add_theme_stylebox_override("hover", hover)
	b.add_theme_stylebox_override("pressed", pressed)
	b.add_theme_stylebox_override("focus", normal)

func _arm_drag_hint() -> void:
	if drag_hint == null:
		return
	if mode == "play" and playing and Save.rounds == 0:
		drag_hint.visible = true
		drag_hint.modulate.a = 1.0
		drag_hint_t = 0.0
		if drag_pill:
			drag_pill.visible = true
			drag_pill.modulate.a = 1.0
	else:
		_hide_drag_hint()

func _hide_drag_hint() -> void:
	drag_hint_t = -1.0
	if drag_hint:
		drag_hint.visible = false
	if drag_pill:
		drag_pill.visible = false

func _tick_drag_hint(delta: float) -> void:
	if drag_hint == null or drag_hint_t < 0.0:
		return
	if joy_held and joy_finger.distance_to(joy_anchor) > JOY_DEADZONE:
		drag_hint_t = maxf(drag_hint_t, 3.05)
	if round_cover != null and round_cover.visible and drag_hint_t < 3.0:
		return
	drag_hint_t += delta
	if drag_hint_t < 3.0:
		drag_hint.modulate.a = 1.0
	elif drag_hint_t < 4.1:
		drag_hint.modulate.a = clampf(1.0 - (drag_hint_t - 3.0) / 1.1, 0.0, 1.0)
	else:
		_hide_drag_hint()
		return
	if drag_pill:
		drag_pill.modulate.a = drag_hint.modulate.a

func _configure_result_actions() -> void:
	var nxt := map_index + 1
	var nxt_open := _level_open(nxt)
	var offer_keep := round_eaten != "" and not continue_used and not round_settled
	if keep_btn:
		keep_btn.visible = offer_keep
		keep_btn.disabled = false
	if next_btn:
		if round_cleared and nxt_open:
			next_btn.text = "Next"
			_paint_button(next_btn, Color(0.16, 0.66, 0.42))
		else:
			next_btn.text = "Retry"
			_paint_button(next_btn, Color(0.20, 0.48, 0.86))
		next_btn.visible = true
		if offer_keep:
			next_btn.position = Vector2(40, 760)
			if continue_btn:
				continue_btn.position = Vector2(40, 896)
		else:
			next_btn.position = Vector2(40, 688)
			if continue_btn:
				continue_btn.position = Vector2(40, 824)

func _on_keep_going() -> void:
	if continue_used or round_settled or mode != "results":
		return
	continue_used = true
	if keep_btn:
		keep_btn.visible = false
	_show_rewarded("continue")

func _present_eaten(who: String) -> void:
	playing = false
	joy_held = false
	ad_hold = false
	eaten_name = who
	round_eaten = who
	round_cleared = false
	mode = "results"
	_refresh_joystick()
	_close_continue_layer()
	if not round_settled:
		coins_earned = int(float(score) * COIN_RATE)
		if doubled:
			coins_earned *= 2
	round_stars = _star_rating(false)
	if over_lbl:
		over_lbl.text = "%s\n%s   +%d coins" % [_round_headline(), str(map.name), coins_earned]
	_fill_result_bars()
	result_anim = 0.0
	if star_row:
		star_row.set_meta("stars", 0)
		star_row.queue_redraw()
	if so_close_lbl:
		so_close_lbl.visible = false
	if double_btn:
		double_btn.visible = true
		double_btn.disabled = doubled
		double_btn.text = "Coins doubled" if doubled else "Watch ad for 2x coins"
	_configure_result_actions()
	_hide_drag_hint()
	_set_chrome(false)
	_set_match_hud(false)
	_sync_pause_button()
	if over_panel:
		over_panel.visible = true
	if result_card:
		_ease_panel(result_card, -500.0, 500.0, Vector2(330, 500))

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
	_mark_web_phase()
	round_settled = true
	var bonus := CLEAR_COIN_BONUS if cleared else 0
	coins_earned = int(float(score) * COIN_RATE) + bonus
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
	if not cleared:
		Save.note_fail()
	_configure_result_actions()
	_hide_drag_hint()
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
		if round_settled:
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
			_present_eaten(eaten_name)
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

func _on_primary_result() -> void:
	var nxt := map_index + 1
	var nxt_open := _level_open(nxt)
	if round_cleared and nxt_open:
		_on_next_level()
	else:
		_on_results_retry()

func _on_results_retry() -> void:
	if not round_settled:
		_settle_eaten()
	ad_hold = false
	if _between_ad_due():
		_show_interstitial("retry", true)
	else:
		_request_round(map_index)

func _on_next_level() -> void:
	if not _level_open(map_index + 1):
		return
	if _between_ad_due():
		_show_interstitial("next", true)
	else:
		_request_round(map_index + 1)

func _on_continue() -> void:
	if mode == "results" and not round_settled:
		_settle_eaten()
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
		_request_round(map_index)
		return
	if intent == "next":
		var nxt := map_index + 1
		if _level_open(nxt):
			_request_round(nxt)
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
	var payout := coins_earned
	if payout <= 0:
		payout = int(float(score) * COIN_RATE)
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
		_request_round(map_index)

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
	player_invuln = SPAWN_GRACE
	kept_pulse = true
	if kept_lbl:
		kept_lbl.text = "Kept going!"
	size_banner_t = 1.15
	playing = true
	mode = "play"
	doubled = false
	if over_panel:
		over_panel.visible = false
	_set_match_hud(true)
	_sync_pause_button()
	_refresh_hud()

func _set_match_hud(on: bool) -> void:
	match_hud = on
	for n in [sky_haze, score_pill, map_pill, center_pill, clear_track, clear_lbl, score_lbl, level_lbl, next_lbl, next_bg, size_badge]:
		if n:
			n.visible = on
	if next_fill:
		next_fill.visible = on
	if size_lbl:
		size_lbl.visible = on
		if on and size_lbl.text == "":
			size_lbl.text = "Size %d" % (level + 1)
	if on:
		_wake_goal()
	else:
		goal_hold = 0.0
		goal_until_ms = 0
		if combo_lbl:
			combo_lbl.visible = false
		if mile_lbl:
			mile_lbl.visible = false
		if mile_pill:
			mile_pill.visible = false
		if kept_lbl:
			kept_lbl.visible = false
		if name_lbl:
			name_lbl.visible = false
		for tag in rival_labels:
			if tag is CanvasItem:
				(tag as CanvasItem).visible = false
		for f in floaters:
			f.age = -1.0
			if f.lbl:
				(f.lbl as CanvasItem).visible = false
	_sync_vignette()

func _set_chrome(on: bool) -> void:
	if chrome_layer:
		chrome_layer.visible = on
	if hint_lbl:
		hint_lbl.visible = on and Save.rounds == 0
	if hint_pill:
		hint_pill.visible = on and Save.rounds == 0
	if on:
		_refresh_level_pill()
		_refresh_currency()
		_refresh_test_badge()

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
	var logo_pill := Panel.new()
	logo_pill.anchor_left = 0.5
	logo_pill.anchor_right = 0.5
	logo_pill.anchor_top = 0.0
	logo_pill.offset_left = -250
	logo_pill.offset_right = 250
	logo_pill.offset_top = SAFE_TOP + 84
	logo_pill.offset_bottom = SAFE_TOP + 172
	logo_pill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	logo_pill.add_theme_stylebox_override("panel", _ink_pill())
	chrome_layer.add_child(logo_pill)
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
	level_pill.mouse_filter = Control.MOUSE_FILTER_STOP
	level_pill.pressed.connect(_open_level_picker)
	chrome_layer.add_child(level_pill)
	play_btn = _make_button("Play", Vector2.ZERO, Vector2(440, 104), Color(0.14, 0.74, 0.32), 52)
	play_btn.anchor_left = 0.5
	play_btn.anchor_right = 0.5
	play_btn.anchor_top = 0.0
	play_btn.offset_left = -220
	play_btn.offset_right = 220
	play_btn.offset_top = SAFE_TOP + 268
	play_btn.offset_bottom = SAFE_TOP + 372
	play_btn.pressed.connect(_on_play)
	chrome_layer.add_child(play_btn)
	test_badge = _make_button("TEST", Vector2.ZERO, Vector2(108, 40), Color(0.95, 0.45, 0.12), 22)
	test_badge.anchor_left = 1.0
	test_badge.anchor_right = 1.0
	test_badge.anchor_top = 0.0
	test_badge.offset_left = -(SAFE_SIDE + 108)
	test_badge.offset_right = -SAFE_SIDE
	test_badge.offset_top = SAFE_TOP + 72
	test_badge.offset_bottom = SAFE_TOP + 112
	test_badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	test_badge.visible = _tester_active()
	chrome_layer.add_child(test_badge)
	daily_btn = _make_button("Daily reward", Vector2.ZERO, Vector2(280, 72), BRAND_CYAN, 32)
	daily_btn.anchor_left = 0.5
	daily_btn.anchor_right = 0.5
	daily_btn.offset_left = -140
	daily_btn.offset_right = 140
	daily_btn.offset_top = SAFE_TOP + 388
	daily_btn.offset_bottom = SAFE_TOP + 460
	daily_btn.pressed.connect(_show_screen.bind("daily"))
	chrome_layer.add_child(daily_btn)
	hint_pill = Panel.new()
	hint_pill.anchor_left = 0.5
	hint_pill.anchor_right = 0.5
	hint_pill.anchor_top = 1.0
	hint_pill.anchor_bottom = 1.0
	hint_pill.offset_left = -310
	hint_pill.offset_right = 310
	hint_pill.offset_top = -(SAFE_BOTTOM + 276)
	hint_pill.offset_bottom = -(SAFE_BOTTOM + 164)
	hint_pill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hint_pill.visible = Save.rounds == 0
	hint_pill.add_theme_stylebox_override("panel", _ink_pill())
	chrome_layer.add_child(hint_pill)
	hint_lbl = Label.new()
	hint_lbl.text = "Drag to move. Eat small things first, then grow."
	hint_lbl.anchor_left = 0.5
	hint_lbl.anchor_right = 0.5
	hint_lbl.anchor_top = 1.0
	hint_lbl.anchor_bottom = 1.0
	hint_lbl.offset_left = -300
	hint_lbl.offset_right = 300
	hint_lbl.offset_top = -(SAFE_BOTTOM + 268)
	hint_lbl.offset_bottom = -(SAFE_BOTTOM + 168)
	hint_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	hint_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hint_lbl.visible = Save.rounds == 0
	_style_hud(hint_lbl, 32)
	chrome_layer.add_child(hint_lbl)
	hand_icon = UiGlyph.new()
	hand_icon.glyph = "hand"
	hand_icon.anchor_left = 0.5
	hand_icon.anchor_right = 0.5
	hand_icon.anchor_top = 1.0
	hand_icon.anchor_bottom = 1.0
	hand_icon.offset_left = -28
	hand_icon.offset_right = 28
	hand_icon.offset_top = -(SAFE_BOTTOM + 186)
	hand_icon.offset_bottom = -(SAFE_BOTTOM + 130)
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
	row.offset_left = -340
	row.offset_right = 340
	row.offset_top = -(SAFE_BOTTOM + 118)
	row.offset_bottom = -SAFE_BOTTOM
	row.add_theme_constant_override("separation", 8)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	chrome_layer.add_child(row)
	var specs := [
		["skins", "Skins", "skins"],
		["levels", "Levels", "levels"],
		["shop", "Shop", "shop"],
		["settings", "Settings", "settings"],
		["ads", "No ads", "ads"],
	]
	for spec in specs:
		var b := _icon_button(str(spec[0]), str(spec[1]))
		var screen_name := str(spec[2])
		if screen_name == "ads":
			b.pressed.connect(_confirm_remove_ads)
		elif screen_name == "settings":
			b.pressed.connect(_open_settings_menu)
		elif screen_name == "levels":
			b.pressed.connect(_open_level_picker)
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
	b.custom_minimum_size = Vector2(128, 118)
	b.size = Vector2(128, 118)
	b.mouse_filter = Control.MOUSE_FILTER_STOP
	var box := _round_style(BRAND_CREAM)
	b.add_theme_stylebox_override("normal", box)
	b.add_theme_stylebox_override("hover", _round_style(Color(1, 1, 1)))
	b.add_theme_stylebox_override("pressed", _round_style(BRAND_CREAM.darkened(0.06)))
	b.add_theme_stylebox_override("focus", box)
	var icon := UiGlyph.new()
	icon.glyph = glyph
	icon.position = Vector2(38, 8)
	icon.size = Vector2(52, 52)
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	b.add_child(icon)
	var cap := Label.new()
	cap.text = tip
	cap.position = Vector2(0, 64)
	cap.size = Vector2(128, 44)
	cap.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	cap.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	cap.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_style(cap, 20)
	cap.add_theme_color_override("font_color", BRAND_INK)
	cap.add_theme_constant_override("outline_size", 0)
	b.add_child(cap)
	b.pivot_offset = Vector2(64, 59)
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

func _toggle_haptics() -> void:
	Save.set_haptics(not Save.haptics_on)
	_sync_audio()
	if Save.haptics_on:
		HapticService.pulse(false)
	_show_screen("settings")

func _ui_click() -> void:
	_sfx("click", 1.0, false)

func _hud_pill(bg: Color, radius: int) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	s.corner_radius_top_left = radius
	s.corner_radius_top_right = radius
	s.corner_radius_bottom_right = radius
	s.corner_radius_bottom_left = radius
	return s

func _make_hud_panel(bg: Color, radius: int) -> Panel:
	var p := Panel.new()
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	p.add_theme_stylebox_override("panel", _hud_pill(bg, radius))
	return p

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

func _ink_pill() -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = Color(0.08, 0.1, 0.16, 0.82)
	s.corner_radius_top_left = 22
	s.corner_radius_top_right = 22
	s.corner_radius_bottom_right = 22
	s.corner_radius_bottom_left = 22
	s.shadow_color = Color(0, 0, 0, 0.28)
	s.shadow_size = 6
	s.shadow_offset = Vector2(0, 2)
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

func _light_preview() -> bool:
	var p := _query_preview()
	return p in ["levels", "skins", "shop", "settings", "daily", "daily2", "home", "hud", "ads", "gate"]

func _clear_menu() -> void:
	menu_root = null
	if menu_layer == null:
		return
	for c in menu_layer.get_children():
		c.queue_free()

func _mount_menu_column(sheet_bottom: float = -1.0) -> Control:
	_clear_menu()
	menu_layer.visible = true
	var dim := ColorRect.new()
	dim.color = Color(0.11, 0.16, 0.29, 0.45)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	dim.gui_input.connect(_eat_menu_pointer)
	menu_layer.add_child(dim)
	var root := Control.new()
	root.anchor_left = 0.5
	root.anchor_right = 0.5
	root.anchor_top = 0.0
	root.anchor_bottom = 1.0
	root.offset_left = -MENU_W * 0.5
	root.offset_right = MENU_W * 0.5
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	menu_layer.add_child(root)
	menu_root = root
	var sheet := Panel.new()
	sheet.set_anchors_preset(Control.PRESET_FULL_RECT)
	sheet.offset_left = 8
	sheet.offset_top = SAFE_TOP
	sheet.offset_right = -8
	if sheet_bottom > 0.0:
		sheet.anchor_bottom = 0.0
		sheet.offset_bottom = sheet_bottom
	else:
		sheet.offset_bottom = -SAFE_BOTTOM
	sheet.add_theme_stylebox_override("panel", _panel_style())
	sheet.mouse_filter = Control.MOUSE_FILTER_STOP
	sheet.gui_input.connect(_eat_menu_pointer)
	root.add_child(sheet)
	if shot_path == "":
		sheet.modulate.a = 0.0
		sheet.offset_top = SAFE_TOP + 36.0
		var tw := create_tween()
		tw.set_parallel(true)
		tw.tween_property(sheet, "modulate:a", 1.0, 0.18).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		tw.tween_property(sheet, "offset_top", SAFE_TOP, 0.18).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	return root

func _menu_add(node: Node) -> Node:
	var host: Node = menu_root if menu_root != null else menu_layer
	host.add_child(node)
	return node

func _eat_menu_pointer(event: InputEvent) -> void:
	# Mouse only. Eating the raw touch can cancel the emulated click buttons need.
	if event is InputEventMouseButton:
		get_viewport().set_input_as_handled()

func _screen_header(title: String) -> void:
	var label := _menu_label(title, Vector2(40, MENU_HEADER_Y), 48)
	label.size = Vector2(390, 76)
	label.clip_text = true
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_menu_add(label)
	var back := _make_button("Back", Vector2(448, MENU_HEADER_Y), Vector2(232, 76), BRAND_INK, 32)
	back.pressed.connect(_show_screen.bind("attract"))
	_menu_add(back)

func _show_screen(which: String) -> void:
	if which == "menu" or which == "attract":
		Save.practice = false
		mode = "attract"
		playing = false
		_mark_web_phase()
		paused = false
		if pause_layer:
			pause_layer.visible = false
		if menu_layer:
			menu_layer.visible = false
			_clear_menu()
		if hud_layer:
			hud_layer.visible = true
		_set_match_hud(false)
		_set_chrome(true)
		_sync_pause_button()
		return
	mode = which
	playing = false
	_mark_web_phase()
	joy_held = false
	_set_chrome(false)
	_set_match_hud(false)
	if name_lbl:
		name_lbl.visible = false
	hud_layer.visible = true
	_sync_pause_button()
	var sheet_bottom := -1.0
	if which == "shop":
		sheet_bottom = MENU_HEADER_Y + 96.0 + 700.0
	elif which == "settings":
		sheet_bottom = MENU_HEADER_Y + (720.0 if _tester_active() else 584.0)
	_mount_menu_column(sheet_bottom)
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

func _tester_active() -> bool:
	return ALLOW_TESTER and tester_on

func _level_open(index: int) -> bool:
	if index < 0 or index >= CatalogScript.maps().size():
		return false
	if _tester_active():
		return true
	return index <= Save.unlocked_level

func _practice_level(index: int) -> bool:
	return _tester_active() and index > Save.unlocked_level

func _boot_tester() -> void:
	tester_on = false
	if not ALLOW_TESTER:
		return
	var from_url := _web_search().find("test=1") != -1
	if OS.has_feature("web"):
		var flag := "true" if from_url else "false"
		var raw = JavaScriptBridge.eval("(function(){try{if(%s){sessionStorage.setItem('holeTest','1');}return sessionStorage.getItem('holeTest')==='1'?'1':'0';}catch(e){return '0';}})()" % flag, true)
		tester_on = str(raw).strip_edges() == "1"
	else:
		tester_on = from_url

func _set_tester(on: bool) -> void:
	if not ALLOW_TESTER:
		on = false
	tester_on = on
	if OS.has_feature("web"):
		var bit := "1" if tester_on else "0"
		JavaScriptBridge.eval("try{sessionStorage.setItem('holeTest','%s');}catch(e){}" % bit, true)
	_refresh_test_badge()

func _turn_tester_off() -> void:
	_set_tester(false)
	if mode == "settings":
		_show_screen("settings")

func _tap_build_hash() -> void:
	if not ALLOW_TESTER:
		return
	var now := Time.get_ticks_msec()
	if now - hash_tap_ms > 2500:
		hash_taps = 0
	hash_tap_ms = now
	hash_taps += 1
	if hash_taps < 5:
		return
	hash_taps = 0
	_set_tester(true)
	if mode == "settings":
		_show_screen("settings")

func _refresh_test_badge() -> void:
	if test_badge:
		test_badge.visible = _tester_active()

func _open_level_picker() -> void:
	_show_screen("levels")

func _pick_level(index: int, lock: Control = null) -> void:
	if not _level_open(index):
		_deny_locked_level(lock)
		return
	_request_round(index)

func _deny_locked_level(lock: Control) -> void:
	var need := Save.unlocked_level + 1
	if level_lock_note:
		level_lock_note.text = "Clear Level %d to unlock" % need
		level_lock_note.modulate.a = 1.0
	if lock == null:
		return
	var prev = lock.get_meta("shake", null)
	if prev is Tween and (prev as Tween).is_valid():
		(prev as Tween).kill()
	lock.pivot_offset = lock.size * 0.5
	lock.rotation = 0.0
	var tw := create_tween()
	lock.set_meta("shake", tw)
	tw.tween_property(lock, "rotation_degrees", 14.0, 0.05)
	tw.tween_property(lock, "rotation_degrees", -12.0, 0.06)
	tw.tween_property(lock, "rotation_degrees", 8.0, 0.05)
	tw.tween_property(lock, "rotation_degrees", 0.0, 0.05)

func _on_play() -> void:
	var i := map_index
	if not _level_open(i):
		i = mini(Save.unlocked_level, CatalogScript.maps().size() - 1)
	_request_round(i)

func _screen_levels() -> void:
	_screen_header("Levels")
	_add_currency_pills(MENU_HEADER_Y + 92.0)
	level_lock_note = _menu_label("", Vector2(36, MENU_HEADER_Y + 164.0), 28)
	level_lock_note.size = Vector2(648, 44)
	level_lock_note.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	level_lock_note.add_theme_color_override("font_color", Color(0.72, 0.18, 0.16))
	_menu_add(level_lock_note)
	var scroll := ScrollContainer.new()
	scroll.anchor_right = 1.0
	scroll.anchor_bottom = 1.0
	scroll.offset_left = 28
	scroll.offset_top = MENU_HEADER_Y + 214.0
	scroll.offset_right = -28
	scroll.offset_bottom = -(SAFE_BOTTOM + 12)
	scroll.mouse_filter = Control.MOUSE_FILTER_STOP
	_menu_add(scroll)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 12)
	box.custom_minimum_size = Vector2(640, 0)
	scroll.add_child(box)
	var maps: Array = CatalogScript.maps()
	for i in maps.size():
		box.add_child(_level_card(i, maps[i]))

func _screen_skins() -> void:
	_screen_header("Skins")
	_add_currency_pills(MENU_HEADER_Y + 92.0)
	var scroll := ScrollContainer.new()
	scroll.anchor_right = 1.0
	scroll.anchor_bottom = 1.0
	scroll.offset_left = 24
	scroll.offset_top = MENU_HEADER_Y + 176.0
	scroll.offset_right = -24
	scroll.offset_bottom = -(SAFE_BOTTOM + 12)
	scroll.mouse_filter = Control.MOUSE_FILTER_STOP
	_menu_add(scroll)
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
	if personal >= 0.45:
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
		_set_result_row(0, "%s — %s" % [str(skin.name), _goal_line(prog)], float(prog.ratio), skin.a)
	_set_result_row(1, "Map cleared  %d%%  (goal %d%%)" % [int(round(_clear_ratio() * 100.0)), int(round(CLEAR_RATIO * 100.0))], clampf(_clear_ratio() / CLEAR_RATIO, 0.0, 1.0), Color(1.0, 0.72, 0.18))
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
	return _goal_line(Save.progress_for(unlock))

func _goal_line(p: Dictionary) -> String:
	var label := str(p.get("label", "Challenge"))
	var cur := int(p.get("cur", 0))
	var need := maxi(int(p.get("need", 1)), 1)
	if str(p.get("unit", "")) == "":
		return label
	if need <= 1:
		return label
	return "%s — %s of %s" % [label, _grouped(mini(cur, need)), _grouped(need)]

func _grouped(n: int) -> String:
	var s := str(maxi(n, 0))
	var out := ""
	var count := 0
	for i in range(s.length() - 1, -1, -1):
		if count == 3:
			out = "," + out
			count = 0
		out = s[i] + out
		count += 1
	return out

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
	_screen_header("Shop")
	var body := MENU_HEADER_Y + 96.0
	var coins := _menu_label("%s coins" % _grouped(Save.coins), Vector2(40, body), 32)
	coins.size = Vector2(640, 40)
	_menu_add(coins)
	_shop_row("Starting size", Save.size_rank, "size", body + 56.0)
	_shop_row("Speed", Save.speed_rank, "speed", body + 192.0)
	_shop_row("Head start", Save.time_rank, "time", body + 328.0)
	var note := _menu_label("Head start keeps older round-time upgrades.", Vector2(40, body + 460.0), 26)
	note.size = Vector2(640, 36)
	_menu_add(note)
	var ads := "Ads removed" if IapService.no_ads else "Remove Ads  %s" % IapService.price_text()
	var ads_btn := _make_button(ads, Vector2(32, body + 508.0), Vector2(656, 88), Color(0.45, 0.18, 0.22), 32)
	ads_btn.disabled = IapService.no_ads
	ads_btn.pressed.connect(_confirm_remove_ads)
	_menu_add(ads_btn)
	var test := _menu_label("Test purchase. Removes interstitials only.", Vector2(40, body + 608.0), 26)
	test.size = Vector2(640, 36)
	_menu_add(test)

func _shop_row(title: String, rank: int, which: String, y: float) -> void:
	var cost := Save.next_cost(rank)
	var name_l := _menu_label("%s   %d/5" % [title, rank + 1], Vector2(32, y), 30)
	name_l.size = Vector2(380, 40)
	_menu_add(name_l)
	var price := "Maxed" if cost < 0 else "%s coins" % _grouped(cost)
	var price_l := _menu_label(price, Vector2(430, y), 28)
	price_l.size = Vector2(258, 40)
	price_l.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_menu_add(price_l)
	var caption := "Maxed"
	var can := false
	if cost >= 0:
		var missing := cost - Save.coins
		if missing > 0:
			caption = "Need %s more coins" % _grouped(missing)
		else:
			caption = "Buy"
			can = true
	var b := _make_button(caption, Vector2(32, y + 44), Vector2(656, 76), Color(0.2, 0.48, 0.32), 28)
	b.disabled = not can
	b.alignment = HORIZONTAL_ALIGNMENT_CENTER
	b.pressed.connect(_buy_upgrade.bind(which))
	_menu_add(b)

func _buy_upgrade(which: String) -> void:
	Save.try_buy_upgrade(which)
	_show_screen("shop")

func _confirm_remove_ads() -> void:
	_mount_menu_column()
	mode = "shop"
	var msg := _menu_label("Remove ads for %s?\nTest purchase. No charge.\nInterstitials stop. Rewarded ads stay optional." % IapService.price_text(), Vector2(48, 220), 34)
	msg.size = Vector2(624, 180)
	msg.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	msg.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_menu_add(msg)
	var yes := _make_button("Confirm", Vector2(48, 460), Vector2(624, 88), Color(0.55, 0.2, 0.22))
	yes.pressed.connect(_do_remove_ads)
	_menu_add(yes)
	var no := _make_button("Cancel", Vector2(48, 568), Vector2(624, 84), Color(0.2, 0.24, 0.34))
	no.pressed.connect(_show_screen.bind("shop"))
	_menu_add(no)

func _open_settings_menu() -> void:
	settings_from = "menu"
	_show_screen("settings")

func _open_settings_from_pause() -> void:
	if mode != "play" or not paused:
		return
	settings_from = "pause"
	if pause_layer:
		pause_layer.visible = false
	_show_screen("settings")

func _settings_back() -> void:
	joy_held = false
	block_start_until_up = true
	ui_swallow_frames = 24
	if settings_from == "pause":
		_return_to_pause()
		return
	_show_screen("attract")

func _return_to_pause() -> void:
	if menu_layer:
		menu_layer.visible = false
		_clear_menu()
	mode = "play"
	playing = false
	paused = true
	joy_held = false
	ad_hold = false
	if hud_layer:
		hud_layer.visible = true
	_set_chrome(false)
	_set_match_hud(true)
	if name_lbl:
		name_lbl.visible = false
	if pause_layer:
		pause_layer.visible = true
	_sync_pause_button()
	_mark_web_phase()

func _screen_settings() -> void:
	var label := _menu_label("Settings", Vector2(40, MENU_HEADER_Y), 48)
	label.size = Vector2(390, 76)
	label.clip_text = true
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_menu_add(label)
	var back := _make_button("Back", Vector2(448, MENU_HEADER_Y), Vector2(232, 76), BRAND_INK, 32)
	back.pressed.connect(_settings_back)
	_menu_add(back)
	var body := MENU_HEADER_Y + 112.0
	var music := _make_button("Music: %s" % ("On" if Save.music_on else "Off"), Vector2(48, body), Vector2(624, 92), BRAND_CYAN if Save.music_on else BRAND_INK)
	music.pressed.connect(_toggle_music)
	_menu_add(music)
	var sfx_btn := _make_button("SFX: %s" % ("On" if Save.sfx_on else "Off"), Vector2(48, body + 112.0), Vector2(624, 92), BRAND_CYAN if Save.sfx_on else BRAND_INK)
	sfx_btn.pressed.connect(_toggle_sfx)
	_menu_add(sfx_btn)
	var hap_btn := _make_button("Haptics: %s" % ("On" if Save.haptics_on else "Off"), Vector2(48, body + 224.0), Vector2(624, 92), BRAND_CYAN if Save.haptics_on else BRAND_INK)
	hap_btn.pressed.connect(_toggle_haptics)
	_menu_add(hap_btn)
	var note := _menu_label("Music is a CC0 loop. Sound effects are original.", Vector2(48, body + 328.0), 26)
	note.size = Vector2(624, 64)
	note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_menu_add(note)
	var build := Button.new()
	build.text = "Build %s" % _short_sha()
	build.flat = true
	build.position = Vector2(48, body + 400.0)
	build.size = Vector2(624, 44)
	build.alignment = HORIZONTAL_ALIGNMENT_LEFT
	if ui_font:
		build.add_theme_font_override("font", ui_font)
	build.add_theme_font_size_override("font_size", 22)
	build.add_theme_color_override("font_color", Color(0.32, 0.4, 0.5))
	build.add_theme_color_override("font_hover_color", Color(0.32, 0.4, 0.5))
	build.add_theme_color_override("font_pressed_color", Color(0.2, 0.28, 0.38))
	build.pressed.connect(_tap_build_hash)
	_menu_add(build)
	if _tester_active():
		var off := _make_button("Turn tester mode off", Vector2(48, body + 468.0), Vector2(624, 84), Color(0.9, 0.42, 0.14), 32)
		off.pressed.connect(_turn_tester_off)
		_menu_add(off)

func _screen_daily() -> void:
	_screen_header("Daily reward")
	var amount := Save.DAILY_COINS
	var body := MENU_HEADER_Y + 140.0
	if not Save.daily_claimed():
		var today := _menu_label("Today: %d coins" % amount, Vector2(48, body), 40)
		today.size = Vector2(624, 56)
		today.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_menu_add(today)
		var claim := _make_button("Claim", Vector2(48, body + 100.0), Vector2(624, 92), Color(0.16, 0.66, 0.42))
		claim.pressed.connect(_on_claim_daily)
		_menu_add(claim)
	else:
		var got := amount * (2 if Save.daily_doubled else 1)
		var claimed := _menu_label("Claimed today: %d coins" % got, Vector2(48, body), 36)
		claimed.size = Vector2(624, 64)
		claimed.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		claimed.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_menu_add(claimed)
		if Save.daily_doubled:
			var done := _menu_label("Doubled. Come back tomorrow.", Vector2(48, body + 90.0), 32)
			done.size = Vector2(624, 48)
			done.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			_menu_add(done)
		else:
			var dbl := _make_button("Double today's reward", Vector2(48, body + 100.0), Vector2(624, 92), Color(0.90, 0.62, 0.18))
			dbl.pressed.connect(_on_double_daily)
			_menu_add(dbl)

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
	b.add_theme_color_override("font_disabled_color", Color(0.93, 0.94, 0.96))
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
	var coins := _make_button("%s coins" % _grouped(Save.coins), Vector2(28, y), Vector2(324, 64), Color(0.95, 0.62, 0.16), 28)
	coins.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_menu_add(coins)
	var stars_btn := _make_button("%s stars" % _grouped(Save.total_stars()), Vector2(368, y), Vector2(324, 64), Color(0.98, 0.78, 0.18), 28)
	stars_btn.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stars_btn.add_theme_color_override("font_color", Color(0.35, 0.22, 0.05))
	_menu_add(stars_btn)

func _level_card(index: int, m: Dictionary) -> Control:
	var open := _level_open(index)
	var stars_n := int(Save.stars[index]) if index < Save.stars.size() else 0
	var state := "Locked"
	if open and _tester_active() and index > Save.unlocked_level:
		state = "Open (test)"
	elif open:
		state = "Open" if stars_n <= 0 else "Open, %d stars" % stars_n
	var color: Color = m.horizon
	color.s = minf(color.s * 1.2 + 0.15, 0.9)
	color.v = clampf(color.v, 0.72, 0.92)
	if not open:
		color = Color(0.45, 0.5, 0.58)
	if color.v > 0.84:
		color = color.darkened(0.16)
	var luma := color.r * 0.299 + color.g * 0.587 + color.b * 0.114
	var ink := BRAND_INK if luma >= 0.55 else Color.WHITE
	var edge := Color(0.05, 0.08, 0.14, 0.95)
	var card := _make_button("%d    %s" % [index + 1, str(m.name)], Vector2.ZERO, Vector2(640, 92), color, 32)
	card.alignment = HORIZONTAL_ALIGNMENT_LEFT
	card.mouse_filter = Control.MOUSE_FILTER_STOP
	card.add_theme_color_override("font_color", ink)
	card.add_theme_color_override("font_hover_color", ink)
	card.add_theme_color_override("font_pressed_color", ink)
	card.add_theme_color_override("font_outline_color", edge)
	card.add_theme_constant_override("outline_size", 5)
	var lock: UiGlyph = null
	if not open:
		lock = UiGlyph.new()
		lock.glyph = "lock"
		lock.position = Vector2(576, 22)
		lock.size = Vector2(48, 48)
		lock.mouse_filter = Control.MOUSE_FILTER_IGNORE
		card.add_child(lock)
	card.pressed.connect(_pick_level.bind(index, lock))
	var sub := Label.new()
	sub.text = state
	sub.position = Vector2(300, 26)
	sub.size = Vector2(260 if open else 220, 40)
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_style(sub, 24)
	sub.add_theme_color_override("font_color", ink)
	sub.add_theme_color_override("font_outline_color", edge)
	sub.add_theme_constant_override("outline_size", 4)
	sub.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(sub)
	return card

func _skin_card(s: Dictionary) -> Control:
	var id := str(s.id)
	var owned := Save.has_skin(id)
	var wrap := Control.new()
	wrap.custom_minimum_size = Vector2(640, 200)
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
		line = _goal_line(prog)
	var lock_l := _menu_label(line, Vector2(8, 96), 26)
	lock_l.size = Vector2(620, 52)
	lock_l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	wrap.add_child(lock_l)
	var track := ColorRect.new()
	track.position = Vector2(16, 156)
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
		elif glyph == "lock":
			draw_arc(c + Vector2(0, -4), 8, PI, TAU, 14, Color.WHITE, 3.0, true)
			draw_rect(Rect2(c + Vector2(-10, -2), Vector2(20, 16)), Color.WHITE, true)
		elif glyph == "hand":
			draw_circle(c + Vector2(0, 6), 10, Color(1, 1, 1, 0.95))
			draw_rect(Rect2(c + Vector2(-4, -16), Vector2(8, 18)), Color(1, 1, 1, 0.95), true)
			draw_arc(c + Vector2(0, 6), 10, 0, TAU, 16, ink, 2.0, true)
		else:
			draw_arc(c, 13, 0, TAU, 28, ink, 2.4, true)
			draw_line(c + Vector2(-8, 8), c + Vector2(8, -8), Color(0.85, 0.28, 0.32), 2.8)
