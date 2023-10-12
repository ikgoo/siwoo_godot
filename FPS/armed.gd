extends Weapon

class_name ARMED

@export var animation_player_path : NodePath
@onready var animation_player = get_node(animation_player_path)
@export var test : MeshInstance3D
@export var my_ammo : int
@export var boom : GPUParticles3D
@export var my_ammofull : int
@export var raycast : RayCast3D
var is_fireing = false
var is_reoading = false
var is_zoomed = false
@export var weapon_what : String
@export var charater : Timer
var ammo_in_bag = 15
@export var extra_ammo = 30
@export var mag_size = ammo_in_bag
var one_stops = false
@export var damage = 10
@export var fir_rate = 1.0
var ok_naw_end = false
@export var impact_effect : PackedScene
@export var muzzle_flash_path : NodePath
@onready var muzzle_flash = get_node(muzzle_flash_path)

@export var equip_speed = 1.0
@export var unequip_speed = 1.0
@export var reload_speed = 2.3
@export var audio_path : NodePath
@onready var audio = get_node(audio_path)


func _process(delta):
	if ok_naw_end:
		fire_stop()
	var weapon_data = {
		"name" : weapon_name,
		"ammo" : str(my_ammo),
		"image" : weapon_image,
		"ExtraAmmo" :  str(extra_ammo)
	}
	weapon_maneger.update_hud(weapon_data)

func reload():
	if not is_zoomed:
	
		if my_ammo < my_ammofull:
			is_fireing = false
			
			animation_player.play("reload",-1.0)
			is_reoading = true
			my_ammo = my_ammofull
		
func fire():
	if not is_reoading:
#		if ammo_in_bag > 0:
		if not is_fireing:
			if not ok_naw_end:
				if not my_ammo <= 0:  
					ok_naw_end = false
					is_fireing = true
					audio.play()
					
					animation_player.play("fire",-1.0)
					charater.start(0.1)
					ray_cast()
				if ammo_in_bag <= 0:
					reload()
			
func fire_stop():
	is_fireing = false
	ok_naw_end = false
	is_reoading = false
	
func one_stop():
	one_stops = true
func fire_bullet():
	muzzle_flash.emitting = true
	update_ammo("consume") 
	
	ray.force_raycast_update()


func equip():
	animation_player.play("equip", -1.0,equip_speed)
	is_reoading = false
func unequip():
	animation_player.play("unequip", -1.0,unequip_speed)

func is_equip_finished():
	if is_equiped:
		return false
	else:
		return true
		
		
		
func is_unequip_finished():
	if is_equiped:
		return false
	else:
		return true


func on_animation_finished(anim_name):
	match anim_name:
		"unequip":
			is_equiped = false
		"equip":
			is_equiped = true
		"reload":
			is_reoading = false
			update_ammo(reload)
			
			
func update_ammo(action = "Refresh",additional_ammo = 0):
	match action:
		"consume":
			my_ammo -= 1
		"reload":
#			var ammo_needed = mag_size - ammo_in_bag
#
#			if extra_ammo > ammo_needed:
#				ammo_in_bag = mag_size
#				extra_ammo -= ammo_needed
#			else:
#				ammo_in_bag += extra_ammo
#				extra_ammo = 0
			my_ammo = 15
		"add":
			extra_ammo += additional_ammo
	
	
	var weapon_data = {
		"name" : weapon_name,
		"ammo" : str(my_ammo),
		"image" : weapon_image,
		"ExtraAmmo" :  str(extra_ammo)
	}
	weapon_maneger.update_hud(weapon_data)


func show_weapon():
	visible = true
	
func  hide_weapon():
	visible = false
func zoom():
	if not is_zoomed:

		if not is_reoading:
			animation_player.play("zoom")
			is_zoomed = true

func unzoom():
	if not is_reoading:
		animation_player.play("unzoom")
		is_zoomed = false

func ok_naw():
	ok_naw_end = true

func ray_cast():
	if raycast.is_colliding():
			boom.global_position = raycast.get_collision_point()
			boom.emitting = true
			var collider = raycast.get_collider()
			var ttt = collider.collision_layer
			if ttt == 256:
				ttt = 9
			if ttt == 9:
				raycast.get_collider().queue_free()
				
		
func is_zom():
	return is_zoomed
