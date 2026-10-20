extends CharacterBody2D
@onready var sprite_2d = $Sprite2D
@onready var animation_player = $AnimationPlayer
@onready var animated_sprite_2d_2 = $AnimatedSprite2D2

var thing : Scroll
func _ready():
	animation_player.play("idle")
func _on_area_2d_area_entered(area):
	area.get_parent().can_get_item.append(self)
	animated_sprite_2d_2.visible = true

func _on_area_2d_area_exited(area):
	var list = area.get_parent().can_get_item
	list.erase(self)
	animated_sprite_2d_2.visible = self in list
