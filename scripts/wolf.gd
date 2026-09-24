extends CharacterBody3D

var player_ref: CharacterBody3D
var game_ref: Node
var spawn_point := Vector3.ZERO
var max_health := 55
var health := 55
var alive := true
var aggro := false
var attack_timer := 0.0
var gravity := 18.0

var visual_root: Node3D
var name_label: Label3D
var target_marker: Label3D
var front_left_leg: Node3D
var front_right_leg: Node3D
var back_left_leg: Node3D
var back_right_leg: Node3D
var walk_phase := 0.0

func _ready() -> void:
    gravity = float(ProjectSettings.get_setting("physics/3d/default_gravity", 18.0))
    add_to_group("enemies")
    _build_collision()
    _build_model()

func configure(player: CharacterBody3D, game: Node, spawn: Vector3) -> void:
    player_ref = player
    game_ref = game
    spawn_point = spawn

func _build_collision() -> void:
    var collision := CollisionShape3D.new()
    collision.name = "WolfCollision"
    var box := BoxShape3D.new()
    box.size = Vector3(1.15, 1.25, 2.15)
    collision.shape = box
    collision.position = Vector3(0, 0.65, 0)
    add_child(collision)

func _build_model() -> void:
    visual_root = Node3D.new()
    visual_root.name = "WolfModel"
    add_child(visual_root)

    _add_box(visual_root, Vector3(1.0, 0.65, 1.75), Vector3(0, 0.76, 0), Color("59616d"))
    _add_box(visual_root, Vector3(0.76, 0.70, 0.85), Vector3(0, 1.02, -1.12), Color("646d79"))
    _add_box(visual_root, Vector3(0.48, 0.34, 0.62), Vector3(0, 0.89, -1.78), Color("4d555f"))
    _add_box(visual_root, Vector3(0.18, 0.34, 0.18), Vector3(-0.22, 1.45, -1.18), Color("4c535d"))
    _add_box(visual_root, Vector3(0.18, 0.34, 0.18), Vector3(0.22, 1.45, -1.18), Color("4c535d"))

    front_left_leg = _make_leg(Vector3(-0.35, 0.64, -0.58))
    front_right_leg = _make_leg(Vector3(0.35, 0.64, -0.58))
    back_left_leg = _make_leg(Vector3(-0.35, 0.64, 0.58))
    back_right_leg = _make_leg(Vector3(0.35, 0.64, 0.58))

    var tail_pivot := Node3D.new()
    tail_pivot.position = Vector3(0, 0.98, 0.86)
    tail_pivot.rotation_degrees.x = -35.0
    visual_root.add_child(tail_pivot)
    var tail := MeshInstance3D.new()
    var tail_mesh := CylinderMesh.new()
    tail_mesh.top_radius = 0.10
    tail_mesh.bottom_radius = 0.17
    tail_mesh.height = 1.15
    tail.mesh = tail_mesh
    tail.position.y = 0.50
    tail.material_override = _material(Color("4f5864"), 1.0)
    tail_pivot.add_child(tail)

    name_label = Label3D.new()
    name_label.position = Vector3(0, 2.0, 0)
    name_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
    name_label.font_size = 23
    name_label.outline_size = 6
    visual_root.add_child(name_label)

    target_marker = Label3D.new()
    target_marker.text = "▼"
    target_marker.position = Vector3(0, 2.55, 0)
    target_marker.billboard = BaseMaterial3D.BILLBOARD_ENABLED
    target_marker.font_size = 34
    target_marker.outline_size = 7
    target_marker.modulate = Color("ffd05a")
    target_marker.visible = false
    visual_root.add_child(target_marker)
    _update_label()

func _make_leg(pos: Vector3) -> Node3D:
    var pivot := Node3D.new()
    pivot.position = pos
    visual_root.add_child(pivot)
    _add_box(pivot, Vector3(0.22, 0.58, 0.25), Vector3(0, -0.28, 0), Color("4c555f"))
    return pivot

func _add_box(parent: Node3D, size: Vector3, pos: Vector3, color: Color) -> void:
    var mesh_instance := MeshInstance3D.new()
    var mesh := BoxMesh.new()
    mesh.size = size
    mesh_instance.mesh = mesh
    mesh_instance.position = pos
    mesh_instance.material_override = _material(color, 0.95)
    parent.add_child(mesh_instance)

func _physics_process(delta: float) -> void:
    if not alive or player_ref == null or not is_instance_valid(player_ref):
        return

    attack_timer = maxf(0.0, attack_timer - delta)
    var horizontal_to_player := player_ref.global_position - global_position
    horizontal_to_player.y = 0.0
    var distance := horizontal_to_player.length()

    if not player_ref.dead and (aggro or distance < 7.5):
        aggro = true
        if distance > 1.65:
            var direction := horizontal_to_player.normalized()
            velocity.x = direction.x * 2.5
            velocity.z = direction.z * 2.5
            visual_root.rotation.y = lerp_angle(visual_root.rotation.y, atan2(-direction.x, -direction.z), minf(1.0, delta * 8.0))
        else:
            velocity.x = move_toward(velocity.x, 0.0, delta * 12.0)
            velocity.z = move_toward(velocity.z, 0.0, delta * 12.0)
            if attack_timer <= 0.0:
                attack_timer = 1.35
                player_ref.take_damage(randi_range(6, 10))
    else:
        var to_spawn := spawn_point - global_position
        to_spawn.y = 0.0
        if to_spawn.length() > 1.2:
            var return_dir := to_spawn.normalized()
            velocity.x = return_dir.x * 1.5
            velocity.z = return_dir.z * 1.5
            visual_root.rotation.y = lerp_angle(visual_root.rotation.y, atan2(-return_dir.x, -return_dir.z), minf(1.0, delta * 6.0))
        else:
            velocity.x = move_toward(velocity.x, 0.0, delta * 8.0)
            velocity.z = move_toward(velocity.z, 0.0, delta * 8.0)
            aggro = false

    if not is_on_floor():
        velocity.y -= gravity * delta
    else:
        velocity.y = -0.2
    move_and_slide()
    _animate_legs(delta, Vector2(velocity.x, velocity.z).length())

func _animate_legs(delta: float, speed: float) -> void:
    if speed > 0.25:
        walk_phase += delta * 10.0
        var swing := sin(walk_phase) * 0.48
        front_left_leg.rotation.x = swing
        back_right_leg.rotation.x = swing
        front_right_leg.rotation.x = -swing
        back_left_leg.rotation.x = -swing
    else:
        front_left_leg.rotation.x = lerpf(front_left_leg.rotation.x, 0.0, minf(1.0, delta * 10.0))
        front_right_leg.rotation.x = lerpf(front_right_leg.rotation.x, 0.0, minf(1.0, delta * 10.0))
        back_left_leg.rotation.x = lerpf(back_left_leg.rotation.x, 0.0, minf(1.0, delta * 10.0))
        back_right_leg.rotation.x = lerpf(back_right_leg.rotation.x, 0.0, minf(1.0, delta * 10.0))

func take_damage(amount: int) -> void:
    if not alive:
        return
    health = maxi(0, health - amount)
    aggro = true
    _update_label()
    if health <= 0:
        _die()

func _die() -> void:
    alive = false
    velocity = Vector3.ZERO
    visual_root.visible = false
    var collision := get_node_or_null("WolfCollision") as CollisionShape3D
    if collision != null:
        collision.set_deferred("disabled", true)
    if game_ref != null:
        game_ref.on_wolf_defeated(self)
    await get_tree().create_timer(7.0).timeout
    global_position = spawn_point
    health = max_health
    alive = true
    aggro = false
    visual_root.visible = true
    if collision != null:
        collision.set_deferred("disabled", false)
    _update_label()

func set_targeted(value: bool) -> void:
    if target_marker != null:
        target_marker.visible = value and alive

func is_alive_enemy() -> bool:
    return alive

func get_health_ratio() -> float:
    return float(health) / float(max_health)

func _update_label() -> void:
    if name_label != null:
        name_label.text = "Wolf · Lv. 1  [%d/%d]" % [health, max_health]

func _material(color: Color, roughness: float) -> StandardMaterial3D:
    var mat := StandardMaterial3D.new()
    mat.albedo_color = color
    mat.roughness = roughness
    return mat
