extends Node3D

class_name Weapon

var weapon_maneger = null
var player = null
@export var rays : NodePath
@onready var ray = get_node(rays)

var is_equiped = false


@export var weapon_name = "pistol"
@export var weapon_image : Texture


func equip():
	pass
func unequip():
	pass

func is_equip_finished():
	return true
		
		
		
func is_unequip_finished():
	return true



			
func update_ammo(action = "Refresh"):
	var weapon_data = {
		"name" : weapon_name,
		"image" : weapon_image
		
	}
	weapon_maneger.update_hud(weapon_data)


