extends Control

var player
var game

func _ready() -> void:
    visible = true
    queue_redraw()
func _process(_delta: float) -> void:
    queue_redraw()

func _draw() -> void:
    if size.x<=0 or size.y<=0 or player==null or game==null:return
    var s:=clampf(size.y/720.0,0.85,1.55)
    var font:Font = ThemeDB.fallback_font
    if font == null:
        font = SystemFont.new()
    _draw_player_frame(font,s)
    _draw_target_frame(font,s)
    _draw_minimap(font,s)
    _draw_quest_tracker(font,s)
    _draw_controls(font,s)
    _draw_xp_bar(font,s)
    _draw_inventory_button(font,s)
    _draw_version(font,s)
    if game.toast_time>0.0 and not game.toast_text.is_empty():_draw_toast(font,s)
    if game.loot_time>0.0 and not game.loot_text.is_empty():_draw_loot(font,s)
    if game.quest_panel_open:_draw_quest_panel(font,s)
    if game.inventory_open:_draw_inventory(font,s)

func _panel(rect:Rect2,fill:Color,border:Color=Color(0.5,0.5,0.5,0.6),width:float=2.0)->void:
    draw_rect(rect,fill,true);draw_rect(rect,border,false,width)

func _draw_player_frame(font:Font,s:float)->void:
    var p:=Rect2(Vector2(18,18)*s,Vector2(338,120)*s)
    _panel(p,Color(0.015,0.025,0.04,0.86),Color(0.45,0.58,0.70,0.72),2)
    var portrait:=p.position+Vector2(48,52)*s
    draw_circle(portrait,34*s,Color(0.12,0.20,0.30,0.95));draw_circle(portrait,30*s,Color(0.25,0.37,0.49,0.95))
    draw_circle(portrait+Vector2(0,-5)*s,11*s,Color("d7aa83"));draw_rect(Rect2(portrait+Vector2(-13,8)*s,Vector2(26,19)*s),Color("315a83"),true)
    draw_string(font,p.position+Vector2(92,27)*s,"Abenteurer · Stufe %d"%game.level,HORIZONTAL_ALIGNMENT_LEFT,-1,int(18*s),Color.WHITE)
    var hp:=Rect2(p.position+Vector2(92,39)*s,Vector2(226,21)*s)
    draw_rect(hp,Color(0.12,0.03,0.03,0.95),true);draw_rect(Rect2(hp.position,Vector2(hp.size.x*float(player.health)/maxf(1.0,float(player.max_health)),hp.size.y)),Color("b52320"),true)
    draw_string(font,hp.position+Vector2(8,15)*s,"%d / %d LP"%[player.health,player.max_health],HORIZONTAL_ALIGNMENT_LEFT,-1,int(13*s),Color.WHITE)
    var rage:=Rect2(p.position+Vector2(92,65)*s,Vector2(226,15)*s)
    draw_rect(rage,Color(0.13,0.08,0.02,0.95),true);draw_rect(Rect2(rage.position,Vector2(rage.size.x*float(game.rage)/float(game.max_rage),rage.size.y)),Color("c87822"),true)
    draw_string(font,p.position+Vector2(92,101)*s,"Gold %d  ·  Wut %d  ·  +%d Schaden"%[game.gold,game.rage,game.get_weapon_power()],HORIZONTAL_ALIGNMENT_LEFT,-1,int(13*s),Color("efd28d"))

func _draw_target_frame(font:Font,s:float)->void:
    if game.current_target==null or not is_instance_valid(game.current_target):return
    var t=game.current_target
    var w:=300.0*s
    var p:=Rect2(Vector2((size.x-w)*0.5,18*s),Vector2(w,68*s))
    _panel(p,Color(0.04,0.022,0.02,0.88),Color(0.70,0.30,0.18,0.85),2)
    draw_string(font,p.position+Vector2(14,25)*s,"%s · Stufe %d"%[t.get_enemy_display_name(),t.get_enemy_level()],HORIZONTAL_ALIGNMENT_LEFT,-1,int(17*s),Color.WHITE)
    var hp:=Rect2(p.position+Vector2(14,37)*s,Vector2(272,18)*s)
    draw_rect(hp,Color(0.12,0.03,0.03,0.95),true);draw_rect(Rect2(hp.position,Vector2(hp.size.x*t.get_health_ratio(),hp.size.y)),Color("a91c19"),true)
    draw_string(font,hp.position+Vector2(8,14)*s,"%d / %d"%[t.health,t.max_health],HORIZONTAL_ALIGNMENT_LEFT,-1,int(12*s),Color.WHITE)

func _draw_minimap(font:Font,s:float)->void:
    var c:=Vector2(size.x-88*s,86*s);var r:=58*s
    draw_circle(c,r+5*s,Color(0.02,0.03,0.04,0.78));draw_circle(c,r,Color(0.18,0.28,0.18,0.86));draw_arc(c,r,0,TAU,48,Color(0.72,0.61,0.36,0.9),2.0)
    draw_circle(c,4*s,Color("f4f7fb"))
    if game.quest_npc!=null:
        _minimap_blip(c,r,s,game.quest_npc.global_position,Color("ffd45a"),5.0)
    for e in game.enemies:
        if e!=null and is_instance_valid(e) and e.is_alive_enemy():_minimap_blip(c,r,s,e.global_position,Color("d64c43"),3.2)
    draw_string(font,c+Vector2(-28,-78)*s,"KARTE",HORIZONTAL_ALIGNMENT_CENTER,56*s,int(11*s),Color("ead89c"))

func _minimap_blip(c:Vector2,r:float,s:float,world_pos:Vector3,color:Color,rad:float)->void:
    var rel:=world_pos-player.global_position
    var v:=Vector2(rel.x,rel.z)*(r/35.0)
    if v.length()>r-7*s:v=v.normalized()*(r-7*s)
    draw_circle(c+v,rad*s,color)

func _draw_quest_tracker(font:Font,s:float)->void:
    var p:=Rect2(Vector2(size.x-335*s,170*s),Vector2(315,92)*s)
    _panel(p,Color(0.02,0.03,0.05,0.78),Color(0.60,0.48,0.22,0.72),2)
    draw_string(font,p.position+Vector2(12,22)*s,"AUFTRAG",HORIZONTAL_ALIGNMENT_LEFT,-1,int(13*s),Color("f1cf7a"))
    draw_string(font,p.position+Vector2(12,47)*s,game.get_quest_title(),HORIZONTAL_ALIGNMENT_LEFT,p.size.x-24*s,int(16*s),Color.WHITE)
    draw_string(font,p.position+Vector2(12,72)*s,game.get_quest_tracker_text(),HORIZONTAL_ALIGNMENT_LEFT,p.size.x-24*s,int(13*s),Color("d8e1eb"))

func _draw_controls(font:Font,s:float)->void:
    var jc:=Vector2(118*s,size.y-118*s);var thumb:=jc
    if player.move_touch_id!=-1:jc=player.move_origin;thumb=jc+player.move_vector*68*s
    draw_circle(jc,80*s,Color(0.02,0.04,0.07,0.30));draw_circle(jc,76*s,Color(0.75,0.83,0.90,0.11));draw_circle(thumb,31*s,Color(0.88,0.92,0.97,0.42))
    _skill_circle(Vector2(size.x-110*s,size.y-116*s),78*s,Color("a93625"),"ANGRIFF",font,int(13*s),0.0,s)
    _skill_circle(Vector2(size.x-238*s,size.y-86*s),64*s,Color("8a5a24"),"HIEB",font,int(13*s),game.skill1_cd,s)
    _skill_circle(Vector2(size.x-226*s,size.y-214*s),64*s,Color("72502c"),"WIRBEL",font,int(12*s),game.skill2_cd,s)
    _skill_circle(Vector2(size.x-110*s,size.y-250*s),56*s,Color("375b83"),"SPRUNG",font,int(11*s),0.0,s)
    if game.is_player_near_npc():_skill_circle(Vector2(size.x-110*s,size.y-360*s),58*s,Color("9a7625"),"REDEN",font,int(12*s),0.0,s)

func _skill_circle(c:Vector2,r:float,color:Color,text:String,font:Font,font_size:int,cooldown:float,s:float)->void:
    draw_circle(c,r+4*s,Color(0.02,0.025,0.03,0.65));draw_circle(c,r,color)
    draw_string(font,c+Vector2(-r*0.75,5*s),text,HORIZONTAL_ALIGNMENT_CENTER,r*1.5,font_size,Color.WHITE)
    if cooldown>0.0:
        draw_circle(c,r,Color(0,0,0,0.48));draw_string(font,c+Vector2(-20,8)*s,"%.1f"%cooldown,HORIZONTAL_ALIGNMENT_CENTER,40*s,int(17*s),Color.WHITE)

func _draw_xp_bar(font:Font,s:float)->void:
    var bar:=Rect2(Vector2(size.x*0.22,size.y-17*s),Vector2(size.x*0.56,9*s))
    draw_rect(bar,Color(0.02,0.035,0.07,0.82),true);draw_rect(Rect2(bar.position,Vector2(bar.size.x*float(game.xp)/float(maxi(1,game.get_xp_required())),bar.size.y)),Color("4b78c5"),true)
    draw_string(font,bar.position+Vector2(0,-3)*s,"EP %d / %d"%[game.xp,game.get_xp_required()],HORIZONTAL_ALIGNMENT_CENTER,bar.size.x,int(10*s),Color("e6edf8"))

func _draw_inventory_button(font:Font,s:float)->void:
    var r:Rect2=game.get_inventory_button_rect();_panel(r,Color(0.04,0.06,0.08,0.82),Color(0.54,0.47,0.29,0.85),2);draw_string(font,r.position+Vector2(8,27)*s,"TASCHE [%d]"%game.inventory.size(),HORIZONTAL_ALIGNMENT_CENTER,r.size.x-16*s,int(12*s),Color("ead69b"))

func _draw_version(font:Font,s:float)->void:
    draw_string(font,Vector2(12,size.y-10*s),"ELDORIA ONLINE · V0.4",HORIZONTAL_ALIGNMENT_LEFT,-1,int(10*s),Color(1,1,1,0.48))

func _draw_toast(font:Font,s:float)->void:
    var w:=minf(650*s,size.x*0.62);var r:=Rect2(Vector2((size.x-w)*0.5,size.y*0.15),Vector2(w,42*s));_panel(r,Color(0.02,0.03,0.05,0.86),Color(0.73,0.58,0.24,0.88),2);draw_string(font,r.position+Vector2(12,27)*s,game.toast_text,HORIZONTAL_ALIGNMENT_CENTER,r.size.x-24*s,int(16*s),Color.WHITE)
func _draw_loot(font:Font,s:float)->void:
    var w:=minf(460*s,size.x*0.48);var r:=Rect2(Vector2((size.x-w)*0.5,size.y*0.27),Vector2(w,36*s));_panel(r,Color(0.04,0.05,0.03,0.82),Color(0.45,0.67,0.28,0.86),1.5);draw_string(font,r.position+Vector2(10,24)*s,game.loot_text,HORIZONTAL_ALIGNMENT_CENTER,r.size.x-20*s,int(14*s),Color("d9efb4"))

func _draw_quest_panel(font:Font,s:float)->void:
    draw_rect(Rect2(Vector2.ZERO,size),Color(0,0,0,0.50),true)
    var p:Rect2=game.get_quest_panel_rect();_panel(p,Color(0.035,0.045,0.06,0.985),Color(0.67,0.52,0.22,0.95),3)
    draw_string(font,p.position+Vector2(28,42)*s,"HAUPTMANN ARLEN",HORIZONTAL_ALIGNMENT_LEFT,-1,int(14*s),Color("d8b96e"));draw_string(font,p.position+Vector2(28,78)*s,game.get_quest_title(),HORIZONTAL_ALIGNMENT_LEFT,-1,int(25*s),Color.WHITE)
    var y:=p.position.y+122*s
    for line in game.get_quest_body_lines():draw_string(font,Vector2(p.position.x+28*s,y),line,HORIZONTAL_ALIGNMENT_LEFT,p.size.x-56*s,int(16*s),Color("e0e5eb"));y+=34*s
    var b:=game.get_quest_button_rect();_panel(b,Color(0.46,0.30,0.08,0.98),Color(0.88,0.68,0.24,0.98),2);draw_string(font,b.position+Vector2(12,32)*s,game.get_quest_button_text(),HORIZONTAL_ALIGNMENT_CENTER,b.size.x-24*s,int(16*s),Color.WHITE)
    var c:=game.get_quest_close_rect();draw_rect(c,Color(0.16,0.17,0.19,0.96),true);draw_string(font,c.position+Vector2(11,27)*s,"X",HORIZONTAL_ALIGNMENT_LEFT,-1,int(17*s),Color.WHITE)

func _draw_inventory(font:Font,s:float)->void:
    draw_rect(Rect2(Vector2.ZERO,size),Color(0,0,0,0.55),true)
    var p:=game.get_inventory_panel_rect();_panel(p,Color(0.025,0.035,0.05,0.99),Color(0.50,0.58,0.68,0.92),3)
    draw_string(font,p.position+Vector2(28,40)*s,"ABENTEURER-TASCHE",HORIZONTAL_ALIGNMENT_LEFT,-1,int(23*s),Color.WHITE)
    draw_string(font,p.position+Vector2(28,71)*s,"Ausgerüstet: %s  (+%d Schaden)"%[game.equipped_weapon.get("name","Waffe"),game.get_weapon_power()],HORIZONTAL_ALIGNMENT_LEFT,p.size.x-56*s,int(14*s),game.get_rarity_color(game.equipped_weapon.get("rarity","Gewöhnlich")))
    var start_y:=p.position.y+105*s
    if game.inventory.is_empty():
        draw_string(font,Vector2(p.position.x+28*s,start_y),"Noch keine Gegenstände gefunden.",HORIZONTAL_ALIGNMENT_LEFT,-1,int(15*s),Color("aeb8c5"))
    else:
        var max_items:=mini(game.inventory.size(),8)
        for i in range(max_items):
            var item:Dictionary=game.inventory[i];var row:=Rect2(Vector2(p.position.x+28*s,start_y+i*38*s),Vector2(p.size.x-56*s,31*s));draw_rect(row,Color(0.06,0.075,0.095,0.88),true);draw_string(font,row.position+Vector2(10,21)*s,"%s   [%s]"%[item.get("name","Item"),item.get("type","Gegenstand")],HORIZONTAL_ALIGNMENT_LEFT,row.size.x-20*s,int(13*s),game.get_rarity_color(item.get("rarity","Gewöhnlich")))
    var a:=game.get_inventory_auto_rect();_panel(a,Color(0.17,0.28,0.39,0.98),Color(0.45,0.68,0.88,0.98),2);draw_string(font,a.position+Vector2(12,29)*s,"BESTE WAFFE AUSRÜSTEN",HORIZONTAL_ALIGNMENT_CENTER,a.size.x-24*s,int(14*s),Color.WHITE)
    var c:=game.get_inventory_close_rect();draw_rect(c,Color(0.16,0.17,0.19,0.96),true);draw_string(font,c.position+Vector2(11,27)*s,"X",HORIZONTAL_ALIGNMENT_LEFT,-1,int(17*s),Color.WHITE)
