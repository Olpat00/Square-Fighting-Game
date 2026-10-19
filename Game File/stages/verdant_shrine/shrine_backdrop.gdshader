shader_type spatial;
render_mode unshaded, fog_disabled, cull_disabled, depth_draw_opaque;
uniform sampler2D panorama : source_color, filter_linear_mipmap_anisotropic;
uniform float exposure : hint_range(0.1,2.0) = 0.8;
uniform float scene_time = 0.0;
uniform bool low_quality = false;
uniform vec2 parallax_offset = vec2(0.0);

// Each ribbon follows a painted cascade. No architecture is displaced.
float cascade(vec2 uv, vec2 start, vec2 end, float width_top, float width_bottom) {
	float t = clamp((uv.y-start.y)/(end.y-start.y),0.0,1.0);
	float center = mix(start.x,end.x,t);
	float width = mix(width_top,width_bottom,t);
	float side = 1.0-smoothstep(width*0.65,width,abs(uv.x-center));
	return side*smoothstep(start.y,start.y+0.025,uv.y)*(1.0-smoothstep(end.y-0.05,end.y,uv.y));
}

float falling_water(vec2 p) {
	// Long irregular ribbons advect downstream; no repeated horizontal carrier.
	float ribbon = sin(p.x + sin(p.y * 0.59) * 0.83);
	float detail = sin(p.x * 1.39 + p.y * 0.31 + 2.11);
	float spray = sin(p.y * 0.71 + sin(p.x * 0.41) * 0.68);
	return clamp(0.5 + ribbon * 0.22 + detail * 0.17 + spray * 0.11, 0.0, 1.0);
}

void fragment() {
	vec2 uv = UV+parallax_offset;
	vec3 original = texture(panorama,uv).rgb;
	float falls = max(cascade(uv,vec2(0.17,0.27),vec2(0.195,0.83),0.035,0.054),cascade(uv,vec2(0.854,0.305),vec2(0.817,0.85),0.032,0.060));
	falls = max(falls,cascade(uv,vec2(0.576,0.418),vec2(0.563,0.675),0.011,0.021)*0.8);
	falls = max(falls,cascade(uv,vec2(0.793,0.17),vec2(0.789,0.284),0.005,0.012)*0.6);
	// The painted white/blue water excludes the cliff edges inside a ribbon.
	float water_color = smoothstep(0.035,0.13,original.b-original.r*0.65)*smoothstep(0.18,0.43,original.b);
	falls *= water_color;
	vec2 coordinates = uv;
	vec2 flow_coordinates = uv*vec2(610.0,46.0)-vec2(0.0,scene_time*4.4);
	float flow = falling_water(flow_coordinates);
	float fine_flow = low_quality ? flow : falling_water(flow_coordinates*vec2(1.71,1.27)+vec2(3.7,1.9));
	coordinates.y += (flow-0.5)*0.0012*falls;
	coordinates.x += (fine_flow-0.5)*0.0006*falls;
	float foliage_color = smoothstep(0.012,0.065,original.g-max(original.r,original.b)*0.83);
	float foreground_foliage = max(1.0-smoothstep(0.05,0.26,uv.x),smoothstep(0.73,0.95,uv.x));
	float foliage = foliage_color*foreground_foliage*(1.0-smoothstep(0.64,0.94,uv.y));
	coordinates.x += sin(scene_time*0.96+uv.y*29.0+uv.x*7.0)*0.0013*foliage*(low_quality ? 0.55 : 1.0);
	float lagoon = smoothstep(0.73,0.89,uv.y)*(1.0-falls);
	coordinates.x += sin(uv.y*236.0-scene_time*1.8)*0.0011*lagoon;
	coordinates.y += sin(uv.x*159.0+scene_time*1.1)*0.0005*lagoon;
	vec3 color = texture(panorama,coordinates).rgb;
	color *= 1.0+(mix(flow,fine_flow,0.35)-0.5)*0.20*falls;
	color += vec3(0.018,0.024,0.026)*smoothstep(0.62,0.92,fine_flow)*falls;
	// Thin spray banks shift sideways at the foot of both falls.
	float spray_area = exp(-pow((uv.y-0.807)*21.0,2.0))*(exp(-pow((uv.x-0.205)*7.0,2.0))+exp(-pow((uv.x-0.815)*7.0,2.0)));
	float mist = spray_area*(0.022+0.018*sin(uv.x*28.0-scene_time*0.34+sin(uv.y*20.0)));
	color = mix(color,vec3(0.46,0.63,0.64),mist);
	ALBEDO = color*exposure;
}
