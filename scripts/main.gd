extends Node3D

const QUEST_GOAL := 3

var player: CharacterBody3D
var hud: Control
var quest_npc: Node3D
var quest_label: Label3D
var wolves: Array[Node] = []
var current_target: Node = null

var quest_stage := 0 # 0=not accepted, 1=active, 2=ready to turn in, 3=finished
var quest_kills := 0
var quest_panel_open := false

var level := 1
var xp := 0
var gold := 0
var pelts := 0

var attack_cooldown := 0.0
var toast_text := ""
var toast_time := 0.0

func _ready() -> void:
    randomize()
    DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
    DisplayServer.screen_set_orientation(DisplayServer.SCREEN_LANDSCAPE)
    _setup_environment()
    _build_ground()
    _build_village()
    _build_forest()
    _build_npc()
    _spawn_player()
    _build_wolves()
    _build_hud()
    show_toast("Willkommen in Ravenfall", 2.8)

func _process(delta: float) -> void:
    attack_cooldown = maxf(0.0, attack_cooldown - delta)
    toast_time = maxf(0.0, toast_time - delta)
    if current_target != null:
        if not is_instance_valid(current_target) or not current_target.is_alive_enemy():
            select_target(null)
    _update_quest_marker()

func _setup_environment() -> void:
    var world_env := WorldEnvironment.new()
    var env := Environment.new()
    env.background_mode = Environment.BG_COLOR
    env.background_color = Color("7fb2d8")
    env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
    env.ambient_light_color = Color("c1d2dd")
    env.ambient_light_energy = 0.72
    env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
    world_env.environment = env
    add_child(world_env)

    var sun := DirectionalLight3D.new()
    sun.rotation_degrees = Vector3(-52.0, -28.0, 0.0)
    sun.light_energy = 1.35
    sun.shadow_enabled = true
    add_child(sun)

func _build_ground() -> void:
    var ground := StaticBody3D.new()
    ground.name = "RavenfallGround"
    add_child(ground)

    var mesh_instance := MeshInstance3D.new()
    var mesh := BoxMesh.new()
    mesh.size = Vector3(150.0, 0.4, 150.0)
    mesh_instance.mesh = mesh
    mesh_instance.position.y = -0.2
    mesh_instance.material_override = _material(Color("5d9147"), 0.95)
    ground.add_child(mesh_instance)

    var shape := CollisionShape3D.new()
    var box := BoxShape3D.new()
    box.size = Vector3(150.0, 0.4, 150.0)
    shape.shape = box
    shape.position.y = -0.2
    ground.add_child(shape)

    _make_road(Vector3(0.0, 0.025, -18.0), Vector3(8.0, 0.05, 72.0))
    _make_road(Vector3(13.0, 0.028, -41.0), Vector3(34.0, 0.055, 5.5))

func _make_road(pos: Vector3, size: Vector3) -> void:
    var road := MeshInstance3D.new()
    var road_mesh := BoxMesh.new()
    road_mesh.size = size
    road.mesh = road_mesh
    road.position = pos
    road.material_override = _material(Color("9c7b55"), 1.0)
    add_child(road)

func _build_village() -> void:
    _make_house(Vector3(-11.0, 0.0, 3.0), Color("80603f"))
    _make_house(Vector3(11.0, 0.0, 2.0), Color("72563d"))
    _make_house(Vector3(-12.5, 0.0, -14.0), Color("7c583e"))
    _make_house(Vector3(12.0, 0.0, -15.0), Color("73513a"))
    _make_house(Vector3(-11.0, 0.0, -31.0), Color("896747"))

    _make_gate_post(Vector3(-5.2, 0.0, -28.0))
    _make_gate_post(Vector3(5.2, 0.0, -28.0))

    var sign := Label3D.new()
    sign.text = "RAVENFALL"
    sign.position = Vector3(0.0, 5.3, -28.0)
    sign.billboard = BaseMaterial3D.BILLBOARD_ENABLED
    sign.font_size = 42
    sign.outline_size = 8
    sign.modulate = Color("f2d28a")
    add_child(sign)

    _make_crate(Vector3(4.0, 0.0, -8.0))
    _make_crate(Vector3(5.2, 0.0, -8.4))
    _make_crate(Vector3(-4.5, 0.0, -18.0))

func _make_gate_post(pos: Vector3) -> void:
    var body := StaticBody3D.new()
    body.position = pos
    add_child(body)
    var pillar := MeshInstance3D.new()
    var pillar_mesh := BoxMesh.new()
    pillar_mesh.size = Vector3(1.3, 5.0, 1.3)
    pillar.mesh = pillar_mesh
    pillar.position.y = 2.5
    pillar.material_override = _material(Color("6b5848"), 1.0)
    body.add_child(pillar)
    var collision := CollisionShape3D.new()
    var box := BoxShape3D.new()
    box.size = Vector3(1.3, 5.0, 1.3)
    collision.shape = box
    collision.position.y = 2.5
    body.add_child(collision)

func _make_crate(pos: Vector3) -> void:
    var crate := StaticBody3D.new()
    crate.position = pos
    add_child(crate)
    var mesh_instance := MeshInstance3D.new()
    var mesh := BoxMesh.new()
    mesh.size = Vector3(1.1, 1.1, 1.1)
    mesh_instance.mesh = mesh
    mesh_instance.position.y = 0.55
    mesh_instance.material_override = _material(Color("765134"), 1.0)
    crate.add_child(mesh_instance)
    var collision := CollisionShape3D.new()
    var box := BoxShape3D.new()
    box.size = Vector3(1.1, 1.1, 1.1)
    collision.shape = box
    collision.position.y = 0.55
    crate.add_child(collision)

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
    roof.material_override = _material(Color("4c3029"), 1.0)
    house.add_child(roof)

    var door := MeshInstance3D.new()
    var door_mesh := BoxMesh.new()
    door_mesh.size = Vector3(1.4, 2.3, 0.12)
    door.mesh = door_mesh
    door.position = Vector3(0.0, 1.15, -3.06)
    door.material_override = _material(Color("3f2a1e"), 1.0)
    house.add_child(door)

    var collision := CollisionShape3D.new()
    var shape := BoxShape3D.new()
    shape.size = Vector3(7.0, 4.0, 6.0)
    collision.shape = shape
    collision.position.y = 2.0
    house.add_child(collision)

func _build_forest() -> void:
    var positions := [
        Vector3(-25, 0, -4), Vector3(-30, 0, -12), Vector3(-24, 0, -21),
        Vector3(25, 0, -5), Vector3(30, 0, -17), Vector3(24, 0, -25),
        Vector3(-34, 0, 12), Vector3(34, 0, 15), Vector3(-20, 0, 27),
        Vector3(22, 0, 30), Vector3(-38, 0, -33), Vector3(39, 0, -35),
        Vector3(-31, 0, -45), Vector3(-22, 0, -50), Vector3(30, 0, -49),
        Vector3(42, 0, -24), Vector3(-43, 0, -20), Vector3(44, 0, 4)
    ]
    for pos in positions:
        _make_tree(pos, 0.9 + randf() * 0.4)

func _make_tree(pos: Vector3, scale_factor: float) -> void:
    var tree := Node3D.new()
    tree.position = pos
    tree.scale = Vector3.ONE * scale_factor
    add_child(tree)

    var trunk := MeshInstance3D.new()
    var trunk_mesh := CylinderMesh.new()
    trunk_mesh.top_radius = 0.30
    trunk_mesh.bottom_radius = 0.48
    trunk_mesh.height = 4.0
    trunk.mesh = trunk_mesh
    trunk.position.y = 2.0
    trunk.material_override = _material(Color("5b3e29"), 1.0)
    tree.add_child(trunk)

    var crown := MeshInstance3D.new()
    var crown_mesh := SphereMesh.new()
    crown_mesh.radius = 2.1
    crown_mesh.height = 4.1
    crown.mesh = crown_mesh
    crown.position.y = 5.0
    crown.material_override = _material(Color("2f713d"), 0.9)
    tree.add_child(crown)

func _build_npc() -> void:
    quest_npc = Node3D.new()
    quest_npc.name = "HauptmannArlen"
    quest_npc.position = Vector3(-2.8, 0.0, -10.0)
    add_child(quest_npc)

    _make_humanoid_model(quest_npc, Color("a76b33"), Color("d5aa54"), false)

    quest_label = Label3D.new()
    quest_label.position = Vector3(0, 2.9, 0)
    quest_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
    quest_label.font_size = 28
    quest_label.outline_size = 7
    quest_npc.add_child(quest_label)
    _update_quest_marker()

func _make_humanoid_model(parent: Node3D, tunic_color: Color, accent: Color, armed: bool) -> void:
    var torso := MeshInstance3D.new()
    var torso_mesh := BoxMesh.new()
    torso_mesh.size = Vector3(0.9, 1.0, 0.45)
    torso.mesh = torso_mesh
    torso.position = Vector3(0, 1.35, 0)
    torso.material_override = _material(tunic_color, 0.8)
    parent.add_child(torso)

    var head := MeshInstance3D.new()
    var head_mesh := SphereMesh.new()
    head_mesh.radius = 0.32
    head_mesh.height = 0.64
    head.mesh = head_mesh
    head.position = Vector3(0, 2.08, 0)
    head.material_override = _material(Color("d9ab83"), 0.9)
    parent.add_child(head)

    for x in [-0.23, 0.23]:
        var leg := MeshInstance3D.new()
        var leg_mesh := BoxMesh.new()
        leg_mesh.size = Vector3(0.32, 0.85, 0.35)
        leg.mesh = leg_mesh
        leg.position = Vector3(x, 0.45, 0)
        leg.material_override = _material(Color("4c443f"), 1.0)
        parent.add_child(leg)

    for x in [-0.62, 0.62]:
        var arm := MeshInstance3D.new()
        var arm_mesh := BoxMesh.new()
        arm_mesh.size = Vector3(0.25, 0.85, 0.27)
        arm.mesh = arm_mesh
        arm.position = Vector3(x, 1.38, 0)
        arm.material_override = _material(accent, 0.9)
        parent.add_child(arm)

    if armed:
        var blade := MeshInstance3D.new()
        var blade_mesh := BoxMesh.new()
        blade_mesh.size = Vector3(0.10, 1.15, 0.12)
        blade.mesh = blade_mesh
        blade.position = Vector3(0.79, 0.78, -0.08)
        blade.material_override = _material(Color("c5ccd4"), 0.5)
        parent.add_child(blade)

func _spawn_player() -> void:
    player = CharacterBody3D.new()
    player.name = "Player"
    player.position = Vector3(0.0, 0.02, 8.0)
    player.set_script(load("res://scripts/player.gd"))
    player.set("game_ref", self)
    add_child(player)

func _build_wolves() -> void:
    var spawn_positions := [
        Vector3(7.0, 0.02, -35.0),
        Vector3(13.0, 0.02, -42.0),
        Vector3(-7.0, 0.02, -39.0),
        Vector3(20.0, 0.02, -48.0),
        Vector3(-18.0, 0.02, -45.0)
    ]
    for i in range(spawn_positions.size()):
        var wolf := CharacterBody3D.new()
        wolf.name = "Wolf_%d" % (i + 1)
        wolf.position = spawn_positions[i]
        wolf.set_script(load("res://scripts/wolf.gd"))
        add_child(wolf)
        wolf.configure(player, self, spawn_positions[i])
        wolves.append(wolf)

func _build_hud() -> void:
    var canvas := CanvasLayer.new()
    canvas.name = "HUD"
    add_child(canvas)

    hud = Control.new()
    hud.set_script(load("res://scripts/hud.gd"))
    hud.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    hud.mouse_filter = Control.MOUSE_FILTER_IGNORE
    hud.set("player", player)
    hud.set("game", self)
    canvas.add_child(hud)

func try_select_from_screen(camera: Camera3D, screen_pos: Vector2) -> bool:
    if camera == null:
        return false
    var origin := camera.project_ray_origin(screen_pos)
    var direction := camera.project_ray_normal(screen_pos)
    var query := PhysicsRayQueryParameters3D.create(origin, origin + direction * 120.0)
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
    if player == null or player.dead or quest_panel_open or attack_cooldown > 0.0:
        return
    var target := current_target
    if target == null or not is_instance_valid(target) or not target.is_alive_enemy():
        target = _nearest_alive_wolf(5.0)
        if target != null:
            select_target(target)
    if target == null:
        show_toast("Kein Gegner in Reichweite", 1.4)
        return
    var distance := player.global_position.distance_to(target.global_position)
    if distance > 4.2:
        show_toast("Ziel ist zu weit entfernt", 1.2)
        return
    attack_cooldown = 0.72
    player.face_world_position(target.global_position)
    player.play_attack()
    var damage := randi_range(18, 25)
    var critical := randf() < 0.15
    if critical:
        damage *= 2
    target.take_damage(damage)
    if critical:
        show_toast("KRITISCH!  %d Schaden" % damage, 0.9)

func _nearest_alive_wolf(max_distance: float) -> Node:
    var best: Node = null
    var best_dist := max_distance
    for wolf in wolves:
        if wolf == null or not is_instance_valid(wolf) or not wolf.is_alive_enemy():
            continue
        var dist := player.global_position.distance_to(wolf.global_position)
        if dist < best_dist:
            best_dist = dist
            best = wolf
    return best

func try_interact() -> void:
    if quest_npc == null or player == null:
        return
    if player.global_position.distance_to(quest_npc.global_position) > 3.6:
        show_toast("Niemand zum Ansprechen in der Nähe", 1.3)
        return
    quest_panel_open = true
    player.cancel_touches()

func is_player_near_npc() -> bool:
    return player != null and quest_npc != null and player.global_position.distance_to(quest_npc.global_position) <= 3.6

func handle_quest_panel_touch(pos: Vector2) -> void:
    if not quest_panel_open:
        return
    var button := get_quest_button_rect()
    var close_button := get_quest_close_rect()
    if close_button.has_point(pos):
        quest_panel_open = false
        return
    if not button.has_point(pos):
        return
    if quest_stage == 0:
        quest_stage = 1
        quest_kills = 0
        quest_panel_open = false
        show_toast("Quest angenommen: Wölfe vor den Toren", 2.4)
    elif quest_stage == 2:
        quest_stage = 3
        gold += 25
        _add_xp(40)
        quest_panel_open = false
        show_toast("Quest abgeschlossen · +40 EP · +25 Gold", 2.8)
    else:
        quest_panel_open = false

func get_quest_panel_rect() -> Rect2:
    var screen := get_viewport().get_visible_rect().size
    var width := minf(680.0, screen.x * 0.78)
    var height := minf(390.0, screen.y * 0.68)
    return Rect2(Vector2((screen.x - width) * 0.5, (screen.y - height) * 0.5), Vector2(width, height))

func get_quest_button_rect() -> Rect2:
    var panel := get_quest_panel_rect()
    return Rect2(Vector2(panel.position.x + 36.0, panel.end.y - 82.0), Vector2(panel.size.x - 72.0, 52.0))

func get_quest_close_rect() -> Rect2:
    var panel := get_quest_panel_rect()
    return Rect2(Vector2(panel.end.x - 58.0, panel.position.y + 14.0), Vector2(42.0, 42.0))

func get_quest_button_text() -> String:
    if quest_stage == 0:
        return "QUEST ANNEHMEN"
    if quest_stage == 2:
        return "QUEST ABGEBEN"
    return "SCHLIESSEN"

func get_quest_title() -> String:
    return "Wölfe vor den Toren"

func get_quest_body_lines() -> PackedStringArray:
    if quest_stage == 0:
        return PackedStringArray([
            "Hauptmann Arlen: Die Wölfe kommen immer näher an Ravenfall.",
            "Besiege 3 Wölfe vor dem Südtor.",
            "Belohnung: 40 EP und 25 Gold."
        ])
    if quest_stage == 1:
        return PackedStringArray([
            "Die Wölfe befinden sich südlich vor dem Tor.",
            "Fortschritt: %d / %d Wölfe" % [quest_kills, QUEST_GOAL],
            "Kehre danach zu Hauptmann Arlen zurück."
        ])
    if quest_stage == 2:
        return PackedStringArray([
            "Hauptmann Arlen: Gute Arbeit. Ravenfall ist vorerst sicher.",
            "Dein Auftrag ist erfüllt.",
            "Belohnung: 40 EP und 25 Gold."
        ])
    return PackedStringArray([
        "Hauptmann Arlen: Danke für deine Hilfe.",
        "Weitere Aufträge folgen in der nächsten Ausbaustufe."
    ])

func get_quest_tracker_text() -> String:
    if quest_stage == 0:
        return "Sprich mit Hauptmann Arlen"
    if quest_stage == 1:
        return "Wölfe besiegen: %d / %d" % [quest_kills, QUEST_GOAL]
    if quest_stage == 2:
        return "Kehre zu Hauptmann Arlen zurück"
    return "Auftrag abgeschlossen"

func on_wolf_defeated(wolf: Node) -> void:
    if current_target == wolf:
        select_target(null)
    var loot_gold := randi_range(3, 8)
    gold += loot_gold
    pelts += 1
    _add_xp(20)
    if quest_stage == 1:
        quest_kills = mini(QUEST_GOAL, quest_kills + 1)
        if quest_kills >= QUEST_GOAL:
            quest_stage = 2
            show_toast("Questziel erreicht! Zurück zu Hauptmann Arlen", 3.0)
            return
    show_toast("Wolf besiegt · +20 EP · +%d Gold · Wolfspelz" % loot_gold, 2.0)

func _add_xp(amount: int) -> void:
    xp += amount
    var needed := get_xp_required()
    while xp >= needed:
        xp -= needed
        level += 1
        needed = get_xp_required()
        if player != null:
            player.set_max_health(100 + (level - 1) * 12, true)
        show_toast("LEVEL AUFSTIEG! Stufe %d" % level, 2.4)

func get_xp_required() -> int:
    return 100 + (level - 1) * 50

func show_toast(text: String, duration: float = 2.0) -> void:
    toast_text = text
    toast_time = duration

func _update_quest_marker() -> void:
    if quest_label == null:
        return
    if quest_stage == 0:
        quest_label.text = "!\nHauptmann Arlen"
        quest_label.modulate = Color("ffd65a")
    elif quest_stage == 1:
        quest_label.text = "Hauptmann Arlen"
        quest_label.modulate = Color.WHITE
    elif quest_stage == 2:
        quest_label.text = "?\nHauptmann Arlen"
        quest_label.modulate = Color("ffd65a")
    else:
        quest_label.text = "Hauptmann Arlen"
        quest_label.modulate = Color("d8e0e8")

func _material(color: Color, roughness: float) -> StandardMaterial3D:
    var mat := StandardMaterial3D.new()
    mat.albedo_color = color
    mat.roughness = roughness
    return mat
