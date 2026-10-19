shader_type spatial;
uniform vec4 stone_color : source_color = vec4(0.58, 0.60, 0.53, 1.0);
uniform float scene_time = 0.0;
uniform bool low_quality = false;
varying vec3 world_position;
varying float top_surface;
float stone_noise(vec2 p) {
    vec2 cell = floor(p);
    vec2 f = fract(p);
    f = f * f * (3.0 - 2.0 * f);
    vec4 h = fract(sin(vec4(dot(cell, vec2(127.1, 311.7)), dot(cell + vec2(1.0, 0.0), vec2(127.1, 311.7)), dot(cell + vec2(0.0, 1.0), vec2(127.1, 311.7)), dot(cell + vec2(1.0), vec2(127.1, 311.7)))) * 43758.5453);
    return mix(mix(h.x, h.y, f.x), mix(h.z, h.w, f.x), f.y);
}
void vertex() {
    world_position = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
    top_surface = max(NORMAL.y, 0.0);
}
void fragment() {
    vec2 p = world_position.xz;
    float cloud = stone_noise(p * 1.25);
    float fine = stone_noise(p * 8.0);
    float flow = p.x * 1.7 + p.y * 3.7 + (cloud - 0.5) * 4.2 + (fine - 0.5) * 0.30;
    float vein = 1.0 - smoothstep(0.035, 0.095, abs(sin(flow)));
    float hairline = 1.0 - smoothstep(0.025, 0.045, abs(sin(flow * 2.4 + 0.7)));
    vec3 warm_stone = stone_color.rgb * (0.84 + cloud * 0.28);
    ALBEDO = mix(warm_stone, vec3(0.23, 0.29, 0.27), vein * 0.28 + hairline * 0.065);
    ALBEDO += vec3(0.016, 0.011, 0.003) * fine;
    METALLIC = 0.035;
    ROUGHNESS = low_quality ? 0.60 : 0.46 + fine * 0.12;
    if (!low_quality) {
        float wave = sin(p.x * 3.2 + sin(p.y * 3.7 + scene_time * 0.32)) + sin(p.y * 3.4 + sin(p.x * 2.3 - scene_time * 0.27));
        float lace = pow(max(0.0, 1.0 - abs(wave) * 2.7), 4.0);
        EMISSION = vec3(0.025, 0.065, 0.063) * lace * top_surface;
    }
}
