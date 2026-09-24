extends CharacterBody3D

var player_ref: CharacterBody3D
var game_ref: Node
var spawn_point := Vector3.ZERO
var max_health := 78
var health := 78
var alive := true
var aggro := false
var attack_timer := 0.0
var gravity := 18.0
var visual_root: Node3D
var target_marker: Label3D
var walk_phase := 0.0
var legs: Array[Node3D] = []

func _ready() -> void:
    gravity = float(ProjectSettings.get_setting("physics/3d/default_gravity",18.0))
    add_to_group("enemies")
    var c := CollisionShape3D.new(); c.name="EnemyCollision"
    var shape := CapsuleShape3D.new(); shape.radius=0.52; shape.height=0.85
    c.shape=shape; c.position.y=0.45; add_child(c)
    _build_model()

func configure(player:CharacterBody3D,game:Node,spawn:Vector3)->void:
    player_ref=player; game_ref=game; spawn_point=spawn

func _build_model()->void:
    visual_root=Node3D.new(); add_child(visual_root)
    _sphere(Vector3(0.62,0.38,0.78),Vector3(0,0.62,0.18),Color("26282c"))
    _sphere(Vector3(0.42,0.32,0.46),Vector3(0,0.62,-0.62),Color("3f4248"))
    for side in [-1.0,1.0]:
        for i in range(4):
            var pivot:=Node3D.new(); pivot.position=Vector3(0,0.58,-0.45+float(i)*0.32); visual_root.add_child(pivot); legs.append(pivot)
            var leg:=MeshInstance3D.new(); var mesh:=BoxMesh.new(); mesh.size=Vector3(1.15,0.10,0.10); leg.mesh=mesh; leg.position=Vector3(side*0.55,-0.05,0); leg.rotation_degrees.z=side*20.0; leg.material_override=_mat(Color("25272b")); pivot.add_child(leg)
    for x in [-0.18,0.18]:
        var eye:=MeshInstance3D.new(); var sm:=SphereMesh.new(); sm.radius=0.08; sm.height=0.16; eye.mesh=sm; eye.position=Vector3(x,0.78,-1.0); var em:=_mat(Color("d43f36")); em.emission_enabled=true; em.emission=Color("a52320"); em.emission_energy_multiplier=1.5; eye.material_override=em; visual_root.add_child(eye)
    var label:=Label3D.new(); label.text="Höhlenspinne · Stufe 3"; label.position=Vector3(0,1.7,0); label.billboard=BaseMaterial3D.BILLBOARD_ENABLED; label.font_size=20; label.outline_size=6; visual_root.add_child(label)
    target_marker=Label3D.new(); target_marker.text="▼"; target_marker.position=Vector3(0,2.05,0); target_marker.billboard=BaseMaterial3D.BILLBOARD_ENABLED; target_marker.font_size=32; target_marker.outline_size=7; target_marker.modulate=Color("ffd05a"); target_marker.visible=false; visual_root.add_child(target_marker)

func _sphere(sc:Vector3,pos:Vector3,color:Color)->void:
    var n:=MeshInstance3D.new(); var m:=SphereMesh.new(); m.radius=1.0; m.height=2.0; m.radial_segments=10; m.rings=5; n.mesh=m; n.scale=sc; n.position=pos; n.material_override=_mat(color); visual_root.add_child(n)
func _mat(color:Color)->StandardMaterial3D:
    var m:=StandardMaterial3D.new();m.albedo_color=color;m.roughness=0.92;return m

func _physics_process(delta:float)->void:
    if not alive or player_ref==null or not is_instance_valid(player_ref): return
    attack_timer=maxf(0.0,attack_timer-delta)
    var to_player:=player_ref.global_position-global_position; to_player.y=0; var d:=to_player.length()
    if not player_ref.dead and (aggro or d<8.0):
        aggro=true
        if d>1.55:
            var dir:=to_player.normalized(); velocity.x=dir.x*3.1; velocity.z=dir.z*3.1; visual_root.rotation.y=lerp_angle(visual_root.rotation.y,atan2(-dir.x,-dir.z),minf(1.0,delta*8.0))
        else:
            velocity.x=move_toward(velocity.x,0.0,delta*13.0); velocity.z=move_toward(velocity.z,0.0,delta*13.0)
            if attack_timer<=0.0: attack_timer=1.2; player_ref.take_damage(randi_range(9,14))
    else:
        var back:=spawn_point-global_position; back.y=0
        if back.length()>1.2:
            var dir2:=back.normalized(); velocity.x=dir2.x*1.6; velocity.z=dir2.z*1.6
        else: velocity.x=move_toward(velocity.x,0.0,delta*8.0); velocity.z=move_toward(velocity.z,0.0,delta*8.0); aggro=false
    velocity.y=velocity.y-gravity*delta if not is_on_floor() else -0.2
    move_and_slide(); walk_phase+=delta*9.0
    for i in range(legs.size()): legs[i].rotation.y=sin(walk_phase+float(i)*0.7)*0.18

func take_damage(amount:int,critical:bool=false)->void:
    if not alive:return
    health=maxi(0,health-amount);aggro=true
    if game_ref!=null:game_ref.spawn_damage_number(global_position+Vector3(0,1.5,0),amount,critical,false)
    if health<=0:_die()
func _die()->void:
    alive=false;velocity=Vector3.ZERO;visual_root.rotation_degrees.z=75
    var c:=get_node_or_null("EnemyCollision") as CollisionShape3D
    if c!=null:c.set_deferred("disabled",true)
    if game_ref!=null:game_ref.on_enemy_defeated(self,"spider")
    await get_tree().create_timer(8.0).timeout
    global_position=spawn_point;health=max_health;alive=true;aggro=false;visual_root.rotation_degrees.z=0
    if c!=null:c.set_deferred("disabled",false)
func set_targeted(value:bool)->void: if target_marker!=null:target_marker.visible=value and alive
func is_alive_enemy()->bool:return alive
func get_health_ratio()->float:return float(health)/float(max_health)
func get_enemy_display_name()->String:return "Höhlenspinne"
func get_enemy_level()->int:return 3
