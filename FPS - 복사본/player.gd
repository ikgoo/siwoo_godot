extends CharacterBody3D
@onready var unarmed = $camroot/weapons/unarmerd
@onready var camroot = $camroot
var mouse_sence = 0.1

@onready var camera = $camroot/Camera3D
@onready var weapon_maneger = $camroot/weapons
var currunt_val = Vector3.ZERO
var dir = Vector3.ZERO

var speeds = 5
var sprint_speed = 10
const ACCEL = 15.0

const GRAVITY = -20
const JUMP_SPEED = 15
var jump_counter = 0
const air_ACCEL = 9.0
var run = 0
const BOB_FREQ = 1.0
const BOB_AMP = 0.01
var t_bob = 0.0

func process_weapons():
	
	if Input.is_action_just_pressed("empty"):
		weapon_maneger.change_weapon("Empty")
	if Input.is_action_just_pressed("primary"):
		weapon_maneger.change_weapon("primary")
	if Input.is_action_just_pressed("secendary"):
		weapon_maneger.change_weapon("secendary")
	if weapon_maneger.currunt_weapon_slot != "primary":
		if Input.is_action_pressed("fire"):
			weapon_maneger.fire()
	if weapon_maneger.currunt_weapon_slot == "primary":
		if Input.is_action_just_pressed("fire"):
			weapon_maneger.fire()


	if Input.is_action_just_pressed("reload"):
		weapon_maneger.reload()
	if Input.is_action_pressed("zoom"):
		
		weapon_maneger.zoom()
		speeds = 4
		sprint_speed = 4

	if Input.is_action_just_released("zoom"):
		weapon_maneger.unzoom()
		speeds = 5
		sprint_speed = 10
func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	
func _physics_process(delta):
		process_movement_inputs()
		process_movement_jumps(delta)
		process_movement(delta)
		process_weapons()
		head_bob(delta)

func _process(delta):

	window_activity()


func process_movement_inputs():
	dir = Vector3.ZERO
	
	if Input.is_action_pressed("up"):
		dir -= camera.global_transform.basis.z
	if Input.is_action_pressed("down"):
		dir += camera.global_transform.basis.z
	if Input.is_action_pressed("left"):
		dir -= camera.global_transform.basis.x
	if Input.is_action_pressed("right"):
		dir += camera.global_transform.basis.x

	dir = dir.normalized()
	if dir != Vector3.ZERO:
		pass
func process_movement_jumps(delta):
	pass
	#velocity.y += GRAVITY * delta
	
	if is_on_floor():
		jump_counter = 0
		


func process_movement(delta):
	
	velocity.y += GRAVITY * delta
	
	if is_on_floor():
		jump_counter = 0
		
	if Input.is_action_just_pressed("jump") and jump_counter < 2:
		jump_counter += 1
		velocity.y = JUMP_SPEED
	var speed = 0
	if Input.is_action_pressed("sprint"):
		speed = sprint_speed
		if run == 0:
			weapon_maneger.currunt_weapon.animation_player.play("run")
		run = 1
	else:
		speed = speeds
		if weapon_maneger.currunt_weapon_slot != "Empty":
			if run == 1:
				weapon_maneger.currunt_weapon.animation_player.play("unrun")
				run = 0
	var target_val = dir  * speed
	
#		currunt_val = currunt_val.linear_interpolate(target_val,ACCEL * delta)
	var accel = ACCEL if is_on_floor() else air_ACCEL
	
	currunt_val = target_val.lerp(currunt_val, accel * delta)

	
	velocity.x = currunt_val.x
	velocity.z = currunt_val.z
	move_and_slide() 

func _input(event):
	if event is InputEventMouseMotion:
		camroot.rotate_x(deg_to_rad(event.relative.y * mouse_sence * -1))
		camroot.rotation_degrees.x = clamp(camroot.rotation_degrees.x,-75,75)
		self.rotate_y(deg_to_rad(event.relative.x * mouse_sence * -1))
	
	
	
	if event is InputEventMouseButton:
		if event.pressed:
				match event.button_index:
					MOUSE_BUTTON_WHEEL_UP:
						weapon_maneger.next_weapon()
					MOUSE_BUTTON_WHEEL_DOWN:
						weapon_maneger.previous_weapon()
func window_activity():
	if Input.is_action_pressed("ui_cancel"):
		if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	else:
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
func head_bob(delta):
	if not weapon_maneger.is_zomed():
		t_bob += delta * velocity.length() * float(is_on_floor())
		camera.transform.origin = _head_bob(t_bob)
	else:
		camera.position.y = 0
func _head_bob(time) -> Vector3:
	var pos  = Vector3.ZERO
	pos.y = sin(time * BOB_FREQ) * BOB_AMP
	return pos
