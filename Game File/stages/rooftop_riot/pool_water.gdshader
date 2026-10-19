shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back;
uniform vec3 deep_color : source_color = vec3(0.014, 0.19, 0.235);
uniform vec3 shallow_color : source_color = vec3(0.075, 0.45, 0.43);
uniform bool low_quality = false;
uniform float scenery_time = 0.0;
varying vec3 world_position;
float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}
float noise(vec2 p) {
	vec2 cell = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(cell), hash(cell + vec2(1, 0)), f.x),
		mix(hash(cell + vec2(0, 1)), hash(cell + vec2(1, 1)), f.x), f.y);
}
float ripple(vec2 p) {
	vec2 drift = vec2(scenery_time * 0.045, scenery_time * -0.025);
	return (noise(p * 2.3 + drift) - 0.5) * 0.70
		+ (noise(p * 6.7 - drift * 1.4) - 0.5) * 0.22
		+ (noise(p * 15.1 + drift * 2.1) - 0.5) * 0.08;
}
void vertex() {
	world_position = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}
void fragment() {
	vec2 p = world_position.xz;
	float a = sin(p.x * 1.8 + scenery_time * 0.3) * 0.07;
	float b = sin(p.y * 2.1 - scenery_time * 0.2) * 0.07;
	if (!low_quality) {
		a = ripple(p);
		b = ripple(p + vec2(0.27, 0.39));
	}
	vec2 slope = vec2(0.0);
	for (int i = 0; i < 9; i++) {
		if (low_quality && i >= 3) break;
		float index = float(i);
		float angle = index * 2.399963;
		vec2 direction = vec2(cos(angle), sin(angle));
		float frequency = 6.2 + index * 3.13;
		float wave_phase = dot(p, direction) * frequency + scenery_time * (0.6 + sqrt(frequency) * 0.27) + index * 1.71;
		slope += direction * cos(wave_phase) * 0.0023 * frequency / (1.0 + index * 0.7);
	}
	vec3 surface_normal = normalize(vec3(-slope.x, 1.0, -slope.y));
	NORMAL = normalize((VIEW_MATRIX * vec4(surface_normal, 0.0)).xyz);
	// The submerged mosaic and refracted caustics stay beneath broad specular
	// ripples. World-scale detail prevents a flat, painted-turquoise appearance.
	vec2 floor_uv = (p + vec2(a, b) * 0.028) * 7.0;
	vec2 tile_edge = abs(fract(floor_uv) - 0.5);
	float grout = smoothstep(0.455, 0.495, max(tile_edge.x, tile_edge.y));
	float caustic = 0.0;
	if (!low_quality) caustic = pow(1.0 - clamp(abs(a - 0.08) * 9.0, 0.0, 1.0), 8.0)
		* (0.35 + 0.65 * noise(p * 3.2 - scenery_time * 0.025));
	float depth = smoothstep(0.0, 1.5, min(min(p.x + 7.07, 4.37 - p.x), min(-3.875 - p.y, p.y + 8.825)));
	ALBEDO = mix(shallow_color, deep_color, 0.25 + depth * 0.48) * (1.0 - grout * 0.035);
	METALLIC = 0.0;
	ROUGHNESS = low_quality ? 0.20 : 0.145;
	SPECULAR = 0.5;
	CLEARCOAT = 0.30;
	CLEARCOAT_ROUGHNESS = 0.15;
	EMISSION = shallow_color * (0.12 + caustic * 0.26) * (1.0 - grout * 0.2);
}
