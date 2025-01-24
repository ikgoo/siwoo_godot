extends Node3D
@onready var mesh_instance_3d = $MeshInstance3D

@onready var node_3d = $Node3D

@onready var charater = $"../Jet"


var rocks = {
	r1 = preload("res://Objects/bush/_bush_1.tscn"),
	r2 = preload("res://Objects/bush/_bush_2.tscn"),
	r3 = preload("res://Objects/bush/_bush_3.tscn"),
	r4 = preload("res://Objects/bush/_bush_4.tscn"),
	r5 = preload("res://Objects/bush/_bush_5.tscn"),
}


func _ready():
	var rock_keys = rocks.keys()  # [r1, r2, r3, r4] 배열 얻기
	var random_key = rock_keys[randi() % rock_keys.size()]  # 무작위 키 선택
	var rock = rocks[random_key].instantiate()
	node_3d.add_child(rock) # 선택된 바위 모델 반환

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	
	if position.z > charater.position.z + 10:
		queue_free()
