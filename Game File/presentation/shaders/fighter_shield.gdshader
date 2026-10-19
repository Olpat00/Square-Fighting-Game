shader_type spatial;
render_mode unshaded, blend_add, depth_draw_never, cull_back, fog_disabled;

uniform vec4 shield_color : source_color = vec4(0.3, 0.7, 1.0, 1.0);

void fragment() {
	float facing = max(dot(normalize(NORMAL), normalize(VIEW)), 0.0);
	float rim = pow(1.0 - facing, 3.2);
	// Restrained contour bands provide structure while leaving the face clear.
	float latitude = pow(0.5 + 0.5 * cos(UV.y * 75.3982), 18.0);
	float shell = rim * 0.70 + latitude * rim * 0.14;
	vec3 color = mix(shield_color.rgb, vec3(0.85, 0.96, 1.0), rim * 0.22);
	ALBEDO = color;
	EMISSION = color * 0.85;
	ALPHA = shell;
}
