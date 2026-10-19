shader_type spatial;
render_mode unshaded, blend_add, depth_draw_never, cull_disabled, shadows_disabled;
uniform float scene_time = 0.0;
uniform float phase = 0.0;
uniform bool warning = false;
void fragment() {
    vec2 p = UV - 0.5;
    if (warning) {
        float r = length(p * vec2(1.0, 0.9));
        float ring = smoothstep(0.025, 0.0, abs(r - 0.38));
        float cross = step(abs(p.x), 0.014) * step(abs(p.y), 0.27) + step(abs(p.y), 0.014) * step(abs(p.x), 0.27);
        ALBEDO = vec3(1.0, 0.49, 0.16);
        ALPHA = (ring + cross) * (0.55 + sin(scene_time * 11.0) * 0.25);
    } else {
        float body = pow(max(0.0, 1.0 - abs(p.x) * (3.3 - UV.y * 1.4)), 2.0);
        float streams = 0.5 + 0.5 * sin(UV.x * 91.0 + UV.y * 18.0 - scene_time * 31.0 + phase);
        ALBEDO = mix(vec3(0.10, 0.42, 0.58), vec3(0.66, 0.96, 1.0), streams);
        ALPHA = body * smoothstep(0.0, 0.15, UV.y) * 0.82;
    }
}
