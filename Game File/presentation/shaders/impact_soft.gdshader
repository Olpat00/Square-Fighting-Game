shader_type spatial;
render_mode blend_mix, depth_draw_never, cull_disabled;

uniform vec4 effect_color : source_color = vec4(0.5, 0.5, 0.5, 1.0);
uniform int shape = 0;
instance uniform float age = 0.0;

float hash21(vec2 p) {
	p = fract(p * vec2(123.34, 345.45));
	p += dot(p, p + 34.345);
	return fract(p.x * p.y);
}

float noise21(vec2 p) {
	vec2 cell = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash21(cell), hash21(cell + vec2(1.0, 0.0)), f.x), mix(hash21(cell + vec2(0.0, 1.0)), hash21(cell + vec2(1.0)), f.x), f.y);
}

float turbulence(vec2 p) {
	return noise21(p) * 0.57 + noise21(p * 2.13 + 7.7) * 0.28 + noise21(p * 4.41 + 3.2) * 0.15;
}

void fragment() {
	vec2 p = UV * 2.0 - 1.0;
	float opacity;
	float illumination = 1.0;
	if (shape == 1) {
		// A small tapered stain/droplet. Blood never uses emissive materials.
		float width = max(0.03, 0.40 * (1.0 - p.x * p.x) * (0.8 + p.x * 0.3));
		opacity = (1.0 - smoothstep(width * 0.55, width, abs(p.y))) * (1.0 - smoothstep(0.78, 1.0, abs(p.x)));
		opacity *= 1.0 - smoothstep(0.3, 1.0, age);
	} else {
		// Layered extinction and soft turbulent edges read as suspended dust,
		// rather than a repeated five-lobed cartoon cloud. No TIME clock: paused
		// or frozen impacts retain their internal structure along with the pose.
		vec2 flow = p * 3.7 + vec2(age * 0.25, -age * 0.60);
		float cloud = turbulence(flow);
		float radius = length(p);
		float envelope = 1.0 - smoothstep(0.18, 0.95, radius);
		float density = envelope * smoothstep(0.21, 0.68, cloud);
		opacity = (1.0 - exp(-density * 2.2)) * 0.34;
		opacity *= 1.0 - smoothstep(0.12, 1.0, age);
		illumination = 0.70 + 0.35 * turbulence(flow + vec2(-0.18, 0.25));
	}
	ALBEDO = effect_color.rgb * illumination;
	ROUGHNESS = 1.0;
	SPECULAR = 0.08;
	ALPHA = opacity * effect_color.a;
}
