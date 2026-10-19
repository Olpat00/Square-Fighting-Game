shader_type spatial;
render_mode diffuse_burley, specular_schlick_ggx;

uniform vec3 base_color : source_color = vec3(0.5, 0.52, 0.55);
uniform float metalness = 0.7;
uniform float base_roughness = 0.39;
uniform bool low_quality = false;
uniform sampler2D grain_map : repeat_enable, filter_linear_mipmap_anisotropic;
varying vec3 wp;

void vertex() {
	wp = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	float grain = texture(grain_map, wp.xz * 1.8 + wp.y * 0.45).r;
	float brushed = grain;
	float dust = 0.0;
	if (!low_quality) {
		brushed = texture(grain_map, vec2(wp.x * 0.4, wp.z * 18.0 + wp.y * 22.0)).r;
		dust = smoothstep(0.57, 0.8, texture(grain_map, wp.xz * 0.13 + wp.y * 0.16).r);
	}
	ALBEDO = base_color * (0.97 + grain * 0.06) * (1.0 - dust * 0.025);
	ROUGHNESS = clamp(base_roughness + brushed * 0.035 + dust * 0.02, 0.08, 1.0);
	// Large per-pixel metallic changes looked like camouflage under the solar
	// key. The alloys retain their authored response; dust is a faint finish.
	METALLIC = metalness * (1.0 - dust * 0.035);
	SPECULAR = 0.45;
}
