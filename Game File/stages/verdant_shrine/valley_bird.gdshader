shader_type spatial;
render_mode unshaded, cull_disabled, fog_disabled, depth_draw_never, shadows_disabled;
uniform float scene_time = 0.0;
uniform float phase = 0.0;
float line_distance(vec2 p, vec2 a, vec2 b) {
	vec2 ab = b-a;
	return length(p-a-ab*clamp(dot(p-a,ab)/dot(ab,ab),0.0,1.0));
}
void fragment() {
	vec2 p = (UV-0.5)*vec2(2.0,1.0);
	float flap = sin(scene_time*7.6+phase);
	vec2 tip = vec2(0.89,0.04+flap*0.27);
	float wing = min(line_distance(p,vec2(0.0,0.03),tip),line_distance(p,vec2(0.0,0.03),tip*vec2(-1.0,1.0)));
	float body = length((p-vec2(0.0,0.02))*vec2(1.0,0.5));
	float silhouette = max(1.0-smoothstep(0.014,0.044,wing),1.0-smoothstep(0.035,0.058,body));
	ALBEDO = vec3(0.035,0.078,0.065);
	ALPHA = silhouette*0.82;
}
