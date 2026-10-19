shader_type spatial;
render_mode unshaded, blend_add, depth_draw_never, cull_disabled, fog_disabled;

// World-shaped contours. The center remains transparent, including when a
// fighter passes through an ultimate telegraph. No screen texture or renderer-
// specific feature is required by either the Forward+ or Mobile profile.
uniform vec4 effect_color : source_color = vec4(0.3, 0.75, 1.0, 1.0);
uniform vec2 extent = vec2(0.56);
uniform vec2 shape_size = vec2(0.43);
uniform int shape = 0; // 0 shock ring, 1 solar zone, 2 rectangular telegraph
uniform float brightness = 1.0;
uniform float line_width = 0.008;
uniform bool warning = false;
instance uniform float age = 0.0;
instance uniform float opacity = 1.0;
instance uniform float intensity = 1.0;
instance uniform vec3 floor_limit = vec3(-1000.0, 0.0, 0.0);
varying vec3 world_position;

void vertex() {
	world_position = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

float glow_line(float distance_to_line, float width) {
	float core = 1.0 - smoothstep(width * 0.35, width, distance_to_line);
	float halo = exp(-distance_to_line * distance_to_line / (width * width * 22.0));
	return core * 0.63 + halo * 0.105;
}

void fragment() {
	vec2 p = (UV * 2.0 - 1.0) * extent;
	float ink = 0.0;
	float core = 0.0;
	if (shape == 2) {
		vec2 q = abs(p) - shape_size;
		float edge = abs(max(q.x, q.y));
		// Quiet full boundary plus brighter registration corners, like a
		// precise holographic drafting instrument rather than a debug box.
		float corner_distance = max(abs(abs(p.x) - shape_size.x), abs(abs(p.y) - shape_size.y));
		float corner = 1.0 - smoothstep(0.18, 0.34, corner_distance);
		ink = glow_line(edge, line_width) * mix(0.38, 0.94, corner);
		float outer_edge = abs(max(q.x - 0.055, q.y - 0.055));
		ink += glow_line(outer_edge, line_width * 0.55) * corner * 0.16;
		core = (1.0 - smoothstep(0.0, line_width, edge)) * corner;
	} else {
		float radius = shape_size.x;
		float angle = atan(p.y, p.x);
		float radial = length(p);
		float line = abs(radial - radius);
		float sweep = 0.70 + 0.30 * sin(angle * 2.0 + age * 3.0);
		ink = glow_line(line, line_width) * sweep;
		core = 1.0 - smoothstep(0.0, line_width, line);
		if (!warning) {
			// A broken inner filament and fine tangent streaks imply a
			// compressed wave; there is no filled disc behind the face.
			float filament_radius = radius * (0.86 + age * 0.06);
			float filament = glow_line(abs(radial - filament_radius), line_width * 0.50);
			float arc = smoothstep(-0.10, 0.58, sin(angle * 3.0 - age * 2.0));
			ink += filament * arc * 0.31;
			float tangent = pow(max(0.0, cos(angle * 7.0 + age * 4.0)), 24.0);
			ink += tangent * exp(-pow((radial - radius * 0.95) / max(0.001, radius * 0.065), 2.0)) * 0.07;
		}
		if (shape == 1 && !warning) {
			float pulse_radius = radius * mix(0.46, 0.96, smoothstep(0.0, 1.0, age));
			ink += glow_line(abs(radial - pulse_radius), line_width * 0.8) * 0.35 * (1.0 - age * 0.7);
			// Restrained solar rays stay at the perimeter, never a whiteout.
			float ray = pow(max(0.0, cos(angle * 12.0)), 38.0);
			ink += ray * smoothstep(radius * 0.78, radius * 0.92, radial) * (1.0 - smoothstep(radius * 0.97, radius * 1.055, radial)) * 0.19;
		}
	}
	vec3 tint = mix(effect_color.rgb, vec3(0.92, 0.97, 1.0), core * 0.34);
	ALBEDO = tint * brightness * intensity;
	ALPHA = clamp(ink * effect_color.a * opacity, 0.0, 0.78);
	if (world_position.x > floor_limit.y && world_position.x < floor_limit.z) {
		ALPHA *= smoothstep(floor_limit.x - 0.01, floor_limit.x + 0.015, world_position.y);
	}
}
