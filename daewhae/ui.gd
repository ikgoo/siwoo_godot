extends Control

var water_t_on_o = false
var tempe_t_on_o = false
var planet
@onready var animation_player = $"../../AnimationPlayer"
@onready var h_slider = $show_me_the_p/HSlider
@onready var label = $show_me_the_p/Label
@onready var watering = $water_n/watering
@onready var sun = $"../../Node2D/sun"
@onready var node_2d = $"../../Node2D"
var wateringv = false
var suning = false
var sun_rot
var up_down = "down"
var mouse_up = false
var oxyen_t_on_o = false
@onready var pop_up = $pop_up
@onready var button_3 = $Button3
@onready var water_n = $water_n

@onready var tempe_l = $tmepe
@onready var onshil_l = $onshil
@onready var seed_p = $"../../seed_p"

var seed_ssap = true
func _ready():
	planet = get_tree().get_root().get_child(1)




func _process(delta):

	tempe_l.text = "온도 : " + str(snapped(planet.tempe,0.1)) + "°C"
	onshil_l.text = "온실가스 : " + str(snapped(planet.onshil,0.01)) + "ppm"
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
		
	elif not Gamemanger.my_thing == "sun":
		node_2d.visible = false

func _input(event):
	if event.is_action_pressed("ui_cancel"):
		Gamemanger.my_thing = null
		sun_rot = false
		node_2d.visible = false
		planet.seed = null
		
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			if not mouse_up:

				
				if Gamemanger.my_thing == "water":
					watering.emitting = true
					if planet.tempe > 60:
						watering.get_child(0).emitting = true
					
				if Gamemanger.my_thing == "sun":
					sun_rot = true
					sun.mesh_instance_2d.visible = true
			if planet.seed:
				if seed_ssap:
					if not planet.mouse_on_s:
							var camera = get_viewport().get_camera_2d()
							var zoom = camera.zoom
							var mouse_position = camera.get_global_position() + ((get_viewport().get_mouse_position() - get_viewport().get_visible_rect().size / 2) / zoom)
							var current_tile_pos = planet.grass_tilemap.local_to_map(planet.grass_tilemap.to_local(mouse_position))
							var water_ch = [0,0]
							var tempe_ch = [0,0]
							var oxyen_ch = [0,0]
							match planet.seed:
								"warm":
									planet.grass_tilemap.set_layer_modulate(0, Color(0.5, 0.9, 0.4))
									water_ch = [50,80]
									tempe_ch = [20,35]

								"fire":
									planet.grass_tilemap.set_layer_modulate(0, Color(0.95, 0.76, 0.44))
									water_ch = [30,60]
									tempe_ch = [35,60]

								"snow":
									planet.grass_tilemap.set_layer_modulate(0, Color(1.0, 1.0, 1.0))
									water_ch = [50,80]
									tempe_ch = [15,25]

								"rain":
									planet.grass_tilemap.set_layer_modulate(0, Color(0.45, 0.65, 0.5))
									water_ch = [60,100]
									tempe_ch = [20,35]

							if planet.all_thing.has(current_tile_pos):
								if planet.all_thing[current_tile_pos]["water"] > water_ch[0] and planet.all_thing[current_tile_pos]["water"] < water_ch[1]:
									if planet.tempe > tempe_ch[0] and planet.tempe < tempe_ch[1]:
										
										planet.set_seed(planet.seed,current_tile_pos)
										seed_ssap = false

									else:
										print(planet.all_thing[current_tile_pos]["tempe"])
										if planet.all_thing[current_tile_pos]["tempe"] > tempe_ch[0]:
											pop_up.text_thing("온도가 너무 높습니다")
											print(3)
										else:
											pop_up.text_thing("온도가 낮습니다")
											print(4)
								else:
									print(planet.all_thing[current_tile_pos]["water"])
									if planet.all_thing[current_tile_pos]["water"] > water_ch[0]:
										pop_up.text_thing("수분이 너무 많습니다")
										print(5)
									else:
										pop_up.text_thing("수분이 부족합니다")
										print(6)
							planet.seed = null
		elif event.button_index == MOUSE_BUTTON_LEFT and event.is_released():
			sun_rot = false
			watering.emitting = false
			watering.get_child(0).emitting = false

							
							
							
							
		elif event.button_index == MOUSE_BUTTON_LEFT and event.is_released():
		
			sun_rot = false
			node_2d.visible = false
			sun.mesh_instance_2d.visible = false



func _on_button_button_down():
	planet.grass_feeling_tile_load(false)
	if not water_t_on_o:
		water_t_on_o = true
		planet.water_tile_load(true)
		up_down = "down"
	else:
		water_t_on_o = false
		planet.water_tile_load(false)


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

	mouse_up = false



func _on_h_slider_value_changed(value):
	watering.get_child(0).emitting = false
	watering.emitting = false
	watering.amount = value * 15
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
	planet.grass_feeling_tile_load(false)
	if not oxyen_t_on_o:
		oxyen_t_on_o = true
		planet.oxyen_tile_load(true)
		up_down = "down"
	else:
		oxyen_t_on_o = false
		planet.oxyen_tile_load(false)


func _on_button_3_mouse_entered():
	mouse_up = true


func _on_button_3_mouse_exited():
	var mouse_pos = get_global_mouse_position()
	var panel_rect = $first_p.get_global_rect()
	
	if not panel_rect.has_point(mouse_pos):
		mouse_up = false


func _on_seeds_button_down():
	animation_player.play("seed_up")


func _on_back_button_down():
	animation_player.play("seed_down")


func _on_fire_seed_button_down():
	if seed_ssap:
		if planet.seed == "warm":
			planet.seed = null
		else:
			planet.seed = "warm"
	else:
		pop_up.text_thing("이미 씨앗을 심었습니다")

func _on_fire_seed_2_button_down():
	if seed_ssap:
		if planet.seed == "fire":
			planet.seed = null
		else:
			planet.seed = "fire"
	else:
		pop_up.text_thing("이미 씨앗을 심었습니다")

func _on_fire_seed_3_button_down():
	if seed_ssap:
		if planet.seed == "snow":
			planet.seed = null
		else:
			planet.seed = "snow"
	else:
		pop_up.text_thing("이미 씨앗을 심었습니다")

func _on_fire_seed_4_button_down():
	if seed_ssap:
		if planet.seed == "rain":
			planet.seed = null
		else:
			planet.seed = "rain"
	else:
		pop_up.text_thing("이미 씨앗을 심었습니다")


func _on_seed_p_mouse_entered():
	planet.mouse_on_s = true


func _on_seed_p_mouse_exited():

	planet.mouse_on_s = false


func _on_diction_button_down():
	pass # Replace with function body.





func _on_water_button_down():
	node_2d.visible = false
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

		planet.type = "sun"
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


func _on_worm_button_down():
	animation_player.play("worm_up")


func _on_back_w_button_down():
	animation_player.play("worm_down")


func _on_fire_button_down():
	if get_tree().get_root().get_child(1).can_add_worm():
		var ggun_scene = preload("res://ggun.tscn")
		var new_ggun = ggun_scene.instantiate()
		
		new_ggun.get_node("sprite").animation = "red"
		
		var mouse_pos = get_global_mouse_position()
		new_ggun.global_position = mouse_pos
		
		get_tree().get_root().get_child(1).add_child(new_ggun)
		get_tree().get_root().get_child(1).now_worm = new_ggun
		get_tree().get_root().get_child(1).worms.append(new_ggun)
		
		new_ggun.start_drag()
	else:
		pop_up.text_thing("균이 너무 많습니다")

func _on_fireco_button_down():
	if get_tree().get_root().get_child(1).can_add_worm():
		var ggun_scene = preload("res://ggun.tscn")
		var new_ggun = ggun_scene.instantiate()
		
		new_ggun.set_as_oxygen_remover()
		
		var mouse_pos = get_global_mouse_position()
		new_ggun.global_position = mouse_pos
		
		get_tree().get_root().get_child(1).add_child(new_ggun)
		get_tree().get_root().get_child(1).now_worm = new_ggun
		get_tree().get_root().get_child(1).worms.append(new_ggun)
		
		new_ggun.start_drag()
	else:
		pop_up.text_thing("균이 너무 많습니다")

func _on_ice_button_down():
	if get_tree().get_root().get_child(1).can_add_worm():
		var ggun_scene = preload("res://ggun.tscn")
		var new_ggun = ggun_scene.instantiate()
		
		new_ggun.set_as_onshil_remover()
		
		var mouse_pos = get_global_mouse_position()
		new_ggun.global_position = mouse_pos
		
		get_tree().get_root().get_child(1).add_child(new_ggun)
		get_tree().get_root().get_child(1).now_worm = new_ggun
		get_tree().get_root().get_child(1).worms.append(new_ggun)
		
		new_ggun.start_drag()
	else:
		pop_up.text_thing("균이 너무 많습니다")

func _on_iceco_button_down():
	if get_tree().get_root().get_child(1).can_add_worm():
		var ggun_scene = preload("res://ggun.tscn")
		var new_ggun = ggun_scene.instantiate()
		
		new_ggun.set_as_onshil_creator()
		
		var mouse_pos = get_global_mouse_position()
		new_ggun.global_position = mouse_pos
		
		get_tree().get_root().get_child(1).add_child(new_ggun)
		get_tree().get_root().get_child(1).now_worm = new_ggun
		get_tree().get_root().get_child(1).worms.append(new_ggun)
		
		new_ggun.start_drag()
	else:
		pop_up.text_thing("균이 너무 많습니다")

func _on_back_w_2_button_down():
	get_tree().get_root().get_child(1).remove_all_worms()


func _on_button_4_mouse_entered():
	mouse_up = true


func _on_button_4_mouse_exited():
	mouse_up = false


func _on_button_4_button_down():
	# 현재 상태 토글
	planet.grass_feeling_active = !planet.grass_feeling_active
	
	# 다른 타일맵 표시 끄기
	planet.water_tile_load(false)
	planet.oxyen_tile_load(false)
	planet.tempe_tile_load(false)
	
	if planet.grass_feeling_active:
		# 풀의 느낌 타일 표시 시작
		planet.grass_feeling_tile_load(true)
	else:
		# 풀의 느낌 타일 표시 중지
		planet.grass_feeling_tile_load(false)
