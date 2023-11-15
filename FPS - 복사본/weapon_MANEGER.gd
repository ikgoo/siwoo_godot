extends Node3D


var all_weapons = {}


var weapons = {}


var is_zoomed = false

var currunt_weapon

var currunt_weapon_slot = "Empty"

var changeing_weapon = false
var unequiped_weapons = false
var weapon_index = int(0)

var hud
func _ready():
	var own = owner
	get_parent().get_node("Camera3D/RayCast3D").add_exception(owner)
	
	hud = owner.get_node("HUD")
	all_weapons = {
		"unarmard" : preload("res://unarmeddd.tscn"),
		"pistol" : preload("res://pistol.tscn"),
		"rifle" : preload("res://rifle.tscn")
	}
	
	weapons = {
		"Empty" : $unarmed,
		"primary" : $pistol,
		"secendary" : $rifle
	}
	for w in weapons:
		if weapons[w] != null:
			weapons[w].weapon_maneger = self
			weapons[w].player = owner
			weapons[w].visible = false
			weapons[w].ray = get_parent().get_node("Camera3D/RayCast3D")
	currunt_weapon = weapons["Empty"]
	change_weapon("Empty")
	
	set_process(false)
			
func _process(delta):
	if unequiped_weapons == false:
		if currunt_weapon.is_unequip_finished() == false:
			return
		unequiped_weapons = true
		currunt_weapon = weapons[currunt_weapon_slot]
		currunt_weapon.equip()
	if currunt_weapon.is_equip_finished() == false:
		return
		
	changeing_weapon = false
	set_process(false)

			
func change_weapon(new_weapon_slot):
	if new_weapon_slot == currunt_weapon_slot:
		currunt_weapon.update_ammo()
		return
	if weapons[new_weapon_slot] == null:
		return
	currunt_weapon_slot = new_weapon_slot
	changeing_weapon = true
	
	weapons[currunt_weapon_slot].update_ammo()
	
	update_weapon_index()
	
	if currunt_weapon != null:
		unequiped_weapons = false
		currunt_weapon.unequip()
		
	set_process(true)
func update_hud(weapon_data):
	var weapon_slot = "1"
	match currunt_weapon_slot:
		"empty":
			weapon_slot = "1"
		"primary":
			weapon_slot = "2"
		"secendary":
			weapon_slot = "3"
	if currunt_weapon is ARMED:
		hud.update_weapon_ui(weapon_data,weapon_slot,currunt_weapon.my_ammo)
	else:
		hud.update_weapon_ui(weapon_data,weapon_slot,0)
	
func update_weapon_index():
	match currunt_weapon_slot:
		"empty":
			weapon_index = 1
		"primary":
			weapon_index = 2
		"secendary":
			weapon_index = 3


func next_weapon():
	weapon_index += 1
	if weapon_index >= weapons.size():
		weapon_index = 0
	change_weapon(weapons.keys()[weapon_index])


	

func fire():
	if not changeing_weapon:
		
		currunt_weapon.fire()

func fire_stop():
	currunt_weapon.fire_stop()


func reload():
	if not changeing_weapon:
		currunt_weapon.reload()






func previous_weapon():
	weapon_index -= 1
	if weapon_index < 0:
		weapon_index = weapons.size() - 1
		
	change_weapon(weapons.keys()[weapon_index])
func zoom():
	if currunt_weapon_slot != "empty":
		if not changeing_weapon:
			is_zoomed = true
			currunt_weapon.zoom()
func unzoom():
	if currunt_weapon_slot != "empty":
		if not changeing_weapon:
			is_zoomed = false
			currunt_weapon.unzoom()

func is_zomed():
	if is_zoomed:
		return true
	if not is_zoomed:
		return false
