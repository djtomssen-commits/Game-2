extends Control

var player
var game

func _ready() -> void:
    queue_redraw()

func _process(_delta: float) -> void:
    queue_redraw()

func _draw() -> void:
    var screen := size
    if screen.x <= 0.0 or screen.y <= 0.0 or player == null or game == null:
        return

    var scale := clampf(screen.y / 720.0, 0.85, 1.55)
    var font := ThemeDB.fallback_font

    _draw_player_frame(font, scale)
    _draw_target_frame(font, scale)
    _draw_quest_tracker(font, scale)
    _draw_controls(font, scale)

    if game.toast_time > 0.0 and not game.toast_text.is_empty():
        var toast_w := minf(720.0 * scale, screen.x * 0.68)
        var toast_rect := Rect2(Vector2((screen.x - toast_w) * 0.5, screen.y * 0.16), Vector2(toast_w, 48.0 * scale))
        draw_rect(toast_rect, Color(0.02, 0.03, 0.05, 0.82), true)
        draw_rect(toast_rect, Color(0.72, 0.58, 0.25, 0.9), false, 2.0)
        draw_string(font, toast_rect.position + Vector2(16.0 * scale, 31.0 * scale), game.toast_text, HORIZONTAL_ALIGNMENT_CENTER, toast_rect.size.x - 32.0 * scale, int(19 * scale), Color.WHITE)

    if game.quest_panel_open:
        _draw_quest_panel(font, scale)

func _draw_player_frame(font: Font, scale: float) -> void:
    var panel := Rect2(Vector2(22.0 * scale, 20.0 * scale), Vector2(330.0 * scale, 104.0 * scale))
    draw_rect(panel, Color(0.015, 0.025, 0.045, 0.82), true)
    draw_rect(panel, Color(0.48, 0.58, 0.68, 0.75), false, 2.0)
    draw_string(font, panel.position + Vector2(14, 25) * scale, "Abenteurer · Stufe %d" % game.level, HORIZONTAL_ALIGNMENT_LEFT, -1, int(20 * scale), Color.WHITE)

    var hp_back := Rect2(panel.position + Vector2(14, 38) * scale, Vector2(300, 22) * scale)
    var hp_ratio := float(player.health) / float(maxi(1, player.max_health))
    draw_rect(hp_back, Color(0.12, 0.04, 0.04, 0.9), true)
    draw_rect(Rect2(hp_back.position, Vector2(hp_back.size.x * hp_ratio, hp_back.size.y)), Color(0.70, 0.12, 0.10, 0.95), true)
    draw_string(font, hp_back.position + Vector2(8, 17) * scale, "%d / %d LP" % [player.health, player.max_health], HORIZONTAL_ALIGNMENT_LEFT, -1, int(15 * scale), Color.WHITE)

    var xp_back := Rect2(panel.position + Vector2(14, 68) * scale, Vector2(300, 13) * scale)
    var xp_ratio := float(game.xp) / float(maxi(1, game.get_xp_required()))
    draw_rect(xp_back, Color(0.05, 0.08, 0.13, 0.9), true)
    draw_rect(Rect2(xp_back.position, Vector2(xp_back.size.x * xp_ratio, xp_back.size.y)), Color(0.25, 0.48, 0.78, 0.95), true)
    draw_string(font, panel.position + Vector2(14, 98) * scale, "Gold %d   ·   Wolfspelze %d" % [game.gold, game.pelts], HORIZONTAL_ALIGNMENT_LEFT, -1, int(15 * scale), Color("f0d28a"))

func _draw_target_frame(font: Font, scale: float) -> void:
    if game.current_target == null or not is_instance_valid(game.current_target):
        return
    var target = game.current_target
    var width := 330.0 * scale
    var panel := Rect2(Vector2((size.x - width) * 0.5, 22.0 * scale), Vector2(width, 70.0 * scale))
    draw_rect(panel, Color(0.035, 0.025, 0.025, 0.84), true)
    draw_rect(panel, Color(0.72, 0.35, 0.22, 0.85), false, 2.0)
    draw_string(font, panel.position + Vector2(14, 25) * scale, "Wolf · Stufe 1", HORIZONTAL_ALIGNMENT_LEFT, -1, int(19 * scale), Color.WHITE)
    var hp_back := Rect2(panel.position + Vector2(14, 38) * scale, Vector2(302, 20) * scale)
    draw_rect(hp_back, Color(0.12, 0.04, 0.04, 0.92), true)
    draw_rect(Rect2(hp_back.position, Vector2(hp_back.size.x * target.get_health_ratio(), hp_back.size.y)), Color(0.66, 0.10, 0.08, 0.96), true)
    draw_string(font, hp_back.position + Vector2(8, 16) * scale, "%d / %d" % [target.health, target.max_health], HORIZONTAL_ALIGNMENT_LEFT, -1, int(14 * scale), Color.WHITE)

func _draw_quest_tracker(font: Font, scale: float) -> void:
    var panel_size := Vector2(350, 105) * scale
    var panel := Rect2(Vector2(size.x - panel_size.x - 22.0 * scale, 22.0 * scale), panel_size)
    draw_rect(panel, Color(0.02, 0.03, 0.05, 0.76), true)
    draw_rect(panel, Color(0.60, 0.48, 0.22, 0.72), false, 2.0)
    draw_string(font, panel.position + Vector2(14, 25) * scale, "AUFTRAG", HORIZONTAL_ALIGNMENT_LEFT, -1, int(18 * scale), Color("f1cf7a"))
    draw_string(font, panel.position + Vector2(14, 53) * scale, "Wölfe vor den Toren", HORIZONTAL_ALIGNMENT_LEFT, -1, int(18 * scale), Color.WHITE)
    draw_string(font, panel.position + Vector2(14, 82) * scale, game.get_quest_tracker_text(), HORIZONTAL_ALIGNMENT_LEFT, panel.size.x - 28 * scale, int(15 * scale), Color("d8e1eb"))

func _draw_controls(font: Font, scale: float) -> void:
    var joystick_center := Vector2(135.0 * scale, size.y - 135.0 * scale)
    var thumb := joystick_center
    if player.move_touch_id != -1:
        joystick_center = player.move_origin
        thumb = joystick_center + player.move_vector * 75.0 * scale
    draw_circle(joystick_center, 92.0 * scale, Color(0.02, 0.04, 0.07, 0.34))
    draw_circle(joystick_center, 88.0 * scale, Color(0.72, 0.80, 0.90, 0.13))
    draw_circle(thumb, 38.0 * scale, Color(0.86, 0.91, 0.96, 0.44))

    var attack_center := Vector2(size.x - 130.0 * scale, size.y - 135.0 * scale)
    draw_circle(attack_center, 82.0 * scale, Color(0.18, 0.04, 0.03, 0.70))
    draw_circle(attack_center, 76.0 * scale, Color(0.68, 0.16, 0.10, 0.72))
    draw_string(font, attack_center + Vector2(-45, 7) * scale, "ANGRIFF", HORIZONTAL_ALIGNMENT_LEFT, -1, int(17 * scale), Color.WHITE)

    var jump_center := Vector2(size.x - 300.0 * scale, size.y - 100.0 * scale)
    draw_circle(jump_center, 68.0 * scale, Color(0.08, 0.13, 0.20, 0.68))
    draw_circle(jump_center, 62.0 * scale, Color(0.24, 0.43, 0.67, 0.66))
    draw_string(font, jump_center + Vector2(-34, 7) * scale, "SPRUNG", HORIZONTAL_ALIGNMENT_LEFT, -1, int(15 * scale), Color.WHITE)

    if game.is_player_near_npc():
        var interact_center := Vector2(size.x - 145.0 * scale, size.y - 320.0 * scale)
        draw_circle(interact_center, 70.0 * scale, Color(0.12, 0.10, 0.035, 0.74))
        draw_circle(interact_center, 64.0 * scale, Color(0.66, 0.48, 0.11, 0.73))
        draw_string(font, interact_center + Vector2(-29, 6) * scale, "REDEN", HORIZONTAL_ALIGNMENT_LEFT, -1, int(15 * scale), Color.WHITE)

    draw_string(font, Vector2(24, size.y - 22) * Vector2(scale, 1.0), "Links: bewegen  ·  Rechts wischen: Kamera  ·  Gegner antippen: anwählen", HORIZONTAL_ALIGNMENT_LEFT, -1, int(14 * scale), Color(0.91, 0.94, 0.98, 0.75))

func _draw_quest_panel(font: Font, scale: float) -> void:
    draw_rect(Rect2(Vector2.ZERO, size), Color(0.0, 0.0, 0.0, 0.46), true)
    var panel: Rect2 = game.get_quest_panel_rect()
    draw_rect(panel, Color(0.045, 0.055, 0.07, 0.98), true)
    draw_rect(panel, Color(0.64, 0.50, 0.22, 0.95), false, 3.0)
    draw_string(font, panel.position + Vector2(28, 46) * scale, "HAUPTMANN ARLEN", HORIZONTAL_ALIGNMENT_LEFT, -1, int(16 * scale), Color("d4b56a"))
    draw_string(font, panel.position + Vector2(28, 83) * scale, game.get_quest_title(), HORIZONTAL_ALIGNMENT_LEFT, -1, int(28 * scale), Color.WHITE)

    var lines: PackedStringArray = game.get_quest_body_lines()
    var y := panel.position.y + 128.0 * scale
    for line in lines:
        draw_string(font, Vector2(panel.position.x + 28.0 * scale, y), line, HORIZONTAL_ALIGNMENT_LEFT, panel.size.x - 56.0 * scale, int(17 * scale), Color("e0e5eb"))
        y += 34.0 * scale

    var button: Rect2 = game.get_quest_button_rect()
    draw_rect(button, Color(0.44, 0.29, 0.09, 0.98), true)
    draw_rect(button, Color(0.86, 0.66, 0.24, 0.98), false, 2.0)
    draw_string(font, button.position + Vector2(12, 34) * scale, game.get_quest_button_text(), HORIZONTAL_ALIGNMENT_CENTER, button.size.x - 24.0 * scale, int(18 * scale), Color.WHITE)

    var close_button: Rect2 = game.get_quest_close_rect()
    draw_rect(close_button, Color(0.18, 0.19, 0.21, 0.96), true)
    draw_string(font, close_button.position + Vector2(13, 29) * scale, "X", HORIZONTAL_ALIGNMENT_LEFT, -1, int(19 * scale), Color.WHITE)
