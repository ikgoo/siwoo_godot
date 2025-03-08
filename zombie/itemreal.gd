extends Node3D
@export var item : Inven_Item
var mesh_instance = null
@export var mesh_i : PackedScene
func _ready():
	var d = mesh_i.instantiate()
	if d.mesh and d.mesh.surface_get_material(0):
		# 메테리얼 복제
		var material = d.mesh.surface_get_material(0).duplicate()
		# 복제된 메테리얼을 설정
		d.set_surface_override_material(0, material)

		# 예시: 빨간색으로 변경

	add_child(d)
	mesh_instance = d
