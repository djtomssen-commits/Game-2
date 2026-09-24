extends CharacterBody3D

var player_ref: CharacterBody3D
var game_ref: Node
var spawn_point := Vector3.ZERO
var max_health := 82
var health := 82
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
    _build_collision()
    _build_model()

func configure(player: CharacterBody3D,game: Node,spawn: Vector3) -> void:
    player_ref=player; game_ref=game; spawn_point=spawn

func _build_collision() -> void:
    var collision := CollisionShape3D.new(); collision.name="EnemyCollision"
    var capsule := CapsuleShape3D.new(); capsule.radius=0.42; capsule.height=1.9
    collision.shape=capsule; collision.position.y=0.95; add_child(collision)

func _build_model() -> void:
    visual_root=Node3D.new(); add_child(visual_root)
    _add_cylinder(0.35,0.45,0.95,Vector3(0,1.34,0),Color("6f3f34"))
    _add_sphere(Vector3(0.32,0.35,0.32),Vector3(0,2.08,0),Color("c89a75"))
    _add_sphere(Vector3(0.34,0.17,0.34),Vector3(0,2.28,0),Color("342e2a"))
    left_leg=_make_limb(Vector3(-0.22,0.9,0),Color("403c3a"))
    right_leg=_make_limb(Vector3(0.22,0.9,0),Color("403c3a"))
    var left_arm:=_make_arm(Vector3(-0.56,1.72,0),Color("8b5c43"))
    right_arm=_make_arm(Vector3(0.56,1.72,0),Color("8b5c43"))
    _add_box_to(right_arm,Vector3(0.10,1.0,0.08),Vector3(0,-1.05,-0.06),Color("bcc4ca"))
    _add_box_to(right_arm,Vector3(0.45,0.09,0.08),Vector3(0,-0.66,-0.06),Color("5a3b24"))
    var name:=Label3D.new(); name.text="Bandit · Stufe 2"; name.position=Vector3(0,2.75,0); name.billboard=BaseMaterial3D.BILLBOARD_ENABLED; name.font_size=20; name.outline_size=6; visual_root.add_child(name)
    target_marker=Label3D.new(); target_marker.text="▼"; target_marker.position=Vector3(0,3.15,0); target_marker.billboard=BaseMaterial3D.BILLBOARD_ENABLED; target_marker.font_size=32; target_marker.outline_size=7; target_marker.modulate=Color("ffd05a"); target_marker.visible=false; visual_root.add_child(target_marker)

func _make_limb(pos:Vector3,color:Color)->Node3D:
    var p:=Node3D.new(); p.position=pos; visual_root.add_child(p); _add_cylinder_to(p,0.13,0.16,0.86,Vector3(0,-0.43,0),color); return p
func _make_arm(pos:Vector3,color:Color)->Node3D:
    var p:=Node3D.new(); p.position=pos; visual_root.add_child(p); _add_cylinder_to(p,0.12,0.14,0.82,Vector3(0,-0.41,0),color); return p
func _add_cylinder(tr:float,br:float,h:float,pos:Vector3,color:Color)->void: _add_cylinder_to(visual_root,tr,br,h,pos,color)
func _add_cylinder_to(parent:Node,tr:float,br:float,h:float,pos:Vector3,color:Color)->void:
    var n:=MeshInstance3D.new(); var m:=CylinderMesh.new(); m.top_radius=tr; m.bottom_radius=br; m.height=h; m.radial_segments=9; n.mesh=m; n.position=pos; n.material_override=_material(color,0.95); parent.add_child(n)
func _add_sphere(sc:Vector3,pos:Vector3,color:Color)->void:
    var n:=MeshInstance3D.new(); var m:=SphereMesh.new(); m.radius=1.0; m.height=2.0; m.radial_segments=10; m.rings=5; n.mesh=m; n.scale=sc; n.position=pos; n.material_override=_material(color,0.92); visual_root.add_child(n)
func _add_box_to(parent:Node,size:Vector3,pos:Vector3,color:Color)->void:
    var n:=MeshInstance3D.new(); var m:=BoxMesh.new(); m.size=size; n.mesh=m; n.position=pos; n.material_override=_material(color,0.6); parent.add_child(n)

func _physics_process(delta:float)->void:
    if not alive or player_ref==null or not is_instance_valid(player_ref): return
    attack_timer=maxf(0.0,attack_timer-delta)
    var to_player:=player_ref.global_position-global_position; to_player.y=0
    var d:=to_player.length()
    if not player_ref.dead and (aggro or d<8.5):
        aggro=true
        if d>1.75:
            var dir:=to_player.normalized(); velocity.x=dir.x*2.35; velocity.z=dir.z*2.35; visual_root.rotation.y=lerp_angle(visual_root.rotation.y,atan2(-dir.x,-dir.z),minf(1.0,delta*7.0))
        else:
            velocity.x=move_toward(velocity.x,0.0,delta*10.0); velocity.z=move_toward(velocity.z,0.0,delta*10.0)
            if attack_timer<=0.0:
                attack_timer=1.45; _swing(); player_ref.take_damage(randi_range(8,13))
    else:
        var back:=spawn_point-global_position; back.y=0
        if back.length()>1.4:
            var dir2:=back.normalized(); velocity.x=dir2.x*1.35; velocity.z=dir2.z*1.35; visual_root.rotation.y=lerp_angle(visual_root.rotation.y,atan2(-dir2.x,-dir2.z),minf(1.0,delta*6.0))
        else:
            velocity.x=move_toward(velocity.x,0.0,delta*7.0); velocity.z=move_toward(velocity.z,0.0,delta*7.0); aggro=false
    velocity.y=velocity.y-gravity*delta if not is_on_floor() else -0.2
    move_and_slide(); _animate(delta,Vector2(velocity.x,velocity.z).length())

func _animate(delta:float,speed:float)->void:
    if speed>0.25:
        walk_phase+=delta*8.0; var swing:=sin(walk_phase)*0.48; left_leg.rotation.x=swing; right_leg.rotation.x=-swing
    else:
        left_leg.rotation.x=lerpf(left_leg.rotation.x,0.0,minf(1.0,delta*10.0)); right_leg.rotation.x=lerpf(right_leg.rotation.x,0.0,minf(1.0,delta*10.0))
func _swing()->void:
    var t:=create_tween(); t.tween_property(right_arm,"rotation:z",-1.0,0.12); t.tween_property(right_arm,"rotation:z",0.0,0.20)

func take_damage(amount:int,critical:bool=false)->void:
    if not alive:return
    health=maxi(0,health-amount); aggro=true
    if game_ref!=null: game_ref.spawn_damage_number(global_position+Vector3(0,2.5,0),amount,critical,false)
    var t:=create_tween(); t.tween_property(visual_root,"scale",Vector3(1.08,0.94,1.08),0.07); t.tween_property(visual_root,"scale",Vector3.ONE,0.11)
    if health<=0:_die()
func _die()->void:
    alive=false; velocity=Vector3.ZERO; visual_root.rotation_degrees.z=80
    var c:=get_node_or_null("EnemyCollision") as CollisionShape3D
    if c!=null:c.set_deferred("disabled",true)
    if game_ref!=null:game_ref.on_enemy_defeated(self,"bandit")
    await get_tree().create_timer(9.0).timeout
    global_position=spawn_point; health=max_health; alive=true; aggro=false; visual_root.rotation_degrees.z=0
    if c!=null:c.set_deferred("disabled",false)
func set_targeted(value:bool)->void:
    if target_marker!=null:target_marker.visible=value and alive
func is_alive_enemy()->bool:return alive
func get_health_ratio()->float:return float(health)/float(max_health)
func get_enemy_display_name()->String:return "Bandit"
func get_enemy_level()->int:return 2
func _material(color:Color,roughness:float)->StandardMaterial3D:
    var m:=StandardMaterial3D.new();m.albedo_color=color;m.roughness=roughness;return m
