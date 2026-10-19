shader_type spatial;
uniform float scene_time = 0.0;
uniform bool low_quality = false;
uniform vec4 deep_color : source_color = vec4(0.025,0.26,0.25,1.0);
varying vec3 world_pos;
void vertex() { world_pos = (MODEL_MATRIX*vec4(VERTEX,1.0)).xyz; }
void fragment() {
	float ripple = sin(world_pos.x*2.6 + sin(world_pos.z*1.6+scene_time*0.5)*1.5 + scene_time*0.63);
	float crossing = low_quality ? 0.0 : sin(world_pos.z*5.0-world_pos.x*1.3-scene_time*0.7);
	float ridge = pow(max(0.0,ripple*0.65+crossing*0.35),12.0);
	ALBEDO = deep_color.rgb * (0.85 + ripple*0.06) + vec3(0.10,0.25,0.19)*ridge;
	METALLIC = 0.2;
	ROUGHNESS = low_quality ? 0.40 : 0.23;
	NORMAL_MAP = vec3(0.5+ripple*0.018,0.5+crossing*0.016,1.0);
	EMISSION = deep_color.rgb*0.035;
}
