extends Node3D
const APPLE = preload("res://item/tems/apple.tres")
const ITEM_GROUND = preload("res://item_ground.tscn")
@onready var animation_player = $AnimationPlayer
@onready var run_sprite = $run
@onready var idle_sprite = $idle
@onready var camera_3d = $cam_angle/Camera3D
@onready var cam_angle = $cam_angle
@onready var inventory = $CanvasLayer/inventory
var now_time = "day"
@onready var character_body_3d = $CharacterBody3D
@onready var marker_3d = $Marker3D
@onready var gridmap = $GridMap
@onready var inventory_ui = $CanvasLayer/inventory
@onready var maker_ui = $CanvasLayer/maker
@onready var world_environment = $WorldEnvironment
@onready var texture_rect2 = $CanvasLayer/TextureRect2
@onready var mouse_ray = $cam_angle/Camera3D/mouse_ray
var is_click_move = true
func _ready():
	# UI의 mouse_filter를 IGNORE로 설정하여 빈 영역 클릭이 통과되도록 함
	if inventory_ui:
		inventory_ui.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if maker_ui:
		maker_ui.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	# 초기 환경 설정 (낮으로 시작)
	setup_initial_environment()
	
	# TextureRect2 회전 시스템 초기화
	setup_texture_rect2_rotation()
	
	# obsticle signal 연결
	connect_all_obsticle_signals()

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

# 낮/밤 전환 관련 변수
var environment_tween: Tween  # 환경 변화를 위한 Tween
var transition_duration = 0.5  # 전환 시간 (0.5초)

# TextureRect2 회전 관련 변수
var rotation_tween: Tween  # 회전을 위한 Tween
var rotation_timer: Timer  # 10초마다 회전을 위한 타이머

# 테스트용 함수 - T키로 수동 낮/밤 전환 (디버깅용)
func _input(event):
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_T:
			# T키로 수동 전환 테스트
			_on_day_night_timer_timeout()
			print("수동 낮/밤 전환 실행 - 현재 시간: ", now_time)
		elif event.keycode == KEY_R:
			# R키로 수동 회전 테스트
			rotate_texture_rect2()
			print("수동 TextureRect2 회전 실행")


func get_camera_basis() -> Basis:
	return cam_angle.transform.basis
# 캐릭터 애니메이션을 처리하는 함수
# dir: 이동 방향 벡터 (Vector3)

func _physics_process(delta):
	cam_ray()
	if Input.is_action_just_pressed('clicks'):
		handle_mouse_click()

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

# 마우스 클릭 시 mouse_ray의 충돌 위치를 사용하는 함수
func handle_mouse_click():
	# 클릭 이동이 비활성화되어 있으면 리턴
	if not is_click_move:
		print("클릭 이동 비활성화 - 이동 취소")
		return
	
	# UI 위에서 클릭했는지 확인
	update_ui_mouse_status()
	print("UI 위에 있음: ", is_mouse_over_any_ui)
	if is_mouse_over_any_ui:
		print("UI 클릭 - 이동 취소")
		return
	
	# mouse_ray가 충돌했는지 확인
	if not mouse_ray.is_colliding():
		print("mouse_ray 충돌 없음 - 이동 취소")
		return
	
	# mouse_ray의 충돌 위치 사용
	var world_pos = mouse_ray.get_collision_point()
	print("월드 위치 (mouse_ray): ", world_pos)
	
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
	
	# 3D 물리 공간에서 raycast 수행
	# obstacle은 input_event로 먼저 처리되므로, 여기서는 GridMap과 모든 것을 감지
	var space_state = get_world_3d().direct_space_state
	var query = PhysicsRayQueryParameters3D.create(ray_origin, ray_origin + ray_direction * 1000)
	query.collision_mask = 5  # collision layer 1(GridMap)과 4(Obstacle) 감지
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
func drop_item_at_position(item: Item, target_position: Vector3) -> void: 
	var new = ITEM_GROUND.instantiate()
	new.thing = item
	new.position = target_position
	new.position.y = 0
	new.position.y -= 0.05
	add_child(new)


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
	print("마우스 아래 컨트롤: ", control_under_mouse)
	if control_under_mouse:
		is_mouse_over_any_ui = true
		print("름름: ", control_under_mouse.name)
		
		# 어떤 UI인지 구분
		if control_under_mouse.name.contains("inventory") or control_under_mouse.get_parent().name.contains("inventory"):
			is_mouse_over_inventory = true
		elif control_under_mouse.name.contains("maker") or control_under_mouse.get_parent().name.contains("maker"):
			is_mouse_over_maker = true


func _on_day_night_timer_timeout():
	if now_time == 'day':
		now_time = 'night'
		transition_to_night()
	else:
		now_time = 'day'
		transition_to_day()

# 초기 환경 설정 함수
func setup_initial_environment():
	if not world_environment:
		print("WorldEnvironment 노드를 찾을 수 없습니다!")
		return
	
	# 기본 Environment 생성 (없는 경우)
	if not world_environment.environment:
		world_environment.environment = Environment.new()
	
	# 초기값을 낮 상태로 설정 (fog_density = 0.0)
	world_environment.environment.fog_enabled = true
	world_environment.environment.fog_density = 0.0
	print("초기 환경 설정 완료: 낮 상태 (fog_density = 0.0)")

# 밤으로 전환하는 함수 (density 0 -> 1)
func transition_to_night():
	if not world_environment or not world_environment.environment:
		print("WorldEnvironment 또는 Environment가 없습니다!")
		return
	
	print("밤으로 전환 시작...")
	
	# 기존 Tween이 있으면 중지
	if environment_tween:
		environment_tween.kill()
	
	# 새로운 Tween 생성
	environment_tween = create_tween()
	
	# fog_density를 0에서 1로 부드럽게 변화
	environment_tween.tween_property(
		world_environment.environment, 
		"fog_density", 
		1.0, 
		transition_duration
	)
	
	# 전환 완료 시 콜백
	environment_tween.tween_callback(func(): print("밤 전환 완료 (fog_density = 1.0)"))

# 낮으로 전환하는 함수 (density 1 -> 0)
func transition_to_day():
	if not world_environment or not world_environment.environment:
		print("WorldEnvironment 또는 Environment가 없습니다!")
		return
	
	print("낮으로 전환 시작...")
	
	# 기존 Tween이 있으면 중지
	if environment_tween:
		environment_tween.kill()
	
	# 새로운 Tween 생성
	environment_tween = create_tween()
	
	# fog_density를 1에서 0으로 부드럽게 변화
	environment_tween.tween_property(
		world_environment.environment, 
		"fog_density", 
		0.0, 
		transition_duration
	)
	
	# 전환 완료 시 콜백
	environment_tween.tween_callback(func(): print("낮 전환 완료 (fog_density = 0.0)"))

# TextureRect2 회전 시스템 초기화 함수
func setup_texture_rect2_rotation():
	if not texture_rect2:
		print("TextureRect2 노드를 찾을 수 없습니다!")
		return
	
	# 회전 타이머 생성
	rotation_timer = Timer.new()
	rotation_timer.wait_time = 10.0  # 10초마다
	rotation_timer.autostart = true
	rotation_timer.timeout.connect(_on_rotation_timer_timeout)
	add_child(rotation_timer)
	
	print("TextureRect2 회전 시스템 초기화 완료 (10초마다 180도 회전)")
	# 초기 지연 없이 즉시 첫 회전 시작 (10초 동안 서서히 180도)
	rotate_texture_rect2()

# 10초마다 호출되는 회전 함수
func _on_rotation_timer_timeout():
	rotate_texture_rect2()

# TextureRect2를 180도 회전시키는 함수
func rotate_texture_rect2():
	if not texture_rect2:
		return
	
	print("TextureRect2 회전 시작...")
	
	# 기존 회전 Tween이 있으면 중지
	if rotation_tween:
		rotation_tween.kill()
	
	# 새로운 회전 Tween 생성
	rotation_tween = create_tween()
	
	# 현재 회전값에서 180도 추가 회전
	var current_rotation = texture_rect2.rotation
	var target_rotation = current_rotation + deg_to_rad(180)
	
	# 10초 동안 부드럽게 180도 회전
	rotation_tween.tween_property(
		texture_rect2, 
		"rotation", 
		target_rotation, 
		10.0  # 10초 동안 회전
	)
	
	# 회전 완료 시 콜백
	rotation_tween.tween_callback(func(): print("TextureRect2 180도 회전 완료"))


# obsticle 노드들의 signal을 플레이어에 연결하는 함수
func connect_all_obsticle_signals():
	# "player" 그룹에서 플레이어 찾기
	var player = get_tree().get_first_node_in_group("player")
	if not player:
		player = character_body_3d
	
	if not player or not player.has_method("show_description_text"):
		print("플레이어를 찾을 수 없거나 show_description_text 메서드가 없습니다!")
		return
	
	# 씬 트리의 모든 노드를 순회하여 obsticle 노드 찾기
	var obsticles = find_all_obsticles(self)
	
	for obs in obsticles:
		# signal이 이미 연결되어 있지 않으면 연결
		if not obs.show_description_requested.is_connected(player.show_description_text):
			obs.show_description_requested.connect(player.show_description_text)
			print("obsticle signal 연결됨: ", obs.name)


# 재귀적으로 모든 obsticle 노드를 찾는 함수
func find_all_obsticles(node: Node) -> Array:
	var result = []
	
	# 현재 노드가 obsticle 스크립트를 가지고 있는지 확인
	if node.get_script():
		var script_path = node.get_script().get_path()
		if script_path.get_file() == "obsticle.gd":
			result.append(node)
	
	# 모든 자식 노드에 대해 재귀 호출
	for child in node.get_children():
		result.append_array(find_all_obsticles(child))
	
	return result

## 매 프레임 마우스 위치를 추적하여 mouse_ray를 업데이트하는 함수
func cam_ray():
	var mouse_pos = get_viewport().get_mouse_position()
	mouse_ray.target_position = camera_3d.project_local_ray_normal(mouse_pos) * 100.0
	mouse_ray.force_raycast_update()
	
	# 충돌 시 Globals에 월드 좌표 저장
	if mouse_ray.is_colliding():
		Globals.mouse_pos = mouse_ray.get_collision_point()
