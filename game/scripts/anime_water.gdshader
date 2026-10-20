shader_type spatial;
render_mode blend_mix, cull_back, diffuse_burley, specular_schlick_ggx;

// Water Color Palette (Genshin Impact / Liyue / Fontaine crystal clear style)
uniform vec4 shore_color : source_color = vec4(0.35, 0.88, 0.92, 0.40);
uniform vec4 shallow_color : source_color = vec4(0.12, 0.60, 0.76, 0.68);
uniform vec4 deep_color : source_color = vec4(0.04, 0.20, 0.45, 0.88);
uniform float depth_distance : hint_range(0.1, 8.0) = 2.2;

// Shoreline Foam
uniform vec4 foam_color : source_color = vec4(0.96, 0.99, 1.0, 0.95);
uniform float foam_distance : hint_range(0.01, 1.0) = 0.28;

// Wave Animation & Caustics
uniform vec2 flow_direction = vec2(0.0, 0.08); // Flows gently along the river (Z axis)
uniform float wave_scale_1 = 3.5;
uniform float wave_scale_2 = 9.0;
uniform float wave_height = 0.025;

// Screen Refraction & Fresnel Reflection
uniform sampler2D screen_texture : hint_screen_texture, filter_linear_mipmap;
uniform sampler2D depth_texture : hint_depth_texture, filter_linear_mipmap;
uniform float refraction_strength : hint_range(0.0, 0.05) = 0.015;
uniform float reflection_strength : hint_range(0.0, 1.0) = 0.35;

void vertex() {
	// Gentle harmonic surface displacement
	vec2 p = (UV + flow_direction * TIME) * wave_scale_1;
	float w1 = sin(p.x * 2.0 + p.y * 1.5 + TIME * 1.6) * 0.015;
	float w2 = cos(p.x * -1.8 + p.y * 3.0 - TIME * 1.2) * 0.010;
	VERTEX.y += (w1 + w2) * (wave_height / 0.025);
}

// Procedural anime caustics pattern
float get_caustics(vec2 uv) {
	vec2 p1 = uv * 22.0 + vec2(TIME * 0.35, TIME * 0.55);
	vec2 p2 = uv * 32.0 - vec2(TIME * 0.45, TIME * 0.25);
	float c1 = sin(p1.x + sin(p1.y * 0.9));
	float c2 = cos(p2.y + cos(p2.x * 0.9));
	float val = clamp((c1 + c2) * 0.5 + 0.5, 0.0, 1.0);
	return pow(val, 3.2);
}

void fragment() {
	// 1. Precise Screen-Space Water Depth
	float depth_raw = texture(depth_texture, SCREEN_UV).r;
	vec3 ndc = vec3(SCREEN_UV * 2.0 - 1.0, depth_raw);
	vec4 view_pos = INV_PROJECTION_MATRIX * vec4(ndc, 1.0);
	view_pos.xyz /= view_pos.w;
	float linear_depth = -view_pos.z;
	float surface_depth = -VERTEX.z;
	float water_depth = max(0.0, linear_depth - surface_depth);

	// 2. Multi-octave wave normal perturbation in Tangent Space
	vec2 uv_flow1 = UV * wave_scale_1 + flow_direction * TIME;
	vec2 uv_flow2 = UV * wave_scale_2 - vec2(flow_direction.y, flow_direction.x) * (TIME * 0.85);

	float wave_dx = sin(uv_flow1.x * 4.0 + uv_flow1.y * 2.5 + TIME * 2.0) * 0.06
	              + cos(uv_flow2.x * 6.0 - uv_flow2.y * 4.0 + TIME * 1.7) * 0.04;
	float wave_dy = cos(uv_flow1.x * 3.0 - uv_flow1.y * 3.5 + TIME * 1.8) * 0.06
	              + sin(uv_flow2.x * 5.0 + uv_flow2.y * 5.0 - TIME * 2.2) * 0.04;

	// Perturb the existing View-Space surface normal correctly
	vec3 tangent_norm = normalize(vec3(wave_dx, wave_dy, 1.0));
	NORMAL = normalize(mat3(TANGENT, BINORMAL, NORMAL) * tangent_norm);

	// 3. Screen Refraction (distorts riverbed underneath)
	vec2 refract_offset = vec2(wave_dx, wave_dy) * refraction_strength * clamp(water_depth * 1.5, 0.0, 1.0);
	vec4 screen_refract = texture(screen_texture, SCREEN_UV + refract_offset);

	// 4. Smooth Shoreline Alpha Fade (no razor-sharp cutoff against grass!)
	float shore_fade = smoothstep(0.01, 0.35, water_depth);

	// 5. Stylized Animated Anime Shoreline Foam
	float foam_edge = 1.0 - smoothstep(0.01, foam_distance, water_depth);
	float foam_pulse = sin(TIME * 2.8 + (UV.x + UV.y) * 28.0) * 0.5 + 0.5;
	float foam = smoothstep(0.35, 0.85, foam_edge * (0.65 + foam_pulse * 0.45));

	// 6. Water Color Gradient (shore turquoise -> shallow azure -> deep sapphire)
	float depth_t = clamp(water_depth / depth_distance, 0.0, 1.0);
	vec4 water_tint = mix(shallow_color, deep_color, depth_t);
	water_tint = mix(shore_color, water_tint, smoothstep(0.04, 0.40, water_depth));

	// 7. Caustics Shimmer in shallow water
	float caust = get_caustics(UV) * smoothstep(1.8, 0.08, water_depth) * 0.28;
	vec3 caust_color = vec3(0.75, 1.0, 0.95) * caust;

	// 8. Composite Water Color
	vec3 base_color = mix(screen_refract.rgb, water_tint.rgb, water_tint.a);
	base_color += caust_color;

	// Foam blending
	base_color = mix(base_color, foam_color.rgb, foam * foam_color.a);

	// 9. Fresnel Sky Specular Glint
	float fresnel = pow(1.0 - max(0.0, dot(NORMAL, VIEW)), 4.0);
	vec3 sky_glint = mix(vec3(0.55, 0.82, 1.0), vec3(1.0, 0.95, 0.85), fresnel);
	base_color = mix(base_color, sky_glint, fresnel * reflection_strength * (1.0 - foam));

	ALBEDO = base_color;
	ALPHA = clamp(shore_fade * max(water_tint.a, 0.45) + foam * 0.85 + fresnel * 0.20, 0.0, 1.0);
	ROUGHNESS = mix(0.04, 0.35, foam);
	SPECULAR = 0.90;
	METALLIC = 0.05;
}
