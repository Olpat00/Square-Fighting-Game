shader_type spatial;
render_mode unshaded, blend_add, depth_draw_never, cull_disabled;

uniform vec4 primary_color : source_color = vec4(0.1, 0.7, 1.0, 1.0);
uniform vec4 accent_color : source_color = vec4(0.9, 0.95, 1.0, 1.0);
uniform int signature = 0;
uniform float amount = 0.0;
uniform float phase = 0.0;
uniform float brightness = 1.0;

void fragment() {
	float fresnel = pow(1.0 - abs(dot(normalize(NORMAL), normalize(VIEW))), 3.1);
	float threads = pow(0.5 + 0.5 * sin(UV.y * 80.0 + sin(UV.x * 19.0 + phase) * 3.0 - phase * 3.0), 22.0);
	float meridians = pow(0.5 + 0.5 * sin(UV.x * 50.265 + phase * 0.6), 30.0);
	float detail = threads * 0.32 + meridians * 0.14;
	if (signature == 1) detail += pow(0.5 + 0.5 * sin(UV.x * 31.4 + UV.y * 20.0 - phase * 2.0), 10.0) * fresnel * 0.36;
	if (signature == 2 || signature == 3 || signature == 5) detail *= 0.40;
	if (signature == 4 || signature == 6) detail = meridians * 0.42 + threads * 0.13;
	ALBEDO = mix(primary_color.rgb, accent_color.rgb, threads * 0.50) * brightness;
	ALPHA = (fresnel * 0.20 + detail) * amount;
}
