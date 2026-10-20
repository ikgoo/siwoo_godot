extends Area2D
@onready var gpu_particles_2d = $GPUParticles2D
@onready var sprite_2d_2 = $Sprite2D2
@onready var animated_sprite_2d_2 = $AnimatedSprite2D2

var is_earned = false

func action() -> void:
	if is_earned:
		return
	Gamemaneger.get_scroll(Gamemaneger.random_scroll())
	is_earned = true
	gpu_particles_2d.emitting = false
	sprite_2d_2.visible = false
	animated_sprite_2d_2.visible = false


func _on_area_entered(area):
	animated_sprite_2d_2.visible = true


func _on_area_exited(area):
	animated_sprite_2d_2.visible = false
