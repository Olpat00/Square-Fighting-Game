shader_type spatial;
render_mode specular_schlick_ggx;

uniform vec4 base_color : source_color = vec4(0.18, 0.22, 0.24, 1.0);
uniform float metallic_value = 0.7;
uniform float roughness_value = 0.6;
uniform bool low_quality = false;
varying vec3 object_position;

float grain(vec3 p) {
	return fract(sin(dot(floor(p), vec3(12.9898, 78.233, 34.147))) * 43758.5453);
}
void vertex() { object_position = VERTEX; }
void fragment() {
	float speckle = low_quality ? 0.5 : grain(object_position * 32.0);
	float brushed = low_quality ? 0.5 : sin(object_position.x * 74.0 + object_position.z * 21.0) * 0.5 + 0.5;
	ALBEDO = base_color.rgb * (0.94 + speckle * 0.055 + brushed * 0.025);
	METALLIC = metallic_value;
	ROUGHNESS = clamp(roughness_value + (speckle - 0.5) * 0.05, 0.1, 1.0);
}
