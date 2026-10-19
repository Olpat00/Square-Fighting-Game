shader_type spatial;
render_mode unshaded, cull_disabled, fog_disabled;

uniform sampler2D earth_map : source_color, repeat_enable, filter_linear_mipmap_anisotropic;
uniform float longitude = 0.075;
uniform float scene_time = 0.0;
uniform bool low_quality = false;
uniform vec3 sun_direction = vec3(-0.65, 0.52, 0.74);

float cloud_noise(vec2 p) {
	return sin(p.x*19.0+sin(p.y*13.0)*1.9)*sin(p.y*21.0+sin(p.x*8.0));
}

void fragment() {
	// A ray-sphere projection gives a correctly curved limb in orthographic and
	// perspective cameras. The texture is NASA's real MODIS Blue Marble mosaic.
	vec2 p = (UV - 0.5) * 2.10;
	float radius = length(p);
	if (radius > 1.036) { discard; }
	float z = sqrt(max(0.0, 1.0 - dot(p, p)));
	vec3 n = normalize(vec3(p.x, -p.y, z));
	float sun = dot(n, normalize(sun_direction));
	vec2 earth_uv = vec2(atan(n.x, n.z) / TAU + 0.5 + longitude, acos(clamp(n.y, -1.0, 1.0)) / PI);
	vec3 surface = texture(earth_map, earth_uv).rgb;
	// A separate high cloud layer creeps over the rotating surface. These are
	// planetary weather bands; the foreground remains an airless vacuum.
	vec2 clouds_uv = earth_uv+vec2(scene_time*0.00013,0.0);
	float clouds = smoothstep(0.32,0.72,cloud_noise(clouds_uv*vec2(2.0,1.0))+cloud_noise(clouds_uv*vec2(4.7,3.0))*0.20);
	float cloud_alpha = clouds*(low_quality ? 0.12 : 0.18)*smoothstep(0.04,0.17,earth_uv.y)*(1.0-smoothstep(0.84,0.97,earth_uv.y));
	surface = mix(surface,vec3(0.87,0.90,0.94),cloud_alpha);
	float daylight = smoothstep(-0.10, 0.24, sun);
	float shading = 0.016 + daylight * (0.34 + 0.76 * max(sun, 0.0));
	vec3 planet = surface * shading;
	float limb = pow(1.0 - z, 3.8);
	planet += vec3(0.055, 0.24, 0.61) * limb * daylight * 0.34;
	float halo = exp(-abs(radius - 1.0) * 135.0) * smoothstep(-0.15, 0.32, sun);
	planet = mix(planet, vec3(0.065, 0.28, 0.67) * halo, step(1.0, radius));
	ALBEDO = planet;
	EMISSION = planet * 0.13;
	ALPHA = radius > 1.0 ? halo * 0.55 : 1.0;
}
