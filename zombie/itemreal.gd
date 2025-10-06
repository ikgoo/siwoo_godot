extends Node3D
@export var item : Inven_Item
var mesh_instance = null
@export var mesh_i : PackedScene
func _ready():
	mesh_instance = mesh_i.instantiate()
	if mesh_instance.mesh:
	  # 메시 자체를 복제
		mesh_instance.mesh = mesh_instance.mesh.duplicate()
	  # 메테리얼 복제
		var material = StandardMaterial3D.new()
	  # 복제된 메테리얼을 메시에 설정
		mesh_instance.mesh.surface_set_material(0, material)
	  # 초기 색상 설정
		material.albedo_color = Color(randf_range(0, 1), 0, 0)

	add_child(mesh_instance)
