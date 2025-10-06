extends Node3D
const APPLE = preload("res://item/tems/apple.tres")
const ITEM_GROUND = preload("res://item_ground.tscn")
@onready var animation_player = $AnimationPlayer
@onready var run_sprite = $run
@onready var idle_sprite = $idle
@onready var camera_3d = $cam_angle/Camera3D
@onready var cam_angle = $cam_angle
@onready var inventory = $CanvasLayer/inventory

@onready var character_body_3d = $CharacterBody3D
@onready var marker_3d = $Marker3D
@onready var gridmap = $GridMap
@onready var inventory_ui = $CanvasLayer/inventory
@onready var maker_ui = $CanvasLayer/maker

func _ready():
	# UI의 mouse_filter를 IGNORE로 설정하여 빈 영역에서 마우스 이벤트가 통과하도록 함
	if inventory_ui:
		inventory_ui.mouse_filter = Control.MOUSE_FILTER_IGNORE
		print("인벤토리 UI mouse_filter를 IGNORE로 설정")
	if maker_ui:
		maker_ui.mouse_filter = Control.MOUSE_FILTER_IGNORE
		print("제작법 UI mouse_filter를 IGNORE로 설정")

# 마우스가 UI 위에 있는지 확인하는 변수들
var is_mouse_over_inventory = false
var is_mouse_over_maker = false
var is_mouse_over_any_ui = false
const STONE_AXE = preload("res://item/tems/stone_axe.tres")
var ROT_STEPS = 8
var ROT_SPEED = 180
# 회전 관련 변수
var rot_step = 0
var target_rot = 0
var rotating = false


func get_camera_basis() -> Basis:
	return cam_angle.transform.basis
# 캐릭터 애니메이션을 처리하는 함수
# dir: 이동 방향 벡터 (Vector3)

func _physics_process(delta):
	if Input.is_action_just_pressed('clicks'):
		handle_mouse_click(get_viewport().get_mouse_position())

	marker_3d.global_position = character_body_3d.global_position
	cam_angle.global_position = lerp(cam_angle.global_position, marker_3d.global_position, 0.08)
	

	# 회전 처리 (Q키: 시계방향, E키: 반시계방향)
	if Input.is_action_just_pressed("e") and not rotating:
		start_rot(1)  # 시계방향
	elif Input.is_action_just_pressed("q") and not rotating:
		start_rot(-1)
		
	# 회전 업데이트
	update_rot(delta)



func drop(thig):
	var new = ITEM_GROUND.instantiate()
	new.thing = thig
	new.position = character_body_3d.position
	new.position.y -= 0.05
	add_child(new)
# dir: 1 = 시계방향, -1 = 반시계방향
func start_rot(dir: int):
	rot_step += dir
	
	# 범위를 벗어나면 순환처리
	if rot_step >= ROT_STEPS:
		rot_step = 0
	elif rot_step < 0:
		rot_step = ROT_STEPS - 1
	
	target_rot = rot_step
	rotating = true

# 회전 업데이트 함수
func update_rot(delta):
	if not rotating:
		return
	
	# 목표 각도 계산 (45도씩 증가)
	var target_angle = target_rot * 45.0
	var cur_angle = cam_angle.rotation_degrees.y
	
	# 각도 차이 계산 (최단 경로로 회전)
	var angle_diff = target_angle - cur_angle
	
	# 180도를 넘는 회전은 반대 방향으로
	if angle_diff > 180:
		angle_diff -= 360
	elif angle_diff < -180:
		angle_diff += 360
	
	# 회전 속도에 따라 각도 조정
	var rot_amount = ROT_SPEED * delta
	
	# 목표에 도달했는지 확인
	if abs(angle_diff) <= rot_amount:
		cam_angle.rotation_degrees.y = target_angle

		rotating = false
	else:
		# 부드럽게 회전
		var dir_sign = sign(angle_diff)
		cam_angle.rotation_degrees.y += dir_sign * rot_amount

# 마우스 클릭 시 GridMap과의 충돌 위치를 계산하는 함수
# mouse_pos: 마우스 화면 좌표 (Vector2)
func handle_mouse_click(mouse_pos: Vector2):
	# UI 위에서 클릭했는지 확인
	update_ui_mouse_status()
	if is_mouse_over_any_ui:
		print("UI 클릭 - 이동하지 않음")
		return
	
	# GridMap 이동 로직
	var world_pos = get_gridmap_intersection(mouse_pos)
	if world_pos != Vector3.ZERO:
		print("GridMap 충돌 위치: ", world_pos)
		print("Grid 좌표: ", world_to_grid_position(world_pos))
		
		# 손에 아이템이 있으면 그 위치로 가서 아이템 떨어뜨리기
		if InventoryManeger.now_hand:
			move_and_drop_item(world_pos)
		else:
			# 손에 아이템이 없으면 단순 이동
			character_body_3d.move_to_position(world_pos)

# 마우스 위치에서 GridMap과의 교차점을 찾는 함수
# mouse_pos: 마우스 화면 좌표 (Vector2)
# 반환값: Vector3 - 충돌 위치 (충돌 없으면 Vector3.ZERO)
func get_gridmap_intersection(mouse_pos: Vector2) -> Vector3:
	# 카메라에서 마우스 위치로 레이 생성
	var camera = camera_3d
	var ray_origin = camera.project_ray_origin(mouse_pos)
	var ray_direction = camera.project_ray_normal(mouse_pos)
	
	# 3D 물리 공간에서 raycast 수행 (collision mask 1만 감지, 캐릭터 제외)
	var space_state = get_world_3d().direct_space_state
	var query = PhysicsRayQueryParameters3D.create(ray_origin, ray_origin + ray_direction * 1000)
	query.collision_mask = 1  # collision layer 1만 감지
	query.exclude = [character_body_3d]  # 캐릭터 제외
	query.collide_with_areas = true  # Area3D와 충돌 감지 활성화
	query.collide_with_bodies = true  # StaticBody3D, RigidBody3D 등과 충돌 감지
	var result = space_state.intersect_ray(query)
	
	# 충돌이 있으면 위치 반환
	if result.has("position"):
		return result.position
	
	return Vector3.ZERO

# 월드 좌표를 GridMap의 그리드 좌표로 변환하는 함수
# world_pos: 월드 좌표 (Vector3)
# 반환값: Vector3i - 그리드 좌표
func world_to_grid_position(world_pos: Vector3) -> Vector3i:
	# GridMap의 transform을 고려하여 로컬 좌표로 변환
	var local_pos = gridmap.to_local(world_pos)
	
	# GridMap의 셀 크기로 나누어 그리드 좌표 계산
	var grid_pos = Vector3i(
		int(floor(local_pos.x)),
		int(floor(local_pos.y)),
		int(floor(local_pos.z))
	)
	
	return grid_pos

# 인벤토리 UI 위에서 클릭했는지 확인하는 함수
# mouse_pos: 마우스 화면 좌표 (Vector2)


# 아이템을 들고 있을 때 목표 위치로 이동 후 아이템 떨어뜨리기
# target_pos: 목표 위치 (Vector3)
func move_and_drop_item(target_pos: Vector3):
	print("아이템을 들고 ", target_pos, "로 이동합니다")
	$CanvasLayer/inventory
	# 이동 완료 후 아이템 떨어뜨리기 위한 콜백 설정
	var item_to_drop = InventoryManeger.now_hand
	InventoryManeger.now_hand = null  # 손에서 아이템 제거
	
	# 플레이어 이동
	character_body_3d.move_to_position(target_pos)
	
	# 이동 완료 후 아이템 떨어뜨리기
	await character_body_3d.tween.finished
	drop_item_at_position(item_to_drop, target_pos)

# 특정 위치에 아이템 떨어뜨리기
# item: 떨어뜨릴 아이템 (Item)
# position: 떨어뜨릴 위치 (Vector3)
func drop_item_at_position(item: Item, position: Vector3):
	var new = ITEM_GROUND.instantiate()
	new.thing = item
	new.position = position
	new.position.y = 0
	new.position.y -= 0.05
	add_child(new)
	print("아이템 ", item.name, "을(를) ", position, "에 떨어뜨렸습니다")


func add_tem(thing):
	inventory.add_item(thing)

func anime_update(thing):
	character_body_3d.hand_anime(thing)

# UI 마우스 상태를 업데이트하는 함수  
func update_ui_mouse_status():
	# 초기화
	is_mouse_over_any_ui = false
	is_mouse_over_inventory = false
	is_mouse_over_maker = false
	
	# mouse_filter가 IGNORE로 설정되었으므로 실제 UI 요소만 감지됨
	var control_under_mouse = get_viewport().gui_get_hovered_control()
	if control_under_mouse:
		print("마우스 아래 Control: ", control_under_mouse.name, " (", control_under_mouse.get_class(), ")")
		is_mouse_over_any_ui = true
		
		# 어떤 UI인지 구분
		if control_under_mouse.name.contains("inventory") or control_under_mouse.get_parent().name.contains("inventory"):
			is_mouse_over_inventory = true
			print("인벤토리 UI 영역")
		elif control_under_mouse.name.contains("maker") or control_under_mouse.get_parent().name.contains("maker"):
			is_mouse_over_maker = true
			print("제작법 UI 영역")
		else:
			print("기타 UI 요소")
	else:
		print("마우스 아래에 UI 없음 - 캐릭터 이동 가능")
