extends Node2D

const BLUE_G = preload("res://blue_g.png")
const RED_G = preload("res://red_g (18).png")
@onready var animated_sprite_2d = $AnimatedSprite2D
@onready var animation_player = $AnimationPlayer
var color = "red"
func _ready():

	animated_sprite_2d.animation = "red"
	animation_player.play("going")
	
func on(thing):
	if thing == "blue":
		animated_sprite_2d.animation = "blue"
		color = "blue"

func _process(delta):
	pass



func  go():
	var tween = create_tween()
	var go_val = Vector2(global_position.x + randi_range(-20,20),global_position.y + randi_range(-20,20))
	print(go_val)
	if go_val.x < 64 * 16 and go_val.x > 0 and go_val.y < 64 * 16 and go_val.y > 0:
		tween.tween_property(self, "position", go_val, 10)
			


func _on_area_2d_mouse_entered():
	get_tree().get_root().get_child(1).now_worm = self
	

func _on_area_2d_mouse_exited():
	get_tree().get_root().get_child(1).now_worm = null


func jip():
	animation_player.stop()
	animated_sprite_2d.frame = 2

func nut():
	animation_player.play("going")
	
