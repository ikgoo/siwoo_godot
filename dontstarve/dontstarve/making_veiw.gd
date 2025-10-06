extends Node3D

@export var thing : obsticle

func _ready():
	pass # Replace with function body.


## 매 프레임 호출되는 함수 - 마우스 위치를 추적합니다
## delta: 프레임 간 경과 시간
func _process(_delta):
	# 마우스 화면 좌표를 월드 좌표로 변환
	var mouse_pos = get_viewport().get_mouse_position()
	var world_pos = get_gridmap_intersection(mouse_pos)
	
	if world_pos != Vector3.ZERO:
		# Y좌표는 현재 위치 유지, X와 Z만 마우스 위치로 업데이트
		global_position.x = world_pos.x
		global_position.z = world_pos.z


## 마우스 위치에서 GridMap과의 교차점을 찾는 함수 (main.gd와 동일한 방식)
## mouse_pos: 마우스 화면 좌표 (Vector2)
## 반환값: Vector3 - 충돌 위치 (충돌 없으면 Vector3.ZERO)
func get_gridmap_intersection(mouse_pos: Vector2) -> Vector3:
	# 카메라에서 마우스 위치로 레이 생성
	var camera = get_viewport().get_camera_3d()
	if not camera:
		return Vector3.ZERO
	
	var ray_origin = camera.project_ray_origin(mouse_pos)
	var ray_direction = camera.project_ray_normal(mouse_pos)
	
	# 캐릭터 참조 가져오기
	var character = get_tree().get_first_node_in_group("player")
	
	# 3D 물리 공간에서 raycast 수행
	# obstacle은 input_event로 먼저 처리되므로, 여기서는 GridMap과 모든 것을 감지
	var space_state = get_world_3d().direct_space_state
	var query = PhysicsRayQueryParameters3D.create(ray_origin, ray_origin + ray_direction * 1000)
	query.collision_mask = 5  # collision layer 1(GridMap)과 4(Obstacle) 감지
	if character:
		query.exclude = [character]  # 캐릭터 제외
	query.collide_with_areas = true  # Area3D와 충돌 감지 활성화
	query.collide_with_bodies = true  # StaticBody3D, RigidBody3D 등과 충돌 감지
	var result = space_state.intersect_ray(query)
	
	# 충돌이 있으면 위치 반환
	if result.has("position"):
		# 충돌한 개체 정보 출력
		if result.has("collider"):
			var collider = result.collider
			print("========== 충돌 정보 ==========")
			print("개체 이름: ", collider.name)
			print("개체 타입: ", collider.get_class())
			print("collision_layer: ", collider.collision_layer)
			if collider.has("collision_mask"):
				print("collision_mask: ", collider.collision_mask)
			print("충돌 위치: ", result.position)
			print("================================")
		return result.position
	else:
		print("충돌 없음 - GridMap을 찾을 수 없습니다")
	
	return Vector3.ZERO
