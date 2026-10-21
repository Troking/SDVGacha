shader_type spatial;
render_mode blend_mix, cull_back, diffuse_toon, specular_toon;

// Multi-Biome Splat Terrain Shader (Genshin Impact / Open World RPG style)
// Seamlessly blends 8 rich biomes based on world coordinates and slope:
// 1. Sakura Valley (Spring green + pink petals)
// 2. Bamboo Forest (Deep moss + fallen bamboo leaves)
// 3. Asian City Promenade (Paved stone flagstones)
// 4. High School Campus (Asphalt + concrete plazas)
// 5. Riverbank & Underwater Riverbed (Moist sand, river pebbles, authentic Voronoi caustics)
// 6. Blighted Undead Crypt (Ash, necrotic cracked soil, purple veins)
// 7. Neo-Cyber District (Dark tech-asphalt with glowing cyan/magenta grid)
// 8. Mountain Cliffs & Karst Spire (Weathered stratified rock)

group_uniforms Base_Palettes;
uniform vec3 sakura_grass_col : source_color = vec3(0.32, 0.68, 0.22);
uniform vec3 bamboo_moss_col : source_color = vec3(0.18, 0.48, 0.16);
uniform vec3 city_stone_col : source_color = vec3(0.64, 0.62, 0.60);
uniform vec3 school_pave_col : source_color = vec3(0.55, 0.56, 0.58);
uniform vec3 river_sand_col : source_color = vec3(0.72, 0.62, 0.45);
uniform vec3 blight_ash_col : source_color = vec3(0.18, 0.16, 0.20);
uniform vec3 cyber_asphalt_col : source_color = vec3(0.10, 0.11, 0.15);
uniform vec3 cliff_rock_col : source_color = vec3(0.44, 0.45, 0.48);

varying vec3 v_world_pos;
varying vec3 v_world_normal;

// Fast pseudo-noise hash
float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453123);
}

// 2D Smooth Value Noise
float noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	vec2 u = f * f * (3.0 - 2.0 * f);
	return mix(
		mix(hash(i + vec2(0.0, 0.0)), hash(i + vec2(1.0, 0.0)), u.x),
		mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), u.x),
		u.y
	);
}

// Voronoi 2D Hash
vec2 voronoi_hash2(vec2 p) {
	p = vec2(dot(p, vec2(127.1, 311.7)), dot(p, vec2(269.5, 183.3)));
	return fract(sin(p) * 43758.5453);
}

// Authentic Voronoi Cellular Anime Caustics (Crisp dancing honeycomb webs!)
float get_voronoi_caustics(vec2 p, float time) {
	vec2 n = floor(p);
	vec2 f = fract(p);
	float m_dist1 = 1.0;
	float m_dist2 = 1.0;
	for (int j = -1; j <= 1; j++) {
		for (int i = -1; i <= 1; i++) {
			vec2 g = vec2(float(i), float(j));
			vec2 o = voronoi_hash2(n + g);
			o = 0.5 + 0.4 * sin(time + 6.2831 * o);
			vec2 r = g + o - f;
			float d = dot(r, r);
			if (d < m_dist1) {
				m_dist2 = m_dist1;
				m_dist1 = d;
			} else if (d < m_dist2) {
				m_dist2 = d;
			}
		}
	}
	float border = sqrt(m_dist2) - sqrt(m_dist1);
	return pow(1.0 - clamp(border * 1.8, 0.0, 1.0), 2.5);
}

// Micro-detail procedural grass tufts and blades
float get_grass_micro(vec2 p) {
	float n1 = noise(p * 8.0);
	float n2 = noise(p * 24.0);
	return n1 * 0.7 + n2 * 0.3;
}

// Paved stone flagstones pattern
float get_flagstone_pattern(vec2 p) {
	vec2 grid = fract(p * 0.85);
	vec2 edge = min(grid, 1.0 - grid);
	float border = smoothstep(0.03, 0.08, min(edge.x, edge.y));
	float stone_var = noise(floor(p * 0.85)) * 0.25;
	return border * (0.85 + stone_var);
}

// Cyber tech grid pattern with glowing circuit traces
vec3 get_cyber_grid(vec2 p, float time) {
	vec2 g = fract(p * 0.5);
	vec2 border_dist = min(g, 1.0 - g);
	float line_w = 0.04;
	float line_mask = 1.0 - smoothstep(0.0, line_w, min(border_dist.x, border_dist.y));

	float pulse = sin(p.x * 0.5 + p.y * 0.5 + time * 1.5) * 0.5 + 0.5;
	vec3 cyan_glow = vec3(0.0, 0.95, 1.0) * (0.8 + pulse * 0.4);
	vec3 magenta_glow = vec3(1.0, 0.12, 0.80);

	float color_flip = step(0.5, noise(floor(p * 0.5)));
	vec3 active_glow = mix(cyan_glow, magenta_glow, color_flip * 0.35);

	return active_glow * line_mask;
}

// Blighted corrupted soil veins
vec3 get_blight_veins(vec2 p, float time) {
	float n = noise(p * 1.8 + vec2(sin(time * 0.2), cos(time * 0.2)));
	float vein = smoothstep(0.48, 0.52, n) * (1.0 - smoothstep(0.52, 0.56, n));
	float pulse = sin(time * 2.0 + p.x + p.y) * 0.3 + 0.7;
	return vec3(0.65, 0.15, 0.85) * vein * pulse * 2.0;
}

// Sakura petal specks scattered on ground
vec3 get_sakura_petals(vec2 p) {
	vec2 petal_uv = fract(p * 6.0);
	float h = hash(floor(p * 6.0));
	if (h > 0.65) {
		float dist = length(petal_uv - vec2(0.5 + (h - 0.7) * 0.4, 0.5));
		if (dist < 0.22) {
			float petal_mask = smoothstep(0.22, 0.12, dist);
			return vec3(1.0, 0.72, 0.82) * petal_mask * 0.95;
		}
	}
	return vec3(0.0);
}

void vertex() {
	v_world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	v_world_normal = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
}

void fragment() {
	float x = v_world_pos.x;
	float y = v_world_pos.y;
	float z = v_world_pos.z;
	vec2 xz = vec2(x, z);

	// -------------------------------------------------------------
	// 1. BIOME WEIGHT CALCULATION
	// -------------------------------------------------------------

	// A. River & Shoreline
	float x_riv = sin(z * 0.025) * 3.5;
	float d_riv = abs(x - x_riv);

	// 1. Underwater Riverbed (y < -0.40 and d_riv < 5.0)
	float w_riverbed = (1.0 - smoothstep(3.2, 5.0, d_riv)) * (1.0 - smoothstep(-0.65, 0.10, y));

	// 2. Shoreline Sand Band (d_riv in [3.2, 6.8] and y < 0.8)
	float w_shore_sand = smoothstep(3.0, 4.2, d_riv) * (1.0 - smoothstep(5.8, 7.5, d_riv)) * (1.0 - smoothstep(0.3, 1.2, y));

	// B. Sakuragaoka High School Campus: X in [8, 54], Z in [-74, -22]
	float w_school_x = smoothstep(6.0, 10.0, x) * (1.0 - smoothstep(52.0, 56.0, x));
	float w_school_z = smoothstep(-76.0, -72.0, z) * (1.0 - smoothstep(-24.0, -20.0, z));
	float w_school = w_school_x * w_school_z;

	// C. Asian Imperial City: X in [8, 55], Z in [-22, 18]
	float w_city_x = smoothstep(6.0, 10.0, x) * (1.0 - smoothstep(52.0, 56.0, x));
	float w_city_z = smoothstep(-24.0, -20.0, z) * (1.0 - smoothstep(16.0, 20.0, z));
	float w_city = w_city_x * w_city_z * (1.0 - w_school);

	// Main Connecting Stone Road (City <-> School, and City <-> Bridge)
	float d_bridge_road = abs(z - (-6.0));
	float w_bridge_road = (1.0 - smoothstep(1.8, 3.2, d_bridge_road)) * smoothstep(-1.0, 3.0, x) * (1.0 - smoothstep(14.0, 18.0, x));
	float d_school_avenue = abs(x - 30.0);
	float w_school_avenue = (1.0 - smoothstep(2.2, 4.0, d_school_avenue)) * smoothstep(-28.0, -24.0, z) * (1.0 - smoothstep(-18.0, -14.0, z));
	float w_paved_roads = max(w_bridge_road, w_school_avenue);

	// D. Blighted Undead Crypt: X < -18, Z < -50
	float w_blight_x = 1.0 - smoothstep(-24.0, -16.0, x);
	float w_blight_z = 1.0 - smoothstep(-58.0, -48.0, z);
	float w_blight = w_blight_x * w_blight_z;

	// E. Neo-Cyber City: X in [16, 75], Z in [55, 115]
	float w_cyber_x = smoothstep(12.0, 20.0, x) * (1.0 - smoothstep(72.0, 80.0, x));
	float w_cyber_z = smoothstep(50.0, 60.0, z);
	float w_cyber = w_cyber_x * w_cyber_z;

	// F. Emerald Bamboo Forest: X < -6, Z in [18, 90]
	float w_bamboo_x = 1.0 - smoothstep(-12.0, -5.0, x);
	float w_bamboo_z = smoothstep(14.0, 22.0, z) * (1.0 - w_blight);
	float w_bamboo = w_bamboo_x * w_bamboo_z;

	// G. Sakura Blossom Valley (West side, default nature zone)
	float w_sakura_x = 1.0 - smoothstep(-8.0, -4.0, x);
	float w_sakura_z = (1.0 - smoothstep(14.0, 22.0, z)) * (1.0 - w_blight);
	float w_sakura = w_sakura_x * w_sakura_z;

	// H. Cliff / Mountain Rocks (steep slopes where Normal.y < 0.78 or high perimeter)
	float slope = 1.0 - clamp(v_world_normal.y, 0.0, 1.0);
	float w_cliff = smoothstep(0.22, 0.42, slope);
	float d_edge = max(abs(x), abs(z));
	float w_edge_mountain = smoothstep(76.0, 96.0, d_edge) * smoothstep(0.12, 0.32, slope);
	w_cliff = max(w_cliff, w_edge_mountain);

	float d_karst = length(vec2(x - 55.0, z - 55.0));
	float w_karst_area = (1.0 - smoothstep(18.0, 42.0, d_karst)) * smoothstep(4.5, 7.5, y);
	w_cliff = max(w_cliff, w_karst_area * 0.85);

	// -------------------------------------------------------------
	// 2. BIOME COLOR GENERATION (Optimized with dynamic branch gating)
	// -------------------------------------------------------------

	// Base nature green grass with micro-variation
	float grass_micro = (w_sakura > 0.01 || w_bamboo > 0.01) ? get_grass_micro(xz) : 0.5;
	vec3 col_sakura_grass = sakura_grass_col * (0.88 + grass_micro * 0.24);
	if (w_sakura > 0.01) {
		col_sakura_grass += get_sakura_petals(xz) * w_sakura;
	}

	// Bamboo deep moss & leaf litter
	vec3 col_bamboo = bamboo_moss_col;
	if (w_bamboo > 0.01) {
		float bamboo_noise = noise(xz * 4.0);
		col_bamboo = mix(bamboo_moss_col, vec3(0.24, 0.38, 0.12), bamboo_noise * 0.45);
		col_bamboo *= (0.85 + grass_micro * 0.25);
	}

	// Shoreline Sand with damp gradient
	vec3 col_sand = river_sand_col;
	float wet_factor = 0.0;
	if (w_shore_sand > 0.01) {
		float sand_noise = noise(xz * 6.0);
		col_sand = river_sand_col * (0.90 + sand_noise * 0.20);
		wet_factor = 1.0 - smoothstep(-0.55, 0.15, y);
		col_sand = mix(col_sand, col_sand * 0.58, wet_factor);
	}

	// Underwater Riverbed with rounded pebbles & golden silt
	vec3 col_riverbed = vec3(0.38, 0.39, 0.36);
	if (w_riverbed > 0.01) {
		float pebble_n1 = noise(xz * 4.0);
		float pebble_n2 = noise(xz * 10.0);
		col_riverbed = mix(vec3(0.32, 0.36, 0.34), vec3(0.48, 0.44, 0.38), pebble_n1 * 0.55 + pebble_n2 * 0.45);

		// Authentic Voronoi Cellular Caustics (Dynamic riverbed branch)
		float caust_mask = smoothstep(-0.35, -0.65, y) * (1.0 - smoothstep(3.4, 4.6, d_riv));
		if (caust_mask > 0.01) {
			float caust_t = TIME * 1.2;
			float c1 = get_voronoi_caustics(xz * 1.2 + vec2(0.0, caust_t * 0.35), caust_t);
			float c2 = get_voronoi_caustics(xz * 1.8 - vec2(caust_t * 0.25, caust_t * 0.4), caust_t * 1.2);
			float voronoi_caust = min(c1, c2);
			col_riverbed += vec3(0.55, 0.95, 1.0) * voronoi_caust * caust_mask * 0.55;
		}
	}

	// City Paved Flagstones
	vec3 col_city = city_stone_col;
	if (w_city > 0.01 || w_paved_roads > 0.01) {
		float flagstones = get_flagstone_pattern(xz);
		col_city = city_stone_col * flagstones;
	}

	// High School Campus
	vec3 col_school = school_pave_col;
	if (w_school > 0.01) {
		float school_asphalt = 0.92 + noise(xz * 12.0) * 0.15;
		col_school = school_pave_col * school_asphalt;
	}

	// Blighted Undead Earth
	vec3 col_blight = blight_ash_col;
	vec3 blight_veins = vec3(0.0);
	if (w_blight > 0.01) {
		float blight_noise = noise(xz * 3.0);
		col_blight = mix(blight_ash_col, vec3(0.12, 0.10, 0.14), blight_noise * 0.5);
		blight_veins = get_blight_veins(xz, TIME);
	}

	// Neo-Cyber City Asphalt with glowing circuits
	vec3 col_cyber = cyber_asphalt_col;
	vec3 cyber_grid_glow = vec3(0.0);
	if (w_cyber > 0.01) {
		float cyber_noise = noise(xz * 8.0);
		col_cyber = cyber_asphalt_col * (0.92 + cyber_noise * 0.15);
		cyber_grid_glow = get_cyber_grid(xz, TIME);
	}

	// Cliff Rock Strata
	vec3 col_cliff = cliff_rock_col;
	if (w_cliff > 0.01) {
		float rock_strata = sin(y * 1.8 + noise(xz * 0.5) * 4.0) * 0.15;
		float rock_noise = noise(xz * 2.0);
		col_cliff = cliff_rock_col * (0.85 + rock_strata + rock_noise * 0.25);
	}

	// -------------------------------------------------------------
	// 3. COMPOSITE BLEND
	// -------------------------------------------------------------
	vec3 final_color = col_sakura_grass;

	final_color = mix(final_color, col_bamboo, w_bamboo);
	final_color = mix(final_color, col_sand, w_shore_sand);
	final_color = mix(final_color, col_riverbed, w_riverbed);
	final_color = mix(final_color, col_city, w_city);
	final_color = mix(final_color, col_school, w_school);
	final_color = mix(final_color, col_city, w_paved_roads);
	final_color = mix(final_color, col_blight, w_blight);
	final_color = mix(final_color, col_cyber, w_cyber);
	final_color = mix(final_color, col_cliff, w_cliff);

	// -------------------------------------------------------------
	// 4. EMISSIVE HIGHLIGHTS (Cyber neon & Blight purple soul glow)
	// -------------------------------------------------------------
	vec3 emissive = vec3(0.0);
	emissive += cyber_grid_glow * w_cyber * (1.0 - w_cliff);
	emissive += blight_veins * w_blight * (1.0 - w_cliff);

	ALBEDO = final_color;
	EMISSION = emissive;
	// Damp wet riverbed and sand have glistening sheen
	float wet_sheen = max(w_riverbed, w_shore_sand * wet_factor);
	ROUGHNESS = mix(0.92, 0.45, wet_sheen);
	SPECULAR = mix(0.12, 0.35, wet_sheen);
	METALLIC = mix(0.0, 0.15, w_cyber);
}
