extends Node2D

@onready var animation_player = $AnimationPlayer
const LINJA_SLASH = preload("uid://darpwh46l7a0q")
@onready var animated_sprite_2d = $AnimatedSprite2D

var  off = false
func _ready():
	animation_player.play("summon")
	if Gamemaneger.character.bow.position.x < 0:
		off = true
		animated_sprite_2d.flip_h = true
	else:
		off = false
		animated_sprite_2d.flip_h = false
func end():
	animation_player.play("go")



func summon():
	
	var slash = LINJA_SLASH.instantiate()
	slash.off = off
	slash.global_position = global_position
	get_parent().add_child(slash)
	
func attack():
	animation_player.play("attack")
