shader_type spatial;
render_mode unshaded, blend_add, depth_draw_never, cull_disabled, shadows_disabled;
uniform float simulation_time = 0.0;
uniform bool warning = false;
uniform bool low_quality = false;
void fragment() {
	vec2 p = UV - 0.5;
	if (warning) {
		float r = length(p * vec2(1.0, 1.15));
		float ring = smoothstep(0.32, 0.35, r) * (1.0 - smoothstep(0.43, 0.47, r));
		float chevron = step(0.56, fract(UV.x * 5.0 + abs(p.y) * 4.0));
		ALBEDO = vec3(1.0, 0.55, 0.08);
		ALPHA = (ring + chevron * 0.20 * (1.0 - smoothstep(0.25, 0.32, r))) * (0.74 + sin(simulation_time * 9.0) * 0.16);
	} else {
		float h = 1.0 - UV.y;
		float warp = sin(h * 13.0 - simulation_time * 22.0) * 0.033;
		float plume = exp(-pow((p.x + warp) / (0.18 * (1.0 - h) + 0.02), 2.0));
		float sparks = low_quality ? 0.0 : pow(max(0.0, sin(UV.x * 152.0 + h * 29.0 - simulation_time * 34.0)), 17.0);
		ALBEDO = mix(vec3(1.0, 0.20, 0.025), vec3(1.0, 0.83, 0.39), pow(1.0 - h, 3.0));
		EMISSION = ALBEDO * 1.6;
		ALPHA = (plume * 0.93 + sparks * 0.08) * smoothstep(0.0, 0.03, h) * (1.0 - smoothstep(0.70, 1.0, h));
	}
}
