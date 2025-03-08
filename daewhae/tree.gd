extends Node2D
@onready var sprite_2d_l = $Node2D/Sprite2D_l

@onready var area_2d = $Area2D
@onready var animation_player = $AnimationPlayer
var died = true
var fire = 0

var pos
# Called when the node enters the scene tree for the first time.
func _ready():
	animation_player.play("grow")
	

func _on_area_2d_area_entered(area):
	if died:
		
		get_tree().get_root().get_child(1).trees.erase(pos)

		queue_free()

func on():
	
	died = false
	visible = true

func sp_sprite(tree_temp):
	sprite_2d_l.sprite(tree_temp)

func fire_a():
	$Node2D/AnimatedSprite2D.visible = true
	$Node2D/AnimatedSprite2D2.visible = true
	$Node2D/AnimatedSprite2D3.visible = true
	animation_player.play("on_fire")


func fire_a_f():
	$Node2D/AnimatedSprite2D.visible = true
	$Node2D/AnimatedSprite2D2.visible = true
	$Node2D/AnimatedSprite2D3.visible = true

func fire_time():
	fire += 1
	if fire == 10:
		get_tree().get_root().get_child(1).trees.erase(pos)
		queue_free()
		
