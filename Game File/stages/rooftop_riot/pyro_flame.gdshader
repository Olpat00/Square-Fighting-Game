shader_type spatial;
render_mode unshaded, blend_add, depth_draw_never, cull_disabled;

uniform float phase = 0.0;

float hash(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }
float noise(vec2 p) {
	vec2 cell = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(cell), hash(cell + vec2(1, 0)), f.x),
		mix(hash(cell + vec2(0, 1)), hash(cell + vec2(1, 1)), f.x), f.y);
}

void fragment() {
	float height = 1.0 - UV.y;
	float clock = TIME * 3.7 + phase;
	vec2 flow = vec2(UV.x * 5.0, height * 4.5 - clock);
	float turbulence = noise(flow) * 0.65 + noise(flow * 2.1) * 0.35;
	float center = 0.5 + sin(height * 8.0 - clock * 0.8) * height * 0.07;
	float width = mix(0.40, 0.035, pow(height, 0.85));
	float envelope = 1.0 - smoothstep(width * 0.40, width, abs(UV.x - center));
	float density = clamp(envelope - height * 0.65 + (turbulence - 0.5) * 1.1, 0.0, 1.0);
	density *= smoothstep(0.0, 0.045, height) * (1.0 - smoothstep(0.76, 1.0, height));
	float core = pow(density, 2.0) * (1.0 - height);
	vec3 flame = mix(vec3(1.2, 0.12, 0.015), vec3(1.5, 0.73, 0.18), density);
	flame = mix(flame, vec3(1.8, 1.32, 0.62), core);
	ALBEDO = flame;
	ALPHA = density * 0.86;
}
