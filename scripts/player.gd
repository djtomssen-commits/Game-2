extends CharacterBody3D

const MOVE_SPEED := 6.5
const ACCELERATION := 24.0
const JUMP_VELOCITY := 7.3
const LOOK_SENSITIVITY := 0.0044
const JOYSTICK_RADIUS := 112.0

var game_ref: Node
var gravity := 18.0
var yaw := 0.0
var pitch := -0.20
var move_touch_id := -1
var look_touch_id := -1
var move_origin := Vector2.ZERO
var move_vector := Vector2.ZERO
var jump_requested := false
var dead := false
var health := 100
var max_health := 100

var camera_pivot: Node3D
var spring_arm: SpringArm3D
var camera: Camera3D
var model_root: Node3D
var left_leg: Node3D
var right_leg: Node3D
var left_arm: Node3D
var right_arm: Node3D
var cape: Node3D
var walk_phase := 0.0
var attack_anim_time := 0.0
var spin_anim_time := 0.0
var hit_anim_time := 0.0
var desired_facing := 0.0

func _ready() -> void:
    gravity = float(ProjectSettings.get_setting("physics/3d/default_gravity", 18.0))
    _build_collision()
    _build_model()
    _build_camera()
    Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func _build_collision() -> void:
    var collision := CollisionShape3D.new()
    var capsule := CapsuleShape3D.new()
    capsule.radius = 0.40
    capsule.height = 1.85
    collision.shape = capsule
    collision.position.y = 0.93
    add_child(collision)

func _build_camera() -> void:
    camera_pivot = Node3D.new()
    camera_pivot.name = "CameraPivot"
    camera_pivot.position = Vector3(0.0, 1.62, 0.0)
    add_child(camera_pivot)
    spring_arm = SpringArm3D.new()
    spring_arm.name = "SpringArm"
    spring_arm.spring_length = 4.8
    spring_arm.margin = 0.20
    spring_arm.add_excluded_object(get_rid())
    camera_pivot.add_child(spring_arm)
    camera = Camera3D.new()
    camera.name = "ThirdPersonCamera"
    camera.current = true
    camera.fov = 66.0
    camera.position = Vector3(0.35,0.12,0)
    spring_arm.add_child(camera)

func _build_model() -> void:
    model_root = Node3D.new()
    model_root.name = "RavenfallWarrior"
    add_child(model_root)

    # Rounded low-poly hero: armor, pauldrons, boots, cape, shield and sword.
    _add_cylinder(model_root,0.36,0.46,0.95,Vector3(0,1.34,0),Color("315a83"))
    _add_cylinder(model_root,0.42,0.38,0.22,Vector3(0,1.78,0),Color("b07b37"))
    _add_sphere(model_root,Vector3(0.32,0.35,0.32),Vector3(0,2.12,0),Color("d7aa83"))
    _add_sphere(model_root,Vector3(0.35,0.18,0.35),Vector3(0,2.31,0.01),Color("5a4434"))
    _add_box(model_root,Vector3(0.12,0.16,0.08),Vector3(-0.12,2.11,-0.31),Color("2a2727"))
    _add_box(model_root,Vector3(0.12,0.16,0.08),Vector3(0.12,2.11,-0.31),Color("2a2727"))

    left_leg = _make_limb(Vector3(-0.23,0.90,0),0.14,0.18,0.88,Color("414850"),Vector3(0,-0.44,0))
    right_leg = _make_limb(Vector3(0.23,0.90,0),0.14,0.18,0.88,Color("414850"),Vector3(0,-0.44,0))
    _add_box(left_leg,Vector3(0.34,0.20,0.55),Vector3(0,-0.88,-0.08),Color("3a302a"))
    _add_box(right_leg,Vector3(0.34,0.20,0.55),Vector3(0,-0.88,-0.08),Color("3a302a"))

    left_arm = _make_limb(Vector3(-0.58,1.72,0),0.12,0.15,0.84,Color("6d8baa"),Vector3(0,-0.42,0))
    right_arm = _make_limb(Vector3(0.58,1.72,0),0.12,0.15,0.84,Color("6d8baa"),Vector3(0,-0.42,0))
    _add_sphere(model_root,Vector3(0.27,0.18,0.30),Vector3(-0.54,1.80,0),Color("8f6735"))
    _add_sphere(model_root,Vector3(0.27,0.18,0.30),Vector3(0.54,1.80,0),Color("8f6735"))

    var shield := MeshInstance3D.new()
    var shield_mesh := CylinderMesh.new()
    shield_mesh.top_radius = 0.44
    shield_mesh.bottom_radius = 0.44
    shield_mesh.height = 0.11
    shield_mesh.radial_segments = 10
    shield.mesh = shield_mesh
    shield.position = Vector3(0,-0.48,-0.22)
    shield.rotation_degrees.x = 90.0
    shield.material_override = _material(Color("7d5730"),0.86)
    left_arm.add_child(shield)
    _add_box(left_arm,Vector3(0.08,0.72,0.08),Vector3(0,-0.85,-0.04),Color("52331f"))
    _add_box(left_arm,Vector3(0.12,0.12,0.12),Vector3(0,-1.26,-0.04),Color("d0d5db"),0.42)

    _add_box(right_arm,Vector3(0.10,0.48,0.10),Vector3(0,-0.67,-0.05),Color("573722"))
    _add_box(right_arm,Vector3(0.12,1.15,0.09),Vector3(0,-1.42,-0.05),Color("cbd3da"),0.34)
    _add_box(right_arm,Vector3(0.52,0.10,0.10),Vector3(0,-0.88,-0.05),Color("a98245"))

    cape = Node3D.new()
    cape.position = Vector3(0,1.46,0.25)
    model_root.add_child(cape)
    _add_box(cape,Vector3(0.78,1.2,0.07),Vector3(0,-0.28,0),Color("6f2630"))

    var name_label := Label3D.new()
    name_label.text = "Abenteurer"
    name_label.position = Vector3(0,2.82,0)
    name_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
    name_label.font_size = 21
    name_label.outline_size = 6
    name_label.modulate = Color("e9eef6")
    model_root.add_child(name_label)

func _make_limb(pivot_pos: Vector3, top_radius: float, bottom_radius: float, height: float, color: Color, mesh_offset: Vector3) -> Node3D:
    var pivot := Node3D.new()
    pivot.position = pivot_pos
    model_root.add_child(pivot)
    _add_cylinder(pivot,top_radius,bottom_radius,height,mesh_offset,color)
    return pivot

func _add_box(parent: Node, size: Vector3, pos: Vector3, color: Color, roughness: float = 0.85) -> void:
    var node := MeshInstance3D.new()
    var mesh := BoxMesh.new()
    mesh.size = size
    node.mesh = mesh
    node.position = pos
    node.material_override = _material(color,roughness)
    parent.add_child(node)

func _add_cylinder(parent: Node, top_radius: float, bottom_radius: float, height: float, pos: Vector3, color: Color) -> void:
    var node := MeshInstance3D.new()
    var mesh := CylinderMesh.new()
    mesh.top_radius = top_radius
    mesh.bottom_radius = bottom_radius
    mesh.height = height
    mesh.radial_segments = 10
    node.mesh = mesh
    node.position = pos
    node.material_override = _material(color,0.9)
    parent.add_child(node)

func _add_sphere(parent: Node, scale_value: Vector3, pos: Vector3, color: Color) -> void:
    var node := MeshInstance3D.new()
    var mesh := SphereMesh.new()
    mesh.radius = 1.0
    mesh.height = 2.0
    mesh.radial_segments = 12
    mesh.rings = 6
    node.mesh = mesh
    node.scale = scale_value
    node.position = pos
    node.material_override = _material(color,0.9)
    parent.add_child(node)

func _unhandled_input(event: InputEvent) -> void:
    if game_ref == null:
        return
    if game_ref.quest_panel_open:
        if event is InputEventScreenTouch and event.pressed:
            game_ref.handle_quest_panel_touch(event.position)
        elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
            game_ref.handle_quest_panel_touch(event.position)
        return
    if game_ref.inventory_open:
        if event is InputEventScreenTouch and event.pressed:
            game_ref.handle_inventory_touch(event.position)
        elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
            game_ref.handle_inventory_touch(event.position)
        return

    var screen := get_viewport().get_visible_rect().size
    if event is InputEventScreenTouch:
        if event.pressed:
            if game_ref.get_inventory_button_rect().has_point(event.position):
                game_ref.toggle_inventory()
            elif _inside_attack_button(event.position,screen):
                game_ref.perform_player_attack()
            elif _inside_skill1_button(event.position,screen):
                game_ref.perform_skill_1()
            elif _inside_skill2_button(event.position,screen):
                game_ref.perform_skill_2()
            elif _inside_jump_button(event.position,screen):
                jump_requested = true
            elif _inside_interact_button(event.position,screen):
                game_ref.try_interact()
            elif event.position.x < screen.x * 0.42 and move_touch_id == -1:
                move_touch_id = event.index
                move_origin = event.position
                move_vector = Vector2.ZERO
            elif look_touch_id == -1:
                if not game_ref.try_select_from_screen(camera,event.position):
                    look_touch_id = event.index
        else:
            if event.index == move_touch_id:
                move_touch_id = -1
                move_vector = Vector2.ZERO
            if event.index == look_touch_id:
                look_touch_id = -1
    elif event is InputEventScreenDrag:
        if event.index == move_touch_id:
            move_vector = (event.position-move_origin)/(JOYSTICK_RADIUS*_ui_scale(screen))
            move_vector = move_vector.limit_length(1.0)
        elif event.index == look_touch_id:
            yaw -= event.relative.x*LOOK_SENSITIVITY
            pitch -= event.relative.y*LOOK_SENSITIVITY
            pitch = clampf(pitch,-0.72,0.28)
    elif event is InputEventMouseMotion and Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT):
        yaw -= event.relative.x*LOOK_SENSITIVITY
        pitch -= event.relative.y*LOOK_SENSITIVITY
        pitch = clampf(pitch,-0.72,0.28)
    elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
        if game_ref.get_inventory_button_rect().has_point(event.position):
            game_ref.toggle_inventory()
        else:
            game_ref.try_select_from_screen(camera,event.position)
    elif event is InputEventKey and event.pressed and not event.echo:
        match event.keycode:
            KEY_F: game_ref.perform_player_attack()
            KEY_1: game_ref.perform_skill_1()
            KEY_2: game_ref.perform_skill_2()
            KEY_Q: game_ref.try_interact()
            KEY_I: game_ref.toggle_inventory()

func _physics_process(delta: float) -> void:
    if dead:
        velocity = Vector3.ZERO
        _animate_model(delta,0.0)
        return
    var input_vec := move_vector
    if Input.is_key_pressed(KEY_A): input_vec.x -= 1.0
    if Input.is_key_pressed(KEY_D): input_vec.x += 1.0
    if Input.is_key_pressed(KEY_W): input_vec.y -= 1.0
    if Input.is_key_pressed(KEY_S): input_vec.y += 1.0
    input_vec = input_vec.limit_length(1.0)

    var camera_basis := Basis(Vector3.UP,yaw)
    var desired := camera_basis*Vector3(input_vec.x,0.0,input_vec.y)
    desired.y = 0.0
    if desired.length() > 0.01:
        desired = desired.normalized()
        desired_facing = atan2(-desired.x,-desired.z)
    velocity.x = move_toward(velocity.x,desired.x*MOVE_SPEED,ACCELERATION*delta)
    velocity.z = move_toward(velocity.z,desired.z*MOVE_SPEED,ACCELERATION*delta)
    if not is_on_floor():
        velocity.y -= gravity*delta
    else:
        velocity.y = JUMP_VELOCITY if (jump_requested or Input.is_key_pressed(KEY_SPACE)) else -0.2
    jump_requested = false
    move_and_slide()
    camera_pivot.rotation = Vector3(pitch,yaw,0.0)
    model_root.rotation.y = lerp_angle(model_root.rotation.y,desired_facing,minf(1.0,delta*11.0))
    _animate_model(delta,Vector2(velocity.x,velocity.z).length())

func _animate_model(delta: float, speed: float) -> void:
    attack_anim_time = maxf(0.0,attack_anim_time-delta)
    spin_anim_time = maxf(0.0,spin_anim_time-delta)
    hit_anim_time = maxf(0.0,hit_anim_time-delta)
    if spin_anim_time > 0.0:
        model_root.rotation.y += delta*14.0
        right_arm.rotation.z = -1.0
    elif speed > 0.35 and is_on_floor():
        walk_phase += delta*9.5
        var swing := sin(walk_phase)*0.58
        left_leg.rotation.x = lerpf(left_leg.rotation.x,swing,minf(1.0,delta*14.0))
        right_leg.rotation.x = lerpf(right_leg.rotation.x,-swing,minf(1.0,delta*14.0))
        if attack_anim_time <= 0.0:
            left_arm.rotation.x = lerpf(left_arm.rotation.x,-swing*0.48,minf(1.0,delta*14.0))
            right_arm.rotation.x = lerpf(right_arm.rotation.x,swing*0.48,minf(1.0,delta*14.0))
    else:
        left_leg.rotation.x = lerpf(left_leg.rotation.x,0.0,minf(1.0,delta*12.0))
        right_leg.rotation.x = lerpf(right_leg.rotation.x,0.0,minf(1.0,delta*12.0))
        if attack_anim_time <= 0.0:
            left_arm.rotation.x = lerpf(left_arm.rotation.x,0.0,minf(1.0,delta*12.0))
            right_arm.rotation.x = lerpf(right_arm.rotation.x,0.0,minf(1.0,delta*12.0))
            right_arm.rotation.z = lerpf(right_arm.rotation.z,0.0,minf(1.0,delta*12.0))
    if attack_anim_time > 0.0:
        var total := 0.48 if attack_anim_time > 0.36 else 0.36
        var t := 1.0 - attack_anim_time/total
        var slash := sin(clampf(t,0.0,1.0)*PI)
        right_arm.rotation.x = -0.35-slash*1.15
        right_arm.rotation.z = -slash*1.05
    if cape != null:
        cape.rotation.x = lerpf(cape.rotation.x,0.12+minf(speed/10.0,0.28),minf(1.0,delta*5.0))

func play_attack(heavy: bool = false) -> void:
    attack_anim_time = 0.48 if heavy else 0.36

func play_spin_attack() -> void:
    spin_anim_time = 0.55

func face_world_position(world_pos: Vector3) -> void:
    var direction := world_pos-global_position
    direction.y = 0.0
    if direction.length() > 0.01:
        desired_facing = atan2(-direction.x,-direction.z)
        model_root.rotation.y = desired_facing

func take_damage(amount: int) -> void:
    if dead:
        return
    health = maxi(0,health-amount)
    hit_anim_time = 0.18
    if game_ref != null:
        game_ref.spawn_damage_number(global_position+Vector3(0,2.2,0),amount,false,true)
    if health <= 0:
        _die()

func _die() -> void:
    dead = true
    cancel_touches()
    model_root.rotation_degrees.z = 72.0
    game_ref.show_toast("Du wurdest besiegt · Wiederbelebung...",2.2)
    await get_tree().create_timer(2.2).timeout
    global_position = Vector3(0.0,0.05,9.0)
    health = max_health
    dead = false
    model_root.rotation_degrees.z = 0.0
    game_ref.select_target(null)
    game_ref.rage = 0
    game_ref.show_toast("Wiederbelebt in Ravenfall",1.8)

func set_max_health(value: int, heal_full: bool = false) -> void:
    max_health = value
    health = max_health if heal_full else mini(health,max_health)

func cancel_touches() -> void:
    move_touch_id = -1
    look_touch_id = -1
    move_vector = Vector2.ZERO

func _inside_attack_button(pos: Vector2,screen: Vector2) -> bool:
    var s := _ui_scale(screen)
    return pos.distance_to(Vector2(screen.x-92.0*s,screen.y-112.0*s)) <= 67.0*s
func _inside_skill1_button(pos: Vector2,screen: Vector2) -> bool:
    var s := _ui_scale(screen)
    return pos.distance_to(Vector2(screen.x-225.0*s,screen.y-82.0*s)) <= 57.0*s
func _inside_skill2_button(pos: Vector2,screen: Vector2) -> bool:
    var s := _ui_scale(screen)
    return pos.distance_to(Vector2(screen.x-215.0*s,screen.y-205.0*s)) <= 57.0*s
func _inside_jump_button(pos: Vector2,screen: Vector2) -> bool:
    var s := _ui_scale(screen)
    return pos.distance_to(Vector2(screen.x-92.0*s,screen.y-255.0*s)) <= 52.0*s
func _inside_interact_button(pos: Vector2,screen: Vector2) -> bool:
    var s := _ui_scale(screen)
    return pos.distance_to(Vector2(screen.x-92.0*s,screen.y-370.0*s)) <= 55.0*s
func _ui_scale(screen: Vector2) -> float:
    return clampf(screen.y/720.0,0.85,1.55)
func _material(color: Color,roughness: float) -> StandardMaterial3D:
    var mat := StandardMaterial3D.new()
    mat.albedo_color = color
    mat.roughness = roughness
    return mat
