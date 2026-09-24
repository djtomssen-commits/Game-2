extends Node3D

const QUEST_WOLVES := 0
const QUEST_BANDITS := 1
const QUEST_CAPTAIN := 2
const QUEST_MINE_SPIDERS := 3
const QUEST_MINE_BOSS := 4
const QUEST_DONE := 5

const SURFACE_MINE_ENTRANCE := Vector3(-17.0, 0.0, -80.0)
const MINE_EXIT := Vector3(220.0, 0.0, 31.0)
const MINE_CENTER := Vector3(220.0, 0.0, 0.0)

var player: CharacterBody3D
var hud: Control
var quest_npc: Node3D
var quest_label: Label3D
var enemies: Array[Node] = []
var wolves: Array[Node] = []
var bandits: Array[Node] = []
var captain: Node = null
var spiders: Array[Node] = []
var mine_boss: Node = null
var current_target: Node = null

var quest_id := QUEST_WOLVES
var quest_stage := 0 # 0=available, 1=active, 2=ready, 3=all done
var quest_progress := 0
var quest_panel_open := false
var inventory_open := false

var level := 1
var xp := 0
var gold := 0
var pelts := 0
var rage := 0
var max_rage := 100
var potions := 3
var potion_cd := 0.0

var inventory: Array[Dictionary] = []
var equipped_weapon: Dictionary = {"name":"Rekrutenschwert", "power":0, "rarity":"Gewöhnlich", "type":"Waffe"}
var equipped_armor: Dictionary = {"name":"Rekrutenwams", "armor":0, "rarity":"Gewöhnlich", "type":"Rüstung"}
var equipped_charm: Dictionary = {"name":"Kein Talisman", "power":0, "rarity":"Gewöhnlich", "type":"Schmuck"}

var attack_cooldown := 0.0
var skill1_cd := 0.0
var skill2_cd := 0.0
var toast_text := ""
var toast_time := 0.0
var loot_text := ""
var loot_time := 0.0
var autosave_timer := 6.0

func _ready() -> void:
    randomize()
    DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
    DisplayServer.screen_set_orientation(DisplayServer.SCREEN_LANDSCAPE)
    _setup_environment()
    _build_ground()
    _build_village()
    _build_forest_and_ruins()
    _build_bandit_camp_and_mine()
    _build_mine_zone()
    _scatter_world_detail()
    _build_npc()
    _spawn_player()
    _build_wolves()
    _build_bandits()
    _build_captain()
    _build_mine_enemies()
    _build_hud()
    _load_game()
    show_toast("Ravenfall · Kapitel II", 3.0)

func _process(delta: float) -> void:
    attack_cooldown = maxf(0.0, attack_cooldown - delta)
    skill1_cd = maxf(0.0, skill1_cd - delta)
    skill2_cd = maxf(0.0, skill2_cd - delta)
    potion_cd = maxf(0.0, potion_cd - delta)
    toast_time = maxf(0.0, toast_time - delta)
    loot_time = maxf(0.0, loot_time - delta)
    autosave_timer -= delta
    if autosave_timer <= 0.0:
        autosave_timer = 6.0
        save_game()
    if current_target != null:
        if not is_instance_valid(current_target) or not current_target.is_alive_enemy():
            select_target(null)
    _update_quest_marker()

func _setup_environment() -> void:
    var world_env := WorldEnvironment.new()
    var env := Environment.new()
    env.background_mode = Environment.BG_SKY
    var sky := Sky.new()
    var sky_mat := ProceduralSkyMaterial.new()
    sky_mat.sky_top_color = Color("4d86b5")
    sky_mat.sky_horizon_color = Color("b9d7e7")
    sky_mat.ground_bottom_color = Color("30442e")
    sky_mat.ground_horizon_color = Color("95b884")
    sky_mat.sun_angle_max = 18.0
    sky_mat.sun_curve = 0.16
    sky.sky_material = sky_mat
    env.sky = sky
    env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
    env.ambient_light_energy = 0.68
    env.reflected_light_source = Environment.REFLECTION_SOURCE_SKY
    env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
    world_env.environment = env
    add_child(world_env)

    var sun := DirectionalLight3D.new()
    sun.name = "Sun"
    sun.rotation_degrees = Vector3(-52.0, -32.0, 0.0)
    sun.light_color = Color("fff0cf")
    sun.light_energy = 1.28
    sun.shadow_enabled = true
    sun.directional_shadow_max_distance = 70.0
    add_child(sun)

func _build_ground() -> void:
    var ground := StaticBody3D.new()
    ground.name = "RavenfallGround"
    add_child(ground)

    var mesh_instance := MeshInstance3D.new()
    var mesh := BoxMesh.new()
    mesh.size = Vector3(190.0, 0.45, 190.0)
    mesh_instance.mesh = mesh
    mesh_instance.position.y = -0.225
    mesh_instance.material_override = _material(Color("5b8d43"), 0.98)
    ground.add_child(mesh_instance)

    var shape := CollisionShape3D.new()
    var box := BoxShape3D.new()
    box.size = Vector3(190.0, 0.45, 190.0)
    shape.shape = box
    shape.position.y = -0.225
    ground.add_child(shape)

    _make_road(Vector3(0.0, 0.025, -25.0), Vector3(8.5, 0.05, 100.0), Color("a78459"))
    _make_road(Vector3(15.0, 0.028, -48.0), Vector3(38.0, 0.055, 5.8), Color("96724d"))
    _make_road(Vector3(-14.0, 0.029, -63.0), Vector3(31.0, 0.05, 4.5), Color("8d6d4b"))

    # Low-poly boundary hills make the zone feel enclosed without heavy terrain meshes.
    for hill_data in [
        [Vector3(-63, -4, -28), Vector3(28, 9, 38)], [Vector3(62, -5, -30), Vector3(30, 10, 42)],
        [Vector3(-52, -5, 48), Vector3(37, 11, 27)], [Vector3(54, -5, 52), Vector3(35, 10, 29)],
        [Vector3(-45, -5, -82), Vector3(42, 13, 25)], [Vector3(48, -6, -88), Vector3(46, 15, 27)]
    ]:
        _make_hill(hill_data[0], hill_data[1])

func _make_road(pos: Vector3, size: Vector3, color: Color) -> void:
    var road := MeshInstance3D.new()
    var road_mesh := BoxMesh.new()
    road_mesh.size = size
    road.mesh = road_mesh
    road.position = pos
    road.material_override = _material(color, 1.0)
    add_child(road)

func _make_hill(pos: Vector3, scale_value: Vector3) -> void:
    var hill := MeshInstance3D.new()
    var sphere := SphereMesh.new()
    sphere.radius = 1.0
    sphere.height = 2.0
    sphere.radial_segments = 12
    sphere.rings = 6
    hill.mesh = sphere
    hill.position = pos
    hill.scale = scale_value
    hill.material_override = _material(Color("456f3a"), 1.0)
    add_child(hill)

func _build_village() -> void:
    _make_house(Vector3(-12.0, 0.0, 5.0), -8.0, Color("d0a36f"), Color("55372e"))
    _make_house(Vector3(12.0, 0.0, 4.0), 5.0, Color("c38e62"), Color("4a302a"))
    _make_house(Vector3(-13.5, 0.0, -13.0), -2.0, Color("d2aa78"), Color("593b30"))
    _make_house(Vector3(13.0, 0.0, -15.0), 4.0, Color("bd8d61"), Color("4c322a"))
    _make_house(Vector3(-13.0, 0.0, -31.0), 4.0, Color("c9a070"), Color("51362d"))

    _make_gate_post(Vector3(-5.3, 0.0, -31.5))
    _make_gate_post(Vector3(5.3, 0.0, -31.5))
    _make_gate_beam(Vector3(0.0, 5.0, -31.5))

    var sign := Label3D.new()
    sign.text = "RAVENFALL"
    sign.position = Vector3(0.0, 5.8, -31.5)
    sign.billboard = BaseMaterial3D.BILLBOARD_ENABLED
    sign.font_size = 38
    sign.outline_size = 9
    sign.modulate = Color("f3d58d")
    add_child(sign)

    _make_well(Vector3(4.2, 0.0, -9.0))
    _make_crate(Vector3(6.7, 0.0, -8.0), 0.9)
    _make_crate(Vector3(7.7, 0.0, -8.4), 0.7)
    _make_crate(Vector3(-6.0, 0.0, -20.0), 0.85)

    for z in [-3.0, -11.0, -19.0, -27.0]:
        _make_lantern(Vector3(-5.0, 0.0, z))
        _make_lantern(Vector3(5.0, 0.0, z - 2.0))

    for x in range(-21, 22, 4):
        if abs(x) > 6:
            _make_fence_post(Vector3(float(x), 0.0, -32.0))

func _make_house(pos: Vector3, yaw_deg: float, wall_color: Color, roof_color: Color) -> void:
    var house := StaticBody3D.new()
    house.position = pos
    house.rotation_degrees.y = yaw_deg
    add_child(house)

    _add_box_mesh(house, Vector3(7.2, 3.8, 6.0), Vector3(0, 1.9, 0), wall_color)
    var roof := MeshInstance3D.new()
    var roof_mesh := PrismMesh.new()
    roof_mesh.size = Vector3(8.3, 2.8, 7.0)
    roof.mesh = roof_mesh
    roof.position.y = 5.05
    roof.rotation_degrees.y = 90.0
    roof.material_override = _material(roof_color, 1.0)
    house.add_child(roof)

    # Timber framing and windows add depth without external assets.
    for x in [-3.0, 0.0, 3.0]:
        _add_box_mesh(house, Vector3(0.16, 3.8, 0.14), Vector3(x, 1.9, -3.03), Color("5b3b29"))
    _add_box_mesh(house, Vector3(7.0, 0.16, 0.14), Vector3(0, 3.45, -3.03), Color("5b3b29"))
    _add_box_mesh(house, Vector3(1.35, 2.25, 0.14), Vector3(0, 1.13, -3.08), Color("432b20"))
    for x in [-2.0, 2.0]:
        _add_box_mesh(house, Vector3(1.15, 1.0, 0.12), Vector3(x, 2.05, -3.09), Color("6aa0b2"), 0.25)
        _add_box_mesh(house, Vector3(1.32, 0.09, 0.15), Vector3(x, 2.05, -3.16), Color("563824"))
        _add_box_mesh(house, Vector3(0.09, 1.15, 0.15), Vector3(x, 2.05, -3.16), Color("563824"))

    var collision := CollisionShape3D.new()
    var shape := BoxShape3D.new()
    shape.size = Vector3(7.2, 3.8, 6.0)
    collision.shape = shape
    collision.position.y = 1.9
    house.add_child(collision)

func _make_gate_post(pos: Vector3) -> void:
    var body := StaticBody3D.new()
    body.position = pos
    add_child(body)
    _add_box_mesh(body, Vector3(1.35, 5.0, 1.35), Vector3(0, 2.5, 0), Color("665344"))
    _add_box_mesh(body, Vector3(1.65, 0.45, 1.65), Vector3(0, 5.0, 0), Color("4b3b31"))
    var collision := CollisionShape3D.new()
    var box := BoxShape3D.new()
    box.size = Vector3(1.35, 5.0, 1.35)
    collision.shape = box
    collision.position.y = 2.5
    body.add_child(collision)

func _make_gate_beam(pos: Vector3) -> void:
    _add_box_mesh(self, Vector3(12.0, 0.65, 0.9), pos, Color("5e4939"))

func _make_well(pos: Vector3) -> void:
    var root := Node3D.new()
    root.position = pos
    add_child(root)
    for i in range(12):
        var angle := TAU * float(i) / 12.0
        var stone_pos := Vector3(cos(angle) * 1.15, 0.45, sin(angle) * 1.15)
        _add_box_mesh(root, Vector3(0.58, 0.7, 0.45), stone_pos, Color("77736d"))
    _add_cylinder_mesh(root, 0.22, 0.28, 3.0, Vector3(-1.45, 1.5, 0), Color("5d3e28"))
    _add_cylinder_mesh(root, 0.22, 0.28, 3.0, Vector3(1.45, 1.5, 0), Color("5d3e28"))
    _add_box_mesh(root, Vector3(3.4, 0.25, 0.25), Vector3(0, 2.9, 0), Color("5d3e28"))

func _make_lantern(pos: Vector3) -> void:
    var root := Node3D.new()
    root.position = pos
    add_child(root)
    _add_cylinder_mesh(root, 0.09, 0.12, 2.6, Vector3(0, 1.3, 0), Color("4a3526"))
    var lamp := MeshInstance3D.new()
    var sphere := SphereMesh.new()
    sphere.radius = 0.18
    sphere.height = 0.36
    lamp.mesh = sphere
    lamp.position = Vector3(0, 2.45, 0)
    var mat := _material(Color("ffd86a"), 0.45)
    mat.emission_enabled = true
    mat.emission = Color("ffb84a")
    mat.emission_energy_multiplier = 1.7
    lamp.material_override = mat
    root.add_child(lamp)

func _make_fence_post(pos: Vector3) -> void:
    _add_box_mesh(self, Vector3(0.18, 1.25, 0.18), pos + Vector3(0, 0.62, 0), Color("5b412d"))

func _make_crate(pos: Vector3, scale_factor: float) -> void:
    var crate := StaticBody3D.new()
    crate.position = pos
    crate.scale = Vector3.ONE * scale_factor
    add_child(crate)
    _add_box_mesh(crate, Vector3(1.1, 1.1, 1.1), Vector3(0, 0.55, 0), Color("7b5735"))
    _add_box_mesh(crate, Vector3(1.18, 0.10, 1.18), Vector3(0, 0.22, 0), Color("4f3525"))
    _add_box_mesh(crate, Vector3(1.18, 0.10, 1.18), Vector3(0, 0.88, 0), Color("4f3525"))
    var collision := CollisionShape3D.new()
    var box := BoxShape3D.new()
    box.size = Vector3(1.1, 1.1, 1.1)
    collision.shape = box
    collision.position.y = 0.55
    crate.add_child(collision)

func _build_forest_and_ruins() -> void:
    var positions := [
        Vector3(-26,0,-4),Vector3(-31,0,-11),Vector3(-27,0,-20),Vector3(27,0,-5),Vector3(31,0,-16),Vector3(25,0,-25),
        Vector3(-35,0,13),Vector3(36,0,14),Vector3(-22,0,29),Vector3(23,0,31),Vector3(-39,0,-34),Vector3(40,0,-36),
        Vector3(-32,0,-45),Vector3(-23,0,-51),Vector3(31,0,-50),Vector3(43,0,-25),Vector3(-44,0,-20),Vector3(45,0,4),
        Vector3(-30,0,-61),Vector3(-38,0,-69),Vector3(34,0,-61),Vector3(42,0,-72),Vector3(-48,0,-53),Vector3(49,0,-56)
    ]
    for i in range(positions.size()):
        _make_tree(positions[i], 0.82 + randf() * 0.42, i % 3 == 0)
    for rock_pos in [Vector3(-18,0,-39),Vector3(18,0,-36),Vector3(-27,0,-57),Vector3(23,0,-59),Vector3(32,0,-73),Vector3(-31,0,-76)]:
        _make_rock(rock_pos, 0.8 + randf() * 0.8)
    _make_ruin(Vector3(-19.0, 0.0, -65.0))

func _make_tree(pos: Vector3, scale_factor: float, pine: bool) -> void:
    var tree := Node3D.new()
    tree.position = pos
    tree.scale = Vector3.ONE * scale_factor
    add_child(tree)
    _add_cylinder_mesh(tree, 0.28, 0.46, 4.1, Vector3(0, 2.05, 0), Color("5b3d28"))
    if pine:
        for j in range(3):
            var crown := MeshInstance3D.new()
            var cone := CylinderMesh.new()
            cone.top_radius = 0.0
            cone.bottom_radius = 2.15 - j * 0.35
            cone.height = 2.8
            cone.radial_segments = 8
            crown.mesh = cone
            crown.position.y = 4.4 + j * 1.25
            crown.material_override = _material(Color("2e6a3c").lerp(Color("3f7a43"), j * 0.18), 1.0)
            tree.add_child(crown)
    else:
        for crown_data in [[Vector3(-0.7,4.8,0),1.7],[Vector3(0.8,5.0,0.2),1.55],[Vector3(0,6.0,0),1.8]]:
            var crown := MeshInstance3D.new()
            var sphere := SphereMesh.new()
            sphere.radius = 1.0
            sphere.height = 2.0
            sphere.radial_segments = 10
            sphere.rings = 5
            crown.mesh = sphere
            crown.position = crown_data[0]
            crown.scale = Vector3.ONE * float(crown_data[1])
            crown.material_override = _material(Color("34733f"), 1.0)
            tree.add_child(crown)

func _make_rock(pos: Vector3, s: float) -> void:
    var rock := MeshInstance3D.new()
    var sphere := SphereMesh.new()
    sphere.radius = 1.0
    sphere.height = 1.5
    sphere.radial_segments = 7
    sphere.rings = 4
    rock.mesh = sphere
    rock.position = pos + Vector3(0, 0.55 * s, 0)
    rock.scale = Vector3(1.2 * s, 0.7 * s, s)
    rock.rotation_degrees.y = randf_range(0, 180)
    rock.material_override = _material(Color("686c67"), 1.0)
    add_child(rock)

func _make_ruin(pos: Vector3) -> void:
    var root := Node3D.new()
    root.position = pos
    root.rotation_degrees.y = -18
    add_child(root)
    _add_box_mesh(root, Vector3(0.9, 3.8, 0.9), Vector3(-2.1, 1.9, 0), Color("777b73"))
    _add_box_mesh(root, Vector3(0.9, 2.7, 0.9), Vector3(2.1, 1.35, 0), Color("72766f"))
    _add_box_mesh(root, Vector3(5.0, 0.65, 0.8), Vector3(0, 3.5, 0), Color("6b7069"))

func _scatter_world_detail() -> void:
    # Cheap MultiMesh ground detail: much denser world without hundreds of nodes.
    var grass_positions: Array[Vector3] = []
    var flower_positions: Array[Vector3] = []
    var rng := RandomNumberGenerator.new()
    rng.seed = 4042026
    for i in range(260):
        var x := rng.randf_range(-47.0,47.0)
        var z := rng.randf_range(-72.0,34.0)
        if absf(x) < 7.0 and z > -62.0:
            continue
        if x > 8.0 and z < -68.0:
            continue
        grass_positions.append(Vector3(x,0.18,z))
        if i % 11 == 0:
            flower_positions.append(Vector3(x+0.35,0.22,z-0.25))
    _make_multimesh_detail(grass_positions,Vector3(0.06,0.42,0.06),Color("4f9a45"))
    _make_multimesh_detail(flower_positions,Vector3(0.08,0.30,0.08),Color("e3d36e"))

func _make_multimesh_detail(positions: Array[Vector3], mesh_size: Vector3, color: Color) -> void:
    if positions.is_empty():
        return
    var mesh := BoxMesh.new()
    mesh.size = mesh_size
    var mm := MultiMesh.new()
    mm.transform_format = MultiMesh.TRANSFORM_3D
    mm.instance_count = positions.size()
    mm.mesh = mesh
    for i in range(positions.size()):
        var angle := float((i * 37) % 360) * PI / 180.0
        mm.set_instance_transform(i,Transform3D(Basis(Vector3.UP,angle),positions[i]))
    var inst := MultiMeshInstance3D.new()
    inst.multimesh = mm
    inst.material_override = _material(color,1.0)
    add_child(inst)

func _build_bandit_camp_and_mine() -> void:
    var camp := Node3D.new()
    camp.position = Vector3(17.0, 0.0, -78.0)
    add_child(camp)
    _make_tent(camp, Vector3(0,0,0), Color("6d3d32"))
    _make_tent(camp, Vector3(7,0,-4), Color("5c4734"))
    _make_campfire(camp, Vector3(3.5,0,-1.5))
    _make_crate(Vector3(20.5,0,-81.5),0.75)
    _make_crate(Vector3(22.0,0,-82.0),0.65)

    var mine := Node3D.new()
    mine.position = Vector3(-17.0, 0.0, -80.0)
    add_child(mine)
    _add_box_mesh(mine, Vector3(11.0, 5.8, 3.0), Vector3(0,2.9,1.2), Color("5b5c58"))
    _add_box_mesh(mine, Vector3(5.4, 4.2, 0.35), Vector3(0,2.1,-0.38), Color("111419"), 1.0)
    for x in [-2.9, 2.9]:
        _add_box_mesh(mine, Vector3(0.55, 4.8, 0.55), Vector3(x,2.4,-0.7), Color("4e3423"))
    _add_box_mesh(mine, Vector3(6.4, 0.6, 0.6), Vector3(0,4.65,-0.7), Color("4e3423"))
    var mine_label := Label3D.new()
    mine_label.text = "ALTE MINE"
    mine_label.position = Vector3(0, 5.5, -0.8)
    mine_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
    mine_label.font_size = 30
    mine_label.outline_size = 8
    mine_label.modulate = Color("d6c198")
    mine.add_child(mine_label)

func _build_mine_zone() -> void:
    # Kapitel-II-Zone liegt weit außerhalb der Oberwelt und wird über den Mineneingang betreten.
    var mine_root := Node3D.new()
    mine_root.name = "OldMineInterior"
    add_child(mine_root)

    _make_static_block(Vector3(220.0,-0.5,0.0),Vector3(82.0,1.0,72.0),Color("282b2e"))
    _make_static_block(Vector3(179.0,4.0,0.0),Vector3(2.0,9.0,72.0),Color("343638"))
    _make_static_block(Vector3(261.0,4.0,0.0),Vector3(2.0,9.0,72.0),Color("343638"))
    _make_static_block(Vector3(220.0,4.0,-36.0),Vector3(84.0,9.0,2.0),Color("303235"))
    _make_static_block(Vector3(220.0,8.5,0.0),Vector3(84.0,1.0,72.0),Color("202225"))

    # Felsinseln und Kristalle brechen den langen Tunnel auf.
    for rock_data in [
        [Vector3(190,0,-4),3.0],[Vector3(249,0,-8),2.6],[Vector3(198,0,-24),2.2],
        [Vector3(241,0,-27),3.2],[Vector3(208,0,15),2.0],[Vector3(235,0,12),2.4]
    ]:
        _make_rock(rock_data[0],rock_data[1])

    for crystal_pos in [Vector3(187,0.4,10),Vector3(252,0.4,8),Vector3(204,0.4,-17),Vector3(238,0.4,-20),Vector3(218,0.4,-31)]:
        var crystal := MeshInstance3D.new()
        var mesh := PrismMesh.new()
        mesh.size = Vector3(0.8,2.5,0.8)
        crystal.mesh = mesh
        crystal.position = crystal_pos
        crystal.rotation_degrees = Vector3(0,randf_range(0,180),randf_range(-8,8))
        var mat := _material(Color("4d8fac"),0.34)
        mat.emission_enabled = true
        mat.emission = Color("2b6e91")
        mat.emission_energy_multiplier = 1.5
        crystal.material_override = mat
        mine_root.add_child(crystal)

    for light_pos in [Vector3(205,4,20),Vector3(236,4,1),Vector3(213,4,-24)]:
        var light := OmniLight3D.new()
        light.position = light_pos
        light.light_color = Color("ffb45f")
        light.light_energy = 2.0
        light.omni_range = 14.0
        light.shadow_enabled = false
        mine_root.add_child(light)

    var exit_label := Label3D.new()
    exit_label.text = "AUSGANG · RAVENFALL"
    exit_label.position = MINE_EXIT + Vector3(0,3.0,-1.0)
    exit_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
    exit_label.font_size = 26
    exit_label.outline_size = 7
    exit_label.modulate = Color("f0d18a")
    add_child(exit_label)

    var boss_label := Label3D.new()
    boss_label.text = "KRISTALLKAMMER"
    boss_label.position = Vector3(220,4.5,-32)
    boss_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
    boss_label.font_size = 28
    boss_label.outline_size = 8
    boss_label.modulate = Color("8ed8ff")
    add_child(boss_label)

func _make_static_block(pos: Vector3, size_value: Vector3, color: Color) -> void:
    var body := StaticBody3D.new()
    body.position = pos
    add_child(body)
    _add_box_mesh(body,size_value,Vector3.ZERO,color,0.98)
    var collision := CollisionShape3D.new()
    var shape := BoxShape3D.new()
    shape.size = size_value
    collision.shape = shape
    body.add_child(collision)

func _make_tent(parent: Node3D, pos: Vector3, color: Color) -> void:
    var tent := MeshInstance3D.new()
    var prism := PrismMesh.new()
    prism.size = Vector3(4.8, 3.0, 5.0)
    tent.mesh = prism
    tent.position = pos + Vector3(0,1.5,0)
    tent.rotation_degrees.y = 90.0
    tent.material_override = _material(color, 1.0)
    parent.add_child(tent)

func _make_campfire(parent: Node3D, pos: Vector3) -> void:
    for i in range(8):
        var angle := TAU * i / 8.0
        var stone := MeshInstance3D.new()
        var mesh := SphereMesh.new()
        mesh.radius = 0.24
        mesh.height = 0.35
        mesh.radial_segments = 6
        mesh.rings = 3
        stone.mesh = mesh
        stone.position = pos + Vector3(cos(angle)*0.75,0.18,sin(angle)*0.75)
        stone.material_override = _material(Color("67635e"),1.0)
        parent.add_child(stone)
    var flame := MeshInstance3D.new()
    var cone := CylinderMesh.new()
    cone.top_radius = 0.0
    cone.bottom_radius = 0.36
    cone.height = 1.1
    cone.radial_segments = 8
    flame.mesh = cone
    flame.position = pos + Vector3(0,0.55,0)
    var fire_mat := _material(Color("ff8b36"),0.35)
    fire_mat.emission_enabled = true
    fire_mat.emission = Color("ff6b24")
    fire_mat.emission_energy_multiplier = 2.2
    flame.material_override = fire_mat
    parent.add_child(flame)

func _build_npc() -> void:
    quest_npc = Node3D.new()
    quest_npc.name = "HauptmannArlen"
    quest_npc.position = Vector3(-2.7, 0.0, -12.0)
    quest_npc.rotation_degrees.y = 180.0
    add_child(quest_npc)
    _make_npc_model(quest_npc)
    quest_label = Label3D.new()
    quest_label.position = Vector3(0, 3.1, 0)
    quest_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
    quest_label.font_size = 27
    quest_label.outline_size = 7
    quest_npc.add_child(quest_label)
    _update_quest_marker()

func _make_npc_model(parent: Node3D) -> void:
    _add_cylinder_mesh(parent, 0.36, 0.46, 0.95, Vector3(0,1.35,0), Color("9a5f31"))
    _add_sphere_mesh(parent, Vector3(0.34,0.38,0.34), Vector3(0,2.08,0), Color("d2a47e"))
    _add_sphere_mesh(parent, Vector3(0.39,0.20,0.39), Vector3(0,2.27,0), Color("49342a"))
    for x in [-0.56,0.56]:
        _add_cylinder_mesh(parent,0.13,0.15,0.82,Vector3(x,1.38,0),Color("c5914a"))
    for x in [-0.22,0.22]:
        _add_cylinder_mesh(parent,0.14,0.16,0.85,Vector3(x,0.48,0),Color("45484c"))
    for x in [-0.54,0.54]:
        _add_sphere_mesh(parent,Vector3(0.24,0.18,0.28),Vector3(x,1.76,0),Color("745028"))
    _add_box_mesh(parent,Vector3(0.10,1.1,0.09),Vector3(0.72,0.95,-0.08),Color("c4cbd1"),0.4)

func _spawn_player() -> void:
    player = CharacterBody3D.new()
    player.name = "Player"
    player.position = Vector3(0.0, 0.02, 9.0)
    player.set_script(load("res://scripts/player.gd"))
    player.set("game_ref", self)
    add_child(player)

func _build_wolves() -> void:
    var spawn_positions := [
        Vector3(7.0,0.02,-39.0),Vector3(13.0,0.02,-46.0),Vector3(-8.0,0.02,-42.0),
        Vector3(21.0,0.02,-53.0),Vector3(-18.0,0.02,-50.0),Vector3(-4.0,0.02,-57.0)
    ]
    for i in range(spawn_positions.size()):
        var wolf := CharacterBody3D.new()
        wolf.name = "Wolf_%d" % (i + 1)
        wolf.position = spawn_positions[i]
        wolf.set_script(load("res://scripts/wolf.gd"))
        add_child(wolf)
        wolf.configure(player, self, spawn_positions[i])
        wolves.append(wolf)
        enemies.append(wolf)

func _build_bandits() -> void:
    var spawn_positions := [
        Vector3(14.0,0.02,-73.0),Vector3(21.0,0.02,-76.0),Vector3(25.0,0.02,-84.0),Vector3(13.0,0.02,-86.0)
    ]
    for i in range(spawn_positions.size()):
        var bandit := CharacterBody3D.new()
        bandit.name = "Bandit_%d" % (i + 1)
        bandit.position = spawn_positions[i]
        bandit.set_script(load("res://scripts/bandit.gd"))
        add_child(bandit)
        bandit.configure(player, self, spawn_positions[i])
        bandits.append(bandit)
        enemies.append(bandit)

func _build_captain() -> void:
    captain = CharacterBody3D.new()
    captain.name = "Banditenhauptmann"
    captain.position = Vector3(19.0,0.02,-91.0)
    captain.set_script(load("res://scripts/captain.gd"))
    add_child(captain)
    captain.configure(player,self,captain.position)
    enemies.append(captain)

func _build_mine_enemies() -> void:
    var spider_spawns := [
        Vector3(193,0.02,19),Vector3(204,0.02,8),Vector3(238,0.02,14),
        Vector3(248,0.02,-2),Vector3(199,0.02,-15),Vector3(233,0.02,-18),Vector3(211,0.02,-25)
    ]
    for i in range(spider_spawns.size()):
        var spider := CharacterBody3D.new()
        spider.name = "CaveSpider_%d" % (i+1)
        spider.position = spider_spawns[i]
        spider.set_script(load("res://scripts/spider.gd"))
        add_child(spider)
        spider.configure(player,self,spider_spawns[i])
        spiders.append(spider)
        enemies.append(spider)

    mine_boss = CharacterBody3D.new()
    mine_boss.name = "Kristallwaechter"
    mine_boss.position = Vector3(220,0.02,-30)
    mine_boss.set_script(load("res://scripts/mine_boss.gd"))
    add_child(mine_boss)
    mine_boss.configure(player,self,mine_boss.position)
    enemies.append(mine_boss)

func _build_hud() -> void:
    var canvas := CanvasLayer.new()
    canvas.name = "HUD"
    canvas.layer = 20
    add_child(canvas)
    hud = Control.new()
    hud.name = "HUDRoot"
    hud.set_script(load("res://scripts/hud.gd"))
    hud.position = Vector2.ZERO
    hud.size = get_viewport().get_visible_rect().size
    hud.mouse_filter = Control.MOUSE_FILTER_IGNORE
    hud.visible = true
    hud.process_mode = Node.PROCESS_MODE_ALWAYS
    hud.set("player", player)
    hud.set("game", self)
    canvas.add_child(hud)

func try_select_from_screen(camera: Camera3D, screen_pos: Vector2) -> bool:
    if camera == null:
        return false
    var origin := camera.project_ray_origin(screen_pos)
    var direction := camera.project_ray_normal(screen_pos)
    var query := PhysicsRayQueryParameters3D.create(origin, origin + direction * 130.0)
    query.collide_with_areas = true
    query.collide_with_bodies = true
    var result := get_world_3d().direct_space_state.intersect_ray(query)
    if result.is_empty():
        return false
    var collider = result.get("collider")
    if collider != null and collider.is_in_group("enemies") and collider.is_alive_enemy():
        select_target(collider)
        return true
    return false

func select_target(target: Node) -> void:
    if current_target != null and is_instance_valid(current_target):
        current_target.set_targeted(false)
    current_target = target
    if current_target != null and is_instance_valid(current_target):
        current_target.set_targeted(true)

func perform_player_attack() -> void:
    if not _can_attack() or attack_cooldown > 0.0:
        return
    var target := _get_attack_target(7.5)
    if target == null:
        show_toast("Kein Gegner in Reichweite", 1.2)
        return
    if player.global_position.distance_to(target.global_position) > 5.8:
        var closer := _nearest_alive_enemy(5.8)
        if closer != null:
            target = closer
            select_target(target)
        else:
            show_toast("Ziel ist zu weit entfernt", 1.1)
            return
    attack_cooldown = 0.66
    player.face_world_position(target.global_position)
    player.play_attack(false)
    var damage := randi_range(17, 23) + get_weapon_power()
    var critical := randf() < 0.16
    if critical:
        damage = int(round(damage * 1.8))
    rage = mini(max_rage, rage + 12)
    target.take_damage(damage, critical)

func perform_skill_1() -> void:
    if not _can_attack() or skill1_cd > 0.0:
        return
    if rage < 20:
        show_toast("Nicht genug Wut", 1.0)
        return
    var target := _get_attack_target(6.0)
    if target == null or player.global_position.distance_to(target.global_position) > 5.0:
        show_toast("Kraftschlag: kein Ziel in Reichweite", 1.1)
        return
    rage -= 20
    skill1_cd = 4.0
    player.face_world_position(target.global_position)
    player.play_attack(true)
    var damage := randi_range(35, 43) + get_weapon_power() * 2
    var critical := randf() < 0.20
    if critical:
        damage = int(round(damage * 1.75))
    target.take_damage(damage, critical)
    show_toast("KRAFTSCHLAG", 0.65)

func perform_skill_2() -> void:
    if not _can_attack() or skill2_cd > 0.0:
        return
    if rage < 35:
        show_toast("Nicht genug Wut", 1.0)
        return
    var hit_any := false
    rage -= 35
    skill2_cd = 7.0
    player.play_spin_attack()
    for enemy in enemies:
        if enemy != null and is_instance_valid(enemy) and enemy.is_alive_enemy():
            if player.global_position.distance_to(enemy.global_position) <= 5.0:
                hit_any = true
                enemy.take_damage(randi_range(24, 31) + get_weapon_power(), false)
    if not hit_any:
        rage = mini(max_rage, rage + 20)
        show_toast("Wirbelwind trifft niemanden", 1.0)
    else:
        show_toast("WIRBELWIND", 0.7)

func use_potion() -> void:
    if player == null or player.dead or quest_panel_open or inventory_open:
        return
    if potion_cd > 0.0:
        show_toast("Heiltrank bereit in %.1fs" % potion_cd,1.0)
        return
    if potions <= 0:
        show_toast("Keine Heiltränke mehr",1.2)
        return
    if player.health >= player.max_health:
        show_toast("Lebenspunkte bereits voll",1.0)
        return
    var heal_amount := maxi(25,int(round(float(player.max_health)*0.45)))
    player.heal(heal_amount)
    potions -= 1
    potion_cd = 14.0
    show_toast("Heiltrank · +%d LP" % heal_amount,1.4)
    save_game()

func _can_attack() -> bool:
    return player != null and not player.dead and not quest_panel_open and not inventory_open

func _get_attack_target(max_distance: float) -> Node:
    var target := current_target
    if target != null and is_instance_valid(target) and target.is_alive_enemy():
        return target
    target = _nearest_alive_enemy(max_distance)
    if target != null:
        select_target(target)
    return target

func _nearest_alive_enemy(max_distance: float) -> Node:
    var best: Node = null
    var best_dist := max_distance
    for enemy in enemies:
        if enemy == null or not is_instance_valid(enemy) or not enemy.is_alive_enemy():
            continue
        var dist := player.global_position.distance_to(enemy.global_position)
        if dist < best_dist:
            best_dist = dist
            best = enemy
    return best

func try_interact() -> void:
    if player == null:
        return
    if player.global_position.distance_to(MINE_EXIT) <= 5.0:
        player.global_position = SURFACE_MINE_ENTRANCE + Vector3(0,0.05,6.0)
        player.cancel_touches()
        select_target(null)
        show_toast("Ravenfall · Alte Mine verlassen",2.0)
        save_game()
        return
    if player.global_position.distance_to(SURFACE_MINE_ENTRANCE) <= 5.5:
        if quest_id < QUEST_MINE_SPIDERS:
            show_toast("Die Alte Mine ist noch versiegelt",1.6)
            return
        player.global_position = MINE_EXIT + Vector3(0,0.05,-5.0)
        player.cancel_touches()
        select_target(null)
        show_toast("ALTE MINE · Kapitel II",2.2)
        save_game()
        return
    if quest_npc == null or player.global_position.distance_to(quest_npc.global_position) > 3.7:
        show_toast("Nichts zum Interagieren in der Nähe",1.2)
        return
    quest_panel_open = true
    inventory_open = false
    player.cancel_touches()

func is_player_near_npc() -> bool:
    return player != null and quest_npc != null and player.global_position.distance_to(quest_npc.global_position) <= 3.7

func is_interaction_available() -> bool:
    if player == null:
        return false
    if is_player_near_npc():
        return true
    if player.global_position.distance_to(MINE_EXIT) <= 5.0:
        return true
    if player.global_position.distance_to(SURFACE_MINE_ENTRANCE) <= 5.5:
        return true
    return false

func get_interact_label() -> String:
    if player == null:
        return "REDEN"
    if player.global_position.distance_to(MINE_EXIT) <= 5.0:
        return "RAUS"
    if player.global_position.distance_to(SURFACE_MINE_ENTRANCE) <= 5.5:
        return "MINE"
    return "REDEN"

func get_current_zone_name() -> String:
    if player != null and player.global_position.x > 150.0:
        return "Alte Mine"
    return "Ravenfall"

func get_objective_distance_text() -> String:
    if player == null:
        return ""
    var target_pos := quest_npc.global_position if quest_npc != null else Vector3.ZERO
    if quest_stage == 1 and quest_id in [QUEST_WOLVES,QUEST_BANDITS,QUEST_CAPTAIN]:
        if quest_id == QUEST_WOLVES:
            target_pos = Vector3(5,0,-45)
        elif quest_id == QUEST_BANDITS:
            target_pos = Vector3(18,0,-80)
        else:
            target_pos = Vector3(19,0,-91)
    elif quest_stage == 1 and quest_id in [QUEST_MINE_SPIDERS,QUEST_MINE_BOSS]:
        if player.global_position.x < 150.0:
            target_pos = SURFACE_MINE_ENTRANCE
        elif quest_id == QUEST_MINE_SPIDERS:
            target_pos = Vector3(220,0,-8)
        else:
            target_pos = Vector3(220,0,-30)
    var d := int(round(player.global_position.distance_to(target_pos)))
    return "%dm" % d

func toggle_inventory() -> void:
    inventory_open = not inventory_open
    quest_panel_open = false
    if player != null:
        player.cancel_touches()

func handle_quest_panel_touch(pos: Vector2) -> void:
    if not quest_panel_open:
        return
    if get_quest_close_rect().has_point(pos):
        quest_panel_open = false
        return
    if not get_quest_button_rect().has_point(pos):
        return
    if quest_stage == 0:
        quest_stage = 1
        quest_progress = 0
        quest_panel_open = false
        show_toast("Quest angenommen: %s" % get_quest_title(), 2.3)
    elif quest_stage == 2:
        _turn_in_current_quest()
    else:
        quest_panel_open = false

func _turn_in_current_quest() -> void:
    if quest_id == QUEST_WOLVES:
        gold += 28
        _add_xp(55)
        add_item({"name":"Eisenklinge von Ravenfall", "power":4, "rarity":"Ungewöhnlich", "type":"Waffe"}, true)
        quest_id = QUEST_BANDITS
    elif quest_id == QUEST_BANDITS:
        gold += 55
        _add_xp(90)
        add_item({"name":"Wächterklinge", "power":8, "rarity":"Selten", "type":"Waffe"}, true)
        quest_id = QUEST_CAPTAIN
    elif quest_id == QUEST_CAPTAIN:
        gold += 95
        _add_xp(145)
        add_item({"name":"Klinge des Grenzwächters", "power":13, "rarity":"Episch", "type":"Waffe"}, true)
        potions += 2
        quest_id = QUEST_MINE_SPIDERS
        show_toast("KAPITEL II FREIGESCHALTET · Die Alte Mine",3.0)
    elif quest_id == QUEST_MINE_SPIDERS:
        gold += 120
        _add_xp(180)
        add_item({"name":"Minenwächter-Brustpanzer", "armor":6, "rarity":"Selten", "type":"Rüstung"}, true)
        potions += 2
        quest_id = QUEST_MINE_BOSS
    elif quest_id == QUEST_MINE_BOSS:
        gold += 220
        _add_xp(300)
        add_item({"name":"Kristallherz von Eldoria", "power":6, "rarity":"Episch", "type":"Schmuck"}, true)
        add_item({"name":"Kristallschneide", "power":19, "rarity":"Episch", "type":"Waffe"}, true)
        quest_id = QUEST_DONE
        quest_stage = 3
        quest_progress = 0
        quest_panel_open = false
        save_game()
        show_toast("KAPITEL II ABGESCHLOSSEN · Die Mine ist gereinigt",3.4)
        return
    quest_stage = 0
    quest_progress = 0
    quest_panel_open = false
    save_game()
    show_toast("Auftrag erfüllt · neuer Auftrag verfügbar",2.6)

func get_quest_panel_rect() -> Rect2:
    var screen := get_viewport().get_visible_rect().size
    var width := minf(720.0, screen.x * 0.76)
    var height := minf(400.0, screen.y * 0.72)
    return Rect2(Vector2((screen.x-width)*0.5,(screen.y-height)*0.5),Vector2(width,height))

func get_quest_button_rect() -> Rect2:
    var panel := get_quest_panel_rect()
    return Rect2(Vector2(panel.position.x+38.0,panel.end.y-78.0),Vector2(panel.size.x-76.0,50.0))

func get_quest_close_rect() -> Rect2:
    var panel := get_quest_panel_rect()
    return Rect2(Vector2(panel.end.x-56.0,panel.position.y+14.0),Vector2(40.0,40.0))

func get_inventory_panel_rect() -> Rect2:
    var screen := get_viewport().get_visible_rect().size
    var width := minf(780.0, screen.x * 0.82)
    var height := minf(520.0, screen.y * 0.80)
    return Rect2(Vector2((screen.x-width)*0.5,(screen.y-height)*0.5),Vector2(width,height))

func get_inventory_button_rect() -> Rect2:
    var screen := get_viewport().get_visible_rect().size
    var scale := clampf(screen.y / 720.0, 0.85, 1.55)
    return Rect2(Vector2(24.0*scale,132.0*scale),Vector2(112.0*scale,40.0*scale))

func get_inventory_close_rect() -> Rect2:
    var panel := get_inventory_panel_rect()
    return Rect2(Vector2(panel.end.x-56.0,panel.position.y+14.0),Vector2(40.0,40.0))

func get_inventory_auto_rect() -> Rect2:
    var panel := get_inventory_panel_rect()
    return Rect2(Vector2(panel.position.x+28.0,panel.end.y-70.0),Vector2(panel.size.x-56.0,44.0))

func handle_inventory_touch(pos: Vector2) -> void:
    if not inventory_open:
        return
    if get_inventory_close_rect().has_point(pos):
        inventory_open = false
        return
    if get_inventory_auto_rect().has_point(pos):
        auto_equip_best_weapon()

func get_quest_button_text() -> String:
    if quest_stage == 0:
        return "QUEST ANNEHMEN"
    if quest_stage == 2:
        return "BELOHNUNG ABHOLEN"
    return "SCHLIESSEN"

func get_quest_title() -> String:
    match quest_id:
        QUEST_WOLVES: return "Wölfe vor den Toren"
        QUEST_BANDITS: return "Die Räuber vom Ostlager"
        QUEST_CAPTAIN: return "Der Hauptmann der Räuber"
        QUEST_MINE_SPIDERS: return "Unter Ravenfall"
        QUEST_MINE_BOSS: return "Das Herz der Mine"
        _: return "Ravenfall gesichert"

func get_quest_body_lines() -> PackedStringArray:
    if quest_id == QUEST_WOLVES:
        if quest_stage == 0: return PackedStringArray(["Hauptmann Arlen: Die Wölfe werden dreister.","Besiege 3 Wölfe südlich des Tores.","Belohnung: 55 EP, 28 Gold und eine neue Klinge."])
        if quest_stage == 1: return PackedStringArray(["Halte die Straße nach Süden frei.","Fortschritt: %d / 3 Wölfe" % quest_progress,"Kehre danach zu mir zurück."])
        return PackedStringArray(["Gute Arbeit. Die Straße ist wieder passierbar.","Deine Belohnung wartet."])
    if quest_id == QUEST_BANDITS:
        if quest_stage == 0: return PackedStringArray(["Hinter den Wölfen stecken Räuber.","Besiege 4 Banditen am Lager vor der Alten Mine.","Belohnung: 90 EP, 55 Gold und eine seltene Waffe."])
        if quest_stage == 1: return PackedStringArray(["Folge der Straße zum Ostlager.","Fortschritt: %d / 4 Banditen" % quest_progress,"Zerschlage das Lager."])
        return PackedStringArray(["Das Lager fällt. Ihr Hauptmann steht noch.","Hol dir deine Belohnung."])
    if quest_id == QUEST_CAPTAIN:
        if quest_stage == 0: return PackedStringArray(["Jetzt fehlt nur noch ihr Hauptmann.","Besiege den Banditenhauptmann hinter dem Ostlager.","Danach öffnen wir die Alte Mine."])
        if quest_stage == 1: return PackedStringArray(["Elitegegner im Süden des Lagers.","Banditenhauptmann: %d / 1" % quest_progress,"Bereite dich auf einen härteren Kampf vor."])
        return PackedStringArray(["Der Hauptmann ist gefallen.","Doch unter uns bewegt sich etwas.","Kapitel II wartet in der Alten Mine."])
    if quest_id == QUEST_MINE_SPIDERS:
        if quest_stage == 0: return PackedStringArray(["Arlen: Die Mine ist wieder offen.","Betritt die Alte Mine und besiege 5 Höhlenspinnen.","Tipp: Am Eingang erscheint MINE, wenn du nah genug bist."])
        if quest_stage == 1: return PackedStringArray(["Durchsuche die Alte Mine.","Höhlenspinnen: %d / 5" % quest_progress,"Verlasse die Mine danach über den Ausgang."])
        return PackedStringArray(["Die Nester sind zerstört.","Arlen will wissen, was tiefer in der Mine lauert."])
    if quest_id == QUEST_MINE_BOSS:
        if quest_stage == 0: return PackedStringArray(["Arlen: Ein Kristallwächter blockiert die tiefste Kammer.","Betritt die Mine und besiege den Kristallwächter.","Belohnung: epische Ausrüstung und viel Erfahrung."])
        if quest_stage == 1: return PackedStringArray(["Der Wächter wartet in der Kristallkammer.","Kristallwächter: %d / 1" % quest_progress,"Nutze Heiltränke im Kampf."])
        return PackedStringArray(["Der Kristallwächter ist gefallen.","Die Alte Mine ist wieder sicher.","Kapitel II ist abgeschlossen."])
    return PackedStringArray(["Ravenfall und die Alte Mine sind gesichert.","Weitere Gebiete folgen im nächsten Kapitel."])

func get_quest_tracker_text() -> String:
    if quest_id == QUEST_DONE:
        return "Kapitel II abgeschlossen"
    if quest_stage == 0:
        return "Sprich mit Hauptmann Arlen"
    if quest_stage == 2:
        return "Kehre zu Hauptmann Arlen zurück"
    match quest_id:
        QUEST_WOLVES: return "Wölfe besiegen: %d / 3" % quest_progress
        QUEST_BANDITS: return "Banditen besiegen: %d / 4" % quest_progress
        QUEST_CAPTAIN: return "Banditenhauptmann: %d / 1" % quest_progress
        QUEST_MINE_SPIDERS: return "Höhlenspinnen: %d / 5" % quest_progress
        QUEST_MINE_BOSS: return "Kristallwächter: %d / 1" % quest_progress
    return "Abenteuer fortsetzen"

func on_enemy_defeated(enemy: Node, enemy_type: String) -> void:
    if current_target == enemy:
        select_target(null)
    if enemy_type == "wolf":
        var loot_gold := randi_range(3,8); gold += loot_gold; pelts += 1; _add_xp(20)
        if randf() < 0.10: potions += 1
        if randf() < 0.16: add_item({"name":"Wolfszahn-Anhänger", "power":1, "rarity":"Ungewöhnlich", "type":"Schmuck"}, false)
        if quest_id == QUEST_WOLVES and quest_stage == 1:
            quest_progress = mini(3,quest_progress+1)
            if quest_progress >= 3: quest_stage=2; show_toast("Questziel erreicht · zurück zu Arlen",2.5)
        show_loot("+20 EP · +%d Gold · Wolfspelz" % loot_gold)
    elif enemy_type == "bandit":
        var loot_gold := randi_range(7,14); gold += loot_gold; _add_xp(32)
        if randf() < 0.14: potions += 1
        if randf() < 0.22: add_item({"name":"Banditenring", "power":2, "rarity":"Ungewöhnlich", "type":"Schmuck"}, false)
        if quest_id == QUEST_BANDITS and quest_stage == 1:
            quest_progress = mini(4,quest_progress+1)
            if quest_progress >= 4: quest_stage=2; show_toast("Banditenlager gebrochen · zurück zu Arlen",2.7)
        show_loot("+32 EP · +%d Gold · Beute" % loot_gold)
    elif enemy_type == "captain":
        var loot_gold := randi_range(18,28); gold += loot_gold; _add_xp(65); potions += 1
        add_item({"name":"Siegelring des Hauptmanns", "power":3, "rarity":"Selten", "type":"Schmuck"}, false)
        if quest_id == QUEST_CAPTAIN and quest_stage == 1: quest_progress=1; quest_stage=2; show_toast("ELITE BESIEGT · zurück zu Arlen",2.8)
        show_loot("+65 EP · +%d Gold · Elitebeute" % loot_gold)
    elif enemy_type == "spider":
        var loot_gold := randi_range(8,16); gold += loot_gold; _add_xp(42)
        if randf() < 0.24: potions += 1
        if randf() < 0.18: add_item({"name":"Chitinpanzer", "armor":3, "rarity":"Ungewöhnlich", "type":"Rüstung"}, false)
        if quest_id == QUEST_MINE_SPIDERS and quest_stage == 1:
            quest_progress = mini(5,quest_progress+1)
            if quest_progress >= 5: quest_stage=2; show_toast("Spinnennester zerstört · zurück zu Arlen",2.8)
        show_loot("+42 EP · +%d Gold · Chitin" % loot_gold)
    elif enemy_type == "mine_boss":
        var loot_gold := randi_range(45,70); gold += loot_gold; _add_xp(120); potions += 2
        add_item({"name":"Kristallsplitter-Talisman", "power":4, "rarity":"Selten", "type":"Schmuck"}, true)
        if quest_id == QUEST_MINE_BOSS and quest_stage == 1: quest_progress=1; quest_stage=2; show_toast("BOSS BESIEGT · zurück zu Arlen",3.0)
        show_loot("+120 EP · +%d Gold · Bossbeute" % loot_gold)
    save_game()

func add_item(item: Dictionary, auto_equip: bool = false) -> void:
    inventory.append(item.duplicate(true))
    loot_text = "%s gefunden" % item.get("name","Gegenstand")
    loot_time = 2.2
    if auto_equip:
        _equip_if_better(item)

func _equip_if_better(item: Dictionary) -> void:
    var item_type := String(item.get("type",""))
    if item_type == "Waffe" and int(item.get("power",0)) > int(equipped_weapon.get("power",0)):
        equipped_weapon = item.duplicate(true)
        show_toast("Neue Waffe: %s" % equipped_weapon.get("name","Waffe"),1.8)
    elif item_type == "Rüstung" and int(item.get("armor",0)) > int(equipped_armor.get("armor",0)):
        equipped_armor = item.duplicate(true)
        show_toast("Neue Rüstung: %s" % equipped_armor.get("name","Rüstung"),1.8)
    elif item_type == "Schmuck" and int(item.get("power",0)) > int(equipped_charm.get("power",0)):
        equipped_charm = item.duplicate(true)
        show_toast("Neuer Talisman: %s" % equipped_charm.get("name","Schmuck"),1.8)

func auto_equip_best_weapon() -> void:
    auto_equip_best_gear()

func auto_equip_best_gear() -> void:
    for item in inventory:
        _equip_if_better(item)
    show_toast("Beste Ausrüstung angelegt",1.5)
    save_game()

func get_weapon_power() -> int:
    return int(equipped_weapon.get("power",0)) + int(equipped_charm.get("power",0))

func get_armor_value() -> int:
    return int(equipped_armor.get("armor",0))

func _add_xp(amount: int) -> void:
    xp += amount
    var needed := get_xp_required()
    while xp >= needed:
        xp -= needed
        level += 1
        needed = get_xp_required()
        if player != null:
            player.set_max_health(100 + (level - 1) * 14, true)
        show_toast("STUFE %d ERREICHT" % level, 2.4)

func get_xp_required() -> int:
    return 100 + (level - 1) * 55

func show_toast(text: String, duration: float = 2.0) -> void:
    toast_text = text
    toast_time = duration

func show_loot(text: String) -> void:
    loot_text = text
    loot_time = 2.1

func spawn_damage_number(world_pos: Vector3, amount: int, critical: bool = false, friendly_damage: bool = false) -> void:
    var label := Label3D.new()
    label.text = ("KRIT %d" % amount) if critical else str(amount)
    label.global_position = world_pos
    label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
    label.font_size = 30 if critical else 24
    label.outline_size = 7
    label.modulate = Color("ffd45c") if critical else (Color("ff6a5f") if friendly_damage else Color.WHITE)
    add_child(label)
    var tween := create_tween()
    tween.set_parallel(true)
    tween.tween_property(label, "position", label.position + Vector3(0,1.25,0), 0.75).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
    tween.tween_property(label, "modulate:a", 0.0, 0.75)
    tween.set_parallel(false)
    tween.tween_callback(label.queue_free)

func save_game() -> void:
    if player == null:
        return
    var data := {
        "version":5,
        "level":level,"xp":xp,"gold":gold,"pelts":pelts,"rage":rage,"potions":potions,
        "quest_id":quest_id,"quest_stage":quest_stage,"quest_progress":quest_progress,
        "inventory":inventory,"equipped_weapon":equipped_weapon,"equipped_armor":equipped_armor,"equipped_charm":equipped_charm,
        "player_pos":[player.global_position.x,player.global_position.y,player.global_position.z]
    }
    var file := FileAccess.open("user://eldoria_save_v05.json",FileAccess.WRITE)
    if file != null:
        file.store_string(JSON.stringify(data))

func _load_game() -> void:
    var save_path := "user://eldoria_save_v05.json"
    if not FileAccess.file_exists(save_path):
        if FileAccess.file_exists("user://eldoria_save_v04.json"):
            save_path = "user://eldoria_save_v04.json"
        else:
            return
    var file := FileAccess.open(save_path,FileAccess.READ)
    if file == null:
        return
    var parsed = JSON.parse_string(file.get_as_text())
    if typeof(parsed) != TYPE_DICTIONARY:
        return
    var save_version := int(parsed.get("version",4))
    level = int(parsed.get("level",1)); xp = int(parsed.get("xp",0)); gold = int(parsed.get("gold",0)); pelts = int(parsed.get("pelts",0)); rage = int(parsed.get("rage",0)); potions = int(parsed.get("potions",3))
    quest_id = int(parsed.get("quest_id",QUEST_WOLVES)); quest_stage = int(parsed.get("quest_stage",0)); quest_progress = int(parsed.get("quest_progress",0))
    if save_version < 5 and quest_id == 3 and quest_stage == 3:
        quest_id = QUEST_MINE_SPIDERS; quest_stage = 0; quest_progress = 0
    var inv = parsed.get("inventory",[]); inventory.clear()
    if inv is Array:
        for entry in inv:
            if entry is Dictionary: inventory.append(entry)
    var weapon = parsed.get("equipped_weapon",equipped_weapon)
    if weapon is Dictionary: equipped_weapon = weapon
    var armor = parsed.get("equipped_armor",equipped_armor)
    if armor is Dictionary: equipped_armor = armor
    var charm = parsed.get("equipped_charm",equipped_charm)
    if charm is Dictionary: equipped_charm = charm
    player.set_max_health(100 + (level - 1) * 14,true)
    var pos = parsed.get("player_pos",[])
    if pos is Array and pos.size() == 3:
        var saved_pos := Vector3(float(pos[0]),float(pos[1]),float(pos[2]))
        if saved_pos.length() < 360.0:
            player.global_position = saved_pos
    _update_quest_marker()

func get_rarity_color(rarity: String) -> Color:
    match rarity:
        "Ungewöhnlich": return Color("6fd47b")
        "Selten": return Color("65a8ff")
        "Episch": return Color("b77bff")
        _: return Color("d9dde3")

func _update_quest_marker() -> void:
    if quest_label == null:
        return
    if quest_id == QUEST_DONE:
        quest_label.text = "Hauptmann Arlen"
        quest_label.modulate = Color("d8e0e8")
    elif quest_stage == 0:
        quest_label.text = "!\nHauptmann Arlen"
        quest_label.modulate = Color("ffd45a")
    elif quest_stage == 2:
        quest_label.text = "?\nHauptmann Arlen"
        quest_label.modulate = Color("ffd45a")
    else:
        quest_label.text = "Hauptmann Arlen"
        quest_label.modulate = Color.WHITE

func _add_box_mesh(parent: Node, size: Vector3, pos: Vector3, color: Color, roughness: float = 0.92) -> MeshInstance3D:
    var node := MeshInstance3D.new()
    var mesh := BoxMesh.new()
    mesh.size = size
    node.mesh = mesh
    node.position = pos
    node.material_override = _material(color, roughness)
    parent.add_child(node)
    return node

func _add_cylinder_mesh(parent: Node, top_radius: float, bottom_radius: float, height: float, pos: Vector3, color: Color) -> MeshInstance3D:
    var node := MeshInstance3D.new()
    var mesh := CylinderMesh.new()
    mesh.top_radius = top_radius
    mesh.bottom_radius = bottom_radius
    mesh.height = height
    mesh.radial_segments = 10
    node.mesh = mesh
    node.position = pos
    node.material_override = _material(color, 0.95)
    parent.add_child(node)
    return node

func _add_sphere_mesh(parent: Node, scale_value: Vector3, pos: Vector3, color: Color) -> MeshInstance3D:
    var node := MeshInstance3D.new()
    var mesh := SphereMesh.new()
    mesh.radius = 1.0
    mesh.height = 2.0
    mesh.radial_segments = 12
    mesh.rings = 6
    node.mesh = mesh
    node.scale = scale_value
    node.position = pos
    node.material_override = _material(color, 0.9)
    parent.add_child(node)
    return node

func _material(color: Color, roughness: float) -> StandardMaterial3D:
    var mat := StandardMaterial3D.new()
    mat.albedo_color = color
    mat.roughness = roughness
    return mat
