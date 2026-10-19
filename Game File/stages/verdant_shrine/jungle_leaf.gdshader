shader_type spatial;
render_mode cull_disabled, diffuse_burley;
uniform vec4 leaf_color : source_color = vec4(0.15,0.31,0.14,1.0);
uniform float scene_time = 0.0;
uniform bool low_quality = false;
void vertex() {
	vec3 origin = MODEL_MATRIX[3].xyz;
	float amplitude = low_quality ? 0.045 : 0.13;
	VERTEX.x += sin(scene_time * 1.05 + origin.x*0.3 + origin.z*0.23 + UV.y*2.0) * UV.y * amplitude;
	VERTEX.y += cos(scene_time * 0.76 + origin.x*0.4) * UV.y * amplitude * 0.23;
}
void fragment() {
	float vein = 1.0-smoothstep(0.01,0.045,abs(UV.x-0.5));
	float ribs = pow(max(0.0,sin(UV.y*60.0+abs(UV.x-0.5)*24.0)),10.0);
	ALBEDO = leaf_color.rgb * (0.83 + UV.y*0.20 + vein*0.26 + ribs*0.06);
	ROUGHNESS = 0.77;
	BACKLIGHT = leaf_color.rgb*0.16;
}
