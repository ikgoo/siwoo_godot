extends Control

var water_t_on_o = false
var tempe_t_on_o = false
var planet
@onready var animation_player = $"../../AnimationPlayer"
@onready var h_slider = $show_me_the_p/HSlider
@onready var label = $show_me_the_p/Label

@onready var sun = $"../../Node2D/sun"
@onready var node_2d = $"../../Node2D"
@onready var water_n = $"../../water_n"
@onready var watering = $"../../water_n/watering"
var wateringv = false
var suning = false
var sun_rot
var up_down = "down"
var mouse_up = false
var oxyen_t_on_o = false
@onready var pop_up = $pop_up
@onready var button_3 = $Button3

# Called when the node enters the scene tree for the first time.
func _ready():
	print(button_3.position)
	print(button_3.global_position)
	planet = get_tree().get_root().get_child(1)



# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if sun_rot:
		sun.sprite_2d.rotation += 1
		
	if Gamemanger.camera_zoom:
		

		watering.scale = Gamemanger.camera_zoom / 2
		
		node_2d.scale = Gamemanger.camera_zoom / 2

		

		
	if Gamemanger.my_thing == "water":
		
		var mouse_pos = get_global_mouse_position()
		water_n.position = mouse_pos
		

		
	if Gamemanger.my_thing == "sun":
		
		var mouse_pos = get_global_mouse_position()
		
		node_2d.visible = true
		node_2d.position = mouse_pos
		


func _input(event):
	
	if event.is_action_pressed("ui_cancel"):
		Gamemanger.my_thing = null
		watering.emitting = false
		sun_rot = false
		node_2d.visible = false
		
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			if not mouse_up:

				
				if Gamemanger.my_thing == "water":
					watering.emitting = true
					
				if Gamemanger.my_thing == "sun":
					sun_rot = true
					sun.mesh_instance_2d.visible = true
					
		elif event.button_index == MOUSE_BUTTON_LEFT and event.is_released():

			watering.emitting = false
			sun_rot = false
			node_2d.visible = false
			sun.mesh_instance_2d.visible = false




func _on_water_button_down():
	planet.value_ws = 10
	h_slider.value = 10
	if not wateringv:

		planet.type = "water"
		Gamemanger.my_thing = "water"
		wateringv = true
		suning = false
	else:
		wateringv = false
		planet.type = null
		Gamemanger.my_thing = null
		
	if planet.type:
		if up_down == "down":
			animation_player.play("coming_up")
			up_down = "up"
	else:
		if up_down == "up":
			animation_player.play("coming_down")
			up_down = "down"
func _on_sun_button_down():
	planet.value_ws = 10
	h_slider.value = 10
	if not suning:

		planet.type = "tempe"
		Gamemanger.my_thing = "sun"
		wateringv = false
		suning = true
	else:
		suning = false
		planet.type = null
		Gamemanger.my_thing = null
	if planet.type:
		if up_down == "down":
			animation_player.play("coming_up")
			up_down = "up"
	else:
		if up_down == "up":
			animation_player.play("coming_down")
			up_down = "down"

func _on_button_button_down():
	if water_t_on_o:
		planet.water_tile_load(false)
		water_t_on_o = false
		tempe_t_on_o = false
		oxyen_t_on_o = false
	else:
		water_t_on_o = true
		tempe_t_on_o = false
		oxyen_t_on_o = false
		planet.water_tile_load(true)


func _on_button_2_button_down():
	if tempe_t_on_o:
		planet.tempe_tile_load(false)
		tempe_t_on_o = false
		water_t_on_o = false
		oxyen_t_on_o = false
	else:
		tempe_t_on_o = true
		water_t_on_o = false
		oxyen_t_on_o = false
		planet.tempe_tile_load(true)


func _on_first_p_mouse_entered():
	mouse_up = true


func _on_show_me_the_p_mouse_entered():
	mouse_up = true


func _on_button_mouse_entered():
	mouse_up = true


func _on_button_2_mouse_entered():
	mouse_up = true


func _on_button_mouse_exited():
	# 마우스가 Panel 영역을 벗어났는지 확인
	var mouse_pos = get_global_mouse_position()
	var panel_rect = $Button.get_global_rect()
	
	if not panel_rect.has_point(mouse_pos):
		mouse_up = false


func _on_button_2_mouse_exited():
	# 마우스가 Panel 영역을 벗어났는지 확인
	var mouse_pos = get_global_mouse_position()
	var panel_rect = $Button2.get_global_rect()
	
	if not panel_rect.has_point(mouse_pos):
		mouse_up = false


func _on_show_me_the_p_mouse_exited():
	# 마우스가 Panel 영역을 벗어났는지 확인
	var mouse_pos = get_global_mouse_position()
	var panel_rect = $show_me_the_p.get_global_rect()
	
	if not panel_rect.has_point(mouse_pos):
		mouse_up = false


func _on_first_p_mouse_exited():
	# 마우스가 Panel 영역을 벗어났는지 확인
	var mouse_pos = get_global_mouse_position()
	var panel_rect = $first_p.get_global_rect()
	
	if not panel_rect.has_point(mouse_pos):
		mouse_up = false



func _on_h_slider_value_changed(value):
	watering.emitting = false
	watering.amount = value * 10
	planet.value_ws = value
	label.text = str(value) + "%"


func pop_up_on(thing):
	if thing == "fire":
		pop_up.animation_player.stop()
		pop_up.animation_player.play("pop_up")
		pop_up.fire()
	if thing == "fire_off":
		pop_up.animation_player.stop()
		pop_up.animation_player.play("pop_up")
		pop_up.fire_end()
		
		
		


func _on_button_3_button_down():
	if oxyen_t_on_o:
		planet.oxyen_tile_load(false)
		water_t_on_o = false
		tempe_t_on_o = false
		oxyen_t_on_o = false
	else:
		water_t_on_o = false
		tempe_t_on_o = false
		oxyen_t_on_o = true
		planet.oxyen_tile_load(true)


func _on_button_3_mouse_entered():
	mouse_up = true


func _on_button_3_mouse_exited():
	var mouse_pos = get_global_mouse_position()
	var panel_rect = $first_p.get_global_rect()
	
	if not panel_rect.has_point(mouse_pos):
		mouse_up = false
