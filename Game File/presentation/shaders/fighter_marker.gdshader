shader_type spatial;
render_mode unshaded, blend_mix, depth_draw_never, cull_disabled;

uniform vec4 player_color : source_color = vec4(0.3, 0.7, 1.0, 1.0);

void fragment() {
	vec2 p = UV * 2.0 - 1.0;
	float radius = length(p);
	float outer = smoothstep(0.75, 0.79, radius) * (1.0 - smoothstep(0.91, 0.96, radius));
	float inner = smoothstep(0.60, 0.64, radius) * (1.0 - smoothstep(0.67, 0.70, radius));
	// Four open arcs remain readable on the roof without a filled plastic puck.
	float gap = smoothstep(0.08, 0.15, min(abs(p.x), abs(p.y)));
	ALBEDO = player_color.rgb;
	EMISSION = player_color.rgb * 0.35;
	ALPHA = (outer * gap * 0.8 + inner * 0.3) * player_color.a;
}
