shader_type spatial;
render_mode cull_disabled, depth_draw_never, shadows_disabled;
uniform float scene_time = 0.0;
uniform bool low_quality = false;
uniform vec4 tint : source_color = vec4(0.47,0.72,0.63,1.0);
uniform float opacity = 0.62;
void fragment() {
	float stream = sin(UV.x*59.0 + sin(UV.y*9.0-scene_time*1.8)*0.43);
	float foam = pow(max(0.0,sin(UV.y*41.0-scene_time*5.0+UV.x*8.0)),5.0);
	float edge = smoothstep(0.0,0.08,UV.x) * smoothstep(0.0,0.08,1.0-UV.x);
	ALBEDO = tint.rgb*(0.70+stream*0.09+foam*0.3);
	EMISSION = tint.rgb*0.06;
	ROUGHNESS = 0.40;
	ALPHA = edge*opacity*(0.73+stream*0.18+foam*0.09);
}
