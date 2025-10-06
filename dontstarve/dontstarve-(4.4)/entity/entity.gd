@tool
extends Node3D
@onready var sprite_3d = $Sprite3D
var hp
@export var thing: entity = null:
	set(value):
		print("value:", value)
		thing = value
		if thing:
			if sprite_3d:
				sprite_3d.texture = thing.img
				sprite_3d.hframes = thing.frames
				sprite_3d.vframes = thing.y_frames
			hp = thing.hp

func take_damage(damage:int):
	hp -= damage
	if hp <= 0:
		sprite_3d.modulate = Color()
