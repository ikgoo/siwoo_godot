extends RigidBody3D

var mouse_sensitivity := 0.001
var twist_input := 0.0
var pitch_input := 0.0

@onready var twist := $twist
@onready var pitch := $twist/Node3D
var jumped = false
var jump g
# Called when the node enters the scene tree for the first time.
func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	var input := Vector3.ZERO
	input.x = Input.get_axis("move_left","move_right")
	input.z = Input.get_axis("move_up","move_down")
	if Input.is_action_just_pressed("ui_accept"):
		jumped = True
		
	apply_central_force(twist.basis * input   * 1200.0 * delta)
	if Input.is_action_pressed("mouse"):
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	else:
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	
	twist.rotate_y(twist_input)
	
	pitch.rotate_x(pitch_input)
	pitch.rotation.x = clamp(pitch.rotation.x,deg_to_rad(-30),deg_to_rad(30))
	twist_input = 0.0
	pitch_input = 0.0
	
	
func _unhandled_input(event: InputEvent)-> void:
	
	if event is InputEventMouseMotion:
		if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
			twist_input = - event.relative.x * mouse_sensitivity
			pitch_input = - event.relative.y * mouse_sensitivity
			
