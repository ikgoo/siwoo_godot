extends Control

var weapon_ui
var health_ui = 100
var display_ui
var slot_ui


func enter_tree():
	weapon_ui = $ColorRect/ColorRect/weapon_slot
	health_ui = $ColorRect/health
	

func update_weapon_ui(weapon_data,weapon_slot,ammo_in_bag):
	$ColorRect/weapon.text = weapon_data["name"] + ": / " + str(ammo_in_bag)
	$ColorRect/ColorRect/weapon_slot.text = weapon_slot
	$ColorRect/health.text = str(health_ui)
func _process(delta):
	$ColorRect/health.text = str(health_ui)
