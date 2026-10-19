shader_type spatial;
render_mode unshaded, blend_add, depth_draw_never, cull_disabled, fog_disabled;

uniform vec4 effect_color : source_color = vec4(0.8, 0.85, 1.0, 1.0);
uniform float brightness = 1.0;
uniform bool taper = true;
instance uniform float age = 0.0;
instance uniform float opacity = 1.0;
instance uniform float intensity = 1.0;

void fragment() {
	float edge = abs(UV.y * 2.0 - 1.0);
	float thin_core = 1.0 - smoothstep(0.055, 0.18, edge);
	float halo = pow(max(0.0, 1.0 - edge), 3.0) * 0.12;
	float ends = taper ? smoothstep(0.0, 0.10, UV.x) * (1.0 - smoothstep(0.78, 1.0, UV.x)) : 1.0;
	vec3 tint = mix(effect_color.rgb, vec3(0.96, 0.97, 1.0), thin_core * 0.45);
	ALBEDO = tint * brightness * intensity;
	ALPHA = (thin_core * 0.65 + halo) * ends * opacity * effect_color.a;
}
