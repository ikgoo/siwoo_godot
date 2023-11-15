extends CharacterBody3D

@export var player : CharacterBody3D
@export var my_ammo : int
@export var my_ammo_full : int
const SPEED = 5.0
var accel  = 10
var gravity_ok = true
@onready var timer = $Timer
@onready var audio_stream_player = $AudioStreamPlayer
@export var na_path : NodePath
@export var HUD : NodePath
@onready var nav : NavigationAgent3D = get_node(na_path)
@onready var hud : Control = get_node(HUD)
var in_pl = false
var gravity = -10
var gra = 0
const JUMP_SPEED = 30
const GRAVITY = -5
var jump = false
@export var anipl = AnimationPlayer
@export var target : Marker3D

func _ready():
	var i = 0
	
func _physics_process(delta):
	var dir = Vector3()
	if not is_on_floor():
		global_position.y += GRAVITY * delta
	dir = nav.get_next_path_position().direction_to(target.global_position)
	
	velocity = velocity.lerp(dir * SPEED,accel * delta)
	if jump:
		process_movement_jumps(delta)
	if not is_on_floor():
		gra += 0.01
		global_position.y + gravity * gra
	if is_on_floor():
		gra = 0
		
	move_and_slide()
	
	look_at(player.global_transform.origin,Vector3.UP)
	if global_rotation.x != 0:
		global_rotation.z = 0

func PlayerHit():
	if in_pl ==true:
		hud.health_ui -= 10
		audio_stream_player.play()
		timer.start(1)
		

func _on_area_3d_area_entered(area):
	in_pl = true
	PlayerHit()

func _on_area_3d_area_exited(area):
	in_pl = false




	
func process_movement_jumps(delta):
	velocity.y = JUMP_SPEED
	velocity.y += gravity * delta
	
	


func _on_mobjump_area_entered(area):
	jump = false


func _on_mobjump_2_area_entered(area):
	jump = false


func _on_area_3d_2_area_entered(area):
	gravity_ok = true


func _on_area_3d_2_area_exited(area):
	gravity_ok = false
