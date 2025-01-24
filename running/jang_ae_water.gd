extends Node3D

@onready var node_3d = $Node3D

@onready var charater = $"../Jet"
var rot

var rocks = {
	r1 = preload("res://fbx/Low_Poly_Rock_Small_001.fbx"),
	r5 = preload("res://fbx/Low_Poly_Rock_001.fbx"),
	r6 = preload("res://fbx/Low_Poly_Rock_002.fbx"),
}


func _ready():
	rot = randi_range(-1,1)
	var rock_keys = rocks.keys()  # [r1, r2, r3, r4] 배열 얻기
	var random_key = rock_keys[randi() % rock_keys.size()]  # 무작위 키 선택
	var rock = rocks[random_key].instantiate()
	node_3d.add_child(rock) # 선택된 바위 모델 반환

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):

	if position.z > charater.position.z:
		queue_free()
	if rot > 0:
		rotation.x += 0.005
		rotation.y += 0.005
	if rot < 0:
		rotation.x -= 0.005
		rotation.y -= 0.005
	




# 랜덤으로 선택
