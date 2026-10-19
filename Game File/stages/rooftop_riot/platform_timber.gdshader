shader_type spatial;
render_mode diffuse_burley, specular_schlick_ggx;
uniform vec4 timber_color : source_color = vec4(0.43, 0.27, 0.15, 1.0);
uniform bool low_quality = false;
varying vec3 local_position;
void vertex() { local_position = (MODEL_MATRIX * vec4(VERTEX,1.0)).xyz; }
float hash(vec2 p) { return fract(sin(dot(p,vec2(127.1,311.7)))*43758.5453); }
float noise(vec2 p) {
	vec2 i=floor(p), f=fract(p); f=f*f*(3.0-2.0*f);
	return mix(mix(hash(i),hash(i+vec2(1,0)),f.x),mix(hash(i+vec2(0,1)),hash(i+vec2(1,1)),f.x),f.y);
}
void fragment() {
	vec2 p=local_position.xz;
	float growth=noise(vec2(p.x*0.75,p.y*19.0));
	float grain=0.5;
	if (!low_quality) {
		float phase=p.y*240.0+growth*7.0+sin(p.x*1.5)*1.8;
		grain=0.5+0.5*sin(phase)*(1.0-smoothstep(0.7,3.0,fwidth(phase)));
	}
	ALBEDO=timber_color.rgb*(0.86+growth*0.25+grain*0.08);
	ROUGHNESS=0.56+grain*0.08;
	SPECULAR=0.32;
}
