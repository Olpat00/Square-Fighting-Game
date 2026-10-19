shader_type spatial;
render_mode unshaded, blend_mix, depth_draw_never, cull_disabled, shadows_disabled;

uniform float simulation_time = 0.0;
uniform bool low_quality = false;
varying float age;
varying float seed;
varying float opacity;

float hash(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }
float noise(vec2 p) {
	vec2 cell = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(cell), hash(cell + vec2(1.0, 0.0)), f.x), mix(hash(cell + vec2(0.0, 1.0)), hash(cell + vec2(1.0)), f.x), f.y);
}
void vertex() {
	seed = INSTANCE_CUSTOM.x;
	age = fract(seed + simulation_time * (0.026 + INSTANCE_CUSTOM.y * 0.019));
	opacity = INSTANCE_CUSTOM.z;
	VERTEX.xy *= 0.74 + age * 1.7;
	VERTEX.y += age * 3.8;
	VERTEX.x += sin(age * 2.8 + seed * 9.0) * age * 0.9;
}
void fragment() {
	vec2 p = (UV - 0.5) * 2.0;
	float rounded = max(0.0, 1.0 - dot(p, p));
	float cloud = noise(UV * 3.4 + vec2(seed * 23.0, -simulation_time * 0.08));
	if (!low_quality) cloud = cloud * 0.65 + noise(UV * 7.0 + seed * 13.0 - vec2(simulation_time * 0.025, age)) * 0.35;
	float life = sin(age * 3.14159265);
	float bottom_glow = (1.0 - age) * 0.14;
	ALBEDO = mix(vec3(0.22, 0.265, 0.27), vec3(0.45, 0.24, 0.12), bottom_glow);
	ALPHA = rounded * rounded * smoothstep(0.08, 0.70, cloud) * life * opacity;
}
