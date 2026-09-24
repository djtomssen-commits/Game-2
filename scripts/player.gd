extends CharacterBody3D

const MOVE_SPEED := 6.0
const ACCELERATION := 20.0
const JUMP_VELOCITY := 7.0
const LOOK_SENSITIVITY := 0.005
const JOYSTICK_RADIUS := 120.0

var gravity: float = 18.0
var yaw := 0.0
var pitch := -0.22
var move_touch_id := -1
var look_touch_id := -1
var move_origin := Vector2.ZERO
var move_vector := Vector2.ZERO
var jump_requested := false

var camera_pivot: Node3D
var camera: Camera3D

func _ready() -> void:
    gravity = float(ProjectSettings.get_setting("physics/3d/default_gravity", 18.0))
    camera_pivot = Node3D.new()
    camera_pivot.name = "CameraPivot"
    camera_pivot.position = Vector3(0.0, 1.45, 0.0)
    add_child(camera_pivot)

    camera = Camera3D.new()
    camera.name = "ThirdPersonCamera"
    camera.position = Vector3(0.0, 1.2, 5.6)
    camera.current = true
    camera.fov = 68.0
    camera_pivot.add_child(camera)

    Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func _unhandled_input(event: InputEvent) -> void:
    var screen := get_viewport().get_visible_rect().size

    if event is InputEventScreenTouch:
        if event.pressed:
            if _inside_jump_button(event.position, screen):
                jump_requested = true
            elif event.position.x < screen.x * 0.45 and move_touch_id == -1:
                move_touch_id = event.index
                move_origin = event.position
                move_vector = Vector2.ZERO
            elif look_touch_id == -1:
                look_touch_id = event.index
        else:
            if event.index == move_touch_id:
                move_touch_id = -1
                move_vector = Vector2.ZERO
            if event.index == look_touch_id:
                look_touch_id = -1

    elif event is InputEventScreenDrag:
        if event.index == move_touch_id:
            move_vector = (event.position - move_origin) / JOYSTICK_RADIUS
            move_vector = move_vector.limit_length(1.0)
        elif event.index == look_touch_id:
            yaw -= event.relative.x * LOOK_SENSITIVITY
            pitch -= event.relative.y * LOOK_SENSITIVITY
            pitch = clamp(pitch, -0.75, 0.35)

    elif event is InputEventMouseMotion and Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT):
        yaw -= event.relative.x * LOOK_SENSITIVITY
        pitch -= event.relative.y * LOOK_SENSITIVITY
        pitch = clamp(pitch, -0.75, 0.35)

func _physics_process(delta: float) -> void:
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

func _inside_jump_button(pos: Vector2, screen: Vector2) -> bool:
    var center := Vector2(screen.x - 120.0, screen.y - 120.0)
    return pos.distance_to(center) <= 88.0
