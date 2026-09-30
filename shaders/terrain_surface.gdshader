shader_type spatial;
render_mode diffuse_burley, specular_schlick_ggx;

varying vec3 world_position;

void vertex() {
    world_position = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
    float fine = sin(world_position.x * 0.055) * sin(world_position.z * 0.067);
    float broad = sin(world_position.x * 0.009 + world_position.z * 0.013);
    float breakup = fine * 0.035 + broad * 0.025;
    ALBEDO = COLOR.rgb * (1.0 + breakup);
    ROUGHNESS = 0.84;
    SPECULAR = 0.20;
}
