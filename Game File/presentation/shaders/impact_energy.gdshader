shader_type spatial;
render_mode unshaded, blend_add, depth_draw_never, cull_disabled, fog_disabled;

uniform vec4 effect_color : source_color = vec4(1.0, 0.7, 0.3, 1.0);
uniform float brightness = 1.1;
uniform int shape = 0;
instance uniform float age = 0.0;

void fragment() {
	vec2 p = UV * 2.0 - 1.0;
	float opacity;
	float core;
	if (shape == 1) {
		float radius = mix(0.16, 0.93, smoothstep(0.0, 0.6, age));
		float line = abs(length(p) - radius);
		opacity = (1.0 - smoothstep(0.016, 0.055, line)) * (1.0 - smoothstep(0.28, 0.68, age));
		core = 0.12;
	} else {
		// Tapered streak with a softer tail, instead of a luminous square chip.
		float width = max(0.04, (1.0 - p.x * p.x) * 0.38);
		float body = 1.0 - smoothstep(width * 0.18, width, abs(p.y));
		float ends = smoothstep(-1.0, -0.72, p.x) * (1.0 - smoothstep(0.75, 1.0, p.x));
		opacity = body * ends * (1.0 - smoothstep(0.15, 1.0, age));
		core = body * 0.18;
	}
	vec3 tint = mix(effect_color.rgb, vec3(1.0, 0.94, 0.83), core);
	// Unshaded output uses ALBEDO directly; EMISSION alone does not change
	// its visible intensity. This keeps the reduced-flashes setting effective.
	ALBEDO = tint * brightness;
	ALPHA = opacity * effect_color.a * 0.78;
}
