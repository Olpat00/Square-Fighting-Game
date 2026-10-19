shader_type spatial;
render_mode unshaded, blend_add, depth_draw_never, cull_disabled, shadows_disabled;

uniform float simulation_time = 0.0;
uniform bool low_quality = false;
varying float ember_alpha;
void vertex() {
	float phase = INSTANCE_CUSTOM.x;
	float cycle = fract(phase + simulation_time * (0.025 + INSTANCE_CUSTOM.y * 0.025));
	VERTEX.y += cycle * 9.0;
	VERTEX.x += sin(cycle * 9.0 + phase * 25.0) * 0.6;
	ember_alpha = sin(cycle * 3.14159265) * (0.45 + INSTANCE_CUSTOM.z * 0.4);
}
void fragment() {
	vec2 p = (UV - 0.5) * 2.0;
	float core = max(0.0, 1.0 - dot(p, p));
	ALBEDO = vec3(1.0, 0.34, 0.06);
	EMISSION = ALBEDO * 1.4;
	ALPHA = core * core * ember_alpha;
}
