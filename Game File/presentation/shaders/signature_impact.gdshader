shader_type spatial;
render_mode unshaded, blend_add, depth_draw_never, cull_disabled, fog_disabled;

uniform vec4 effect_color : source_color = vec4(0.6, 0.8, 1.0, 1.0);
uniform vec4 accent_color : source_color = vec4(1.0);
uniform int signature = 0;
uniform float brightness = 1.0;
instance uniform float age = 0.0;

float hash21(vec2 p) {
	p = fract(p * vec2(123.34, 345.45));
	p += dot(p, p + 34.345);
	return fract(p.x * p.y);
}

float noise21(vec2 p) {
	vec2 cell = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash21(cell), hash21(cell + vec2(1.0, 0.0)), f.x), mix(hash21(cell + vec2(0.0, 1.0)), hash21(cell + vec2(1.0)), f.x), f.y);
}

float turbulence(vec2 p) {
	return noise21(p) * 0.58 + noise21(p * 2.12 + 7.7) * 0.29 + noise21(p * 4.39 + 2.2) * 0.13;
}

void fragment() {
	vec2 p = UV * 2.0 - 1.0;
	float radius = length(p);
	float angle = atan(p.y, p.x);
	float expansion = mix(0.10, 0.90, pow(clamp(age * 2.8, 0.0, 1.0), 0.6));
	float contour = radius;
	float opacity = 0.0;
	float core = exp(-radius * radius * 80.0) * (1.0 - smoothstep(0.0, 0.22, age));
	float life = 1.0 - smoothstep(0.06, 0.78, age);
	float cloud = turbulence(p * 5.6 + vec2(age * 0.70, -age));
	if (signature == 0) {
		float bands = exp(-pow((radius - expansion) * 55.0, 2.0));
		bands += exp(-pow((radius - expansion * 0.76) * 70.0, 2.0)) * 0.42;
		opacity = bands * (0.35 + 0.65 * pow(abs(cos(angle)), 5.0));
	} else if (signature == 1) {
		// Interleaved, irregular tongues of hot plasma, with no star-shaped outline.
		float curl = pow(0.5 + 0.5 * sin(angle * 7.0 + cloud * 9.0 - radius * 14.0), 7.0);
		float envelope = exp(-pow((radius - expansion * 0.61) * 4.0, 2.0));
		opacity = envelope * (curl * 0.78 + cloud * cloud * 0.30);
		core += envelope * curl * 0.32;
	} else if (signature == 2) {
		contour = length(p * vec2(1.0, 1.35));
		opacity = exp(-pow((contour + cloud * 0.13 - expansion * 0.77) * 6.0, 2.0)) * pow(cloud, 1.5) * 0.48;
	} else if (signature == 3) {
		float fibers = pow(0.5 + 0.5 * sin(angle * 11.0 + cloud * 7.0 + radius * 9.0), 28.0);
		opacity = (fibers * 0.32 + pow(cloud, 3.0) * 0.14) * exp(-pow((radius - expansion * 0.68) * 4.0, 2.0));
	} else if (signature == 4) {
		vec2 q = abs(p);
		float box = max(q.x, q.y * 1.35);
		float frame = exp(-pow((box - expansion * 0.65) * 85.0, 2.0));
		float corners = smoothstep(expansion * 0.26, expansion * 0.49, min(q.x, q.y * 1.35));
		opacity = frame * corners * 0.65;
		opacity += exp(-p.y * p.y * 3000.0) * (1.0 - smoothstep(0.3, 0.9, abs(p.x))) * 0.65;
	} else if (signature == 5) {
		// Warm mineral dust splits into two braided eddies behind the strike.
		contour = length(p * vec2(0.9, 1.38));
		float eddy = sin(angle * 3.0 - contour * 9.0 + cloud * 5.0);
		opacity = exp(-pow((contour + eddy * 0.12 - expansion * 0.64) * 7.0, 2.0)) * cloud * cloud * 0.43;
	} else if (signature == 6) {
		float sector = mod(angle + 3.141593, 1.047198) - 0.523599;
		contour = radius * cos(sector);
		float hex = exp(-pow((contour - expansion * 0.80) * 60.0, 2.0));
		opacity = hex * (0.35 + 0.65 * smoothstep(0.04, 0.15, abs(sector)));
		opacity += exp(-pow((contour - expansion * 0.61) * 70.0, 2.0)) * 0.22;
	} else {
		float crescent = exp(-pow((radius - expansion * 0.82) * 40.0, 2.0));
		opacity = crescent * pow(max(0.0, cos(angle - age * 3.0)), 2.0) * 0.70;
		opacity += exp(-pow(p.y - p.x * 0.35, 2.0) * 2100.0) * exp(-radius * 2.0) * 0.48;
	}
	ALBEDO = mix(effect_color.rgb, accent_color.rgb, clamp(core + radius * 0.20, 0.0, 1.0)) * brightness;
	ALPHA = (opacity * life + core * 0.35) * effect_color.a * (1.0 - smoothstep(0.78, 1.0, radius));
}
