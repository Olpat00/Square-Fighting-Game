shader_type spatial;
render_mode unshaded, fog_disabled, cull_disabled, shadows_disabled;
uniform sampler2D panorama : source_color, filter_linear_mipmap;

void fragment() {
	vec3 detailed = texture(panorama, UV).rgb;
	// Keep the skyline edge intact, but let broad terrain masses carry the
	// background beneath it. Tiny rock striations must not compete with hands.
	vec3 color = mix(detailed, textureLod(panorama, UV, 3.0).rgb, smoothstep(0.26, 0.39, UV.y));
	// Compress small bright ridges behind the fight while retaining the crater
	// outline against black space. The vacuum has no invented atmospheric fog.
	float terrain = smoothstep(0.008, 0.055, dot(color, vec3(0.2126, 0.7152, 0.0722)));
	color = mix(color, color * 0.18 + vec3(0.007, 0.011, 0.017), terrain);
	ALBEDO = color * vec3(0.78, 0.84, 0.94);
}
