shader_type spatial;
render_mode unshaded, cull_disabled, shadows_disabled;

uniform float scene_time = 0.0;
uniform bool low_quality = false;
uniform vec3 water_tint : source_color = vec3(0.19, 0.37, 0.43);
uniform float depth_mix = 0.24;
varying vec3 fish_normal;
varying vec3 fish_position;

void vertex() {
    // Each fish has a different stroke phase. Flex increases towards the fork,
    // so the nose leads the swim instead of the entire animal oscillating.
    float phase = INSTANCE_CUSTOM.x * 6.2831853;
    float stroke = scene_time * (3.8 + INSTANCE_CUSTOM.y * 1.8) + phase;
    float tail = 1.0 - smoothstep(-1.06, 0.38, VERTEX.x);
    float bend = sin(stroke + VERTEX.x * 2.4) * tail * tail;
    VERTEX.z += bend * 0.23;
    VERTEX.y += bend * 0.10;
    VERTEX.y += sin(scene_time * 1.1 + phase) * 0.018;
    fish_normal = NORMAL;
    fish_position = VERTEX;
}

void fragment() {
    // A quiet dorsal gradient and silver flank read through the water without
    // borrowing foreground key lights or competing with attack highlights.
    float dorsal = smoothstep(-0.12, 0.21, fish_position.y);
    float flank = pow(max(0.0, abs(fish_normal.z)), 2.0);
    float sheen = 0.86 + flank * 0.17;
    vec3 pigment = COLOR.rgb * mix(1.08, 0.70, dorsal) * sheen;
    ALBEDO = mix(pigment, water_tint, depth_mix);
    ROUGHNESS = 0.75;
}
