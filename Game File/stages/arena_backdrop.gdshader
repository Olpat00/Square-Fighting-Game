shader_type spatial;
render_mode unshaded, fog_disabled, cull_disabled, depth_draw_opaque;
uniform sampler2D panorama : source_color, filter_linear_mipmap_anisotropic;
uniform float exposure : hint_range(0.1, 2.0) = 0.8;
uniform float scenery_time = 0.0;
uniform int ambience_kind = 0;
uniform bool low_quality = false;
uniform vec2 parallax_offset = vec2(0.0);

float hash(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }
float noise(vec2 p) {
	vec2 i = floor(p), f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1.0, 0.0)), f.x), mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0)), f.x), f.y);
}
float fall_mask(vec2 uv, vec2 center, vec2 radius) {
	vec2 p = (uv - center) / radius;
	return (1.0 - smoothstep(0.58, 1.0, abs(p.x))) * (1.0 - smoothstep(0.76, 1.0, abs(p.y)));
}
void fragment() {
	vec2 uv = clamp(UV + parallax_offset, vec2(0.001), vec2(0.999));
	vec3 color = texture(panorama, uv).rgb;
	if (ambience_kind == 1) {
		// Slow moving light in the open water, rather than translating the reef.
		float water = smoothstep(0.03, 0.18, color.b - color.r);
		float rays = sin(uv.x * 43.0 + sin(uv.y * 7.0 + scenery_time * 0.17) * 1.5 + scenery_time * 0.22);
		float shimmer = sin(uv.x * 91.0 + uv.y * 63.0 - scenery_time * 0.61);
		color *= 1.0 + water * (rays * 0.045 + shimmer * (low_quality ? 0.008 : 0.018));
	} else if (ambience_kind == 2) {
		// Motion is confined to the painted molten falls and river. Stone,
		// machinery and window edges remain sharp and stationary.
		float falls = max(max(fall_mask(uv, vec2(0.082, 0.45), vec2(0.056, 0.43)), fall_mask(uv, vec2(0.93, 0.51), vec2(0.065, 0.44))),
			max(fall_mask(uv, vec2(0.23, 0.76), vec2(0.031, 0.16)), fall_mask(uv, vec2(0.67, 0.80), vec2(0.032, 0.16))));
		float river = smoothstep(0.86, 0.97, uv.y);
		float molten = smoothstep(0.14, 0.38, color.r - color.b) * smoothstep(1.28, 1.80, color.r / max(color.g, 0.015));
		float flow = noise(vec2(uv.x * 162.0, uv.y * 92.0 - scenery_time * 2.8));
		if (!low_quality) flow = flow * 0.72 + noise(vec2(uv.x * 307.0, uv.y * 186.0 - scenery_time * 5.6)) * 0.28;
		float eddies = noise(vec2(uv.x * 95.0 - scenery_time * 1.9, uv.y * 127.0 + sin(scenery_time * 0.3) * 0.3));
		float living = mix(flow, eddies, river);
		float region = molten * max(falls, river);
		color *= 1.0 + region * ((living - 0.48) * 0.78 + sin(scenery_time * 1.4 + uv.y * 9.0) * 0.045);
		color += vec3(0.10, 0.025, 0.003) * region * smoothstep(0.65, 0.90, living);
	}
	ALBEDO = color * exposure;
}
