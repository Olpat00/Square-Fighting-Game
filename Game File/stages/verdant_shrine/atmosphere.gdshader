shader_type spatial;
render_mode unshaded, cull_disabled, depth_draw_never, shadows_disabled;
uniform float scene_time = 0.0;
uniform bool low_quality = false;
uniform vec4 tint : source_color = vec4(0.29,0.49,0.42,0.15);
uniform bool shaft = false;
void fragment() {
	float edge = pow(max(0.0,1.0-pow(abs(UV.x-0.5)*2.0,2.0)),2.0);
	float vertical = smoothstep(0.0,0.28,UV.y)*smoothstep(0.0,0.32,1.0-UV.y);
	float flow = shaft ? 1.0 : (0.59+0.25*sin(UV.x*13.0+UV.y*7.0-scene_time*0.25)+0.16*sin(UV.x*24.0-UV.y*5.0-scene_time*0.41));
	ALBEDO = tint.rgb;
	ALPHA = edge*vertical*flow*tint.a;
}
