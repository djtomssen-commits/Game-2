extends Control

var player

func _ready() -> void:
    queue_redraw()

func _process(_delta: float) -> void:
    queue_redraw()

func _draw() -> void:
    var screen := size
    if screen.x <= 0.0 or screen.y <= 0.0:
        return

    var joystick_center := Vector2(135.0, screen.y - 135.0)
    var thumb := joystick_center

    if player != null and is_instance_valid(player) and player.move_touch_id != -1:
        joystick_center = player.move_origin
        thumb = joystick_center + player.move_vector * 75.0

    draw_circle(joystick_center, 92.0, Color(0.02, 0.04, 0.07, 0.30))
    draw_circle(joystick_center, 90.0, Color(0.75, 0.82, 0.88, 0.13))
    draw_circle(thumb, 38.0, Color(0.85, 0.90, 0.95, 0.42))

    var jump_center := Vector2(screen.x - 120.0, screen.y - 120.0)
    draw_circle(jump_center, 72.0, Color(0.12, 0.18, 0.27, 0.52))
    draw_circle(jump_center, 68.0, Color(0.28, 0.50, 0.77, 0.45))

    var font := ThemeDB.fallback_font
    draw_string(font, Vector2(32, 48), "ELDORIA ONLINE  ·  PROTOTYP V0.1", HORIZONTAL_ALIGNMENT_LEFT, -1, 28, Color.WHITE)
    draw_string(font, Vector2(32, 78), "Ravenfall · Testgebiet", HORIZONTAL_ALIGNMENT_LEFT, -1, 20, Color(0.86, 0.92, 1.0))
    draw_string(font, jump_center + Vector2(-35, 7), "SPRUNG", HORIZONTAL_ALIGNMENT_LEFT, -1, 17, Color.WHITE)
    draw_string(font, Vector2(screen.x - 310, 46), "Kamera: rechts wischen", HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color(0.9, 0.94, 1.0))
