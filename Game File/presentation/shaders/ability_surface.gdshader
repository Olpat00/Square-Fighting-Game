shader_type spatial;
render_mode cull_disabled;

// Lit materials for the physical parts of an attack. The grain is object
// local and deterministic: it never crawls when the combat clock is paused.
uniform vec4 base_color : source_color = vec4(0.26, 0.31, 0.35, 1.0);
uniform float metalness = 0.85;
uniform float roughness_value = 0.32;
uniform float grain_strength = 0.12;
uniform int surface_kind = 0; // 0 brushed metal, 1 timber, 2 paper, 3 stone, 4 bark
varying vec3 local_position;

float hash31(vec3 p) {
	p = fract(p * vec3(0.1031, 0.11369, 0.13787));
	p += dot(p, p.yzx + 19.19);
	return fract((p.x + p.y) * p.z);
}

void vertex() { local_position = VERTEX; }

void fragment() {
	vec3 p = local_position;
	float grain = sin(p.x * 740.0 + sin(p.y * 27.0) * 0.9) * 0.5 + 0.5;
	float speckle = hash31(floor(p * 500.0));
	float pattern = mix(grain, speckle, 0.18);
	if (surface_kind == 1) {
		pattern = sin(p.y * 63.0 + sin(p.x * 12.0 + p.z * 5.0) * 2.0) * 0.5 + 0.5;
	} else if (surface_kind == 2) {
		pattern = mix(speckle, sin(p.y * 115.0) * 0.5 + 0.5, 0.23);
	} else if (surface_kind == 3) {
		pattern = hash31(floor(p * 75.0));
	} else if (surface_kind == 4) {
		// Layered longitudinal bark furrows and small weathered plates replace
		// the imported prop's flat orange plastic finish, in object space.
		float warp = sin(p.y * 5.0 + sin(p.x * 11.0)) * 0.11 + sin(p.z * 19.0) * 0.09;
		float ridge = sin((p.x + p.z + warp) * 132.0 + sin(p.y * 21.0) * 0.75);
		float split = pow(max(0.0, ridge), 5.0);
		float plate = hash31(floor(vec3(p.x * 58.0, p.y * 14.0, p.z * 58.0)));
		pattern = mix(plate, 1.0 - split, 0.66);
		grain = ridge * 0.5 + 0.5;
	}
	ALBEDO = base_color.rgb * mix(1.0 - grain_strength, 1.0 + grain_strength, pattern);
	METALLIC = metalness;
	ROUGHNESS = clamp(roughness_value + (speckle - 0.5) * 0.1, 0.05, 1.0);
	NORMAL_MAP = vec3(0.5 + (grain - 0.5) * 0.065, 0.5 + (speckle - 0.5) * 0.045, 1.0);
}
