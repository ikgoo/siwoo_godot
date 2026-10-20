extends Node2D

var on = false
# Called when the node enters the scene tree for the first time.

@onready var animation_player = $AnimationPlayer
@onready var animated_sprite_2d = $AnimatedSprite2D
@onready var animated_sprite_2d_2 = $AnimatedSprite2D2
@onready var label = $AnimatedSprite2D2/Label2

@onready var timer = $Timer
@onready var roll = $roll_e
@onready var label_3 = $Label

@onready var label2= $AnimatedSprite2D/Label

var is_it = false
var now_s 
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if on:
		
		if Input.is_action_just_pressed("f"):
			if Gamemaneger.in_money >= 50:
				if timer.is_stopped():
					timer.start()
					Gamemaneger.in_money -= 50
				else:
					return
			else:
				animation_player.play("not_m")
			roll.roll(Gamemaneger.random_scroll())
			get_parent().animation_player_2.play("make")
				
		if is_it:
			if Input.is_action_just_pressed("e"):
				label.visible = false
				Gamemaneger.get_scroll(now_s)
				now_s = null
				is_it = false
				Gamemaneger.ui.hide_scroll()
				roll.hide_t()
				label2.text = "make item"
		elif Input.is_action_just_pressed("e"):
			Gamemaneger.ui.make_ui.open()
func _on_area_2d_area_entered(area):
	on = true
	animation_player.play("on")
	if is_it:
		Gamemaneger.ui.show_scroll(now_s)
	animated_sprite_2d.visible = true
	animated_sprite_2d_2.visible = true


func _on_area_2d_area_exited(area):
	animated_sprite_2d.visible = false
	animated_sprite_2d_2.visible = false
	on = false
	if is_it:
		Gamemaneger.ui.hide_scroll()
func get_random_scroll():
	roll.roll(Gamemaneger.random_scroll())
	Gamemaneger.r_get = null
	get_parent().animation_player_2.play("make")
func show_scroll(scroll:Scroll):
	Gamemaneger.ui.show_scroll(scroll)
	is_it = true
	now_s = scroll
	label2.text = "get item"

func l_off():
	label_3.visible = true
	
func l_on():
	label_3.visible = true
