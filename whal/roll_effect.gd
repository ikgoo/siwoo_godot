extends Node2D

@onready var animation_player = $AnimationPlayer
@onready var timer = $Timer

@onready var sprite_2d = $Sprite2D

var n_roll
func roll(scroll : Scroll):
	n_roll = scroll
	sprite_2d.texture = scroll.texture
	if scroll.rarity == "normal":
		animation_player.play("normal")
	elif scroll.rarity == "rare":
		animation_player.play("rare")
	elif scroll.rarity == "epic":
		animation_player.play("epic")
	else:
		animation_player.play("mistic")


func ani_end():
	get_parent().show_scroll(n_roll)

func hide_t():
	sprite_2d.texture = null
