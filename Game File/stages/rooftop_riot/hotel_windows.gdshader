shader_type spatial;
render_mode cull_back;
uniform float scenery_time = 0.0;
uniform bool low_quality = false;

varying vec3 world_position;
void vertex() { world_position = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz; }

void fragment() {
	vec2 bay = vec2((world_position.x + 8.66) / 1.02, (world_position.y + 2.35) / 2.2);
	vec2 room = (fract(bay) - vec2(0.5, 0.48)) / vec2(0.833, 0.709) + 0.5;
	float variation = fract(sin(dot(floor(bay), vec2(31.17, 82.63))) * 1738.83);
	float wall = smoothstep(0.05, 0.35, room.y) * (1.0 - smoothstep(0.80, 1.0, room.y));
	float corners = smoothstep(0.0, 0.22, room.x) * (1.0 - smoothstep(0.75, 1.0, room.x));
	vec2 lamp_at = vec2(0.68, 0.63);
	float lamp_pool = exp(-length((room - lamp_at) * vec2(1.1, 0.75)) * 4.0);
	float lamp_shade = (1.0 - smoothstep(0.065, 0.085, abs(room.x - lamp_at.x)))
		* (1.0 - smoothstep(0.040, 0.055, abs(room.y - lamp_at.y)));
	float furnishing = 1.0 - smoothstep(0.17, 0.22, room.y);
	vec3 warm = mix(vec3(0.64, 0.28, 0.09), vec3(0.85, 0.48, 0.20), variation);
	float activity = 0.92 + 0.08 * sin(scenery_time * (0.16 + variation * 0.05) + variation * 21.0);
	float visitor_x = 0.5 + sin(scenery_time * 0.23 + variation * 37.0) * 0.65;
	float visitor = (1.0 - smoothstep(0.035, 0.065, abs(room.x - visitor_x))) * smoothstep(0.22, 0.27, room.y) * (1.0 - smoothstep(0.60, 0.66, room.y));
	ALBEDO = warm * 0.045;
	ROUGHNESS = 0.4;
	EMISSION = warm * (0.055 + wall * corners * 0.15 + lamp_pool * 0.30)
		* (1.0 - furnishing * 0.55) * activity * (1.0 - visitor * (low_quality ? 0.18 : 0.38)) + vec3(0.8, 0.59, 0.32) * lamp_shade * 0.65;
}
