shader_type spatial;
render_mode unshaded, blend_mix, depth_draw_never, cull_disabled, shadows_disabled;
uniform float scene_time = 0.0;
uniform float phase = 0.0;
uniform float length_scale = 1.0;
uniform bool low_quality = false;
varying float reach;

void vertex() {
    reach = clamp(-VERTEX.y / max(0.1, length_scale), 0.0, 1.0);
    // The bell pulls first; the slender filaments follow with increasing lag.
    VERTEX.x += sin(scene_time * 1.7 + phase - reach * 4.0) * reach * 0.11;
    VERTEX.z += cos(scene_time * 1.3 + phase + reach * 3.0) * reach * 0.055;
}

void fragment() {
    float feather = sin(UV.x * 3.1415926);
    ALBEDO = mix(vec3(0.44, 0.67, 0.69), vec3(0.29, 0.48, 0.55), reach);
    ALPHA = feather * (0.54 - reach * 0.27);
}
