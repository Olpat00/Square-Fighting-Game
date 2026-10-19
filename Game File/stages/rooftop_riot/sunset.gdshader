shader_type spatial;
render_mode unshaded, fog_disabled, cull_disabled, shadows_disabled;
uniform float blue_hour : hint_range(0.0, 1.0) = 0.0;
uniform sampler2D city_plate : source_color, filter_linear_mipmap;
uniform float scenery_time = 0.0;
uniform bool low_quality = false;
uniform vec2 parallax_offset = vec2(0.0);

float cloud_field(vec2 p) {
	// Continuous warped waves avoid visible lattice boundaries in the sky.
	vec2 drift = p + vec2(sin(p.y * 0.73 + p.x * 0.13), sin(p.x * 0.51 - p.y * 0.19)) * 0.46;
	float broad = sin(drift.x * 0.89 + drift.y * 0.67);
	float detail = sin(drift.x * 1.43 - drift.y * 0.93 + sin(drift.y * 0.81));
	return clamp(0.5 + broad * 0.29 + detail * 0.19, 0.0, 1.0);
}

void fragment() {
	vec2 uv = clamp(UV + parallax_offset, vec2(0.001), vec2(0.999));
	vec3 color = texture(city_plate, uv).rgb;
	float sky = 1.0 - smoothstep(0.38, 0.55, uv.y);
	float wisps = cloud_field(uv * vec2(12.0, 7.0) + vec2(scenery_time * 0.026, -scenery_time * 0.004));
	if (!low_quality) wisps = wisps * 0.7 + cloud_field(uv * vec2(25.0, 17.0) + vec2(scenery_time * 0.046, 0.0)) * 0.3;
	color = mix(color, vec3(0.30, 0.33, 0.40), sky * smoothstep(0.48, 0.87, wisps) * 0.12);
	// The original matte is a far horizon only. A gentle exposure fall keeps
	// local player silhouettes above it without flattening the cloud detail.
	float luma = dot(color, vec3(0.2126, 0.7152, 0.0722));
	color = mix(color, vec3(luma), 0.10);
	color *= mix(vec3(0.60, 0.64, 0.77), vec3(0.40, 0.51, 0.74), blue_hour * 0.5);
	ALBEDO = color;
}
