shader_type spatial;
render_mode cull_disabled, shadows_disabled;

uniform float simulation_time = 0.0;
uniform bool low_quality = false;
uniform bool falling = false;
uniform float heat = 1.0;
varying vec3 local_position;

float hash(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }
float noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1.0, 0.0)), f.x), mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0)), f.x), f.y);
}
void vertex() { local_position = VERTEX; }
void fragment() {
	vec2 p = falling ? UV * vec2(8.0, 3.0) : local_position.xz * 0.83;
	p.y += simulation_time * (falling ? -0.47 : -0.027);
	float n = noise(p);
	if (!low_quality) { n += noise(p * 3.7 + n * 0.8) * 0.17; }
	float fissure = 1.0 - smoothstep(0.009, 0.059, abs(n - 0.51));
	float stream = falling ? pow(max(0.0, sin(UV.x * 43.0 + n * 5.0)), 2.0) : 0.0;
	float molten = max(fissure * 0.88, stream * 0.88);
	vec3 crust = mix(vec3(0.021, 0.026, 0.030), vec3(0.05, 0.037, 0.030), n);
	vec3 fire = mix(vec3(0.75, 0.021, 0.004), vec3(1.0, 0.32, 0.023), pow(molten, 3.0));
	ALBEDO = mix(crust, fire * 0.3, molten);
	EMISSION = fire * molten * heat * (falling ? 1.5 : 0.85);
	ROUGHNESS = mix(0.89, 0.41, molten);
	METALLIC = 0.12;
}
