extends Node3D

var player

func _ready() -> void:
    _setup_environment()
    _build_ground()
    _build_village()
    _build_forest()
    _build_npc()
    _build_wolf()
    _spawn_player()
    _build_hud()

func _setup_environment() -> void:
    var world_env := WorldEnvironment.new()
    var env := Environment.new()
    env.background_mode = Environment.BG_COLOR
    env.background_color = Color("89b7d6")
    env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
    env.ambient_light_color = Color("b7c7d8")
    env.ambient_light_energy = 0.65
    world_env.environment = env
    add_child(world_env)

    var sun := DirectionalLight3D.new()
    sun.rotation_degrees = Vector3(-48.0, -32.0, 0.0)
    sun.light_energy = 1.25
    sun.shadow_enabled = true
    add_child(sun)

func _build_ground() -> void:
    var ground := StaticBody3D.new()
    ground.name = "RavenfallGround"
    add_child(ground)

    var mesh_instance := MeshInstance3D.new()
    var mesh := BoxMesh.new()
    mesh.size = Vector3(120.0, 0.4, 120.0)
    mesh_instance.mesh = mesh
    mesh_instance.position.y = -0.2
    mesh_instance.material_override = _material(Color("5c8d47"), 0.95)
    ground.add_child(mesh_instance)

    var shape := CollisionShape3D.new()
    var box := BoxShape3D.new()
    box.size = Vector3(120.0, 0.4, 120.0)
    shape.shape = box
    shape.position.y = -0.2
    ground.add_child(shape)

    var road := MeshInstance3D.new()
    var road_mesh := BoxMesh.new()
    road_mesh.size = Vector3(8.0, 0.06, 58.0)
    road.mesh = road_mesh
    road.position = Vector3(0.0, 0.03, -14.0)
    road.material_override = _material(Color("9a7a55"), 1.0)
    add_child(road)

func _build_village() -> void:
    _make_house(Vector3(-10.0, 0.0, 2.0), Color("7d5a3a"))
    _make_house(Vector3(10.0, 0.0, 1.0), Color("6b5138"))
    _make_house(Vector3(-11.5, 0.0, -13.0), Color("76533c"))
    _make_house(Vector3(11.0, 0.0, -14.0), Color("705039"))

    for x in [-15.0, -5.0, 5.0, 15.0]:
        var post := MeshInstance3D.new()
        var post_mesh := CylinderMesh.new()
        post_mesh.top_radius = 0.12
        post_mesh.bottom_radius = 0.16
        post_mesh.height = 2.2
        post.mesh = post_mesh
        post.position = Vector3(x, 1.1, -27.0)
        post.material_override = _material(Color("65472f"), 1.0)
        add_child(post)

func _make_house(pos: Vector3, wall_color: Color) -> void:
    var house := StaticBody3D.new()
    house.position = pos
    add_child(house)

    var body := MeshInstance3D.new()
    var body_mesh := BoxMesh.new()
    body_mesh.size = Vector3(7.0, 4.0, 6.0)
    body.mesh = body_mesh
    body.position.y = 2.0
    body.material_override = _material(wall_color, 0.95)
    house.add_child(body)

    var roof := MeshInstance3D.new()
    var roof_mesh := PrismMesh.new()
    roof_mesh.size = Vector3(8.0, 3.0, 7.0)
    roof.mesh = roof_mesh
    roof.position.y = 5.3
    roof.rotation_degrees.y = 90.0
    roof.material_override = _material(Color("4b302a"), 1.0)
    house.add_child(roof)

    var collision := CollisionShape3D.new()
    var shape := BoxShape3D.new()
    shape.size = Vector3(7.0, 4.0, 6.0)
    collision.shape = shape
    collision.position.y = 2.0
    house.add_child(collision)

func _build_forest() -> void:
    var positions := [
        Vector3(-24, 0, -4), Vector3(-28, 0, -11), Vector3(-22, 0, -20),
        Vector3(24, 0, -6), Vector3(28, 0, -16), Vector3(22, 0, -24),
        Vector3(-31, 0, 12), Vector3(31, 0, 15), Vector3(-18, 0, 24),
        Vector3(20, 0, 28), Vector3(-35, 0, -31), Vector3(35, 0, -34)
    ]
    for pos in positions:
        _make_tree(pos, 0.9 + randf() * 0.35)

func _make_tree(pos: Vector3, scale_factor: float) -> void:
    var tree := Node3D.new()
    tree.position = pos
    tree.scale = Vector3.ONE * scale_factor
    add_child(tree)

    var trunk := MeshInstance3D.new()
    var trunk_mesh := CylinderMesh.new()
    trunk_mesh.top_radius = 0.35
    trunk_mesh.bottom_radius = 0.5
    trunk_mesh.height = 4.0
    trunk.mesh = trunk_mesh
    trunk.position.y = 2.0
    trunk.material_override = _material(Color("5b3e29"), 1.0)
    tree.add_child(trunk)

    var crown := MeshInstance3D.new()
    var crown_mesh := SphereMesh.new()
    crown_mesh.radius = 2.2
    crown_mesh.height = 4.4
    crown.mesh = crown_mesh
    crown.position.y = 5.1
    crown.material_override = _material(Color("2f6d3c"), 0.9)
    tree.add_child(crown)

func _build_npc() -> void:
    var npc := Node3D.new()
    npc.name = "QuestNPC"
    npc.position = Vector3(-2.8, 0.0, -6.0)
    add_child(npc)

    var body := MeshInstance3D.new()
    var mesh := CapsuleMesh.new()
    mesh.radius = 0.5
    mesh.height = 1.8
    body.mesh = mesh
    body.position.y = 0.9
    body.material_override = _material(Color("d5aa54"), 0.9)
    npc.add_child(body)

    var label := Label3D.new()
    label.text = "!  Hauptmann Arlen\nQuestgeber"
    label.position = Vector3(0, 2.5, 0)
    label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
    label.font_size = 30
    label.outline_size = 7
    npc.add_child(label)

func _build_wolf() -> void:
    var wolf := Node3D.new()
    wolf.name = "WolfLv1"
    wolf.position = Vector3(7.0, 0.0, -31.0)
    add_child(wolf)

    var body := MeshInstance3D.new()
    var body_mesh := BoxMesh.new()
    body_mesh.size = Vector3(1.1, 0.8, 2.2)
    body.mesh = body_mesh
    body.position.y = 0.8
    body.material_override = _material(Color("59616d"), 1.0)
    wolf.add_child(body)

    var head := MeshInstance3D.new()
    var head_mesh := BoxMesh.new()
    head_mesh.size = Vector3(0.8, 0.75, 0.8)
    head.mesh = head_mesh
    head.position = Vector3(0, 1.15, -1.25)
    head.material_override = body.material_override
    wolf.add_child(head)

    var label := Label3D.new()
    label.text = "Wolf · Lv. 1"
    label.position = Vector3(0, 2.1, 0)
    label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
    label.font_size = 26
    label.outline_size = 6
    wolf.add_child(label)

func _spawn_player() -> void:
    player = CharacterBody3D.new()
    player.name = "Player"
    player.position = Vector3(0.0, 1.0, 8.0)
    player.set_script(load("res://scripts/player.gd"))
    add_child(player)

    var collision := CollisionShape3D.new()
    var capsule := CapsuleShape3D.new()
    capsule.radius = 0.45
    capsule.height = 1.9
    collision.shape = capsule
    collision.position.y = 0.95
    player.add_child(collision)

    var visual := MeshInstance3D.new()
    var visual_mesh := CapsuleMesh.new()
    visual_mesh.radius = 0.45
    visual_mesh.height = 1.9
    visual.mesh = visual_mesh
    visual.position.y = 0.95
    visual.material_override = _material(Color("3e77b6"), 0.82)
    player.add_child(visual)

func _build_hud() -> void:
    var canvas := CanvasLayer.new()
    canvas.name = "HUD"
    add_child(canvas)

    var hud := Control.new()
    hud.set_script(load("res://scripts/hud.gd"))
    hud.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    hud.mouse_filter = Control.MOUSE_FILTER_IGNORE
    hud.set("player", player)
    canvas.add_child(hud)

func _material(color: Color, roughness: float) -> StandardMaterial3D:
    var mat := StandardMaterial3D.new()
    mat.albedo_color = color
    mat.roughness = roughness
    return mat
