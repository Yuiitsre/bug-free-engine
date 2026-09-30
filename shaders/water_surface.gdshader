shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_disabled, diffuse_burley, specular_schlick_ggx;

varying vec3 world_position;

void vertex() {
    world_position = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
    float wave_a = sin(world_position.x * 0.09 + TIME * 0.65);
    float wave_b = cos(world_position.z * 0.07 - TIME * 0.42);
    float ripple = (wave_a + wave_b) * 0.5;
    ALBEDO = vec3(0.05, 0.31, 0.40) + vec3(0.015, 0.025, 0.03) * ripple;
    METALLIC = 0.08;
    ROUGHNESS = 0.16;
    SPECULAR = 0.75;
    ALPHA = 0.58;
}
