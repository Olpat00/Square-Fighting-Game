shader_type spatial;
render_mode diffuse_burley;
uniform vec4 stone_color : source_color = vec4(0.27, 0.34, 0.29, 1.0);
uniform vec4 moss_color : source_color = vec4(0.20, 0.30, 0.10, 1.0);
uniform float moss_amount = 0.45;
uniform bool low_quality = false;
varying vec3 stone_pos;
varying vec3 stone_normal;
float hash(vec3 p) { return fract(sin(dot(p, vec3(127.1,311.7,74.7))) * 43758.5453); }
float noise(vec3 p) {
	vec3 i = floor(p); vec3 f = fract(p); f = f*f*(3.0-2.0*f);
	return mix(mix(mix(hash(i),hash(i+vec3(1,0,0)),f.x),mix(hash(i+vec3(0,1,0)),hash(i+vec3(1,1,0)),f.x),f.y),mix(mix(hash(i+vec3(0,0,1)),hash(i+vec3(1,0,1)),f.x),mix(hash(i+vec3(0,1,1)),hash(i+vec3(1,1,1)),f.x),f.y),f.z);
}
void vertex() {
	// Object space keeps the grain attached to the moving Heartstone.
	stone_pos = VERTEX;
	stone_normal = NORMAL;
}
void fragment() {
	float broad = noise(stone_pos * 2.1);
	float grain = low_quality ? 0.5 : noise(stone_pos * 28.0);
	float strata = low_quality ? 0.5 : noise(stone_pos * vec3(2.2,24.0,2.2) + vec3(broad*1.8));
	float flecks = low_quality ? 0.5 : noise(stone_pos * 79.0);
	float moss = smoothstep(0.40,0.73,broad + stone_normal.y * 0.11) * moss_amount;
	float mineral = 0.76 + broad*0.26 + grain*0.12 + strata*0.12;
	vec3 rock = stone_color.rgb * mineral;
	rock = mix(rock,rock*0.56,smoothstep(0.66,0.82,flecks)*0.24);
	ALBEDO = mix(rock,moss_color.rgb*(0.86+grain*0.24),moss);
	ROUGHNESS = mix(0.88,0.99,moss);
	if (!low_quality) {
		// Subtle physical relief across the broad faces; the geometry owns
		// the crisp stone edges and deep mortar, not a painted normal seam.
		float height = grain*0.003 + strata*0.003 + flecks*0.001;
		vec3 across = cross(dFdy(VERTEX),NORMAL);
		vec3 along = cross(NORMAL,dFdx(VERTEX));
		float determinant = dot(dFdx(VERTEX),across);
		vec3 gradient = sign(determinant)*(dFdx(height)*across+dFdy(height)*along);
		NORMAL = normalize(abs(determinant)*NORMAL-gradient);
	}
}
