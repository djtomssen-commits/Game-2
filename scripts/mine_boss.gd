extends CharacterBody3D

var player_ref: CharacterBody3D
var game_ref: Node
var spawn_point:=Vector3.ZERO
var max_health:=380
var health:=380
var alive:=true
var aggro:=false
var attack_timer:=0.0
var slam_timer:=3.5
var gravity:=18.0
var visual_root:Node3D
var target_marker:Label3D

func _ready()->void:
    gravity=float(ProjectSettings.get_setting("physics/3d/default_gravity",18.0));add_to_group("enemies")
    var c:=CollisionShape3D.new();c.name="EnemyCollision";var sh:=CapsuleShape3D.new();sh.radius=0.8;sh.height=2.7;c.shape=sh;c.position.y=1.35;add_child(c)
    _build_model()
func configure(player:CharacterBody3D,game:Node,spawn:Vector3)->void:player_ref=player;game_ref=game;spawn_point=spawn
func _build_model()->void:
    visual_root=Node3D.new();add_child(visual_root)
    _box(Vector3(1.6,1.7,0.9),Vector3(0,1.55,0),Color("4e5961"));_box(Vector3(0.9,0.85,0.85),Vector3(0,2.8,0),Color("59666f"))
    for x in [-0.95,0.95]:_box(Vector3(0.55,1.8,0.55),Vector3(x,1.55,0),Color("465057"))
    for x in [-0.48,0.48]:_box(Vector3(0.62,1.55,0.68),Vector3(x,0.52,0),Color("3d464c"))
    var crystal:=MeshInstance3D.new();var pm:=PrismMesh.new();pm.size=Vector3(0.75,2.3,0.75);crystal.mesh=pm;crystal.position=Vector3(0,2.0,-0.55);var cm:=_mat(Color("5ac0e4"));cm.emission_enabled=true;cm.emission=Color("2c94c4");cm.emission_energy_multiplier=2.2;crystal.material_override=cm;visual_root.add_child(crystal)
    var l:=Label3D.new();l.text="Kristallwächter · Boss Stufe 4";l.position=Vector3(0,3.75,0);l.billboard=BaseMaterial3D.BILLBOARD_ENABLED;l.font_size=24;l.outline_size=8;l.modulate=Color("8ed8ff");visual_root.add_child(l)
    target_marker=Label3D.new();target_marker.text="▼";target_marker.position=Vector3(0,4.15,0);target_marker.billboard=BaseMaterial3D.BILLBOARD_ENABLED;target_marker.font_size=38;target_marker.outline_size=8;target_marker.modulate=Color("ffd05a");target_marker.visible=false;visual_root.add_child(target_marker)
func _box(size:Vector3,pos:Vector3,color:Color)->void:
    var n:=MeshInstance3D.new();var m:=BoxMesh.new();m.size=size;n.mesh=m;n.position=pos;n.material_override=_mat(color);visual_root.add_child(n)
func _mat(color:Color)->StandardMaterial3D:
    var m:=StandardMaterial3D.new();m.albedo_color=color;m.roughness=0.78;return m
func _physics_process(delta:float)->void:
    if not alive or player_ref==null or not is_instance_valid(player_ref):return
    attack_timer=maxf(0.0,attack_timer-delta);slam_timer=maxf(0.0,slam_timer-delta)
    var to:=player_ref.global_position-global_position;to.y=0;var d:=to.length()
    if not player_ref.dead and (aggro or d<10.0):
        aggro=true
        if d>2.25:
            var dir:=to.normalized();velocity.x=dir.x*1.8;velocity.z=dir.z*1.8;visual_root.rotation.y=lerp_angle(visual_root.rotation.y,atan2(-dir.x,-dir.z),minf(1.0,delta*5.0))
        else:
            velocity.x=move_toward(velocity.x,0.0,delta*8.0);velocity.z=move_toward(velocity.z,0.0,delta*8.0)
            if slam_timer<=0.0:
                slam_timer=4.2;player_ref.take_damage(randi_range(24,32));if game_ref!=null:game_ref.show_toast("KRISTALLSCHLAG",0.8)
            elif attack_timer<=0.0:
                attack_timer=1.5;player_ref.take_damage(randi_range(14,20))
    velocity.y=velocity.y-gravity*delta if not is_on_floor() else -0.2;move_and_slide()
func take_damage(amount:int,critical:bool=false)->void:
    if not alive:return
    health=maxi(0,health-amount);aggro=true
    if game_ref!=null:game_ref.spawn_damage_number(global_position+Vector3(0,3.1,0),amount,critical,false)
    if health<=0:_die()
func _die()->void:
    alive=false;velocity=Vector3.ZERO;visual_root.rotation_degrees.z=82
    var c:=get_node_or_null("EnemyCollision") as CollisionShape3D;if c!=null:c.set_deferred("disabled",true)
    if game_ref!=null:game_ref.on_enemy_defeated(self,"mine_boss")
    await get_tree().create_timer(18.0).timeout
    global_position=spawn_point;health=max_health;alive=true;aggro=false;visual_root.rotation_degrees.z=0
    if c!=null:c.set_deferred("disabled",false)
func set_targeted(value:bool)->void:if target_marker!=null:target_marker.visible=value and alive
func is_alive_enemy()->bool:return alive
func get_health_ratio()->float:return float(health)/float(max_health)
func get_enemy_display_name()->String:return "Kristallwächter"
func get_enemy_level()->int:return 4
