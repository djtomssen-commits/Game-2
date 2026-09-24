extends CharacterBody3D

const MOVE_SPEED := 6.2
const ACCELERATION := 22.0
const JUMP_VELOCITY := 7.2
const LOOK_SENSITIVITY := 0.0046
const JOYSTICK_RADIUS := 120.0

var game_ref: Node
var gravity := 18.0
var yaw := 0.0
var pitch := -0.24
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
var walk_phase := 0.0
var attack_anim_time := 0.0
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
    capsule.radius = 0.42
    capsule.height = 1.85
    collision.shape = capsule
    collision.position.y = 0.93
    add_child(collision)

func _build_camera() -> void:
    camera_pivot = Node3D.new()
    camera_pivot.name = "CameraPivot"
    camera_pivot.position = Vector3(0.0, 1.55, 0.0)
    add_child(camera_pivot)

    spring_arm = SpringArm3D.new()
    spring_arm.name = "SpringArm"
    spring_arm.spring_length = 5.7
    spring_arm.margin = 0.18
    spring_arm.add_excluded_object(get_rid())
    camera_pivot.add_child(spring_arm)

    camera = Camera3D.new()
    camera.name = "ThirdPersonCamera"
    camera.current = true
    camera.fov = 69.0
    spring_arm.add_child(camera)

func _build_model() -> void:
    model_root = Node3D.new()
    model_root.name = "WarriorModel"
    add_child(model_root)

    _add_box(model_root, Vector3(0.92, 0.98, 0.48), Vector3(0, 1.36, 0), Color("315b8b"))
    _add_box(model_root, Vector3(1.02, 0.20, 0.54), Vector3(0, 1.78, 0), Color("9a6b32"))
    _add_sphere(model_root, 0.32, Vector3(0, 2.08, 0), Color("d5aa86"))
    _add_box(model_root, Vector3(0.68, 0.16, 0.43), Vector3(0, 2.30, 0), Color("5e4635"))

    left_leg = _make_limb(Vector3(-0.24, 0.89, 0), Vector3(0.34, 0.88, 0.38), Color("3c4149"), Vector3(0, -0.44, 0))
    right_leg = _make_limb(Vector3(0.24, 0.89, 0), Vector3(0.34, 0.88, 0.38), Color("3c4149"), Vector3(0, -0.44, 0))
    left_arm = _make_limb(Vector3(-0.62, 1.76, 0), Vector3(0.27, 0.88, 0.29), Color("6b88aa"), Vector3(0, -0.44, 0))
    right_arm = _make_limb(Vector3(0.62, 1.76, 0), Vector3(0.27, 0.88, 0.29), Color("6b88aa"), Vector3(0, -0.44, 0))

    var shield := MeshInstance3D.new()
    var shield_mesh := CylinderMesh.new()
    shield_mesh.top_radius = 0.43
    shield_mesh.bottom_radius = 0.43
    shield_mesh.height = 0.12
    shield.mesh = shield_mesh
    shield.position = Vector3(0, -0.45, -0.24)
    shield.rotation_degrees.x = 90.0
    shield.material_override = _material(Color("7b5630"), 0.85)
    left_arm.add_child(shield)

    var grip := MeshInstance3D.new()
    var grip_mesh := BoxMesh.new()
    grip_mesh.size = Vector3(0.12, 0.48, 0.12)
    grip.mesh = grip_mesh
    grip.position = Vector3(0.0, -0.70, -0.05)
    grip.material_override = _material(Color("5b3824"), 1.0)
    right_arm.add_child(grip)

    var blade := MeshInstance3D.new()
    var blade_mesh := BoxMesh.new()
    blade_mesh.size = Vector3(0.10, 1.18, 0.10)
    blade.mesh = blade_mesh
    blade.position = Vector3(0.0, -1.45, -0.05)
    blade.material_override = _material(Color("c7cdd4"), 0.45)
    right_arm.add_child(blade)

    var name_label := Label3D.new()
    name_label.text = "Abenteurer"
    name_label.position = Vector3(0, 2.78, 0)
    name_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
    name_label.font_size = 24
    name_label.outline_size = 6
    model_root.add_child(name_label)

func _make_limb(pivot_pos: Vector3, size: Vector3, color: Color, mesh_offset: Vector3) -> Node3D:
    var pivot := Node3D.new()
    pivot.position = pivot_pos
    model_root.add_child(pivot)
    _add_box(pivot, size, mesh_offset, color)
    return pivot

func _add_box(parent: Node3D, size: Vector3, pos: Vector3, color: Color) -> void:
    var mesh_instance := MeshInstance3D.new()
    var mesh := BoxMesh.new()
    mesh.size = size
    mesh_instance.mesh = mesh
    mesh_instance.position = pos
    mesh_instance.material_override = _material(color, 0.85)
    parent.add_child(mesh_instance)

func _add_sphere(parent: Node3D, radius: float, pos: Vector3, color: Color) -> void:
    var mesh_instance := MeshInstance3D.new()
    var mesh := SphereMesh.new()
    mesh.radius = radius
    mesh.height = radius * 2.0
    mesh_instance.mesh = mesh
    mesh_instance.position = pos
    mesh_instance.material_override = _material(color, 0.9)
    parent.add_child(mesh_instance)

func _unhandled_input(event: InputEvent) -> void:
    if game_ref != null and game_ref.quest_panel_open:
        if event is InputEventScreenTouch and event.pressed:
            game_ref.handle_quest_panel_touch(event.position)
        elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
            game_ref.handle_quest_panel_touch(event.position)
        return

    var screen := get_viewport().get_visible_rect().size

    if event is InputEventScreenTouch:
        if event.pressed:
            if _inside_attack_button(event.position, screen):
                game_ref.perform_player_attack()
            elif _inside_jump_button(event.position, screen):
                jump_requested = true
            elif _inside_interact_button(event.position, screen):
                game_ref.try_interact()
            elif event.position.x < screen.x * 0.45 and move_touch_id == -1:
                move_touch_id = event.index
                move_origin = event.position
                move_vector = Vector2.ZERO
            elif look_touch_id == -1:
                if not game_ref.try_select_from_screen(camera, event.position):
                    look_touch_id = event.index
        else:
            if event.index == move_touch_id:
                move_touch_id = -1
                move_vector = Vector2.ZERO
            if event.index == look_touch_id:
                look_touch_id = -1

    elif event is InputEventScreenDrag:
        if event.index == move_touch_id:
            move_vector = (event.position - move_origin) / (JOYSTICK_RADIUS * _ui_scale(screen))
            move_vector = move_vector.limit_length(1.0)
        elif event.index == look_touch_id:
            yaw -= event.relative.x * LOOK_SENSITIVITY
            pitch -= event.relative.y * LOOK_SENSITIVITY
            pitch = clampf(pitch, -0.72, 0.32)

    elif event is InputEventMouseMotion and Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT):
        yaw -= event.relative.x * LOOK_SENSITIVITY
        pitch -= event.relative.y * LOOK_SENSITIVITY
        pitch = clampf(pitch, -0.72, 0.32)

    elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
        game_ref.try_select_from_screen(camera, event.position)

    elif event is InputEventKey and event.pressed and not event.echo:
        if event.keycode == KEY_F:
            game_ref.perform_player_attack()
        elif event.keycode == KEY_Q:
            game_ref.try_interact()

func _physics_process(delta: float) -> void:
    if dead:
        velocity = Vector3.ZERO
        _animate_model(delta, 0.0)
        return

    var input_vec := move_vector
    if Input.is_key_pressed(KEY_A):
        input_vec.x -= 1.0
    if Input.is_key_pressed(KEY_D):
        input_vec.x += 1.0
    if Input.is_key_pressed(KEY_W):
        input_vec.y -= 1.0
    if Input.is_key_pressed(KEY_S):
        input_vec.y += 1.0
    input_vec = input_vec.limit_length(1.0)

    var camera_basis := Basis(Vector3.UP, yaw)
    var desired := camera_basis * Vector3(input_vec.x, 0.0, input_vec.y)
    desired.y = 0.0
    if desired.length() > 0.01:
        desired = desired.normalized()
        desired_facing = atan2(-desired.x, -desired.z)

    var target_x := desired.x * MOVE_SPEED
    var target_z := desired.z * MOVE_SPEED
    velocity.x = move_toward(velocity.x, target_x, ACCELERATION * delta)
    velocity.z = move_toward(velocity.z, target_z, ACCELERATION * delta)

    if not is_on_floor():
        velocity.y -= gravity * delta
    else:
        if jump_requested or Input.is_key_pressed(KEY_SPACE):
            velocity.y = JUMP_VELOCITY
        else:
            velocity.y = -0.2
    jump_requested = false

    move_and_slide()
    camera_pivot.rotation = Vector3(pitch, yaw, 0.0)
    model_root.rotation.y = lerp_angle(model_root.rotation.y, desired_facing, minf(1.0, delta * 10.0))
    _animate_model(delta, Vector2(velocity.x, velocity.z).length())

func _animate_model(delta: float, speed: float) -> void:
    attack_anim_time = maxf(0.0, attack_anim_time - delta)
    if speed > 0.35 and is_on_floor() and not dead:
        walk_phase += delta * 9.0
        var swing := sin(walk_phase) * 0.55
        left_leg.rotation.x = lerpf(left_leg.rotation.x, swing, minf(1.0, delta * 14.0))
        right_leg.rotation.x = lerpf(right_leg.rotation.x, -swing, minf(1.0, delta * 14.0))
        if attack_anim_time <= 0.0:
            left_arm.rotation.x = lerpf(left_arm.rotation.x, -swing * 0.55, minf(1.0, delta * 14.0))
            right_arm.rotation.x = lerpf(right_arm.rotation.x, swing * 0.55, minf(1.0, delta * 14.0))
    else:
        left_leg.rotation.x = lerpf(left_leg.rotation.x, 0.0, minf(1.0, delta * 12.0))
        right_leg.rotation.x = lerpf(right_leg.rotation.x, 0.0, minf(1.0, delta * 12.0))
        if attack_anim_time <= 0.0:
            left_arm.rotation.x = lerpf(left_arm.rotation.x, 0.0, minf(1.0, delta * 12.0))
            right_arm.rotation.x = lerpf(right_arm.rotation.x, 0.0, minf(1.0, delta * 12.0))
            right_arm.rotation.z = lerpf(right_arm.rotation.z, 0.0, minf(1.0, delta * 12.0))

    if attack_anim_time > 0.0:
        var t := 1.0 - attack_anim_time / 0.36
        var slash := sin(t * PI)
        right_arm.rotation.x = -0.45 - slash * 1.0
        right_arm.rotation.z = -slash * 0.95

func play_attack() -> void:
    attack_anim_time = 0.36

func face_world_position(world_pos: Vector3) -> void:
    var direction := world_pos - global_position
    direction.y = 0.0
    if direction.length() > 0.01:
        desired_facing = atan2(-direction.x, -direction.z)
        model_root.rotation.y = desired_facing

func take_damage(amount: int) -> void:
    if dead:
        return
    health = maxi(0, health - amount)
    if health <= 0:
        _die()

func _die() -> void:
    dead = true
    cancel_touches()
    game_ref.show_toast("Du wurdest besiegt · Wiederbelebung...", 2.2)
    await get_tree().create_timer(2.2).timeout
    global_position = Vector3(0.0, 0.05, 8.0)
    health = max_health
    dead = false
    game_ref.select_target(null)
    game_ref.show_toast("Wiederbelebt in Ravenfall", 1.8)

func set_max_health(value: int, heal_full: bool = false) -> void:
    max_health = value
    if heal_full:
        health = max_health
    else:
        health = mini(health, max_health)

func cancel_touches() -> void:
    move_touch_id = -1
    look_touch_id = -1
    move_vector = Vector2.ZERO

func _inside_jump_button(pos: Vector2, screen: Vector2) -> bool:
    var scale := _ui_scale(screen)
    return pos.distance_to(Vector2(screen.x - 300.0 * scale, screen.y - 100.0 * scale)) <= 68.0 * scale

func _inside_attack_button(pos: Vector2, screen: Vector2) -> bool:
    var scale := _ui_scale(screen)
    return pos.distance_to(Vector2(screen.x - 130.0 * scale, screen.y - 135.0 * scale)) <= 82.0 * scale

func _inside_interact_button(pos: Vector2, screen: Vector2) -> bool:
    var scale := _ui_scale(screen)
    return pos.distance_to(Vector2(screen.x - 145.0 * scale, screen.y - 320.0 * scale)) <= 70.0 * scale

func _ui_scale(screen: Vector2) -> float:
    return clampf(screen.y / 720.0, 0.85, 1.55)

func _material(color: Color, roughness: float) -> StandardMaterial3D:
    var mat := StandardMaterial3D.new()
    mat.albedo_color = color
    mat.roughness = roughness
    return mat
