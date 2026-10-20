extends Node2D
#공격 파티클
@onready var animation_player = $AnimationPlayer
@onready var gpu_particles_2d = $GPUParticles2D
@onready var gpu_particles_2d_2 = $GPUParticles2D2
@onready var ray_cast_2d = $RayCast2D

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.
func attack():

	gpu_particles_2d.restart()
	gpu_particles_2d_2.restart()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	look_at(get_global_mouse_position())
