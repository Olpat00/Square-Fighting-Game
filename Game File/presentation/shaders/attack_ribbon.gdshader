shader_type spatial;
render_mode unshaded, blend_add, depth_draw_never, cull_disabled;

uniform vec4 primary_color : source_color = vec4(0.15, 0.72, 1.0, 1.0);
uniform vec4 accent_color : source_color = vec4(0.9, 0.97, 1.0, 1.0);
uniform int signature = 0;
uniform float brightness = 1.0;
uniform float strength = 1.0;
uniform float phase = 0.0;

float hash21(vec2 p) {
	p = fract(p * vec2(123.34, 345.45));
	p += dot(p, p + 34.345);
	return fract(p.x * p.y);
}

void fragment() {
	float edge = abs(UV.y * 2.0 - 1.0);
	float body = pow(max(0.0, 1.0 - edge), 2.0);
	float core = exp(-pow((UV.y - 0.70) * 30.0, 2.0));
	float length_mask = smoothstep(0.0, 0.09, UV.x) * (1.0 - smoothstep(0.82, 1.0, UV.x));
	float grain = hash21(floor(UV * vec2(180.0, 23.0)));
	float strands = pow(0.5 + 0.5 * sin(UV.y * 88.0 + sin(UV.x * 15.0 - phase) * 1.3), 9.0);
	float pattern = 1.0;
	float opacity = body * 0.36 + core * 0.68 + strands * body * 0.22;
	if (signature == 0) {
		// Clutch: tightly compressed slipstream with three fine pressure rails.
		opacity += pow(0.5 + 0.5 * cos(UV.y * 31.4), 24.0) * body * 0.3;
	} else if (signature == 1) {
		// Sunstruck: curling plasma petals and hot particulate in a solar wake.
		pattern = 0.55 + 0.45 * sin(UV.x * 28.0 - phase * 2.0 + sin(UV.y * 10.0));
		opacity = body * (0.4 + pattern * 0.48) + core * 0.6;
	} else if (signature == 2) {
		// Heavy Duty: a broad, turbulent condensation fan around a hot edge.
		pattern = 0.56 + grain * 0.44;
		opacity = body * pattern * 0.5 + core * 0.20;
	} else if (signature == 3) {
		// Deadfall: splinter-like fibrous striations, never an opaque green slab.
		pattern = step(0.34, grain) * (0.36 + strands);
		opacity = (body * 0.35 + core * 0.30) * pattern;
	} else if (signature == 4) {
		// Fine Print: three precise, ruled cuts with clipped typography-like ticks.
		float rules = pow(0.5 + 0.5 * cos(UV.y * 31.4), 32.0);
		float ticks = step(0.87, fract(UV.x * 18.0)) * smoothstep(0.35, 0.8, UV.y);
		opacity = body * 0.10 + rules * body * 0.72 + ticks * core * 0.32;
	} else if (signature == 5) {
		// Explorer: braided mineral dust and a warm double filament.
		float braid = pow(0.5 + 0.5 * sin(UV.y * 44.0 + sin(UV.x * 32.0) * 1.8), 12.0);
		opacity = body * (0.18 + braid * 0.62) + core * 0.25;
	} else if (signature == 6) {
		// Sentinel: hard segmented plates with bright seams and a gold crest.
		float plates = smoothstep(0.03, 0.12, fract(UV.x * 11.0));
		opacity = (body * 0.44 + core * 0.64) * plates;
	} else {
		// Midnight: the luminous edge of a very thin violet silk cut.
		opacity = body * 0.13 + core * 0.55 + strands * body * 0.12;
	}
	vec3 color = mix(primary_color.rgb, accent_color.rgb, clamp(core * 0.76 + pow(UV.x, 4.0) * 0.20, 0.0, 1.0));
	ALBEDO = color * brightness;
	ALPHA = clamp(opacity * length_mask * COLOR.a * strength, 0.0, 0.92);
}
