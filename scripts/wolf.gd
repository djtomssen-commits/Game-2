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
var legs: Array[Node3D] = []
var tail_pivot: Node3D
var walk_phase := 0.0

func _ready() -> void:
    gravity = float(ProjectSettings.get_setting("physics/3d/default_gravity",18.0))
    add_to_group("enemies")
    _build_collision()
    _build_model()

func configure(player: CharacterBody3D,game: Node,spawn: Vector3) -> void:
    player_ref = player
    game_ref = game
    spawn_point = spawn

func _build_collision() -> void:
    var collision := CollisionShape3D.new()
    collision.name = "EnemyCollision"
    var box := BoxShape3D.new()
    box.size = Vector3(1.2,1.2,2.1)
    collision.shape = box
    collision.position = Vector3(0,0.65,0)
    add_child(collision)

func _build_model() -> void:
    visual_root = Node3D.new()
    add_child(visual_root)
    _add_sphere(Vector3(0.62,0.42,1.0),Vector3(0,0.78,0),Color("59636d"))
    _add_sphere(Vector3(0.48,0.42,0.52),Vector3(0,1.04,-1.02),Color("68727c"))
    _add_sphere(Vector3(0.30,0.23,0.44),Vector3(0,0.92,-1.53),Color("4c555d"))
    for x in [-0.24,0.24]:
        var ear := MeshInstance3D.new()
        var cone := CylinderMesh.new()
        cone.top_radius = 0.0
        cone.bottom_radius = 0.13
        cone.height = 0.40
        cone.radial_segments = 6
        ear.mesh = cone
        ear.position = Vector3(x,1.46,-1.12)
        ear.rotation_degrees.z = -12.0 if x < 0 else 12.0
        ear.material_override = _material(Color("4d555e"),1.0)
        visual_root.add_child(ear)
    for p in [Vector3(-0.34,0.62,-0.58),Vector3(0.34,0.62,-0.58),Vector3(-0.34,0.62,0.57),Vector3(0.34,0.62,0.57)]:
        legs.append(_make_leg(p))
    tail_pivot = Node3D.new()
    tail_pivot.position = Vector3(0,0.96,0.90)
    tail_pivot.rotation_degrees.x = -55.0
    visual_root.add_child(tail_pivot)
    var tail := MeshInstance3D.new()
    var tail_mesh := CylinderMesh.new()
    tail_mesh.top_radius = 0.07
    tail_mesh.bottom_radius = 0.15
    tail_mesh.height = 1.15
    tail_mesh.radial_segments = 8
    tail.mesh = tail_mesh
    tail.position.y = 0.50
    tail.material_override = _material(Color("505a63"),1.0)
    tail_pivot.add_child(tail)
    name_label = Label3D.new()
    name_label.text = "Wolf · Stufe 1"
    name_label.position = Vector3(0,2.05,0)
    name_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
    name_label.font_size = 20
    name_label.outline_size = 6
    visual_root.add_child(name_label)
    target_marker = Label3D.new()
    target_marker.text = "▼"
    target_marker.position = Vector3(0,2.55,0)
    target_marker.billboard = BaseMaterial3D.BILLBOARD_ENABLED
    target_marker.font_size = 32
    target_marker.outline_size = 7
    target_marker.modulate = Color("ffd05a")
    target_marker.visible = false
    visual_root.add_child(target_marker)

func _make_leg(pos: Vector3) -> Node3D:
    var pivot := Node3D.new()
    pivot.position = pos
    visual_root.add_child(pivot)
    var leg := MeshInstance3D.new()
    var mesh := CylinderMesh.new()
    mesh.top_radius = 0.09
    mesh.bottom_radius = 0.11
    mesh.height = 0.62
    mesh.radial_segments = 8
    leg.mesh = mesh
    leg.position.y = -0.30
    leg.material_override = _material(Color("4d565e"),1.0)
    pivot.add_child(leg)
    return pivot

func _add_sphere(scale_value: Vector3,pos: Vector3,color: Color) -> void:
    var node := MeshInstance3D.new()
    var mesh := SphereMesh.new()
    mesh.radius = 1.0
    mesh.height = 2.0
    mesh.radial_segments = 10
    mesh.rings = 5
    node.mesh = mesh
    node.scale = scale_value
    node.position = pos
    node.material_override = _material(color,0.95)
    visual_root.add_child(node)

func _physics_process(delta: float) -> void:
    if not alive or player_ref == null or not is_instance_valid(player_ref):
        return
    attack_timer = maxf(0.0,attack_timer-delta)
    var to_player := player_ref.global_position-global_position
    to_player.y = 0.0
    var distance := to_player.length()
    if not player_ref.dead and (aggro or distance < 7.5):
        aggro = true
        if distance > 1.65:
            var dir := to_player.normalized()
            velocity.x = dir.x*2.7
            velocity.z = dir.z*2.7
            visual_root.rotation.y = lerp_angle(visual_root.rotation.y,atan2(-dir.x,-dir.z),minf(1.0,delta*8.0))
        else:
            velocity.x = move_toward(velocity.x,0.0,delta*12.0)
            velocity.z = move_toward(velocity.z,0.0,delta*12.0)
            if attack_timer <= 0.0:
                attack_timer = 1.35
                player_ref.take_damage(randi_range(6,10))
    else:
        var back := spawn_point-global_position
        back.y = 0.0
        if back.length() > 1.2:
            var dir2 := back.normalized()
            velocity.x = dir2.x*1.6
            velocity.z = dir2.z*1.6
            visual_root.rotation.y = lerp_angle(visual_root.rotation.y,atan2(-dir2.x,-dir2.z),minf(1.0,delta*6.0))
        else:
            velocity.x = move_toward(velocity.x,0.0,delta*8.0)
            velocity.z = move_toward(velocity.z,0.0,delta*8.0)
            aggro = false
    velocity.y = velocity.y-gravity*delta if not is_on_floor() else -0.2
    move_and_slide()
    _animate(delta,Vector2(velocity.x,velocity.z).length())

func _animate(delta: float,speed: float) -> void:
    if speed > 0.25:
        walk_phase += delta*10.0
        var swing := sin(walk_phase)*0.48
        legs[0].rotation.x = swing
        legs[3].rotation.x = swing
        legs[1].rotation.x = -swing
        legs[2].rotation.x = -swing
        tail_pivot.rotation.z = sin(walk_phase*0.6)*0.18
    else:
        for leg in legs:
            leg.rotation.x = lerpf(leg.rotation.x,0.0,minf(1.0,delta*10.0))

func take_damage(amount: int,critical: bool = false) -> void:
    if not alive:
        return
    health = maxi(0,health-amount)
    aggro = true
    if game_ref != null:
        game_ref.spawn_damage_number(global_position+Vector3(0,2.0,0),amount,critical,false)
    var tween := create_tween()
    tween.tween_property(visual_root,"scale",Vector3(1.10,0.92,1.10),0.07)
    tween.tween_property(visual_root,"scale",Vector3.ONE,0.11)
    if health <= 0:
        _die()

func _die() -> void:
    alive = false
    velocity = Vector3.ZERO
    visual_root.rotation_degrees.z = 78.0
    var collision := get_node_or_null("EnemyCollision") as CollisionShape3D
    if collision != null: collision.set_deferred("disabled",true)
    if game_ref != null: game_ref.on_enemy_defeated(self,"wolf")
    await get_tree().create_timer(7.0).timeout
    global_position = spawn_point
    health = max_health
    alive = true
    aggro = false
    visual_root.rotation_degrees.z = 0.0
    if collision != null: collision.set_deferred("disabled",false)

func set_targeted(value: bool) -> void:
    if target_marker != null: target_marker.visible = value and alive
func is_alive_enemy() -> bool: return alive
func get_health_ratio() -> float: return float(health)/float(max_health)
func get_enemy_display_name() -> String: return "Wolf"
func get_enemy_level() -> int: return 1
func _material(color: Color,roughness: float) -> StandardMaterial3D:
    var mat := StandardMaterial3D.new(); mat.albedo_color=color; mat.roughness=roughness; return mat
