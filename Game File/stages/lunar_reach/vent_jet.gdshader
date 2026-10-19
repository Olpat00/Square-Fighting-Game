shader_type spatial;
render_mode unshaded, blend_add, depth_draw_never, cull_disabled, shadows_disabled;

uniform float phase = 0.0;

void fragment() {
	float y = 1.0 - UV.y;
	float x = UV.x - 0.5;
	float width = 0.08 + y * 0.3;
	float plume = exp(-pow(x / width, 2.0) * 3.0) * pow(1.0 - y, 0.95);
	float flecks = pow(max(0.0, sin(x * 191.0 + y * 67.0 + TIME * -24.0 + phase) * sin(y * 98.0 - TIME * 41.0)), 9.0);
	float ring = pow(max(0.0, sin(y * 70.0 - TIME * 36.0)), 11.0);
	ALBEDO = mix(vec3(0.36, 0.6, 0.86), vec3(0.89, 0.96, 1.0), pow(1.0 - y, 3.0));
	EMISSION = ALBEDO * (0.8 + ring * 0.4);
	ALPHA = plume * (0.30 + flecks * 0.6) * smoothstep(0.0, 0.04, y);
}
