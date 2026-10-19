shader_type spatial;
render_mode diffuse_burley, specular_schlick_ggx;
uniform vec4 panel_color : source_color = vec4(0.40,0.47,0.50,1.0);
uniform bool low_quality = false;
varying vec3 p;
varying vec3 n;
void vertex() { p=VERTEX; n=NORMAL; }
float hash(vec2 q) { return fract(sin(dot(q,vec2(127.1,311.7)))*43758.5453); }
void fragment() {
	vec2 plane=abs(n.y)>0.65 ? p.xz : p.xy;
	vec2 cell=fract(plane*30.0)-0.5;
	float aa=max(fwidth(plane.x*30.0),fwidth(plane.y*30.0));
	float grip=1.0-smoothstep(0.12-aa,0.20+aa,length(cell));
	float fine=low_quality ? 0.5 : hash(floor(plane*vec2(170.0,440.0)));
	ALBEDO=panel_color.rgb*(0.90+grip*0.05+fine*0.05);
	ROUGHNESS=0.67+grip*0.1;
	METALLIC=0.38;
	SPECULAR=0.40;
}
