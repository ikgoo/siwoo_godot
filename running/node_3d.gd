extends Node3D
@onready var mesh_instance_3d_4 = $MeshInstance3D4
@onready var charater = $"../Jet"
@onready var mesh_instance_3d_3 = $MeshInstance3D3
@onready var mesh_instance_3d_2 = $MeshInstance3D2
@onready var mesh_instance_3d = $MeshInstance3D


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if mesh_instance_3d_4.global_position.x - charater.global_position.x < 40:
		position.x += 20
	if mesh_instance_3d_3.global_position.x - charater.global_position.x > -50:
		position.x -= 20
	if mesh_instance_3d_2.global_position.z - charater.global_position.z > -100:
		position.z -= 400
	if mesh_instance_3d_2.global_position.z - charater.global_position.z > -50:
		position.z += 400
	if mesh_instance_3d.global_position.y - charater.global_position.y > 50:
		position.y += 100
	if mesh_instance_3d.global_position.y - charater.global_position.y > -25:
		position.y -= 100
