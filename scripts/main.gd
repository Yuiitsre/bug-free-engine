extends Node3D

# ============================================================
# LYRENTHOS — PHASE 1: INSULAR GENESIS
# Production-oriented vertical slice.
#
# The world is generated from deterministic scalar fields.
# Rendering uses one ArrayMesh per chunk instead of one node
# per terrain column. Terrain and water are separate surfaces.
# ============================================================

const WORLD_SEED := 418231
const CHUNK_CELLS := 24
const CELL_SIZE := 2.0
const STREAM_RADIUS := 2
const WORLD_WATER_LEVEL := 7.0
const WORLD_DAY_MINUTES := 1440.0

var height_noise := FastNoiseLite.new()
var detail_noise := FastNoiseLite.new()
var climate_noise := FastNoiseLite.new()
var moisture_noise := FastNoiseLite.new()
var river_noise := FastNoiseLite.new()
var structure_noise := FastNoiseLite.new()

var terrain_material: Material
var water_material: Material
var dark_material: StandardMaterial3D
var light_material: StandardMaterial3D
var emissive_material: StandardMaterial3D

var world_root: Node3D
var player: CharacterBody3D
var camera_pivot: Node3D
var camera_pitch: Node3D
var player_camera: Camera3D
var title_camera: Camera3D
var title_layer: CanvasLayer
var hud_layer: CanvasLayer
var inventory_layer: CanvasLayer
var settings_layer: CanvasLayer
var crosshair: Label
var biome_label: Label
var coords_label: Label
var time_label: Label
var interact_label: Label

var title_visible := true
var inventory_visible := false
var settings_visible := false

var yaw := 0.0
var pitch := -12.0
var mouse_sensitivity := 0.003
var world_clock := 690.0
var world_day := 1

var generated_chunks: Dictionary = {}
var chunk_seed_cache: Dictionary = {}
var biome_defs: Array = []

func _ready() -> void:
    _load_biome_data()
    _configure_noise()
    _build_materials()
    _build_environment()
    _build_world_root()
    _generate_starting_world()
    _build_player()
    _build_title_screen()
    _build_hud()
    _build_inventory()
    _build_settings()
    _set_gameplay_active(false)
    Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func _process(delta: float) -> void:
    if not title_visible:
        _simulate_world(delta)
        _update_player(delta)
        _update_hud()

func _input(event: InputEvent) -> void:
    if event is InputEventMouseMotion and not title_visible and not inventory_visible and not settings_visible:
        yaw -= event.relative.x * mouse_sensitivity
        pitch = clamp(pitch - event.relative.y * mouse_sensitivity, -70.0, 45.0)
        if player:
            player.rotation.y = yaw
        if camera_pitch:
            camera_pitch.rotation.x = deg_to_rad(pitch)

    if event is InputEventKey and event.pressed and not event.echo:
        if event.keycode == KEY_TAB and not title_visible:
            _toggle_inventory()
        elif event.keycode == KEY_ESCAPE:
            if inventory_visible or settings_visible:
                _close_overlays()
            else:
                Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func _configure_noise() -> void:
    height_noise.seed = WORLD_SEED
    height_noise.frequency = 0.0033
    height_noise.fractal_octaves = 5
    height_noise.fractal_lacunarity = 2.0
    height_noise.fractal_gain = 0.52
    height_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH

    detail_noise.seed = WORLD_SEED + 103
    detail_noise.frequency = 0.019
    detail_noise.fractal_octaves = 3
    detail_noise.fractal_gain = 0.45

    climate_noise.seed = WORLD_SEED + 701
    climate_noise.frequency = 0.0017

    moisture_noise.seed = WORLD_SEED + 887
    moisture_noise.frequency = 0.0022

    river_noise.seed = WORLD_SEED + 1601
    river_noise.frequency = 0.0017
    river_noise.fractal_octaves = 3

    structure_noise.seed = WORLD_SEED + 3007
    structure_noise.frequency = 0.007

func _load_biome_data() -> void:
    var file := FileAccess.open("res://data/biomes/biomes.json", FileAccess.READ)
    if file:
        var parsed = JSON.parse_string(file.get_as_text())
        if parsed is Array:
            biome_defs = parsed
    if biome_defs.is_empty():
        biome_defs = [
            {"id":"meadow","name":"Emerald Meadow","color":"#4d8a61","roughness":0.86},
            {"id":"forest","name":"Silverpine Forest","color":"#285141","roughness":0.90},
            {"id":"wetland","name":"Mistfen","color":"#3f6259","roughness":0.94},
            {"id":"highland","name":"Cloudstep Highlands","color":"#687883","roughness":0.88},
            {"id":"desert","name":"Redglass Expanse","color":"#a96e4a","roughness":0.92},
            {"id":"coast","name":"Bluewind Coast","color":"#527b73","roughness":0.76},
            {"id":"arcane","name":"Starfall Basin","color":"#4d5f91","roughness":0.72},
            {"id":"frost","name":"Frostpine Reach","color":"#7891a3","roughness":0.91}
        ]

func _build_materials() -> void:
    var terrain_shader := load("res://shaders/terrain_surface.gdshader") as Shader
    terrain_material = ShaderMaterial.new()
    (terrain_material as ShaderMaterial).shader = terrain_shader

    var water_shader := load("res://shaders/water_surface.gdshader") as Shader
    water_material = ShaderMaterial.new()
    (water_material as ShaderMaterial).shader = water_shader

    dark_material = StandardMaterial3D.new()
    dark_material.albedo_color = Color("#1a2228")
    dark_material.roughness = 0.78

    light_material = StandardMaterial3D.new()
    light_material.albedo_color = Color("#d5c7aa")
    light_material.roughness = 0.68

    emissive_material = StandardMaterial3D.new()
    emissive_material.albedo_color = Color("#78cfff")
    emissive_material.emission_enabled = true
    emissive_material.emission = Color("#57bdf6")
    emissive_material.emission_energy_multiplier = 5.0

func _build_environment() -> void:
    var world_env := WorldEnvironment.new()
    var env := Environment.new()
    env.background_mode = Environment.BG_SKY
    env.sky = Sky.new()
    env.sky.sky_material = ProceduralSkyMaterial.new()

    var sky := env.sky.sky_material as ProceduralSkyMaterial
    sky.sky_top_color = Color("#071321")
    sky.sky_horizon_color = Color("#a9c8d6")
    sky.ground_horizon_color = Color("#60777e")
    sky.ground_bottom_color = Color("#10181b")
    sky.sun_angle_max = 12.0

    env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
    env.ambient_light_energy = 1.1
    env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
    env.glow_enabled = true
    env.glow_intensity = 0.6
    env.fog_enabled = true
    env.fog_light_color = Color("#9ab0b7")
    env.fog_density = 0.0025
    env.fog_height = 12.0
    env.fog_height_density = 0.045
    world_env.environment = env
    add_child(world_env)

    var sun := DirectionalLight3D.new()
    sun.name = "Sun"
    sun.rotation_degrees = Vector3(-47.0, -34.0, 0.0)
    sun.light_energy = 1.8
    sun.light_color = Color("#fff0d2")
    sun.shadow_enabled = true
    sun.directional_shadow_max_distance = 350.0
    add_child(sun)

func _build_world_root() -> void:
    world_root = Node3D.new()
    world_root.name = "World"
    add_child(world_root)

func _generate_starting_world() -> void:
    for cx in range(-STREAM_RADIUS, STREAM_RADIUS + 1):
        for cz in range(-STREAM_RADIUS, STREAM_RADIUS + 1):
            _generate_chunk(Vector2i(cx, cz))

    _scatter_world_foliage()
    _spawn_landmarks()

func _generate_chunk(chunk_coord: Vector2i) -> void:
    if generated_chunks.has(chunk_coord):
        return

    var terrain_vertices := PackedVector3Array()
    var terrain_normals := PackedVector3Array()
    var terrain_colors := PackedColorArray()
    var terrain_uvs := PackedVector2Array()

    var water_vertices := PackedVector3Array()
    var water_normals := PackedVector3Array()
    var water_uvs := PackedVector2Array()

    var origin_x := float(chunk_coord.x * CHUNK_CELLS) * CELL_SIZE
    var origin_z := float(chunk_coord.y * CHUNK_CELLS) * CELL_SIZE

    for local_x in range(CHUNK_CELLS):
        for local_z in range(CHUNK_CELLS):
            var gx := chunk_coord.x * CHUNK_CELLS + local_x
            var gz := chunk_coord.y * CHUNK_CELLS + local_z
            var h := _height_at(gx, gz)
            var biome := _biome_at(gx, gz)

            _add_top_face(
                terrain_vertices,
                terrain_normals,
                terrain_colors,
                terrain_uvs,
                Vector3(origin_x + local_x * CELL_SIZE, h, origin_z + local_z * CELL_SIZE),
                CELL_SIZE,
                _biome_color(biome, gx, gz)
            )

            var left_h := _height_at(gx - 1, gz)
            var right_h := _height_at(gx + 1, gz)
            var back_h := _height_at(gx, gz - 1)
            var front_h := _height_at(gx, gz + 1)

            if left_h < h:
                _add_side_face(terrain_vertices, terrain_normals, terrain_colors, terrain_uvs,
                    Vector3(origin_x + local_x * CELL_SIZE, left_h, origin_z + local_z * CELL_SIZE),
                    Vector3(origin_x + local_x * CELL_SIZE, h, origin_z + local_z * CELL_SIZE),
                    Vector3(origin_x + local_x * CELL_SIZE, h, origin_z + (local_z + 1) * CELL_SIZE),
                    Vector3(origin_x + local_x * CELL_SIZE, left_h, origin_z + (local_z + 1) * CELL_SIZE),
                    Vector3(-1, 0, 0), _biome_color(biome, gx, gz).darkened(0.12))

            if right_h < h:
                _add_side_face(terrain_vertices, terrain_normals, terrain_colors, terrain_uvs,
                    Vector3(origin_x + (local_x + 1) * CELL_SIZE, right_h, origin_z + (local_z + 1) * CELL_SIZE),
                    Vector3(origin_x + (local_x + 1) * CELL_SIZE, right_h, origin_z + local_z * CELL_SIZE),
                    Vector3(origin_x + (local_x + 1) * CELL_SIZE, h, origin_z + local_z * CELL_SIZE),
                    Vector3(origin_x + (local_x + 1) * CELL_SIZE, h, origin_z + (local_z + 1) * CELL_SIZE),
                    Vector3(1, 0, 0), _biome_color(biome, gx, gz).darkened(0.18))

            if back_h < h:
                _add_side_face(terrain_vertices, terrain_normals, terrain_colors, terrain_uvs,
                    Vector3(origin_x + (local_x + 1) * CELL_SIZE, back_h, origin_z + local_z * CELL_SIZE),
                    Vector3(origin_x + local_x * CELL_SIZE, back_h, origin_z + local_z * CELL_SIZE),
                    Vector3(origin_x + local_x * CELL_SIZE, h, origin_z + local_z * CELL_SIZE),
                    Vector3(origin_x + (local_x + 1) * CELL_SIZE, h, origin_z + local_z * CELL_SIZE),
                    Vector3(0, 0, -1), _biome_color(biome, gx, gz).darkened(0.16))

            if front_h < h:
                _add_side_face(terrain_vertices, terrain_normals, terrain_colors, terrain_uvs,
                    Vector3(origin_x + local_x * CELL_SIZE, front_h, origin_z + (local_z + 1) * CELL_SIZE),
                    Vector3(origin_x + (local_x + 1) * CELL_SIZE, front_h, origin_z + (local_z + 1) * CELL_SIZE),
                    Vector3(origin_x + (local_x + 1) * CELL_SIZE, h, origin_z + (local_z + 1) * CELL_SIZE),
                    Vector3(origin_x + local_x * CELL_SIZE, h, origin_z + (local_z + 1) * CELL_SIZE),
                    Vector3(0, 0, 1), _biome_color(biome, gx, gz).darkened(0.10))

            if _water_at(gx, gz):
                _add_water_face(
                    water_vertices,
                    water_normals,
                    water_uvs,
                    Vector3(origin_x + local_x * CELL_SIZE, WORLD_WATER_LEVEL + 0.035, origin_z + local_z * CELL_SIZE)
                )

    var terrain_mesh := _make_mesh(terrain_vertices, terrain_normals, terrain_colors, terrain_uvs, terrain_material)
    var terrain_instance := MeshInstance3D.new()
    terrain_instance.name = "Terrain_%d_%d" % [chunk_coord.x, chunk_coord.y]
    terrain_instance.mesh = terrain_mesh
    world_root.add_child(terrain_instance)

    var body := StaticBody3D.new()
    body.name = "Collision_%d_%d" % [chunk_coord.x, chunk_coord.y]
    var shape_node := CollisionShape3D.new()
    shape_node.shape = terrain_mesh.create_trimesh_shape()
    body.add_child(shape_node)
    world_root.add_child(body)

    if not water_vertices.is_empty():
        var water_mesh := _make_water_mesh(water_vertices, water_normals, water_uvs)
        var water_instance := MeshInstance3D.new()
        water_instance.name = "Water_%d_%d" % [chunk_coord.x, chunk_coord.y]
        water_instance.mesh = water_mesh
        world_root.add_child(water_instance)

    generated_chunks[chunk_coord] = true
    chunk_seed_cache[chunk_coord] = WORLD_SEED ^ (chunk_coord.x * 73856093) ^ (chunk_coord.y * 19349663)

func _height_at(gx: int, gz: int) -> float:
    var x := float(gx)
    var z := float(gz)

    var continental := height_noise.get_noise_2d(x, z)
    var ridge := 1.0 - absf(height_noise.get_noise_2d(x * 0.38, z * 0.38))
    var detail := detail_noise.get_noise_2d(x, z)
    var h := 9.0 + continental * 7.5 + ridge * 7.0 + detail * 1.35

    var river_strength := 1.0 - clamp(absf(river_noise.get_noise_2d(x, z)) / 0.075, 0.0, 1.0)
    river_strength = pow(river_strength, 3.0)

    if river_strength > 0.03:
        h -= river_strength * 6.5

    h = clamp(h, 1.2, 34.0)
    return h

func _water_at(gx: int, gz: int) -> bool:
    var h := _height_at(gx, gz)
    var river_strength := 1.0 - clamp(absf(river_noise.get_noise_2d(float(gx), float(gz))) / 0.075, 0.0, 1.0)
    return h < WORLD_WATER_LEVEL or pow(river_strength, 2.8) > 0.28

func _biome_at(gx: int, gz: int) -> int:
    var height := _height_at(gx, gz)
    var temperature := climate_noise.get_noise_2d(float(gx), float(gz))
    var moisture := moisture_noise.get_noise_2d(float(gx), float(gz))

    if height > 25.0:
        return 7 if temperature < -0.15 else 3
    if _water_at(gx, gz) and moisture > 0.15:
        return 5
    if moisture > 0.35 and temperature < 0.1:
        return 1
    if moisture > 0.48:
        return 2
    if temperature > 0.52 and moisture < -0.05:
        return 4
    if temperature < -0.50:
        return 7
    if absf(climate_noise.get_noise_2d(float(gx) * 0.4, float(gz) * 0.4)) < 0.12 and height > 14.0:
        return 6
    return 0

func _biome_color(biome: int, gx: int, gz: int) -> Color:
    var base := Color("#4d8a61")
    match biome:
        0: base = Color("#4d8a61")
        1: base = Color("#2f5847")
        2: base = Color("#42695d")
        3: base = Color("#6d7d87")
        4: base = Color("#a36c49")
        5: base = Color("#4c7a70")
        6: base = Color("#526a9b")
        7: base = Color("#7f98a8")

    var variation := detail_noise.get_noise_2d(float(gx) * 0.85, float(gz) * 0.85)
    return base.lightened(variation * 0.07)

func _add_top_face(
    vertices: PackedVector3Array,
    normals: PackedVector3Array,
    colors: PackedColorArray,
    uvs: PackedVector2Array,
    origin: Vector3,
    size: float,
    color: Color
) -> void:
    var a := origin
    var b := origin + Vector3(size, 0, 0)
    var c := origin + Vector3(size, 0, size)
    var d := origin + Vector3(0, 0, size)
    vertices.append_array(PackedVector3Array([a, b, c, a, c, d]))
    normals.append_array(PackedVector3Array([
        Vector3.UP, Vector3.UP, Vector3.UP,
        Vector3.UP, Vector3.UP, Vector3.UP
    ]))
    colors.append_array(PackedColorArray([color, color, color, color, color, color]))
    uvs.append_array(PackedVector2Array([
        Vector2(0,0), Vector2(1,0), Vector2(1,1),
        Vector2(0,0), Vector2(1,1), Vector2(0,1)
    ]))

func _add_side_face(
    vertices: PackedVector3Array,
    normals: PackedVector3Array,
    colors: PackedColorArray,
    uvs: PackedVector2Array,
    a: Vector3,
    b: Vector3,
    c: Vector3,
    d: Vector3,
    normal: Vector3,
    color: Color
) -> void:
    vertices.append_array(PackedVector3Array([a,b,c,a,c,d]))
    normals.append_array(PackedVector3Array([normal,normal,normal,normal,normal,normal]))
    colors.append_array(PackedColorArray([color,color,color,color,color,color]))
    uvs.append_array(PackedVector2Array([
        Vector2(0,0),Vector2(1,0),Vector2(1,1),
        Vector2(0,0),Vector2(1,1),Vector2(0,1)
    ]))

func _add_water_face(
    vertices: PackedVector3Array,
    normals: PackedVector3Array,
    uvs: PackedVector2Array,
    origin: Vector3
) -> void:
    var a := origin
    var b := origin + Vector3(CELL_SIZE,0,0)
    var c := origin + Vector3(CELL_SIZE,0,CELL_SIZE)
    var d := origin + Vector3(0,0,CELL_SIZE)
    vertices.append_array(PackedVector3Array([a,b,c,a,c,d]))
    normals.append_array(PackedVector3Array([
        Vector3.UP,Vector3.UP,Vector3.UP,
        Vector3.UP,Vector3.UP,Vector3.UP
    ]))
    uvs.append_array(PackedVector2Array([
        Vector2(0,0),Vector2(1,0),Vector2(1,1),
        Vector2(0,0),Vector2(1,1),Vector2(0,1)
    ]))

func _make_mesh(
    vertices: PackedVector3Array,
    normals: PackedVector3Array,
    colors: PackedColorArray,
    uvs: PackedVector2Array,
    material: Material
) -> ArrayMesh:
    var arrays := []
    arrays.resize(Mesh.ARRAY_MAX)
    arrays[Mesh.ARRAY_VERTEX] = vertices
    arrays[Mesh.ARRAY_NORMAL] = normals
    arrays[Mesh.ARRAY_COLOR] = colors
    arrays[Mesh.ARRAY_TEX_UV] = uvs

    var mesh := ArrayMesh.new()
    mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
    mesh.surface_set_material(0, material)
    return mesh

func _make_water_mesh(
    vertices: PackedVector3Array,
    normals: PackedVector3Array,
    uvs: PackedVector2Array
) -> ArrayMesh:
    var arrays := []
    arrays.resize(Mesh.ARRAY_MAX)
    arrays[Mesh.ARRAY_VERTEX] = vertices
    arrays[Mesh.ARRAY_NORMAL] = normals
    arrays[Mesh.ARRAY_TEX_UV] = uvs

    var mesh := ArrayMesh.new()
    mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
    mesh.surface_set_material(0, water_material)
    return mesh

func _scatter_world_foliage() -> void:
    var trunks := MultiMesh.new()
    var trunk_mesh := CylinderMesh.new()
    trunk_mesh.top_radius = 0.13
    trunk_mesh.bottom_radius = 0.20
    trunk_mesh.height = 2.8
    trunks.mesh = trunk_mesh
    trunks.transform_format = MultiMesh.TRANSFORM_3D

    var leaves := MultiMesh.new()
    var leaf_mesh := SphereMesh.new()
    leaf_mesh.radius = 1.45
    leaf_mesh.height = 2.8
    leaves.mesh = leaf_mesh
    leaves.transform_format = MultiMesh.TRANSFORM_3D

    var transforms: Array[Transform3D] = []
    var leaf_transforms: Array[Transform3D] = []

    for gx in range(-WORLD_RADIUS_CELLS(), WORLD_RADIUS_CELLS() + 1, 3):
        for gz in range(-WORLD_RADIUS_CELLS(), WORLD_RADIUS_CELLS() + 1, 3):
            var biome := _biome_at(gx, gz)
            if biome not in [0,1,2,6]:
                continue

            var chance := _stable_random(gx, gz)
            if chance < (0.42 if biome == 1 else 0.28):
                var h := _height_at(gx, gz)
                if _water_at(gx, gz):
                    continue

                var pos := Vector3(gx * CELL_SIZE, h + 1.4, gz * CELL_SIZE)
                var scale := 0.72 + _stable_random(gx + 17, gz - 7) * 0.75
                transforms.append(Transform3D(Basis().scaled(Vector3(scale, scale, scale)), pos))
                leaf_transforms.append(Transform3D(
                    Basis().scaled(Vector3(scale * 1.35, scale * 1.05, scale * 1.35)),
                    pos + Vector3(0, 2.0 * scale, 0)
                ))

    trunks.instance_count = transforms.size()
    for i in range(transforms.size()):
        trunks.set_instance_transform(i, transforms[i])

    leaves.instance_count = leaf_transforms.size()
    for i in range(leaf_transforms.size()):
        leaves.set_instance_transform(i, leaf_transforms[i])

    var trunk_instance := MultiMeshInstance3D.new()
    trunk_instance.multimesh = trunks
    trunk_instance.material_override = dark_material
    world_root.add_child(trunk_instance)

    var leaf_instance := MultiMeshInstance3D.new()
    leaf_instance.multimesh = leaves
    leaf_instance.material_override = dark_material.duplicate()
    world_root.add_child(leaf_instance)

func WORLD_RADIUS_CELLS() -> int:
    return CHUNK_CELLS * STREAM_RADIUS + CHUNK_CELLS

func _stable_random(x: int, z: int) -> float:
    var v := x * 374761393 + z * 668265263 + WORLD_SEED * 69069
    v = (v ^ (v >> 13)) * 1274126177
    v = v ^ (v >> 16)
    return float(v & 0x7fffffff) / 2147483647.0

func _spawn_landmarks() -> void:
    _spawn_village(Vector3(-42, 0, -24))
    _spawn_observatory(Vector3(36, 0, 24))
    _spawn_river_mill(Vector3(-4, 0, 46))
    _spawn_ruin(Vector3(42, 0, -38))

func _spawn_village(origin: Vector3) -> void:
    for i in range(5):
        var angle := float(i) * TAU / 5.0
        var pos := origin + Vector3(cos(angle), 0, sin(angle)) * 13.0
        _spawn_hut(pos, 4.6 + float(i) * 0.3)
    _spawn_brazier(origin + Vector3(0, 0.8, 0))

func _spawn_hut(origin: Vector3, radius: float) -> void:
    var root := Node3D.new()
    root.position = Vector3(origin.x, _height_at(int(origin.x / CELL_SIZE), int(origin.z / CELL_SIZE)), origin.z)
    world_root.add_child(root)

    var base := MeshInstance3D.new()
    var base_mesh := BoxMesh.new()
    base_mesh.size = Vector3(radius * 1.65, 1.9, radius * 1.45)
    base.mesh = base_mesh
    base.position.y = 0.95
    base.material_override = light_material
    root.add_child(base)

    var roof := MeshInstance3D.new()
    var roof_mesh := PrismMesh.new()
    roof_mesh.size = Vector3(radius * 1.9, 3.6, radius * 1.7)
    roof.mesh = roof_mesh
    roof.position.y = 3.3
    roof.material_override = dark_material
    root.add_child(roof)

    var lamp := OmniLight3D.new()
    lamp.position = Vector3(0,2.1,0)
    lamp.omni_range = 9.0
    lamp.light_energy = 1.8
    lamp.light_color = Color("#ffbe72")
    root.add_child(lamp)

func _spawn_observatory(origin: Vector3) -> void:
    var y := _height_at(int(origin.x / CELL_SIZE), int(origin.z / CELL_SIZE))
    var root := Node3D.new()
    root.position = Vector3(origin.x,y,origin.z)
    world_root.add_child(root)

    for i in range(8):
        var angle := float(i) * TAU / 8.0
        var col := MeshInstance3D.new()
        var mesh := CylinderMesh.new()
        mesh.top_radius = 0.75
        mesh.bottom_radius = 0.9
        mesh.height = 7.0
        col.mesh = mesh
        col.position = Vector3(cos(angle) * 6.0,3.5,sin(angle)*6.0)
        col.material_override = light_material
        root.add_child(col)

    var ring := MeshInstance3D.new()
    var ring_mesh := TorusMesh.new()
    ring_mesh.inner_radius = 5.0
    ring_mesh.outer_radius = 5.25
    ring.mesh = ring_mesh
    ring.position.y = 7.0
    ring.material_override = emissive_material
    root.add_child(ring)

func _spawn_river_mill(origin: Vector3) -> void:
    var y := _height_at(int(origin.x / CELL_SIZE), int(origin.z / CELL_SIZE))
    var root := Node3D.new()
    root.position = Vector3(origin.x,y,origin.z)
    world_root.add_child(root)

    var body := MeshInstance3D.new()
    var body_mesh := BoxMesh.new()
    body_mesh.size = Vector3(11, 4.5, 8)
    body.mesh = body_mesh
    body.position.y = 2.25
    body.material_override = light_material
    root.add_child(body)

    var wheel := MeshInstance3D.new()
    var wheel_mesh := TorusMesh.new()
    wheel_mesh.inner_radius = 2.3
    wheel_mesh.outer_radius = 2.65
    wheel.mesh = wheel_mesh
    wheel.rotation_degrees = Vector3(90,0,0)
    wheel.position = Vector3(5.5,2.5,0)
    wheel.material_override = dark_material
    root.add_child(wheel)

    var lamp := OmniLight3D.new()
    lamp.position = Vector3(0,3.2,0)
    lamp.omni_range = 12.0
    lamp.light_energy = 2.0
    lamp.light_color = Color("#d9a46b")
    root.add_child(lamp)

func _spawn_ruin(origin: Vector3) -> void:
    var y := _height_at(int(origin.x / CELL_SIZE), int(origin.z / CELL_SIZE))
    var root := Node3D.new()
    root.position = Vector3(origin.x,y,origin.z)
    world_root.add_child(root)

    for i in range(6):
        var angle := float(i) * TAU / 6.0
        var pillar := MeshInstance3D.new()
        var mesh := BoxMesh.new()
        mesh.size = Vector3(1.4, 5.0 + float(i % 2) * 2.0, 1.4)
        pillar.mesh = mesh
        pillar.position = Vector3(cos(angle)*6.0, mesh.size.y*0.5, sin(angle)*6.0)
        pillar.rotation.y = angle
        pillar.material_override = dark_material
        root.add_child(pillar)

    var core := MeshInstance3D.new()
    var core_mesh := SphereMesh.new()
    core_mesh.radius = 1.1
    core_mesh.height = 2.2
    core.mesh = core_mesh
    core.position.y = 2.4
    core.material_override = emissive_material
    root.add_child(core)

func _spawn_brazier(pos: Vector3) -> void:
    var light := OmniLight3D.new()
    light.position = pos
    light.omni_range = 14.0
    light.light_energy = 2.8
    light.light_color = Color("#ff9b56")
    world_root.add_child(light)

func _build_player() -> void:
    player = CharacterBody3D.new()
    player.name = "Player"
    player.floor_snap_length = 0.35
    player.floor_stop_on_slope = true
    player.collision_layer = 2
    player.collision_mask = 1
    player.position = Vector3(0, _height_at(0,0) + 4.0, 0)
    world_root.add_child(player)

    var body := MeshInstance3D.new()
    var capsule := CapsuleMesh.new()
    capsule.height = 1.8
    capsule.radius = 0.38
    body.mesh = capsule
    body.material_override = dark_material
    body.position.y = 0.9
    player.add_child(body)

    var shoulder := MeshInstance3D.new()
    var coat := BoxMesh.new()
    coat.size = Vector3(0.95, 0.75, 0.42)
    shoulder.mesh = coat
    shoulder.material_override = light_material
    shoulder.position = Vector3(0,1.15,-0.15)
    player.add_child(shoulder)

    var collision := CollisionShape3D.new()
    var capsule_shape := CapsuleShape3D.new()
    capsule_shape.height = 1.8
    capsule_shape.radius = 0.38
    collision.shape = capsule_shape
    collision.position.y = 0.9
    player.add_child(collision)

    camera_pivot = Node3D.new()
    camera_pivot.position = Vector3(0,1.35,0)
    player.add_child(camera_pivot)

    camera_pitch = Node3D.new()
    camera_pivot.add_child(camera_pitch)

    var spring := SpringArm3D.new()
    spring.spring_length = 7.0
    spring.margin = 0.3
    spring.collision_mask = 1
    camera_pitch.add_child(spring)

    player_camera = Camera3D.new()
    player_camera.current = true
    player_camera.fov = 68.0
    spring.add_child(player_camera)

    yaw = player.rotation.y

func _update_player(delta: float) -> void:
    if not player:
        return

    var input_2d := Vector2.ZERO
    if Input.is_key_pressed(KEY_W): input_2d.y -= 1.0
    if Input.is_key_pressed(KEY_S): input_2d.y += 1.0
    if Input.is_key_pressed(KEY_A): input_2d.x -= 1.0
    if Input.is_key_pressed(KEY_D): input_2d.x += 1.0
    input_2d = input_2d.normalized()

    var local := Vector3(input_2d.x, 0, input_2d.y)
    var direction := player.global_transform.basis * local
    direction.y = 0

    var sprinting := Input.is_key_pressed(KEY_SHIFT) and input_2d.length() > 0.1
    var target_speed := 4.8 if not sprinting else 8.2
    player.velocity.x = move_toward(player.velocity.x, direction.x * target_speed, 24.0 * delta)
    player.velocity.z = move_toward(player.velocity.z, direction.z * target_speed, 24.0 * delta)

    if not player.is_on_floor():
        player.velocity.y -= 18.0 * delta
    elif Input.is_key_pressed(KEY_SPACE):
        player.velocity.y = 7.6

    player.move_and_slide()

func _simulate_world(delta: float) -> void:
    world_clock += delta * 1.0
    if world_clock >= WORLD_DAY_MINUTES:
        world_clock -= WORLD_DAY_MINUTES
        world_day += 1

    var sun := get_node_or_null("Sun") as DirectionalLight3D
    if sun:
        var normalized := world_clock / WORLD_DAY_MINUTES
        sun.rotation_degrees.x = -90.0 + normalized * 360.0
        sun.light_energy = lerpf(0.16, 1.8, clamp(sin(normalized * TAU - PI * 0.5) * 0.5 + 0.5, 0.0, 1.0))

func _update_hud() -> void:
    if not player:
        return

    var gx := int(round(player.position.x / CELL_SIZE))
    var gz := int(round(player.position.z / CELL_SIZE))
    var biome := _biome_at(gx, gz)
    var biome_name := str(biome_defs[biome]["name"]) if biome < biome_defs.size() else "Unknown"

    biome_label.text = biome_name
    coords_label.text = "X %d   Y %d   Z %d" % [gx, int(round(player.position.y)), gz]

    var h := int(world_clock) / 60
    var m := int(world_clock) % 60
    var suffix := "DAY"
    if h >= 18 or h < 5:
        suffix = "NIGHT"
    time_label.text = "DAY %02d   %02d:%02d   %s" % [world_day, h, m, suffix]

func _build_title_screen() -> void:
    title_layer = CanvasLayer.new()
    title_layer.layer = 20
    add_child(title_layer)

    var root := Control.new()
    root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    title_layer.add_child(root)

    var shade := ColorRect.new()
    shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    shade.color = Color(0.015,0.022,0.032,0.27)
    root.add_child(shade)

    var brand := Label.new()
    brand.text = "LYRENTHOS"
    brand.position = Vector2(74, 78)
    brand.add_theme_font_size_override("font_size", 68)
    brand.add_theme_color_override("font_color", Color("#eff7ff"))
    root.add_child(brand)

    var subtitle := Label.new()
    subtitle.text = "INSULAR GENESIS  •  PHASE 01"
    subtitle.position = Vector2(80, 151)
    subtitle.add_theme_font_size_override("font_size", 18)
    subtitle.add_theme_color_override("font_color", Color("#8dc6e7"))
    root.add_child(subtitle)

    var descriptor := Label.new()
    descriptor.text = "A living frontier shaped by terrain, weather, exploration and what you build."
    descriptor.position = Vector2(80, 183)
    descriptor.add_theme_font_size_override("font_size", 15)
    descriptor.add_theme_color_override("font_color", Color("#cad7df"))
    root.add_child(descriptor)

    var panel := PanelContainer.new()
    panel.position = Vector2(80, 300)
    panel.size = Vector2(390, 290)
    panel.add_theme_stylebox_override("panel", _panel_style(Color(0.02,0.03,0.045,0.86), Color("#78cfff")))
    root.add_child(panel)

    var box := VBoxContainer.new()
    box.add_theme_constant_override("separation", 12)
    panel.add_child(box)

    var play := Button.new()
    play.text = "ENTER LYRENTHOS"
    play.custom_minimum_size = Vector2(0, 58)
    play.add_theme_font_size_override("font_size", 22)
    play.pressed.connect(_begin_game)
    box.add_child(play)

    var settings := Button.new()
    settings.text = "SETTINGS"
    settings.custom_minimum_size = Vector2(0, 50)
    settings.add_theme_font_size_override("font_size", 17)
    settings.pressed.connect(_toggle_settings)
    box.add_child(settings)

    var quit := Button.new()
    quit.text = "QUIT"
    quit.custom_minimum_size = Vector2(0, 50)
    quit.add_theme_font_size_override("font_size", 17)
    quit.pressed.connect(func(): get_tree().quit())
    box.add_child(quit)

    var hint := Label.new()
    hint.text = "Prototype controls:  WASD  •  SHIFT  •  SPACE  •  TAB"
    hint.position = Vector2(80, 625)
    hint.add_theme_font_size_override("font_size", 13)
    hint.add_theme_color_override("font_color", Color("#9aabb5"))
    root.add_child(hint)

    title_camera = Camera3D.new()
    title_camera.position = Vector3(31, 25, 52)
    title_camera.look_at(Vector3(0, 11, 0), Vector3.UP)
    title_camera.current = true
    add_child(title_camera)

func _begin_game() -> void:
    title_visible = false
    title_layer.visible = false
    _set_gameplay_active(true)

func _set_gameplay_active(active: bool) -> void:
    if player_camera:
        player_camera.current = active
    if active:
        Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
    else:
        Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func _build_hud() -> void:
    hud_layer = CanvasLayer.new()
    hud_layer.layer = 10
    hud_layer.visible = false
    add_child(hud_layer)

    crosshair = Label.new()
    crosshair.text = "+"
    crosshair.position = Vector2(795, 430)
    crosshair.add_theme_font_size_override("font_size", 22)
    crosshair.add_theme_color_override("font_color", Color("#f2fbff"))
    hud_layer.add_child(crosshair)

    biome_label = Label.new()
    biome_label.position = Vector2(34, 28)
    biome_label.add_theme_font_size_override("font_size", 20)
    biome_label.add_theme_color_override("font_color", Color("#edf6ff"))
    hud_layer.add_child(biome_label)

    coords_label = Label.new()
    coords_label.position = Vector2(34, 56)
    coords_label.add_theme_font_size_override("font_size", 13)
    coords_label.add_theme_color_override("font_color", Color("#a7bac5"))
    hud_layer.add_child(coords_label)

    time_label = Label.new()
    time_label.position = Vector2(1280, 32)
    time_label.add_theme_font_size_override("font_size", 16)
    time_label.add_theme_color_override("font_color", Color("#edf6ff"))
    hud_layer.add_child(time_label)

    interact_label = Label.new()
    interact_label.text = "TAB  Inventory      SHIFT  Sprint      SPACE  Jump"
    interact_label.position = Vector2(34, 847)
    interact_label.add_theme_font_size_override("font_size", 14)
    interact_label.add_theme_color_override("font_color", Color("#a7bac5"))
    hud_layer.add_child(interact_label)

func _build_inventory() -> void:
    inventory_layer = CanvasLayer.new()
    inventory_layer.layer = 30
    inventory_layer.visible = false
    add_child(inventory_layer)

    var background := ColorRect.new()
    background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    background.color = Color(0.01,0.02,0.028,0.90)
    inventory_layer.add_child(background)

    var panel := PanelContainer.new()
    panel.position = Vector2(220, 120)
    panel.size = Vector2(1160, 660)
    panel.add_theme_stylebox_override("panel", _panel_style(Color(0.025,0.035,0.05,0.97), Color("#4d8aa7")))
    background.add_child(panel)

    var root := VBoxContainer.new()
    root.add_theme_constant_override("separation", 12)
    panel.add_child(root)

    var title := Label.new()
    title.text = "INVENTORY"
    title.add_theme_font_size_override("font_size", 30)
    root.add_child(title)

    var body := HBoxContainer.new()
    body.size_flags_vertical = Control.SIZE_EXPAND_FILL
    root.add_child(body)

    var grid := GridContainer.new()
    grid.columns = 6
    grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    for i in range(36):
        var slot := Button.new()
        slot.text = "%02d" % (i + 1)
        slot.custom_minimum_size = Vector2(120, 82)
        slot.add_theme_font_size_override("font_size", 14)
        grid.add_child(slot)
    body.add_child(grid)

    var info := RichTextLabel.new()
    info.bbcode_enabled = true
    info.custom_minimum_size = Vector2(290, 0)
    info.text = "[font_size=22]LYRENTHOS[/font_size]\n\nThe inventory shell is now functional. Phase 2 will replace these cells with item definitions, drag/drop, stack counts, equipment slots and quick access."
    body.add_child(info)

    var close := Button.new()
    close.text = "TAB  CLOSE"
    close.custom_minimum_size = Vector2(0, 48)
    close.pressed.connect(_close_overlays)
    root.add_child(close)

func _build_settings() -> void:
    settings_layer = CanvasLayer.new()
    settings_layer.layer = 40
    settings_layer.visible = false
    add_child(settings_layer)

    var backdrop := ColorRect.new()
    backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    backdrop.color = Color(0.01,0.015,0.02,0.82)
    settings_layer.add_child(backdrop)

    var panel := PanelContainer.new()
    panel.position = Vector2(480, 170)
    panel.size = Vector2(640, 520)
    panel.add_theme_stylebox_override("panel", _panel_style(Color(0.025,0.035,0.05,0.98), Color("#78cfff")))
    backdrop.add_child(panel)

    var root := VBoxContainer.new()
    root.add_theme_constant_override("separation", 13)
    panel.add_child(root)

    var title := Label.new()
    title.text = "SETTINGS"
    title.add_theme_font_size_override("font_size", 30)
    root.add_child(title)

    var note := Label.new()
    note.text = "Phase 1 settings are intentionally small. The final game will expose graphics, audio, accessibility, controls and gameplay configuration."
    note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    root.add_child(note)

    var controls := Label.new()
    controls.text = "Controls\n\nWASD   Move\nSHIFT   Sprint\nSPACE   Jump\nTAB   Inventory\nE   Interact\nMouse   Camera"
    controls.add_theme_font_size_override("font_size", 17)
    root.add_child(controls)

    var close := Button.new()
    close.text = "BACK"
    close.custom_minimum_size = Vector2(0, 50)
    close.pressed.connect(_toggle_settings)
    root.add_child(close)

func _toggle_inventory() -> void:
    inventory_visible = not inventory_visible
    inventory_layer.visible = inventory_visible
    hud_layer.visible = not inventory_visible
    Input.mouse_mode = Input.MOUSE_MODE_VISIBLE if inventory_visible else Input.MOUSE_MODE_CAPTURED

func _toggle_settings() -> void:
    settings_visible = not settings_visible
    settings_layer.visible = settings_visible
    if settings_visible:
        Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
    else:
        Input.mouse_mode = Input.MOUSE_MODE_VISIBLE if title_visible else Input.MOUSE_MODE_CAPTURED

func _close_overlays() -> void:
    inventory_visible = false
    settings_visible = false
    inventory_layer.visible = false
    settings_layer.visible = false
    hud_layer.visible = not title_visible
    if not title_visible:
        Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _panel_style(fill: Color, border: Color) -> StyleBoxFlat:
    var style := StyleBoxFlat.new()
    style.bg_color = fill
    style.border_color = border
    style.set_border_width_all(1)
    style.corner_radius_top_left = 8
    style.corner_radius_top_right = 8
    style.corner_radius_bottom_left = 8
    style.corner_radius_bottom_right = 8
    style.content_margin_left = 24
    style.content_margin_right = 24
    style.content_margin_top = 22
    style.content_margin_bottom = 22
    return style
