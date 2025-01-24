extends Node2D
@onready var area_2d = $Area2D
@onready var animation_player = $AnimationPlayer
var died = true

func _ready():
	animation_player.play("grow")
	visible = false
	

func _on_area_2d_area_entered(area):
	if died:
		queue_free()





func _on_animation_player_animation_finished(anim_name):
	died = false
	visible = true


func _on_timer_timeout():
	pass # Replace with function body.


func on():
	died = false
	visible = true
