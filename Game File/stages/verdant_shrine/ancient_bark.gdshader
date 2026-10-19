shader_type spatial;
render_mode diffuse_burley;
uniform bool low_quality = false;
varying vec3 world_pos;
void vertex() { world_pos = (MODEL_MATRIX*vec4(VERTEX,1.0)).xyz; }
void fragment() {
	float bend = sin(world_pos.y*0.75+world_pos.z*0.6)*0.4;
	float ridge = sin(world_pos.x*17.0+world_pos.z*14.0+bend);
	float fissure = pow(max(0.0,ridge),7.0);
	float patches = sin(world_pos.x*2.3+world_pos.y*1.3)*sin(world_pos.z*1.5-world_pos.y*0.7)*0.5+0.5;
	ALBEDO = mix(vec3(0.047,0.049,0.029),vec3(0.081,0.104,0.044),patches)*mix(1.0,0.58,fissure);
	ROUGHNESS = 0.95;
}
