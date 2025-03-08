extends Sprite2D


var trees_l = [
	preload("res://godot_tree_f/purple/New Piskel (1).png"),
	preload("res://godot_tree_f/purple/New Piskel (2).png"),
	preload("res://godot_tree_f/purple/New Piskel (3).png"),
	preload("res://godot_tree_f/purple/New Piskel (4).png"),
	preload("res://godot_tree_f/purple/New Piskel.png"),
]

var trees = [
	preload("res://godot_tree_f/light_green/New Piskel (2-2).png"),
	preload("res://godot_tree_f/light_green/New-Piskel-2.png"),
	preload("res://godot_tree_f/light_green/New-Piskel-(1-2).png"),
	preload("res://godot_tree_f/light_green/New-Piskel-(3-2) (2).png"),
	preload("res://godot_tree_f/light_green/New-Piskel-(4-2).png"),
	preload("res://godot_tree_f/green/New-Piske-1l.png"),
	preload("res://godot_tree_f/green/New-Piskel-(1-1).png"),
	preload("res://godot_tree_f/green/New-Piskel-(2-1).png"),
	preload("res://godot_tree_f/green/New-Piskel-(3-1).png"),
	preload("res://godot_tree_f/green/New-Piskel-(4-1).png"),
]

var trees_snow = [
	preload("res://godot_tree_f/snow/piskel_snow_1.png"),
	preload("res://godot_tree_f/snow/piskel_snow_2.png"),
	preload("res://godot_tree_f/snow/piskel_snow_3.png"),
	preload("res://godot_tree_f/snow/piskel_snow_4.png"),
	preload("res://godot_tree_f/snow/piskel_snow_5.png"),
	preload("res://godot_tree_f/green/New-Piskel-(3-1).png"),
]

var trees_rain = [
	preload("res://godot_tree_f/rain/piskel_rain_1.png"),
	preload("res://godot_tree_f/rain/piskel_rain_2.png"),
	preload("res://godot_tree_f/rain/piskel_rain_3.png"),
	preload("res://godot_tree_f/green/New-Piskel-(4-1).png"),
	
]

var trees_fire = [
	preload("res://godot_tree_f/fire/piskel_fire_1.png"),
	preload("res://godot_tree_f/fire/piskel_fire_2.png"), 
	preload("res://godot_tree_f/fire/piskel_fire_3.png"),
	preload("res://godot_tree_f/fire/piskel_fire_4.png"),
]

func _ready():
	texture = trees[randi_range(0,4)]

	var shader_material = ShaderMaterial.new()
	var shader = load("res://tree.gdshader")
	shader_material.shader = shader
	# 파라미터 설정
	shader_material.set_shader_parameter("bend_speed", randf_range(0.5,1))
	shader_material.set_shader_parameter("bend_strength", randf_range(0.01,0.05))
	
	material = shader_material


func sprite(thing):
	if thing == "sanak":
		texture = trees[randi_range(0,9)]
		
	if thing == "lava":
		texture = trees_l[randi_range(0,4)]
		
	if thing == "snow":
		texture = trees_snow[randi_range(0,5)]
	
	if thing == "rain":
		texture = trees_rain[randi_range(0,3)]
	var shader_material = ShaderMaterial.new()
	if thing == "fire":
		texture = trees_fire[randi_range(0,3)]
		
	var shader = load("res://tree.gdshader")
	shader_material.shader = shader
	# 파라미터 설정
	shader_material.set_shader_parameter("bend_speed", randf_range(0.5,1))
	shader_material.set_shader_parameter("bend_strength", randf_range(0.01,0.05))
	
	material = shader_material
