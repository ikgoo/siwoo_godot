extends Node2D

@onready var animated_sprite_2d = $AnimatedSprite2D

var off = false

func _process(delta):
	if off:
		global_position.x -=  10
		animated_sprite_2d.flip_h = true
	else:
		global_position.x += 10
		animated_sprite_2d.flip_h = false




func _on_area_2d_body_shape_entered(body_rid, body, body_shape_index, local_shape_index):
	if  body.get_collision_layer_value(9):
		Gamemaneger.getting_hurt(body,true,false,Gamemaneger.damage*1.2)
	else:
		Gamemaneger.getting_hurt(body,false,false,Gamemaneger.damage*1.2)
	body.hurt(null,true)


func _on_timer_timeout():
	queue_free()
