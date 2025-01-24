extends Node3D

@onready var animation_player = %AnimationPlayer

func _input(_event):
	if Input.is_action_just_pressed("a"):
		animation_player.play("default")
