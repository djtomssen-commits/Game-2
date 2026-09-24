extends Control

var player
var game

var player_panel: Panel
var player_title: Label
var hp_bar: ProgressBar
var rage_bar: ProgressBar
var player_status: Label

var target_panel: Panel
var target_title: Label
var target_hp: ProgressBar

var quest_tracker: Panel
var quest_title: Label
var quest_text: Label

var minimap_panel: Panel
var minimap_title: Label
var minimap_info: Label

var joystick_base: Panel
var joystick_thumb: Panel
var attack_button: Panel
var attack_label: Label
var skill1_button: Panel
var skill1_label: Label
var skill2_button: Panel
var skill2_label: Label
var jump_button: Panel
var jump_label: Label
var talk_button: Panel
var talk_label: Label
var potion_button: Panel
var potion_label: Label

var xp_bar: ProgressBar
var xp_label: Label
var inventory_button: Panel
var inventory_label: Label
var version_label: Label

var toast_panel: Panel
var toast_label: Label
var loot_panel: Panel
var loot_label: Label

var quest_overlay: ColorRect
var quest_panel: Panel
var quest_panel_title: Label
var quest_panel_heading: Label
var quest_panel_body: Label
var quest_panel_button: Panel
var quest_panel_button_label: Label
var quest_panel_close: Label

var inventory_overlay: ColorRect
var inventory_panel: Panel
var inventory_heading: Label
var inventory_equipped: Label
var inventory_items: Label
var inventory_auto: Panel
var inventory_auto_label: Label
var inventory_close: Label

var _last_viewport_size := Vector2.ZERO

func _ready() -> void:
    mouse_filter = Control.MOUSE_FILTER_IGNORE
    process_mode = Node.PROCESS_MODE_ALWAYS
    visible = true
    _build_ui()
    _sync_root_to_viewport()
    _layout()

func _process(_delta: float) -> void:
    if player == null or game == null:
        return
    var vp := get_viewport_rect().size
    if vp != _last_viewport_size:
        _sync_root_to_viewport()
        _layout()
    _update_ui()

func _sync_root_to_viewport() -> void:
    _last_viewport_size = get_viewport_rect().size
    position = Vector2.ZERO
    size = _last_viewport_size

func _style(bg: Color, border: Color, radius: int = 8, border_width: int = 2) -> StyleBoxFlat:
    var s := StyleBoxFlat.new()
    s.bg_color = bg
    s.border_color = border
    s.border_width_left = border_width
    s.border_width_top = border_width
    s.border_width_right = border_width
    s.border_width_bottom = border_width
    s.corner_radius_top_left = radius
    s.corner_radius_top_right = radius
    s.corner_radius_bottom_left = radius
    s.corner_radius_bottom_right = radius
    return s

func _circle_style(bg: Color, border: Color) -> StyleBoxFlat:
    return _style(bg, border, 999, 3)

func _panel_node(parent: Node, name_value: String, bg: Color, border: Color, radius: int = 8) -> Panel:
    var p := Panel.new()
    p.name = name_value
    p.mouse_filter = Control.MOUSE_FILTER_IGNORE
    p.add_theme_stylebox_override("panel", _style(bg, border, radius, 2))
    parent.add_child(p)
    return p

func _label_node(parent: Node, name_value: String, font_size: int = 16, color: Color = Color.WHITE) -> Label:
    var l := Label.new()
    l.name = name_value
    l.mouse_filter = Control.MOUSE_FILTER_IGNORE
    l.add_theme_font_size_override("font_size", font_size)
    l.add_theme_color_override("font_color", color)
    l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    parent.add_child(l)
    return l

func _progress_node(parent: Node, bg: Color, fill: Color) -> ProgressBar:
    var p := ProgressBar.new()
    p.mouse_filter = Control.MOUSE_FILTER_IGNORE
    p.show_percentage = false
    p.min_value = 0.0
    p.max_value = 100.0
    p.value = 100.0
    p.add_theme_stylebox_override("background", _style(bg, Color(0,0,0,0), 4, 0))
    p.add_theme_stylebox_override("fill", _style(fill, Color(0,0,0,0), 4, 0))
    parent.add_child(p)
    return p

func _visual_button(parent: Node, name_value: String, text_value: String, bg: Color, border: Color, font_size: int) -> Array:
    var p := Panel.new()
    p.name = name_value
    p.mouse_filter = Control.MOUSE_FILTER_IGNORE
    p.add_theme_stylebox_override("panel", _circle_style(bg, border))
    parent.add_child(p)
    var l := _label_node(p, name_value + "Label", font_size, Color.WHITE)
    l.text = text_value
    l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    l.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    return [p, l]

func _build_ui() -> void:
    player_panel = _panel_node(self, "PlayerPanel", Color(0.015,0.025,0.04,0.91), Color(0.40,0.55,0.70,0.90), 10)
    player_title = _label_node(player_panel, "PlayerTitle", 18)
    hp_bar = _progress_node(player_panel, Color(0.12,0.03,0.03,0.96), Color(0.72,0.08,0.07,0.98))
    rage_bar = _progress_node(player_panel, Color(0.12,0.07,0.02,0.96), Color(0.86,0.42,0.05,0.98))
    player_status = _label_node(player_panel, "PlayerStatus", 13, Color("efd28d"))

    target_panel = _panel_node(self, "TargetPanel", Color(0.04,0.018,0.018,0.92), Color(0.72,0.25,0.16,0.94), 9)
    target_title = _label_node(target_panel, "TargetTitle", 17)
    target_hp = _progress_node(target_panel, Color(0.12,0.03,0.03,0.96), Color(0.67,0.06,0.05,0.98))

    quest_tracker = _panel_node(self, "QuestTracker", Color(0.02,0.03,0.05,0.88), Color(0.60,0.48,0.22,0.84), 9)
    quest_title = _label_node(quest_tracker, "QuestTitle", 16, Color("f1cf7a"))
    quest_text = _label_node(quest_tracker, "QuestText", 13, Color("d8e1eb"))
    quest_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART

    minimap_panel = _panel_node(self, "MiniMap", Color(0.03,0.08,0.04,0.86), Color(0.63,0.52,0.27,0.92), 999)
    minimap_title = _label_node(minimap_panel, "MiniMapTitle", 11, Color("ead89c"))
    minimap_title.text = "KARTE"
    minimap_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    minimap_info = _label_node(minimap_panel, "MiniMapInfo", 11, Color.WHITE)
    minimap_info.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

    var jb := _visual_button(self, "JoystickBase", "", Color(0.10,0.14,0.18,0.30), Color(0.65,0.75,0.84,0.28), 12)
    joystick_base = jb[0]
    joystick_thumb = Panel.new()
    joystick_thumb.mouse_filter = Control.MOUSE_FILTER_IGNORE
    joystick_thumb.add_theme_stylebox_override("panel", _circle_style(Color(0.84,0.90,0.96,0.45), Color(0.95,0.98,1.0,0.45)))
    joystick_base.add_child(joystick_thumb)

    var ab := _visual_button(self, "AttackButton", "ANGRIFF", Color(0.64,0.12,0.08,0.90), Color(0.95,0.45,0.25,0.96), 14)
    attack_button = ab[0]; attack_label = ab[1]
    var s1 := _visual_button(self, "Skill1Button", "HIEB", Color(0.53,0.30,0.10,0.90), Color(0.86,0.61,0.25,0.96), 13)
    skill1_button = s1[0]; skill1_label = s1[1]
    var s2 := _visual_button(self, "Skill2Button", "WIRBEL", Color(0.42,0.28,0.12,0.90), Color(0.76,0.53,0.25,0.96), 12)
    skill2_button = s2[0]; skill2_label = s2[1]
    var jb2 := _visual_button(self, "JumpButton", "SPRUNG", Color(0.15,0.31,0.49,0.90), Color(0.40,0.65,0.88,0.96), 12)
    jump_button = jb2[0]; jump_label = jb2[1]
    var tb := _visual_button(self, "TalkButton", "REDEN", Color(0.56,0.41,0.08,0.92), Color(0.91,0.70,0.22,0.98), 12)
    talk_button = tb[0]; talk_label = tb[1]
    var pb := _visual_button(self, "PotionButton", "TRANK", Color(0.17,0.45,0.24,0.92), Color(0.48,0.88,0.52,0.98), 12)
    potion_button = pb[0]; potion_label = pb[1]

    xp_bar = _progress_node(self, Color(0.02,0.04,0.08,0.92), Color(0.21,0.43,0.82,0.98))
    xp_label = _label_node(self, "XPLabel", 10, Color("e6edf8"))
    xp_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

    inventory_button = _panel_node(self, "InventoryButton", Color(0.04,0.06,0.08,0.91), Color(0.62,0.51,0.26,0.95), 8)
    inventory_label = _label_node(inventory_button, "InventoryLabel", 12, Color("ead69b"))
    inventory_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    inventory_label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

    version_label = _label_node(self, "Version", 10, Color(1,1,1,0.58))
    version_label.text = "ELDORIA ONLINE · V0.5 · KAPITEL II"

    toast_panel = _panel_node(self, "ToastPanel", Color(0.02,0.03,0.05,0.92), Color(0.73,0.58,0.24,0.94), 8)
    toast_label = _label_node(toast_panel, "ToastLabel", 16)
    toast_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    toast_label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

    loot_panel = _panel_node(self, "LootPanel", Color(0.04,0.06,0.03,0.90), Color(0.45,0.67,0.28,0.92), 8)
    loot_label = _label_node(loot_panel, "LootLabel", 14, Color("d9efb4"))
    loot_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    loot_label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

    quest_overlay = ColorRect.new()
    quest_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
    quest_overlay.color = Color(0,0,0,0.52)
    add_child(quest_overlay)
    quest_panel = _panel_node(quest_overlay, "QuestPanel", Color(0.035,0.045,0.06,0.99), Color(0.76,0.58,0.22,0.98), 10)
    quest_panel_title = _label_node(quest_panel, "QuestNpc", 14, Color("d8b96e"))
    quest_panel_title.text = "HAUPTMANN ARLEN"
    quest_panel_heading = _label_node(quest_panel, "QuestHeading", 25)
    quest_panel_body = _label_node(quest_panel, "QuestBody", 16, Color("e0e5eb"))
    quest_panel_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    quest_panel_button = _panel_node(quest_panel, "QuestAction", Color(0.46,0.30,0.08,0.99), Color(0.88,0.68,0.24,0.99), 8)
    quest_panel_button_label = _label_node(quest_panel_button, "QuestActionLabel", 16)
    quest_panel_button_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    quest_panel_button_label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    quest_panel_close = _label_node(quest_panel, "QuestClose", 20)
    quest_panel_close.text = "✕"
    quest_panel_close.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

    inventory_overlay = ColorRect.new()
    inventory_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
    inventory_overlay.color = Color(0,0,0,0.56)
    add_child(inventory_overlay)
    inventory_panel = _panel_node(inventory_overlay, "InventoryPanel", Color(0.025,0.035,0.05,0.99), Color(0.50,0.58,0.68,0.96), 10)
    inventory_heading = _label_node(inventory_panel, "InventoryHeading", 23)
    inventory_heading.text = "ABENTEURER-TASCHE"
    inventory_equipped = _label_node(inventory_panel, "InventoryEquipped", 14, Color("ead69b"))
    inventory_items = _label_node(inventory_panel, "InventoryItems", 14, Color("dfe7f0"))
    inventory_items.vertical_alignment = VERTICAL_ALIGNMENT_TOP
    inventory_items.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    inventory_auto = _panel_node(inventory_panel, "InventoryAuto", Color(0.17,0.28,0.39,0.99), Color(0.45,0.68,0.88,0.99), 8)
    inventory_auto_label = _label_node(inventory_auto, "InventoryAutoLabel", 14)
    inventory_auto_label.text = "BESTE AUSRÜSTUNG ANLEGEN"
    inventory_auto_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    inventory_auto_label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    inventory_close = _label_node(inventory_panel, "InventoryClose", 20)
    inventory_close.text = "✕"
    inventory_close.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

func _layout() -> void:
    if size.x <= 0.0 or size.y <= 0.0:
        return
    var s := clampf(size.y / 720.0, 0.85, 1.55)

    player_panel.position = Vector2(18,18) * s
    player_panel.size = Vector2(350,122) * s
    player_title.position = Vector2(18,8) * s
    player_title.size = Vector2(315,28) * s
    hp_bar.position = Vector2(18,39) * s
    hp_bar.size = Vector2(314,22) * s
    rage_bar.position = Vector2(18,68) * s
    rage_bar.size = Vector2(314,15) * s
    player_status.position = Vector2(18,87) * s
    player_status.size = Vector2(314,27) * s

    var tw := 310.0 * s
    target_panel.position = Vector2((size.x - tw) * 0.5, 18*s)
    target_panel.size = Vector2(tw,70*s)
    target_title.position = Vector2(14,5) * s
    target_title.size = Vector2(282,27) * s
    target_hp.position = Vector2(14,38) * s
    target_hp.size = Vector2(282,20) * s

    minimap_panel.position = Vector2(size.x-150*s,18*s)
    minimap_panel.size = Vector2(132,132) * s
    minimap_title.position = Vector2(8,7) * s
    minimap_title.size = Vector2(116,20) * s
    minimap_info.position = Vector2(12,42) * s
    minimap_info.size = Vector2(108,65) * s

    quest_tracker.position = Vector2(size.x-345*s,164*s)
    quest_tracker.size = Vector2(327,100) * s
    quest_title.position = Vector2(12,8) * s
    quest_title.size = Vector2(302,28) * s
    quest_text.position = Vector2(12,37) * s
    quest_text.size = Vector2(302,54) * s

    joystick_base.position = Vector2(38*s, size.y-198*s)
    joystick_base.size = Vector2(160,160) * s
    joystick_thumb.size = Vector2(62,62) * s

    attack_button.position = Vector2(size.x-188*s, size.y-194*s)
    attack_button.size = Vector2(156,156) * s
    skill1_button.position = Vector2(size.x-302*s, size.y-135*s)
    skill1_button.size = Vector2(120,120) * s
    skill2_button.position = Vector2(size.x-290*s, size.y-276*s)
    skill2_button.size = Vector2(120,120) * s
    jump_button.position = Vector2(size.x-164*s, size.y-326*s)
    jump_button.size = Vector2(108,108) * s
    talk_button.position = Vector2(size.x-164*s, size.y-438*s)
    talk_button.size = Vector2(108,108) * s
    potion_button.position = Vector2(size.x-413*s, size.y-270*s)
    potion_button.size = Vector2(116,116) * s

    xp_bar.position = Vector2(size.x*0.22, size.y-17*s)
    xp_bar.size = Vector2(size.x*0.56, 10*s)
    xp_label.position = Vector2(size.x*0.22, size.y-38*s)
    xp_label.size = Vector2(size.x*0.56, 20*s)

    inventory_button.position = Vector2(18*s, 150*s)
    inventory_button.size = Vector2(145,42) * s

    version_label.position = Vector2(12*s, size.y-26*s)
    version_label.size = Vector2(220,20) * s

    toast_panel.position = Vector2(size.x*0.24, size.y*0.14)
    toast_panel.size = Vector2(size.x*0.52, 45*s)
    loot_panel.position = Vector2(size.x*0.34, size.y*0.24)
    loot_panel.size = Vector2(size.x*0.32, 38*s)

    quest_overlay.position = Vector2.ZERO
    quest_overlay.size = size
    inventory_overlay.position = Vector2.ZERO
    inventory_overlay.size = size
    _layout_quest_overlay(s)
    _layout_inventory_overlay(s)

func _layout_quest_overlay(s: float) -> void:
    if game == null:
        return
    var r: Rect2 = game.get_quest_panel_rect()
    quest_panel.position = r.position
    quest_panel.size = r.size
    quest_panel_title.position = Vector2(28,14) * s
    quest_panel_title.size = Vector2(r.size.x/s-56,30) * s
    quest_panel_heading.position = Vector2(28,48) * s
    quest_panel_heading.size = Vector2(r.size.x/s-56,44) * s
    quest_panel_body.position = Vector2(28,102) * s
    quest_panel_body.size = Vector2(r.size.x/s-56,170) * s
    var b: Rect2 = game.get_quest_button_rect()
    quest_panel_button.position = b.position - r.position
    quest_panel_button.size = b.size
    var c: Rect2 = game.get_quest_close_rect()
    quest_panel_close.position = c.position - r.position
    quest_panel_close.size = c.size

func _layout_inventory_overlay(s: float) -> void:
    if game == null:
        return
    var r: Rect2 = game.get_inventory_panel_rect()
    inventory_panel.position = r.position
    inventory_panel.size = r.size
    inventory_heading.position = Vector2(28,10) * s
    inventory_heading.size = Vector2(r.size.x/s-56,42) * s
    inventory_equipped.position = Vector2(28,52) * s
    inventory_equipped.size = Vector2(r.size.x/s-56,34) * s
    inventory_items.position = Vector2(28,92) * s
    inventory_items.size = Vector2(r.size.x/s-56,270) * s
    var a: Rect2 = game.get_inventory_auto_rect()
    inventory_auto.position = a.position - r.position
    inventory_auto.size = a.size
    var c: Rect2 = game.get_inventory_close_rect()
    inventory_close.position = c.position - r.position
    inventory_close.size = c.size

func _update_ui() -> void:
    player_title.text = "Abenteurer · Stufe %d" % game.level
    hp_bar.max_value = maxf(1.0, float(player.max_health))
    hp_bar.value = float(player.health)
    rage_bar.max_value = maxf(1.0, float(game.max_rage))
    rage_bar.value = float(game.rage)
    player_status.text = "%d/%d LP · Gold %d · Wut %d · Angriff +%d · Rüstung %d" % [player.health, player.max_health, game.gold, game.rage, game.get_weapon_power(), game.get_armor_value()]

    var t = game.current_target
    var valid_target := t != null and is_instance_valid(t) and t.is_alive_enemy()
    target_panel.visible = valid_target
    if valid_target:
        target_title.text = "%s · Stufe %d" % [t.get_enemy_display_name(), t.get_enemy_level()]
        target_hp.max_value = maxf(1.0, float(t.max_health))
        target_hp.value = float(t.health)

    quest_title.text = "AUFTRAG · " + game.get_quest_title()
    quest_text.text = game.get_quest_tracker_text()

    var alive_count := 0
    for e in game.enemies:
        if e != null and is_instance_valid(e) and e.is_alive_enemy() and player.global_position.distance_to(e.global_position) < 65.0:
            alive_count += 1
    minimap_info.text = "%s\nFeinde: %d\nZiel: %s" % [game.get_current_zone_name(), alive_count, game.get_objective_distance_text()]

    var s := clampf(size.y / 720.0, 0.85, 1.55)
    var base_center := joystick_base.position + joystick_base.size * 0.5
    var thumb_center := base_center
    if player.move_touch_id != -1:
        var desired := player.move_origin + player.move_vector * 68.0 * s
        thumb_center = desired
    joystick_thumb.position = thumb_center - joystick_base.position - joystick_thumb.size*0.5

    skill1_label.text = "HIEB" if game.skill1_cd <= 0.0 else "HIEB\n%.1f" % game.skill1_cd
    skill2_label.text = "WIRBEL" if game.skill2_cd <= 0.0 else "WIRBEL\n%.1f" % game.skill2_cd
    talk_button.visible = game.is_interaction_available()
    talk_label.text = game.get_interact_label()
    potion_label.text = "TRANK\n%d" % game.potions if game.potion_cd <= 0.0 else "TRANK\n%.0fs" % game.potion_cd

    xp_bar.max_value = maxf(1.0, float(game.get_xp_required()))
    xp_bar.value = float(game.xp)
    xp_label.text = "EP %d / %d" % [game.xp, game.get_xp_required()]
    inventory_label.text = "TASCHE [%d]" % game.inventory.size()

    toast_panel.visible = game.toast_time > 0.0 and not game.toast_text.is_empty()
    toast_label.text = game.toast_text
    loot_panel.visible = game.loot_time > 0.0 and not game.loot_text.is_empty()
    loot_label.text = game.loot_text

    quest_overlay.visible = game.quest_panel_open
    if game.quest_panel_open:
        quest_panel_heading.text = game.get_quest_title()
        quest_panel_body.text = "\n".join(game.get_quest_body_lines())
        quest_panel_button_label.text = game.get_quest_button_text()

    inventory_overlay.visible = game.inventory_open
    if game.inventory_open:
        inventory_equipped.text = "Waffe: %s (+%d)   |   Rüstung: %s (%d)   |   Talisman: %s" % [game.equipped_weapon.get("name","Waffe"), game.get_weapon_power(), game.equipped_armor.get("name","Rüstung"), game.get_armor_value(), game.equipped_charm.get("name","Schmuck")]
        if game.inventory.is_empty():
            inventory_items.text = "Noch keine Gegenstände gefunden."
        else:
            var lines := PackedStringArray()
            var count := mini(game.inventory.size(), 9)
            for i in range(count):
                var item: Dictionary = game.inventory[i]
                lines.append("• %s  [%s]" % [item.get("name","Item"), item.get("rarity","Gewöhnlich")])
            inventory_items.text = "\n".join(lines)
