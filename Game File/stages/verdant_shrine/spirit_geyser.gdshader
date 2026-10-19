shader_type spatial;
render_mode unshaded, cull_disabled, depth_draw_never, shadows_disabled;
uniform float scene_time = 0.0;
uniform bool low_quality = false;
uniform bool warning = false;
void fragment() {
	if (warning) {
		float radius = length((UV-0.5)*2.0);
		float ring = 1.0-smoothstep(0.025,0.08,abs(radius-0.74));
		float inner = 1.0-smoothstep(0.014,0.045,abs(radius-0.47));
		float pulse = 0.72+0.28*sin(scene_time*12.0);
		ALBEDO = vec3(1.0,0.61,0.13);
		EMISSION = ALBEDO*0.9;
		ALPHA = max(ring,inner*0.65)*pulse;
	} else {
		float width = mix(0.46,0.18,1.0-UV.y);
		float waviness = sin(UV.y*15.0-scene_time*8.0)*0.035;
		float core = 1.0-smoothstep(width*0.50,width,abs(UV.x-0.5+waviness));
		float crest = smoothstep(0.0,0.16,UV.y);
		float bands = 0.75+0.25*sin(UV.y*40.0-scene_time*16.0);
		ALBEDO = mix(vec3(0.09,0.70,0.67),vec3(0.75,1.0,0.88),core*bands);
		EMISSION = ALBEDO*1.35;
		ALPHA = core*crest*0.90;
	}
}
