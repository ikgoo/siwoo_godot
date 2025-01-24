extends Sprite2D

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

func _ready():
	texture = trees[randi_range(0,randi_range(5,8))]

	var shader_material = ShaderMaterial.new()
	var shader = load("res://tree.gdshader")
	shader_material.shader = shader
	# 파라미터 설정
	shader_material.set_shader_parameter("bend_speed", randf_range(0.5,1))
	shader_material.set_shader_parameter("bend_strength", randf_range(0.01,0.05))
	
	material = shader_material
