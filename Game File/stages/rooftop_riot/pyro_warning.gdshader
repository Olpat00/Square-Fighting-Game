shader_type spatial;
render_mode unshaded, blend_add, depth_draw_never, cull_disabled;

void fragment() {
	vec2 edge = abs(UV - 0.5);
	float frame = smoothstep(0.415, 0.45, max(edge.x, edge.y))
		* (1.0 - smoothstep(0.475, 0.5, max(edge.x, edge.y)));
	float stripes = step(0.56, fract(UV.x * 6.0 + UV.y * 4.0)) * 0.15;
	float ink = frame + stripes * (1.0 - smoothstep(0.37, 0.44, max(edge.x, edge.y)));
	ALBEDO = vec3(1.0, 0.40, 0.065);
	ALPHA = ink * (0.65 + sin(TIME * 5.0) * 0.15);
}
