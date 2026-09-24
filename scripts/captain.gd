extends CharacterBody3D

var player_ref: CharacterBody3D
var game_ref: Node
var spawn_point := Vector3.ZERO
var max_health := 185
var health := 185
var alive := true
var aggro := false
var attack_timer := 0.0
var gravity := 18.0
var visual_root: Node3D
var target_marker: Label3D
var left_leg: Node3D
var right_leg: Node3D
var right_arm: Node3D
var walk_phase := 0.0

func _ready() -> void:
    gravity = float(ProjectSettings.get_setting("physics/3d/default_gravity",18.0))
    add_to_group("enemies")
    var collision := CollisionShape3D.new(); collision.name="EnemyCollision"
    var capsule := CapsuleShape3D.new(); capsule.radius=0.52; capsule.height=2.15
    collision.shape=capsule; collision.position.y=1.05; add_child(collision)
    _build_model()

func configure(player:CharacterBody3D,game:Node,spawn:Vector3)->void:
    player_ref=player; game_ref=game; spawn_point=spawn

func _build_model()->void:
    visual_root=Node3D.new(); add_child(visual_root)
    _cyl(0.43,0.52,1.10,Vector3(0,1.48,0),Color("552b2d"))
    _sphere(Vector3(0.38,0.41,0.38),Vector3(0,2.33,0),Color("c78f68"))
    _sphere(Vector3(0.42,0.20,0.42),Vector3(0,2.55,0),Color("262427"))
    left_leg=_limb(Vector3(-0.26,0.96,0),Color("2f3035"))
    right_leg=_limb(Vector3(0.26,0.96,0),Color("2f3035"))
    var left_arm:=_arm(Vector3(-0.66,1.90,0),Color("704044"))
    right_arm=_arm(Vector3(0.66,1.90,0),Color("704044"))
    _sphere(Vector3(0.34,0.22,0.36),Vector3(-0.62,2.0,0),Color("8e6a38"))
    _sphere(Vector3(0.34,0.22,0.36),Vector3(0.62,2.0,0),Color("8e6a38"))
    _box(right_arm,Vector3(0.14,1.35,0.10),Vector3(0,-1.40,-0.08),Color("c6ccd2"))
    _box(right_arm,Vector3(0.62,0.11,0.11),Vector3(0,-0.90,-0.08),Color("8f673a"))
    var cape:=MeshInstance3D.new(); var cm:=BoxMesh.new(); cm.size=Vector3(0.92,1.45,0.08); cape.mesh=cm; cape.position=Vector3(0,1.40,0.32); cape.material_override=_mat(Color("3b2027")); visual_root.add_child(cape)
    var name:=Label3D.new(); name.text="ELITE · Banditenhauptmann · Stufe 3"; name.position=Vector3(0,3.05,0); name.billboard=BaseMaterial3D.BILLBOARD_ENABLED; name.font_size=23; name.outline_size=7; name.modulate=Color("ffb46b"); visual_root.add_child(name)
    target_marker=Label3D.new(); target_marker.text="▼"; target_marker.position=Vector3(0,3.48,0); target_marker.billboard=BaseMaterial3D.BILLBOARD_ENABLED; target_marker.font_size=38; target_marker.outline_size=8; target_marker.modulate=Color("ffb13b"); target_marker.visible=false; visual_root.add_child(target_marker)

func _limb(pos:Vector3,color:Color)->Node3D:
    var p:=Node3D.new(); p.position=pos; visual_root.add_child(p); _cyl_to(p,0.16,0.20,0.94,Vector3(0,-0.47,0),color); return p
func _arm(pos:Vector3,color:Color)->Node3D:
    var p:=Node3D.new(); p.position=pos; visual_root.add_child(p); _cyl_to(p,0.14,0.17,0.92,Vector3(0,-0.46,0),color); return p
func _cyl(t:float,b:float,h:float,pos:Vector3,color:Color)->void:_cyl_to(visual_root,t,b,h,pos,color)
func _cyl_to(parent:Node,t:float,b:float,h:float,pos:Vector3,color:Color)->void:
    var n:=MeshInstance3D.new();var m:=CylinderMesh.new();m.top_radius=t;m.bottom_radius=b;m.height=h;m.radial_segments=10;n.mesh=m;n.position=pos;n.material_override=_mat(color);parent.add_child(n)
func _sphere(sc:Vector3,pos:Vector3,color:Color)->void:
    var n:=MeshInstance3D.new();var m:=SphereMesh.new();m.radius=1.0;m.height=2.0;m.radial_segments=12;m.rings=6;n.mesh=m;n.scale=sc;n.position=pos;n.material_override=_mat(color);visual_root.add_child(n)
func _box(parent:Node,size:Vector3,pos:Vector3,color:Color)->void:
    var n:=MeshInstance3D.new();var m:=BoxMesh.new();m.size=size;n.mesh=m;n.position=pos;n.material_override=_mat(color);parent.add_child(n)
func _mat(color:Color)->StandardMaterial3D:
    var m:=StandardMaterial3D.new();m.albedo_color=color;m.roughness=0.82;return m

func _physics_process(delta:float)->void:
    if not alive or player_ref==null or not is_instance_valid(player_ref):return
    attack_timer=maxf(0.0,attack_timer-delta)
    var to_player:=player_ref.global_position-global_position;to_player.y=0
    var d:=to_player.length()
    if not player_ref.dead and (aggro or d<10.0):
        aggro=true
        if d>1.9:
            var dir:=to_player.normalized();velocity.x=dir.x*2.55;velocity.z=dir.z*2.55;visual_root.rotation.y=lerp_angle(visual_root.rotation.y,atan2(-dir.x,-dir.z),minf(1.0,delta*7.0))
        else:
            velocity.x=move_toward(velocity.x,0.0,delta*11.0);velocity.z=move_toward(velocity.z,0.0,delta*11.0)
            if attack_timer<=0.0:
                attack_timer=1.25;_swing();player_ref.take_damage(randi_range(13,19))
    else:
        var back:=spawn_point-global_position;back.y=0
        if back.length()>1.4:
            var dir2:=back.normalized();velocity.x=dir2.x*1.5;velocity.z=dir2.z*1.5;visual_root.rotation.y=lerp_angle(visual_root.rotation.y,atan2(-dir2.x,-dir2.z),minf(1.0,delta*6.0))
        else:
            velocity.x=move_toward(velocity.x,0.0,delta*8.0);velocity.z=move_toward(velocity.z,0.0,delta*8.0);aggro=false
    velocity.y=velocity.y-gravity*delta if not is_on_floor() else -0.2
    move_and_slide();_animate(delta,Vector2(velocity.x,velocity.z).length())

func _animate(delta:float,speed:float)->void:
    if speed>0.25:
        walk_phase+=delta*8.5;var sw:=sin(walk_phase)*0.50;left_leg.rotation.x=sw;right_leg.rotation.x=-sw
    else:
        left_leg.rotation.x=lerpf(left_leg.rotation.x,0.0,minf(1.0,delta*10.0));right_leg.rotation.x=lerpf(right_leg.rotation.x,0.0,minf(1.0,delta*10.0))
func _swing()->void:
    var t:=create_tween();t.tween_property(right_arm,"rotation:z",-1.25,0.11);t.tween_property(right_arm,"rotation:z",0.0,0.22)
func take_damage(amount:int,critical:bool=false)->void:
    if not alive:return
    health=maxi(0,health-amount);aggro=true
    if game_ref!=null:game_ref.spawn_damage_number(global_position+Vector3(0,2.8,0),amount,critical,false)
    var t:=create_tween();t.tween_property(visual_root,"scale",Vector3(1.09,0.93,1.09),0.07);t.tween_property(visual_root,"scale",Vector3.ONE,0.12)
    if health<=0:_die()
func _die()->void:
    alive=false;velocity=Vector3.ZERO;visual_root.rotation_degrees.z=82
    var c:=get_node_or_null("EnemyCollision") as CollisionShape3D
    if c!=null:c.set_deferred("disabled",true)
    if game_ref!=null:game_ref.on_enemy_defeated(self,"captain")
    await get_tree().create_timer(18.0).timeout
    global_position=spawn_point;health=max_health;alive=true;aggro=false;visual_root.rotation_degrees.z=0
    if c!=null:c.set_deferred("disabled",false)
func set_targeted(v:bool)->void:
    if target_marker!=null:target_marker.visible=v and alive
func is_alive_enemy()->bool:return alive
func get_health_ratio()->float:return float(health)/float(max_health)
func get_enemy_display_name()->String:return "Banditenhauptmann"
func get_enemy_level()->int:return 3
