extends CharacterBody3D

@onready var camroot = $camroot
var mouse_sence = 0.1

@onready var camera = $camroot/Camera3D

var currunt_val = Vector3.ZERO
var dir = Vector3.ZERO

const SPEED = 10
const SPRINT_SPEED = 20
const ACCEL = 15.0

const GRAVITY = -40.0
const JUMP_SPEED = 15
var jump_counter = 0
const air_ACCEL = 9.0

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	
func _physics_process(delta):
		dir = Vector3.ZERO
		
		if Input.is_action_pressed("up"):
			dir -= camera.global_transform.basis.z
		if Input.is_action_pressed("down"):
			dir += camera.global_transform.basis.z
		if Input.is_action_pressed("left"):
			dir -= camera.global_transform.basis.x
		if Input.is_action_pressed("right"):
			dir += camera.global_transform.basis.x
		
		velocity.y += GRAVITY * delta
		
		if is_on_floor():
			jump_counter = 0
			
		if Input.is_action_just_pressed("jump") and jump_counter < 2:
			jump_counter += 1
			velocity.y = JUMP_SPEED
		
		
		var speed = SPRINT_SPEED if Input.is_action_pressed("sprint") else SPEED
		var target_val = dir  * speed
		
#		currunt_val = currunt_val.linear_interpolate(target_val,ACCEL * delta)
		var accel = ACCEL if is_on_floor() else air_ACCEL
		
		currunt_val = target_val.lerp(currunt_val, accel * delta)

		
		velocity.x = currunt_val.x
		velocity.z = currunt_val.z
		move_and_slide() 
func _process(delta):

	window_activity()

func _input(event):
	if event is InputEventMouseMotion:
		camroot.rotate_x(deg_to_rad(event.relative.y * mouse_sence * -1))
		camroot.rotation_degrees.x = clamp(camroot.rotation_degrees.x,-75,75)
		self.rotate_y(deg_to_rad(event.relative.x * mouse_sence * -1))
	
func window_activity():
	if Input.is_action_pressed("ui_cancel"):
		if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	else:
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
