shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_disabled;

uniform bool use_texture = false;
uniform vec4 albedo_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform sampler2D albedo_texture : source_color, filter_linear_mipmap;
uniform bool use_alpha_scissor = false;
uniform float alpha_scissor_threshold : hint_range(0.0, 1.0) = 0.5;

// Hit Flash (Genshin impact feedback)
uniform float hit_flash : hint_range(0.0, 1.0) = 0.0;
uniform vec4 hit_flash_color : source_color = vec4(1.0, 0.95, 0.85, 1.0);

// Genshin Stepped Cel Shadows (2-tier shading)
uniform vec4 shadow_tint : source_color = vec4(0.48, 0.44, 0.60, 1.0);
uniform vec4 deep_shadow_tint : source_color = vec4(0.35, 0.32, 0.48, 1.0);
uniform float shadow_threshold : hint_range(0.0, 1.0) = 0.38;
uniform float deep_shadow_threshold : hint_range(0.0, 1.0) = 0.15;
uniform float shadow_softness : hint_range(0.001, 0.5) = 0.03;

// Ambient Light Control
uniform vec4 ambient_shadow_color : source_color = vec4(0.55, 0.58, 0.76, 1.0);
uniform float ambient_strength : hint_range(0.0, 1.0) = 0.45;

// Rim Lighting (Anime Edge Glow)
uniform vec4 rim_color : source_color = vec4(1.0, 0.94, 0.85, 1.0);
uniform float rim_strength : hint_range(0.0, 1.0) = 0.28;

// Anisotropic Hair Specular (Angel Ring)
uniform bool is_hair = false;
uniform float hair_specular_power : hint_range(1.0, 128.0) = 32.0;
uniform vec3 hair_inertia = vec3(0.0);
uniform float hair_wind_strength : hint_range(0.0, 3.0) = 1.0;

// Eye Gaze Tracking (Pupils & EyeStar)
uniform bool is_eye = false;
uniform bool is_face = false;
uniform vec2 eye_gaze_offset = vec2(0.0, 0.0);

// Shark Tail Organic Swimming Physics (Ellen Joe)
uniform bool is_tail = false;
uniform float tail_sway_strength : hint_range(0.0, 3.0) = 1.0;
uniform float tail_inertia_x = 0.0;
uniform float tail_inertia_y = 0.0;

void vertex() {
	if (is_hair) {
		// Roots are at Y ~ 1.44 (attached to head), tips flow down to Y ~ 0.55
		// Flexibility increases quadratically towards tips for natural springiness
		float tip_factor = clamp((1.44 - VERTEX.y) / 0.82, 0.0, 1.0);
		float flexibility = tip_factor * tip_factor;

		// 1. Inertia lag from running, jumping, dashing, turning
		VERTEX += hair_inertia * (flexibility * 0.42);

		// 2. Continuous harmonic breeze / breathing oscillation
		float wave1 = sin(TIME * 2.8 + VERTEX.x * 4.5 + VERTEX.y * 3.0) * 0.030;
		float wave2 = cos(TIME * 3.8 + VERTEX.z * 4.0 - VERTEX.y * 2.2) * 0.020;
		float wave3 = sin(TIME * 1.6 + VERTEX.x * 2.0) * 0.012;

		// Twin-tail separation: left twin-tail (X > 0.03) and right twin-tail (X < -0.03) flutter gracefully outwards
		float side = sign(VERTEX.x);
		vec3 sway = vec3(
			(wave1 + wave3) * 0.6 + side * abs(wave2) * 0.35,
			wave1 * 0.25,
			wave2 + wave3 * 0.8
		) * flexibility * hair_wind_strength;

		VERTEX += sway;
	} else if (is_eye) {
		// Shift pupil and eye star slightly in the socket for gaze saccades
		VERTEX.x += eye_gaze_offset.x * 0.006;
		VERTEX.y += eye_gaze_offset.y * 0.005;
	} else if (is_tail) {
		// Tail motion is driven smoothly by Node3D transform physics to prevent mesh distortion
	}
}

void fragment() {
	vec3 base = albedo_color.rgb;
	float alpha = albedo_color.a;
	if (use_texture) {
		vec4 tex = texture(albedo_texture, UV);
		base *= tex.rgb;
		alpha *= tex.a;
	}
	if (use_alpha_scissor && alpha < alpha_scissor_threshold) {
		discard;
	}

	// Apply combat hit flash
	if (hit_flash > 0.001) {
		base = mix(base, hit_flash_color.rgb, hit_flash);
	}

	if (is_face) {
		// Soften face exposure so delicate anime skin blush and contours remain rich and visible under bright outdoor sunlight
		base = mix(base, base * vec3(0.96, 0.90, 0.88), 0.25);
	} else {
		// Keep warm peach tone on bare skin areas so they contrast cleanly against white socks & cuffs
		float is_skin = step(0.85, base.r) * step(0.75, base.g) * step(0.65, base.b) * step(base.b, base.g);
		base = mix(base, base * vec3(0.98, 0.88, 0.82), is_skin * 0.35);
	}

	ALBEDO = base;
	ALPHA = alpha;
	ALPHA_SCISSOR_THRESHOLD = alpha_scissor_threshold;
	ROUGHNESS = 0.65;
	SPECULAR = 0.12;

	// Enable Ambient Occlusion support
	AO = 1.0;
	AO_LIGHT_AFFECT = 0.85;
}

void light() {
	vec3 light_col = clamp(LIGHT_COLOR, vec3(0.0), vec3(1.0));

	float NdotL = dot(NORMAL, LIGHT);
	float shadow_factor = NdotL * ATTENUATION;

	// 2-Tier Stepped Toon Lighting (Mid-tone and Deep-shadow)
	float toon_step_mid = smoothstep(shadow_threshold - shadow_softness, shadow_threshold + shadow_softness, shadow_factor);
	float toon_step_deep = smoothstep(deep_shadow_threshold - shadow_softness, deep_shadow_threshold + shadow_softness, shadow_factor);

	vec3 shade = mix(deep_shadow_tint.rgb, shadow_tint.rgb, toon_step_deep);
	shade = mix(shade, vec3(1.0), toon_step_mid);

	vec3 diffuse_result = ALBEDO * light_col * shade;

	// Grazing Fresnel Rim Highlight (visible on sunlit silhouettes, disabled on face/eyes)
	vec3 rim_result = vec3(0.0);
	if (!is_face && !is_eye) {
		float NdotV = max(0.0, 1.0 - dot(NORMAL, VIEW));
		float rim = pow(NdotV, 3.8) * toon_step_mid;
		rim_result = rim * rim_color.rgb * light_col * (rim_strength * 0.65);
	}

	// Anime Specular Highlight (Disabled on face and eyes to prevent glare)
	vec3 spec_result = vec3(0.0);
	vec3 half_vector = normalize(VIEW + LIGHT);

	if (is_hair) {
		// Anisotropic hair ring restricted to crown to avoid washing out bangs
		vec3 bitangent = cross(NORMAL, vec3(0.0, 1.0, 0.0));
		if (length(bitangent) > 0.01) {
			bitangent = normalize(bitangent);
			float dotTH = dot(bitangent, half_vector);
			float sinTH = sqrt(max(0.0, 1.0 - dotTH * dotTH));
			float dirAtten = smoothstep(-0.8, 0.0, dot(bitangent, half_vector));
			// Mask off front-facing forehead bangs (NORMAL.z > 0.6 and NORMAL.y < 0.1)
			float bangs_mask = smoothstep(0.4, 0.8, NORMAL.z) * step(NORMAL.y, 0.2);
			float hair_spec = pow(sinTH, 96.0) * dirAtten * toon_step_mid * (1.0 - bangs_mask * 0.9);
			spec_result = hair_spec * light_col * vec3(1.0, 0.82, 0.68) * 0.14;
		}
	} else if (!is_face && !is_eye) {
		float NdotH = max(0.0, dot(NORMAL, half_vector));
		float spec = step(0.985, NdotH) * toon_step_mid;
		spec_result = spec * light_col * 0.12;
	}

	// Controlled diffuse & specular accumulation per light (prevents multi-light blowout on white clothing)
	if (is_face) {
		DIFFUSE_LIGHT += clamp(diffuse_result * 0.30, vec3(0.0), vec3(0.35));
	} else {
		DIFFUSE_LIGHT += clamp(diffuse_result * 0.40 + rim_result, vec3(0.0), vec3(0.48));
	}
	SPECULAR_LIGHT += clamp(spec_result, vec3(0.0), vec3(0.10));
}
