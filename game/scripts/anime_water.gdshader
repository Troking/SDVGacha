shader_type spatial;
render_mode blend_mix, cull_disabled, depth_draw_always, diffuse_toon, specular_toon;

// ===================================================================
// AAA ANIME CRYSTAL-CLEAR WATER SHADER (Genshin Impact / Fontaine / Liyue)
// - Pristine, smooth liquid surface with zero zebra-banding
// - True optical transparency revealing underwater riverbed & pebbles
// - High-frequency capillary ripples & flowing downstream current
// - Shimmering diamond sun glints (Genshin stepped specular highlights)
// - Delicate undulating anime shoreline foam ribbons
// - Smooth Fresnel sky reflection & soft feathering against riverbanks
// ===================================================================

group_uniforms Palette_Fontaine;
uniform vec4 deep_color : source_color = vec4(0.08, 0.42, 0.64, 0.60);       // Translucent Fontaine azure-teal
uniform vec4 shallow_color : source_color = vec4(0.16, 0.72, 0.78, 0.38);    // Crystal clear bright turquoise
uniform vec4 shore_color : source_color = vec4(0.42, 0.88, 0.88, 0.18);      // Ultra-transparent shore aqua
uniform vec4 foam_color : source_color = vec4(0.96, 0.99, 1.00, 0.88);       // Soft anime seafoam white
uniform vec4 sun_sparkle_color : source_color = vec4(1.00, 0.98, 0.84, 1.0); // Warm diamond sun sparkle

group_uniforms Flow_And_Dynamics;
uniform float flow_speed : hint_range(0.05, 2.0) = 0.50;
uniform float wave_displacement : hint_range(0.0, 0.06) = 0.015;
uniform float river_half_width : hint_range(2.0, 12.0) = 5.6;
uniform float foam_reach : hint_range(0.2, 2.0) = 0.85;

varying vec3 v_world_pos;
varying vec3 v_world_normal;

// Smooth 3D surface physical wave displacement
float get_fluid_displacement(vec2 pos, float time) {
	float w1 = sin(pos.y * 1.8 + pos.x * 0.5 + time * 2.0) * 0.50;
	float w2 = sin(pos.y * 3.2 - pos.x * 1.2 + time * 2.8) * 0.30;
	float w3 = cos(pos.x * 2.4 + pos.y * 1.6 + time * 1.6) * 0.20;
	return w1 + w2 + w3;
}

// High-frequency capillary ripples for sparkling diamond glints
vec2 get_capillary_derivatives(vec2 p, float time) {
	vec2 p1 = p * 12.0 + vec2(0.0, time * 1.4);
	vec2 p2 = p * 20.0 - vec2(time * 0.9, time * 1.2);
	vec2 p3 = p * 32.0 + vec2(time * 1.1, -time * 0.7);

	float dx = cos(p1.x + sin(p1.y)) * 0.4 + sin(p2.x - p2.y) * 0.35 + cos(p3.x) * 0.25;
	float dy = cos(p1.y + sin(p1.x)) * 0.4 + sin(p2.y + p2.x) * 0.35 + sin(p3.y) * 0.25;
	return vec2(dx, dy);
}

// Procedural anime shoreline foam lace
float get_foam_lace(vec2 uv, float time) {
	vec2 p = uv * 18.0 + vec2(sin(uv.y * 4.0 + time * 1.5) * 0.3, time * 0.8);
	float n1 = sin(p.x * 3.6 + p.y * 2.6);
	float n2 = cos(p.x * 4.4 - p.y * 3.6);
	float bubble = clamp((n1 + n2) * 0.5 + 0.5, 0.0, 1.0);
	return smoothstep(0.45, 0.82, bubble);
}

void vertex() {
	v_world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	v_world_normal = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);

	// Gentle physical wave rise & fall
	float t = TIME * flow_speed;
	float wave = get_fluid_displacement(vec2(v_world_pos.x * 0.6, v_world_pos.z * 0.5), t);
	VERTEX.y += wave * wave_displacement;
}

void fragment() {
	float t = TIME * flow_speed;

	// 1. River centerline & normalized distance to bank
	float x_riv = sin(v_world_pos.z * 0.025) * 3.5;
	float dist_from_center = abs(v_world_pos.x - x_riv);
	float norm_dist = clamp(dist_from_center / river_half_width, 0.0, 1.0);

	// 2. High-frequency capillary ripples (subtle normal perturbation for sparkles)
	vec2 ripple_deriv = get_capillary_derivatives(vec2(v_world_pos.x * 0.5, v_world_pos.z * 0.4), t);
	vec3 local_ripple_norm = normalize(vec3(-ripple_deriv.x * 0.18, 1.0, -ripple_deriv.y * 0.18));
	NORMAL = normalize(mat3(TANGENT, BINORMAL, NORMAL) * local_ripple_norm);

	// 3. Fontaine Crystal Depth Gradient
	// Center is deep crystal azure-teal; shores are see-through clear aqua
	vec4 water_color = mix(deep_color, shallow_color, smoothstep(0.08, 0.55, norm_dist));
	water_color = mix(water_color, shore_color, smoothstep(0.50, 0.92, norm_dist));

	// 4. Smooth Fresnel Sky Reflection (Using flat world normal prevents zebra bands!)
	float view_dot_up = max(0.0, dot(vec3(0.0, 1.0, 0.0), VIEW));
	float fresnel = pow(1.0 - view_dot_up, 3.2);
	vec3 sky_reflection = mix(vec3(0.42, 0.78, 0.98), vec3(0.94, 0.98, 1.0), fresnel * 0.5);

	// 5. Undulating Anime Shoreline Foam Ribbons
	float dist_to_shore = max(0.0, river_half_width - dist_from_center);
	float shore_foam_band = 1.0 - smoothstep(0.02, foam_reach, dist_to_shore);
	float shore_wave = sin(v_world_pos.z * 2.8 + t * 3.6) * 0.28 + 0.72;
	float foam_lace = get_foam_lace(vec2(v_world_pos.x * 0.6, v_world_pos.z * 0.6), t);
	float shore_foam = clamp(shore_foam_band * shore_wave * (0.45 + foam_lace * 0.65), 0.0, 1.0);

	// 6. Downstream Drifting Foam Flecks along mid-current
	vec2 f_uv = vec2(v_world_pos.x * 3.5, v_world_pos.z * 1.6 + t * 0.95);
	float fleck_bubble = pow(clamp(sin(f_uv.x * 3.0 + f_uv.y * 2.0) * cos(f_uv.x * 2.2 - f_uv.y * 3.2) * 0.5 + 0.5, 0.0, 1.0), 5.0);
	float mid_stream_mask = smoothstep(0.85, 0.40, norm_dist) * smoothstep(0.06, 0.35, norm_dist);
	float drifting_flecks = fleck_bubble * mid_stream_mask * 0.35;

	float total_foam = clamp(shore_foam + drifting_flecks, 0.0, 1.0);

	// 7. Stepped Diamond Sun Sparkles (Genshin specular glints)
	vec3 light_dir = normalize(vec3(0.42, 0.76, 0.42));
	vec3 half_vec = normalize(VIEW + light_dir);
	float n_dot_h = max(0.0, dot(NORMAL, half_vec));
	float glint1 = smoothstep(0.965, 0.992, n_dot_h);
	float glint2 = smoothstep(0.915, 0.955, n_dot_h) * 0.35;
	float sparkle = (glint1 + glint2) * (1.0 - total_foam * 0.7);

	// 8. Surface Color Composition
	vec3 final_rgb = water_color.rgb;
	// Smoothly blend sky reflection
	final_rgb = mix(final_rgb, sky_reflection, fresnel * 0.38);
	// Blend foam
	final_rgb = mix(final_rgb, foam_color.rgb, total_foam * foam_color.a);
	// Add diamond sun sparkles
	final_rgb += sun_sparkle_color.rgb * sparkle * 0.75;

	// 9. Soft Shoreline Feather Fade (Seamless edge without polygon clipping)
	float edge_feather = smoothstep(river_half_width, river_half_width - 0.35, dist_from_center);
	// Crystal-clear shallow water: ALPHA is 0.18 - 0.38 so riverbed pebbles & sand are clearly seen!
	float final_alpha = mix(water_color.a, 0.94, total_foam) * edge_feather;

	ALBEDO = final_rgb;
	ALPHA = clamp(final_alpha, 0.0, 1.0);
	ROUGHNESS = mix(0.06, 0.50, total_foam);
	METALLIC = 0.02;
	SPECULAR = 0.45;
}
