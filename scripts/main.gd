extends Node3D

const WORLD_SIZE := 72
const CELL := 2.0

var world_root: Node3D
var player: CharacterBody3D
var inventory_ui: Control

func _ready() -> void:
    _build_environment()
    _generate_world()
    _spawn_player()
    _build_ui()
    Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _unhandled_input(event: InputEvent) -> void:
    if event is InputEventKey and event.pressed and not event.echo:
        if event.keycode == KEY_TAB:
            inventory_ui.visible = not inventory_ui.visible
            Input.mouse_mode = Input.MOUSE_MODE_VISIBLE if inventory_ui.visible else Input.MOUSE_MODE_CAPTURED
        elif event.keycode == KEY_ESCAPE:
            inventory_ui.visible = false
            Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _build_environment() -> void:
    var env := WorldEnvironment.new()
    var e := Environment.new()
    e.background_mode = Environment.BG_SKY
    e.sky = Sky.new()
    e.sky.sky_material = ProceduralSkyMaterial.new()
    var sky := e.sky.sky_material as ProceduralSkyMaterial
    sky.sky_top_color = Color("#07111f")
    sky.sky_horizon_color = Color("#9fc0d2")
    sky.ground_horizon_color = Color("#3c5561")
    sky.ground_bottom_color = Color("#0a1115")
    e.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
    e.ambient_light_energy = 1.15
    env.environment = e
    add_child(env)

    var sun := DirectionalLight3D.new()
    sun.rotation_degrees = Vector3(-55.0, -35.0, 0.0)
    sun.light_energy = 1.6
    sun.shadow_enabled = true
    add_child(sun)

func _generate_world() -> void:
    world_root = Node3D.new()
    world_root.name = "GeneratedWorld"
    add_child(world_root)

    var terrain := FastNoiseLite.new()
    terrain.seed = 418231
    terrain.frequency = 0.012
    terrain.fractal_octaves = 5
    terrain.fractal_lacunarity = 2.0
    terrain.fractal_gain = 0.55
    terrain.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH

    var biome_noise := FastNoiseLite.new()
    biome_noise.seed = 901773
    biome_noise.frequency = 0.004

    for x in range(-WORLD_SIZE, WORLD_SIZE + 1):
        for z in range(-WORLD_SIZE, WORLD_SIZE + 1):
            var n := terrain.get_noise_2d(x, z)
            var ridge := absf(terrain.get_noise_2d(x * 0.35, z * 0.35))
            var h := int(round(8.0 + n * 7.0 + ridge * 9.0))
            var material := _biome_material(biome_noise.get_noise_2d(x, z), h)
            _place_column(x, z, h, material)

    _spawn_structure(Vector3(-28, 0, -18), Color("#293e42"))
    _spawn_structure(Vector3(24, 0, 14), Color("#4a3b31"))
    _spawn_structure(Vector3(4, 0, -38), Color("#30384f"))

func _place_column(x: int, z: int, h: int, material: Material) -> void:
    var mesh := BoxMesh.new()
    mesh.size = Vector3(CELL, maxf(1.0, float(h)), CELL)
    var node := MeshInstance3D.new()
    node.mesh = mesh
    node.position = Vector3(x * CELL, mesh.size.y * 0.5, z * CELL)
    node.material_override = material
    world_root.add_child(node)

func _spawn_structure(origin: Vector3, color: Color) -> void:
    var root := Node3D.new()
    root.position = origin
    world_root.add_child(root)

    for x in range(-4, 5):
        for z in range(-4, 5):
            if abs(x) == 4 or abs(z) == 4:
                var mesh := BoxMesh.new()
                mesh.size = Vector3(1.8, 2.2, 1.8)
                var node := MeshInstance3D.new()
                node.mesh = mesh
                node.position = Vector3(x * 1.8, 1.1, z * 1.8)
                node.material_override = _mat(color, 0.82)
                root.add_child(node)

    var roof := PrismMesh.new()
    roof.size = Vector3(16, 6, 12)
    var roof_node := MeshInstance3D.new()
    roof_node.mesh = roof
    roof_node.position = Vector3(0, 5.5, 0)
    roof_node.material_override = _mat(color.lightened(0.08), 0.95)
    root.add_child(roof_node)

func _biome_material(v: float, h: int) -> Material:
    if h > 20:
        return _mat(Color("#697681"), 0.92)
    if v < -0.28:
        return _mat(Color("#5d5a42"), 0.86)
    if v > 0.32:
        return _mat(Color("#8e6d4f"), 0.90)
    return _mat(Color("#35654a"), 0.82)

func _mat(color: Color, roughness: float) -> StandardMaterial3D:
    var m := StandardMaterial3D.new()
    m.albedo_color = color
    m.roughness = roughness
    return m

func _spawn_player() -> void:
    player = CharacterBody3D.new()
    player.name = "Player"
    player.position = Vector3(0, 25, 0)
    add_child(player)

    var mesh := CapsuleMesh.new()
    mesh.height = 1.8
    mesh.radius = 0.38
    var body := MeshInstance3D.new()
    body.mesh = mesh
    body.material_override = _mat(Color("#28323a"), 0.72)
    player.add_child(body)

    var collision := CollisionShape3D.new()
    var shape := CapsuleShape3D.new()
    shape.height = 1.8
    shape.radius = 0.38
    collision.shape = shape
    player.add_child(collision)

    var cam := Camera3D.new()
    cam.position = Vector3(0, 4.2, 8.5)
    player.add_child(cam)
    cam.look_at(Vector3(0, 1.0, 0), Vector3.UP)

func _process(delta: float) -> void:
    if player:
        _move_player(delta)

func _move_player(delta: float) -> void:
    var dir := Vector3.ZERO
    if Input.is_key_pressed(KEY_W): dir.z -= 1
    if Input.is_key_pressed(KEY_S): dir.z += 1
    if Input.is_key_pressed(KEY_A): dir.x -= 1
    if Input.is_key_pressed(KEY_D): dir.x += 1
    dir = dir.normalized()
    var speed := 4.0 if not Input.is_key_pressed(KEY_SHIFT) else 7.5
    player.velocity.x = dir.x * speed
    player.velocity.z = dir.z * speed
    if not player.is_on_floor():
        player.velocity.y -= 18.0 * delta
    elif Input.is_key_pressed(KEY_SPACE):
        player.velocity.y = 7.0
    player.move_and_slide()

func _build_ui() -> void:
    inventory_ui = ColorRect.new()
    inventory_ui.visible = false
    inventory_ui.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    inventory_ui.color = Color(0.015, 0.025, 0.04, 0.90)
    add_child(inventory_ui)

    var title := Label.new()
    title.text = "LYRENTHOS  •  INVENTORY"
    title.position = Vector2(70, 55)
    title.add_theme_font_size_override("font_size", 30)
    inventory_ui.add_child(title)

    var info := Label.new()
    info.text = "Prototype inventory\n\nTAB Close\nWASD Move   SHIFT Sprint   SPACE Jump   E Interact"
    info.position = Vector2(75, 130)
    info.add_theme_font_size_override("font_size", 20)
    inventory_ui.add_child(info)
