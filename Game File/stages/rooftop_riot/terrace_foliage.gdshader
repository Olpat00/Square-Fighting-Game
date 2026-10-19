shader_type spatial;
render_mode cull_disabled, depth_draw_opaque;

uniform vec4 leaf_color : source_color = vec4(0.03, 0.12, 0.04, 1.0);
uniform bool low_quality = false;
uniform float scenery_time = 0.0;
varying vec3 world_position;

void vertex() {
	world_position = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	float crown = smoothstep(2.4, 6.3, world_position.y);
	float breeze = sin(scenery_time * 0.64 + world_position.x * 0.48 + world_position.z * 0.35);
	float flutter = sin(scenery_time * 1.62 + world_position.x * 3.1 + world_position.z * 2.7);
	VERTEX.x += crown * breeze * 0.045;
	if (!low_quality) {
		VERTEX.x += crown * (breeze * 0.105 + flutter * 0.019);
		VERTEX.z += crown * breeze * 0.065;
	}
}

void fragment() {
	if (!FRONT_FACING) NORMAL = -NORMAL;
	float variation = 0.92 + 0.08 * sin(world_position.x * 8.7 + world_position.z * 4.2);
	ALBEDO = leaf_color.rgb * variation;
	ROUGHNESS = 0.44;
	SPECULAR = 0.35;
	BACKLIGHT = leaf_color.rgb * 1.25;
}
