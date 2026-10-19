shader_type spatial;
render_mode specular_schlick_ggx;

uniform vec4 base_color : source_color = vec4(0.18, 0.24, 0.26, 1.0);
uniform float metallic_value = 0.72;
uniform float roughness_value = 0.56;
uniform int surface_pattern = 0;
uniform bool low_quality = false;
varying vec3 object_position;
varying vec3 object_normal;

float hash21(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float rounded_bar(vec2 p, vec2 extent) {
	vec2 q = abs(p) - extent;
	float distance_to_bar = length(max(q, 0.0)) + min(max(q.x, q.y), 0.0);
	float aa = max(fwidth(distance_to_bar), 0.004);
	return 1.0 - smoothstep(-aa, aa, distance_to_bar);
}

void vertex() {
	object_position = VERTEX;
	object_normal = NORMAL;
}

void fragment() {
	vec3 axis = abs(object_normal);
	vec2 p = axis.y > 0.65 ? object_position.xz : object_position.xy;
	if (axis.x > 0.65) p = object_position.zy;
	vec2 grain_scale = vec2(145.0, 520.0);
	float grain_visibility = 1.0 - smoothstep(0.6, 1.5, max(fwidth(p.x * grain_scale.x), fwidth(p.y * grain_scale.y)));
	float grain = low_quality ? 0.5 : mix(0.5, hash21(floor(p * grain_scale)), grain_visibility);
	float broad = hash21(floor(p * 7.0));
	vec3 color = base_color.rgb * (0.88 + broad * 0.10 + grain * 0.11);
	float height = 0.0;
	float roughness = roughness_value + (grain - 0.5) * 0.10;
	if (surface_pattern == 1 && axis.y > 0.65) {
		// Alternating, short diamond treads retain visible plate joints and a quiet silhouette.
		vec2 cell = p * 3.6;
		vec2 id = floor(cell);
		vec2 q = fract(cell) - 0.5;
		float handed = mod(id.x + id.y, 2.0) < 1.0 ? 1.0 : -1.0;
		vec2 rotated = vec2(q.x + q.y * handed, q.y - q.x * handed) * 0.7071;
		float tread = rounded_bar(rotated, vec2(0.26, 0.045));
		color *= 0.96 + tread * 0.09;
		height = tread * 0.0015;
		roughness -= tread * 0.09;
	} else if (surface_pattern == 2 && axis.z > 0.65) {
		// These dark slots sit inside a physical recessed cassette and steel frame.
		float slot_coordinate = abs(fract(p.x * 9.0) - 0.5);
		float aa = max(fwidth(slot_coordinate), 0.005);
		float fin = smoothstep(0.22 - aa, 0.22 + aa, slot_coordinate);
		color *= 0.30 + fin * 0.78;
		height = fin * 0.010;
	} else if (surface_pattern == 3) {
		float stripe_coordinate = fract((p.x + p.y * 0.85) * 4.4);
		float aa = max(fwidth(stripe_coordinate), 0.006);
		float stripe = smoothstep(0.46 - aa, 0.46 + aa, stripe_coordinate);
		color = mix(vec3(0.085, 0.096, 0.087), base_color.rgb, stripe) * (0.87 + grain * 0.13);
		roughness = 0.73;
	}
	if (!low_quality && height > 0.0 && surface_pattern == 2) {
		// Screen-space surface gradient works on the explicitly flat bevel normals;
		// it does not depend on tangent data or alter the top collision plane.
		vec3 dpdx = dFdx(VERTEX);
		vec3 dpdy = dFdy(VERTEX);
		vec3 r1 = cross(dpdy, NORMAL);
		vec3 r2 = cross(NORMAL, dpdx);
		float determinant = dot(dpdx, r1);
		vec3 gradient = sign(determinant) * (dFdx(height) * r1 + dFdy(height) * r2);
		NORMAL = normalize(abs(determinant) * NORMAL - gradient);
	}
	ALBEDO = color;
	METALLIC = metallic_value;
	ROUGHNESS = clamp(roughness, 0.20, 0.96);
}
