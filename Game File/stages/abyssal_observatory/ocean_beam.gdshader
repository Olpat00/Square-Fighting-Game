shader_type spatial;
render_mode unshaded, blend_add, depth_draw_never, cull_disabled, shadows_disabled;
uniform float scene_time = 0.0;
uniform float phase = 0.0;
uniform bool low_quality = false;
void fragment() {
    float edge = pow(max(0.0, 1.0 - abs(UV.x - 0.5) * 2.0), 2.5);
    float fade = sin(UV.y * 3.14159) * (0.070 + sin(scene_time * 0.31 + phase) * 0.013);
    float current = 0.88 + sin(UV.y * 9.0 - scene_time * 0.47 + phase) * 0.12;
    ALBEDO = vec3(0.20, 0.48, 0.51);
    ALPHA = edge * fade * current * (low_quality ? 0.68 : 1.0);
}
