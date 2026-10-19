shader_type spatial;
render_mode unshaded, blend_mix, depth_draw_never, cull_disabled, shadows_disabled;

// Art-directed molten ribbons. Flow runs down the ribbon, never on screen TIME.
uniform float simulation_time = 0.0;
uniform bool low_quality = false;
uniform float flow_speed = 0.44;
uniform float phase = 0.0;
uniform bool pool = false;
varying vec2 flow_uv;

float hash(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }
float noise(vec2 p) {
	vec2 cell = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(cell), hash(cell + vec2(1.0, 0.0)), f.x), mix(hash(cell + vec2(0.0, 1.0)), hash(cell + vec2(1.0)), f.x), f.y);
}
void vertex() {
	flow_uv = UV;
	if (!pool) VERTEX.z += sin(UV.y * 16.0 - simulation_time * 1.9 + phase) * 0.018 * sin(UV.x * 3.14159265);
}
void fragment() {
	vec2 p = flow_uv * (pool ? vec2(3.5, 2.0) : vec2(4.5, 9.0));
	p.y -= simulation_time * flow_speed + phase;
	float broad = noise(p);
	float fine = low_quality ? broad : noise(p * vec2(2.7, 1.6) + broad * 0.9);
	float dark_crust = smoothstep(0.48, 0.79, broad * 0.66 + fine * 0.34);
	float strands = sin(flow_uv.x * 30.0 + broad * 4.0) * 0.5 + 0.5;
	float heat = clamp(0.79 - dark_crust * 0.70 + strands * 0.16, 0.0, 1.0);
	vec3 orange = mix(vec3(0.20, 0.009, 0.001), vec3(0.78, 0.12, 0.009), heat * heat);
	vec3 cooled = vec3(0.072, 0.012, 0.004);
	ALBEDO = mix(orange, cooled, dark_crust * 0.61);
	EMISSION = orange * heat * 0.44;
	float edge = smoothstep(0.0, 0.11, flow_uv.x) * (1.0 - smoothstep(0.89, 1.0, flow_uv.x));
	float ends = smoothstep(0.0, 0.018, flow_uv.y) * (1.0 - smoothstep(0.96, 1.0, flow_uv.y));
	ALPHA = edge * ends * (pool ? 0.73 : 0.90);
}
