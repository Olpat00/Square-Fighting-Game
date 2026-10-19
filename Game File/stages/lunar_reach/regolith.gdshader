shader_type spatial;
render_mode diffuse_burley, specular_schlick_ggx;

uniform sampler2D grain_map : repeat_enable, filter_linear_mipmap_anisotropic;
uniform vec3 dust_dark : source_color = vec3(0.13, 0.15, 0.19);
uniform vec3 dust_light : source_color = vec3(0.32, 0.35, 0.38);
uniform float texture_scale = 1.0;
uniform float relief = 0.006;
uniform float fracture_strength = 0.0;
uniform bool low_quality = false;
varying vec3 world_position;
varying vec3 world_normal;

void vertex() {
	world_position = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	world_normal = normalize(MODEL_NORMAL_MATRIX * NORMAL);
}

float triplanar_grain(vec3 p, vec3 w) {
	return texture(grain_map, p.yz).r * w.x + texture(grain_map, p.xz).r * w.y + texture(grain_map, p.xy).r * w.z;
}

void fragment() {
	vec3 weights = pow(abs(world_normal), vec3(4.0));
	weights /= max(dot(weights, vec3(1.0)), 0.0001);
	vec3 p = world_position * texture_scale;
	float broad = triplanar_grain(p * 0.035, weights);
	float grain = triplanar_grain(p * 0.10, weights);
	float micro = grain;
	if (!low_quality) micro = triplanar_grain(p * 0.65, weights);
	float mineral = smoothstep(0.63, 0.83, micro);
	float fracture_field = broad;
	if (!low_quality && fracture_strength > 0.0) fracture_field = triplanar_grain(p * 0.035 + vec3(0.37), weights);
	float fractures = 1.0 - smoothstep(0.004, 0.022, abs(fracture_field - 0.49));
	float shade = clamp(broad * 0.5 + grain * 0.44 + micro * 0.14, 0.0, 1.0);
	ALBEDO = mix(dust_dark, dust_light, shade) * (1.0 + mineral * 0.11) * (1.0 - fractures * fracture_strength);
	float fight_backdrop = (1.0 - smoothstep(10.0, 24.0, abs(world_position.x))) * (1.0 - smoothstep(8.0, 38.0, -world_position.z));
	ALBEDO = mix(ALBEDO, dust_dark * 1.20, fight_backdrop * 0.42);
	ROUGHNESS = clamp(0.89 + micro * 0.11 - mineral * 0.14, 0.0, 1.0);
	SPECULAR = 0.19;
	// A fixed world-space gradient is stable across triangle boundaries and
	// orthographic camera motion. Never differentiate interpolated VERTEX here:
	// subpixel triangles can turn that into a full-strength speckled normal.
	if (!low_quality) {
		float e = 0.04;
		float gx = triplanar_grain((p + vec3(e, 0.0, 0.0)) * 0.10, weights) - triplanar_grain((p - vec3(e, 0.0, 0.0)) * 0.10, weights);
		float gy = triplanar_grain((p + vec3(0.0, e, 0.0)) * 0.10, weights) - triplanar_grain((p - vec3(0.0, e, 0.0)) * 0.10, weights);
		float gz = triplanar_grain((p + vec3(0.0, 0.0, e)) * 0.10, weights) - triplanar_grain((p - vec3(0.0, 0.0, e)) * 0.10, weights);
		vec3 gradient = vec3(gx, gy, gz) * relief / (2.0 * e);
		gradient -= world_normal * dot(gradient, world_normal);
		NORMAL = normalize(NORMAL - (VIEW_MATRIX * vec4(gradient, 0.0)).xyz);
	}
}
