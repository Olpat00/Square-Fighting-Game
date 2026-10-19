shader_type spatial;
render_mode unshaded, cull_disabled, fog_disabled;
uniform float scene_time = 0.0;
uniform bool low_quality = false;
varying vec3 world_position;
void vertex() { world_position = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz; }
float hash(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }
float noise(vec2 p) {
    vec2 i = floor(p); vec2 f = fract(p); f = f * f * (3.0 - 2.0 * f);
    return mix(mix(hash(i), hash(i + vec2(1, 0)), f.x), mix(hash(i + vec2(0, 1)), hash(i + vec2(1)), f.x), f.y);
}
void fragment() {
    vec2 p = vec2(world_position.x, world_position.y * 0.956 - world_position.z * 0.292);
    float height = smoothstep(-4.0, 8.0, p.y);
    vec3 deep = vec3(0.002, 0.009, 0.025);
    vec3 upper = vec3(0.011, 0.075, 0.097);
    float pool = exp(-pow((p.x + 2.0) * 0.073, 2.0));
    float clouds = noise(p * 0.12) * 0.6 + noise(p * 0.31) * 0.4;
    vec3 color = mix(deep, upper, height * pool * (0.64 + clouds * 0.36));
    float rays = pow(max(0.0, sin(p.x * 0.91 + p.y * 0.13 + scene_time * 0.025)), 18.0);
    rays += pow(max(0.0, sin(p.x * 1.7 - p.y * 0.16)), 24.0) * 0.4;
    color += vec3(0.009, 0.020, 0.022) * rays * height * (low_quality ? 0.3 : 1.0);
    ALBEDO = color;
}
