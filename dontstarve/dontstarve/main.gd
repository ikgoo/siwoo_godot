extends Node3D
const APPLE = preload("res://item/tems/apple.tres")
const ITEM_GROUND = preload("res://item_ground.tscn")
@onready var animation_player = get_node_or_null("AnimationPlayer")
@onready var run_sprite = get_node_or_null("run")
@onready var idle_sprite = get_node_or_null("idle")
@onready var camera_3d = get_node_or_null("cam_angle/Camera3D")
@onready var cam_angle = get_node_or_null("cam_angle")
@onready var inventory = get_node_or_null("CanvasLayer/inventory")
@onready var character_body_3d = get_node_or_null("CharacterBody3D")
@onready var marker_3d = get_node_or_null("Marker3D")
@onready var inventory_ui = get_node_or_null("CanvasLayer/inventory")
@onready var maker_ui = get_node_or_null("CanvasLayer/maker")
@onready var world_environment = get_node_or_null("WorldEnvironment")
@onready var texture_rect2 = get_node_or_null("CanvasLayer/Sprite2D")
@onready var mouse_ray = get_node_or_null("cam_angle/Camera3D/mouse_ray")
@onready var obsticle_ray = get_node_or_null("cam_angle/Camera3D/obsticle_ray")
@onready var directional_light = get_node_or_null("DirectionalLight3D")
var is_click_move = true
var current_highlighted_obsticle = null  # 현재 하이라이트된 obsticle

# 수면 오버레이 관련
var sleep_overlay_material: ShaderMaterial = null

# 지형 생성기 (한 번만 생성)
var terrain_generator: Node = null

# 개발자 모드 상태
var developer_mode: bool = false
var original_fog_density: float = 0.0

func _ready():
	# main 그룹에 추가 (개발자 모드 신호 수신용)
	add_to_group("main")
	
	# UI의 mouse_filter를 IGNORE로 설정하여 빈 영역 클릭이 통과되도록 함
	if inventory_ui:
		inventory_ui.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if maker_ui:
		maker_ui.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	# 달의 위상 초기화
	if Globals.now_moon == null:
		Globals.now_moon = Globals.moon_phase.nothing
	
	# 게임 시작 시 아침(day)으로 설정
	Globals.now_time = Globals.time_of_day.day
	 
	# 초기 환경 설정
	setup_initial_environment()
	
	# 모든 Obsticle 텍스처 알파 데이터 캐싱
	cache_all_obsticle_textures()
	
	# InventoryManeger의 now_hand 변경 시그널에 연결
	InventoryManeger.change_now_hand.connect(_on_hand_item_changed)
	
	# 수면 오버레이 초기화
	setup_sleep_overlay()
	
	# 시침 첫 회전 시작 (게임 시작과 동시에)
	rotate_clock_hand()
	
	# ChunkSpawner 초기화 (지연 로딩 방식)
	initialize_chunk_spawner()
	
	# 시작 시 (0, 0) 위치에 berry_tree 생성
	spawn_berry_tree_at_origin()

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
var day_cycle_timer: float = 0.0  # 하루 주기 타이머 (전체 하루 추적용)
var time_phase_timer: float = 0.0  # 시간대 변경 타이머 (각 단계 추적용)

# 시침 회전 관련 변수
var rotation_tween: Tween  # 회전을 위한 Tween

# 테스트용 함수 - T키로 수동 낮/밤 전환 (디버깅용)
func _input(event):
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_T:
			# T키로 수동 전환 테스트
			_on_day_night_timer_timeout()


func get_camera_basis() -> Basis:
	return cam_angle.transform.basis
# 캐릭터 애니메이션을 처리하는 함수
# dir: 이동 방향 벡터 (Vector3)

func _physics_process(delta):
	# 수면 오버레이 업데이트
	update_sleep_overlay()
	
	# 하루 주기에 따른 밝기 변화 업데이트
	update_day_night_cycle(delta)
	
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


func _process(_delta):
	# 플레이어 상태 출력 (HP, 스태미나, 허기)
	print("HP: %d | 스태미나: %d | 허기: %d" % [
		InventoryManeger.player_hp,
		InventoryManeger.stamina,
		InventoryManeger.player_hunger
	])



func drop(thig):
	var new = ITEM_GROUND.instantiate()
	new.thing = thig
	new.position = character_body_3d.position
	new.position.y = 0.05
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
	# UI 위에서 클릭했는지 먼저 확인
	update_ui_mouse_status()
	if is_mouse_over_any_ui:
		return
	
	# Shift 키가 눌려있으면 이동 처리
	if Input.is_key_pressed(KEY_SHIFT):
		handle_shift_click()
		return
	
	# 마우스에 obsticle이 걸려있는지 확인
	if Globals.mouse_on_obsticle:
		handle_obsticle_click(Globals.mouse_on_obsticle)
		return
	
	# obsticle이 없으면 지형 클릭 처리
	handle_ground_click()

## Shift + 좌클릭 처리 (강제 이동)
func handle_shift_click():
	if not mouse_ray.is_colliding():
		return
	
	var collision_point = mouse_ray.get_collision_point()
	
	# 캐릭터의 Area3D 무시
	var collider = mouse_ray.get_collider()
	if collider and collider.get_parent() == character_body_3d:
		mouse_ray.add_exception(collider)
		mouse_ray.force_raycast_update()
		mouse_ray.remove_exception(collider)
		
		if not mouse_ray.is_colliding():
			return
		collision_point = mouse_ray.get_collision_point()
	
	# 강제 이동
	if is_click_move:
		character_body_3d.move_to_position(collision_point)

## obsticle 클릭 처리
func handle_obsticle_click(obsticle_node):
	if not obsticle_node or not obsticle_node.thing:
		return
	
	var thing = obsticle_node.thing
	
	# collectable 타입이고 is_collectable이 1이면 수집
	if thing.type == obsticle.mineable.collectable and thing.is_collectable == 1:
		print("📦 [클릭] 수집 가능한 아이템 - 이동 시작")
		# obsticle의 handle_collectable_click 함수 호출
		if obsticle_node.has_method("handle_collectable_click"):
			obsticle_node.handle_collectable_click()
	# 제작대인 경우
	elif thing.type == obsticle.mineable.craft_table:
		if obsticle_node.has_method("open_craft_table_ui"):
			obsticle_node.open_craft_table_ui()
	# 채굴 가능한 타입인 경우 (나무, 돌 등)
	elif character_body_3d.is_mineable_object(obsticle_node):
		print("⛏️ [클릭] 채굴 가능 타입 - 채굴 처리")
		# 도구 체크
		var has_correct_tool = false
		
		if character_body_3d.is_tree_object(obsticle_node) and character_body_3d.has_moon_axe_in_hand():
			has_correct_tool = true
		elif character_body_3d.is_stone_object(obsticle_node) and character_body_3d.has_moon_pickaxe_in_hand():
			has_correct_tool = true
		elif character_body_3d.is_moon_tree_object(obsticle_node) and (character_body_3d.has_axe_in_hand() or character_body_3d.has_moon_axe_in_hand()):
			has_correct_tool = true
		elif character_body_3d.is_moon_stone_object(obsticle_node) and (character_body_3d.has_pickaxe_in_hand() or character_body_3d.has_moon_pickaxe_in_hand()):
			has_correct_tool = true
		
		if has_correct_tool:
			# 이미 범위 안에 있는지 확인
			if obsticle_node in character_body_3d.objects_in_space_area:
				# 범위 안에 있으면 즉시 채굴
				print("  ✅ 범위 내 + 올바른 도구 - 즉시 채굴")
				character_body_3d.on_item = obsticle_node
				character_body_3d.handle_mining_interaction(obsticle_node)
			else:
				# 범위 밖이면 이동
				print("  🚶 범위 밖 + 올바른 도구 - 이동 시작")
				character_body_3d.on_item = obsticle_node
				character_body_3d.move_to_position(obsticle_node.global_position)
		else:
			print("  ❌ 올바른 도구가 없음")
			if character_body_3d and character_body_3d.has_method("show_description_text"):
				character_body_3d.show_description_text("적절한 도구가 필요합니다", 2.0)
	# 그 외의 경우 설명 표시
	else:
		if not thing.sulmung.is_empty():
			if character_body_3d and character_body_3d.has_method("show_description_text"):
				character_body_3d.show_description_text(thing.sulmung, 5.0)

## 지형 클릭 처리
func handle_ground_click():
	if not mouse_ray.is_colliding():
		return
	
	var collider = mouse_ray.get_collider()
	var collision_point = mouse_ray.get_collision_point()
	
	# 캐릭터의 Area3D는 무시하고 다음 충돌 체크
	if collider and collider.get_parent() == character_body_3d:
		mouse_ray.add_exception(collider)
		mouse_ray.force_raycast_update()
		mouse_ray.remove_exception(collider)
		
		if not mouse_ray.is_colliding():
			return
		
		collider = mouse_ray.get_collider()
		collision_point = mouse_ray.get_collision_point()
	
	# 손에 아이템이 있으면
	if InventoryManeger.now_hand:
		# is_setable 아이템이면서 making_veiw가 활성화되어 있으면
		var making_veiw = get_node_or_null("making_veiw")
		if making_veiw and making_veiw.instant_place_mode:
			move_and_drop_item(collision_point)
		else:
			# 일반 아이템이면 내려놓기
			move_and_drop_item(collision_point)
	else:
		# 손에 아이템이 없으면 단순 이동
		if is_click_move:
			character_body_3d.move_to_position(collision_point)

# 월드 좌표를 GridMap의 그리드 좌표로 변환하는 함수
# world_pos: 월드 좌표 (Vector3)
# 반환값: Vector3i - 그리드 좌표
func world_to_grid_position(world_pos: Vector3) -> Vector3i:
	# 로컬 좌표로 변환 (GridMap 제거됨)
	var local_pos = world_pos
	
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
	# 내려놓을 아이템 저장
	var item_to_drop = InventoryManeger.now_hand
	
	if not item_to_drop:
		return
	
	# 플레이어 이동
	character_body_3d.move_to_position(target_pos)
	
	# 이동 완료 대기 (is_moving_to_target이 false가 될 때까지)
	while character_body_3d.is_moving_to_target:
		await get_tree().process_frame
	
	# 이동이 완료되었는지 확인 (목표 위치에 도착했는지)
	var distance_to_target = character_body_3d.global_position.distance_to(target_pos)
	if distance_to_target < 0.5:  # 목표 위치에 충분히 가까우면
		# 손에서 아이템 제거
		InventoryManeger.now_hand = null
		InventoryManeger.change_now_hand.emit(InventoryManeger.now_hand)
		# 바닥에 아이템 생성
		drop_item_at_position(item_to_drop, target_pos)

# 특정 위치에 아이템 떨어뜨리기
# item: 떨어뜨릴 아이템 (Item)
# position: 떨어뜨릴 위치 (Vector3)
func drop_item_at_position(item: Item, target_position: Vector3) -> void: 
	var new = ITEM_GROUND.instantiate()
	new.thing = item
	# X, Z 좌표는 target_position 사용, Y는 지면 높이(0.05)로 설정
	new.position = Vector3(target_position.x, 0.05, target_position.z)
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
	if control_under_mouse:
		is_mouse_over_any_ui = true
		
		# 어떤 UI인지 구분
		if control_under_mouse.name.contains("inventory") or control_under_mouse.get_parent().name.contains("inventory"):
			is_mouse_over_inventory = true
		elif control_under_mouse.name.contains("maker") or control_under_mouse.get_parent().name.contains("maker"):
			is_mouse_over_maker = true


func _on_day_night_timer_timeout():
	var current_time = Time.get_ticks_msec() / 1000.0  # 게임 시작 후 경과 시간 (초)
	
	# 시간대 순환: day → afternoon → night → midnight → day
	match Globals.now_time:
		Globals.time_of_day.day:
			Globals.now_time = Globals.time_of_day.afternoon
			print("⏰ [%.1f초] 시간 변경: 낮 → 오후" % current_time)
		Globals.time_of_day.afternoon:
			Globals.now_time = Globals.time_of_day.night
			print("⏰ [%.1f초] 시간 변경: 오후 → 밤" % current_time)
			# transition_to_night() 제거 - update_day_night_cycle()에서 자동 처리
		Globals.time_of_day.night:
			Globals.now_time = Globals.time_of_day.midnight
			print("⏰ [%.1f초] 시간 변경: 밤 → 자정" % current_time)
		Globals.time_of_day.midnight:
			Globals.now_time = Globals.time_of_day.day
			print("⏰ [%.1f초] 시간 변경: 자정 → 낮 (새로운 하루)" % current_time)
			# transition_to_day() 제거 - update_day_night_cycle()에서 자동 처리
			# 하루가 지날 때마다 달의 위상 변경
			advance_moon_phase()
	
	# 시간 변경 시 inventory UI의 해/달 업데이트
	update_inventory_celestial_body()

# 초기 환경 설정 함수
func setup_initial_environment():
	if not world_environment:
		return
	
	# 기본 Environment 생성 (없는 경우)
	if not world_environment.environment:
		world_environment.environment = Environment.new()
	
	# 초기값을 낮 상태로 설정 (fog_density = 0.0)
	world_environment.environment.fog_enabled = true
	world_environment.environment.fog_density = 0.0


## 개발자 모드 설정 (카메라에서 호출)
func set_developer_mode(enabled: bool):
	developer_mode = enabled
	
	if not world_environment or not world_environment.environment:
		return
	
	if developer_mode:
		# 개발자 모드: fog 끄기
		original_fog_density = world_environment.environment.fog_density
		world_environment.environment.fog_enabled = false
	else:
		# 일반 모드: fog 복원
		world_environment.environment.fog_enabled = true
		world_environment.environment.fog_density = original_fog_density


func update_day_night_cycle(delta: float):
	if not world_environment or not world_environment.environment:
		return
	
	# 개발자 모드에서는 fog 업데이트 안 함
	if developer_mode:
		return
	
	# 전체 하루 타이머 증가 (밝기 계산용)
	day_cycle_timer += delta
	
	# 하루가 지나면 리셋
	if day_cycle_timer >= Globals.DAY_DURATION:
		day_cycle_timer = 0.0
	
	# 시간대 변경 타이머 증가
	time_phase_timer += delta
	
	# 하루는 4단계(day, afternoon, night, midnight)로 구성
	# 각 단계는 DAY_DURATION / 4 초 동안 지속
	var time_phase_duration = Globals.DAY_DURATION / 4.0
	
	# time_phase_duration이 지나면 시간대 변경 및 리셋
	if time_phase_timer >= time_phase_duration:
		time_phase_timer = 0.0
		_on_day_night_timer_timeout()  # 시간대 변경 함수 호출
	
	# 사인 곡선으로 밝기 계산 (전체 하루 기준)
	# sin(0) = 0 (낮 시작)
	# sin(π/2) = 1 (한밤중)
	# sin(π) = 0 (다음 날)
	var cycle_progress = day_cycle_timer / Globals.DAY_DURATION  # 0.0 ~ 1.0
	var angle = cycle_progress * PI  # 0 ~ π
	var fog_intensity = sin(angle)  # 0 ~ 1 ~ 0 (사인 곡선)
	
	# fog_density 업데이트
	world_environment.environment.fog_density = fog_intensity
	
	# DirectionalLight 밝기 조절 (밤에는 어둡게, 낮에는 밝게)
	if directional_light:
		# 낮: 0.2 (밝음), 밤: 0.05 (어두움)
		# fog_intensity가 높을수록(밤) 조명이 어두워짐
		var light_brightness = lerp(0.2, 0.05, fog_intensity)
		directional_light.light_energy = light_brightness
	
	# 디버그 (필요시 주석 해제)
	# if int(day_cycle_timer) % 5 == 0 and delta > 0:
	#     print("시간: %.1f초 | fog_density: %d%%" % [day_cycle_timer, int(fog_intensity * 100)])

# 시침을 한 바퀴(360도) 회전시키는 함수
# 게임 시작 시 한 번만 호출됨
# Globals.DAY_DURATION 초 동안 천천히 360도 회전
func rotate_clock_hand():
	if not texture_rect2:
		return
	
	# 기존 회전 Tween이 있으면 중지
	if rotation_tween:
		rotation_tween.kill()
	
	# 새로운 회전 Tween 생성
	rotation_tween = create_tween()
	rotation_tween.set_loops()  # 무한 반복
	
	# 0도에서 360도까지 회전 (상대적 회전)
	# from_current()를 사용하면 현재 값에서 상대적으로 증가
	rotation_tween.tween_property(
		texture_rect2, 
		"rotation", 
		deg_to_rad(360), 
		Globals.DAY_DURATION  # 하루 시간 동안 360도 회전
	).from_current().as_relative()

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

## 모든 Obsticle의 텍스처 알파 데이터를 캐싱하는 함수
## 게임 시작 시 한 번만 호출되어 성능 최적화
func cache_all_obsticle_textures():
	var obsticles = find_all_obsticles(self)
	
	for obs in obsticles:
		if obs.has_method("cache_texture_alpha"):
			obs.cache_texture_alpha()

## 매 프레임 마우스 위치를 추적하여 mouse_ray를 업데이트하는 함수
func cam_ray():
	var mouse_pos = get_viewport().get_mouse_position()
	mouse_ray.target_position = camera_3d.project_local_ray_normal(mouse_pos) * 100.0
	mouse_ray.force_raycast_update()
	
	# 충돌 시 Globals에 월드 좌표 저장
	if mouse_ray.is_colliding():
		var collider = mouse_ray.get_collider()
		
		# 캐릭터의 Area3D는 무시하고 다음 충돌 체크
		if collider and collider.get_parent() == character_body_3d:
			# Area3D를 건너뛰고 그 뒤의 충돌 체크
			mouse_ray.add_exception(collider)
			mouse_ray.force_raycast_update()
			mouse_ray.remove_exception(collider)
			
			if not mouse_ray.is_colliding():
				return
			
			collider = mouse_ray.get_collider()
		
		Globals.mouse_pos = mouse_ray.get_collision_point()
	
	# obsticle_ray 업데이트 및 픽셀 퍼펙트 체크
	update_obsticle_ray()


## obsticle_ray를 사용하여 픽셀 퍼펙트 감지를 수행하는 함수
## Area3D를 감지하고, obsticle 자체의 픽셀 퍼펙트 함수를 호출
## 실패 시 해당 Area를 제외하고 다시 raycast 반복
func update_obsticle_ray():
	if not obsticle_ray:
		return
	
	var mouse_pos = get_viewport().get_mouse_position()
	obsticle_ray.target_position = camera_3d.project_local_ray_normal(mouse_pos) * 100.0
	
	# 제외할 충돌체 목록 초기화
	var excluded_areas: Array = []
	var max_iterations = 10  # 최대 10번 반복
	var found_valid_obsticle = null  # 찾은 obsticle 저장
	var iteration_count = 0  # 실제 반복 횟수
	
	for i in range(max_iterations):
		# 이전에 제외한 Area들을 제외하고 raycast
		for excluded in excluded_areas:
			obsticle_ray.add_exception(excluded)
		
		obsticle_ray.force_raycast_update()
		
		# 제외 목록 초기화 (다음 반복을 위해)
		for excluded in excluded_areas:
			obsticle_ray.remove_exception(excluded)
		
		# 충돌하지 않으면 종료
		if not obsticle_ray.is_colliding():
			break
		
		var collider = obsticle_ray.get_collider()
		iteration_count += 1  # 충돌 감지 시 카운트 증가
		
		# Area3D인지 확인
		if collider is Area3D:
			# Area3D의 부모가 Sprite3D인지 확인
			var sprite = collider.get_parent()
			if sprite and sprite is Sprite3D:
				# Sprite3D의 부모가 obsticle (StaticBody3D)인지 확인
				var obsticle_node = sprite.get_parent()
				if obsticle_node and obsticle_node is StaticBody3D:
					# obsticle 자체의 픽셀 퍼펙트 체크 함수 호출 (감지된 Area와 충돌 지점 전달)
					var detected_area_id = collider.get_instance_id()
					var obsticle_id = obsticle_node.get_instance_id()
					var collision_point = obsticle_ray.get_collision_point()
					print("[%d] raycast 감지 - Area ID: %s, 호출할 obsticle ID: %s" % [iteration_count, detected_area_id, obsticle_id])
					
					if obsticle_node.has_method("check_pixel_perfect_from_main"):
						var pixel_check = obsticle_node.check_pixel_perfect_from_main(collider, collision_point)
						
						if pixel_check:
							# 성공: 이 obsticle을 저장하고 종료
							print("[%d] raycast 성공 - Area ID: %s" % [iteration_count, detected_area_id])
							found_valid_obsticle = obsticle_node
							break
						else:
							# 실패: 이 Area를 제외하고 다음 반복
							print("[%d] raycast 실패 - Area ID: %s" % [iteration_count, detected_area_id])
							excluded_areas.append(collider)
							continue
		
		# Area3D가 아니거나 조건에 맞지 않으면 종료
		break
	
	# 이전에 하이라이트된 obsticle과 다르면 색상 업데이트
	if found_valid_obsticle != current_highlighted_obsticle:
		# 이전 obsticle 색상 복원
		if current_highlighted_obsticle and is_instance_valid(current_highlighted_obsticle):
			if current_highlighted_obsticle.has_method("reset_color"):
				current_highlighted_obsticle.reset_color()
		
		# 새로운 obsticle 저장
		current_highlighted_obsticle = found_valid_obsticle
		
		# 유효한 obsticle을 찾지 못했으면 모든 obsticle을 원래 색상으로 복원
		if not found_valid_obsticle:
			reset_all_obsticle_colors()
	
	# Globals에 마우스에 걸린 obsticle 저장
	Globals.mouse_on_obsticle = found_valid_obsticle


## 모든 obsticle의 색상을 원래대로 복원하는 함수
func reset_all_obsticle_colors():
	var obsticles = find_all_obsticles(self)
	for obs in obsticles:
		var sprite = obs.get_node_or_null("Sprite3D")
		if sprite and sprite.has_method("update_hover_effect"):
			sprite.is_hovered = false
			sprite.update_hover_effect()


## 수면 오버레이 초기화 함수
func setup_sleep_overlay():
	# 카메라에 CanvasLayer 추가
	var canvas_layer = CanvasLayer.new()
	canvas_layer.name = "SleepOverlay"
	camera_3d.add_child(canvas_layer)
	
	# ColorRect 생성
	var color_rect = ColorRect.new()
	color_rect.name = "SleepColorRect"
	color_rect.color = Color(0, 0, 0, 0)  # 투명
	color_rect.anchor_left = 0.0
	color_rect.anchor_top = 0.0
	color_rect.anchor_right = 1.0
	color_rect.anchor_bottom = 1.0
	color_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE  # 마우스 클릭이 통과되도록 설정
	canvas_layer.add_child(color_rect)
	
	# 셰이더 로드 및 적용
	var shader = load("res://shder/sleep.gdshader")
	if shader:
		sleep_overlay_material = ShaderMaterial.new()
		sleep_overlay_material.shader = shader
		color_rect.material = sleep_overlay_material
	else:
		push_error("sleep.gdshader를 찾을 수 없습니다!")

## 매 프레임 수면 오버레이 업데이트
func update_sleep_overlay():
	if not sleep_overlay_material:
		return
	
	if character_body_3d and character_body_3d.has_method("update_sleep_overlay_external"):
		character_body_3d.update_sleep_overlay_external(sleep_overlay_material)

## 달의 위상을 다음 단계로 진행시키는 함수
## 하루가 지날 때마다 호출됨
func advance_moon_phase():
	var old_phase = Globals.now_moon
	var current_time = Time.get_ticks_msec() / 1000.0  # 게임 시작 후 경과 시간 (초)
	
	# 달의 위상 순서: nothing → small → middle → high → middle_end → small_end → nothing (순환)
	match Globals.now_moon:
		Globals.moon_phase.nothing:
			Globals.now_moon = Globals.moon_phase.small
		Globals.moon_phase.small:
			Globals.now_moon = Globals.moon_phase.middle
		Globals.moon_phase.middle:
			Globals.now_moon = Globals.moon_phase.high
		Globals.moon_phase.high:
			Globals.now_moon = Globals.moon_phase.middle_end
		Globals.moon_phase.middle_end:
			Globals.now_moon = Globals.moon_phase.small_end
		Globals.moon_phase.small_end:
			Globals.now_moon = Globals.moon_phase.nothing  # 처음으로 돌아감
		_:
			# 초기값이 없으면 nothing으로 시작
			Globals.now_moon = Globals.moon_phase.nothing
	
	print("🌙 [%.1f초] 달의 위상 변경: %s → %s" % [current_time, old_phase, Globals.now_moon])

## 손에 든 아이템이 변경될 때 호출되는 함수
## item: 새로 손에 든 아이템 (null이면 손이 비어있음)
func _on_hand_item_changed(item: Item):
	# making_veiw 노드 찾기
	var making_veiw = get_node_or_null("making_veiw")
	if not making_veiw:
		return
	
	# 제작 중이거나 설치 대기 중이면 아무것도 하지 않음 (제작/설치 중인 obsticle 보호)
	if making_veiw.thing != null and (making_veiw.waiting_for_character or not making_veiw.instant_place_mode):
		return
	
	# 손에 든 아이템이 is_setable이면 making_veiw 활성화
	if item and item.is_setable and item.set_obsticle:
		making_veiw.thing = item.set_obsticle
		making_veiw.instant_place_mode = true
		making_veiw.visible = true
	else:
		# is_setable이 아니면 making_veiw 비활성화
		if making_veiw.instant_place_mode:
			making_veiw.thing = null
			making_veiw.instant_place_mode = false
			making_veiw.visible = false
			making_veiw.clear_grid_indicators()


## 시작 시 (0.5, 0.05, 0.5) 위치에 berry_tree 생성
func spawn_berry_tree_at_origin():
	# berry_tree 리소스 로드
	var berry_tree_resource = load("res://obsticle/obsticles/berry_tree.tres") as obsticle
	
	if not berry_tree_resource:
		push_error("[Main] berry_tree 리소스를 로드할 수 없습니다!")
		return
	
	# (0.5, 0.05, 0.5) 위치에 berry_tree 생성 (지형 생성 시 obsticle과 동일하게 Y=0.05)
	var spawn_position = Vector3(0.5, 0.05, 0.5)
	spawn_obsticle_at_position(berry_tree_resource, spawn_position)
	
	print("🍓 [Main] berry_tree 생성 완료 - 위치: ", spawn_position)

## ChunkSpawner 초기화 (청크 기반 지연 로딩)
func initialize_chunk_spawner():
	# ChunkSpawner 노드 생성
	var chunk_spawner = ChunkSpawner.new()
	chunk_spawner.name = "ChunkSpawner"
	chunk_spawner.debug_mode = false  # 릴리즈 시 false로 변경
	
	# 로딩/언로딩 범위 설정
	chunk_spawner.load_range = 3     # 주변 3칸만 로드
	chunk_spawner.unload_range = 5   # 5칸 이상 멀어지면 완전히 제거
	
	add_child(chunk_spawner)
	
	# 모든 청크 데이터 미리 생성 (빠름)
	chunk_spawner.call_deferred("pregenerate_all_chunk_data")
	
	print("✅ [Main] ChunkSpawner 초기화 완료")
	print("  - 로딩 범위: 주변 %d칸 청크" % chunk_spawner.load_range)
	print("  - 언로딩: %d칸 이상 멀어지면 완전히 제거" % chunk_spawner.unload_range)


## [사용 안 함] GridMap 타일에 오브젝트 스폰 (TileSpawnConfig 사용)
func spawn_objects_on_gridmap_DISABLED():
	# GridMap 노드 찾기
	var grid_map_node = get_node_or_null("Node3D2/GridMap")
	if not grid_map_node:
		push_error("[Main] GridMap을 찾을 수 없습니다!")
		return
	
	# TileSpawnConfig 초기화
	TileSpawnConfig.initialize()
	
	# GridMap의 모든 사용된 셀 가져오기
	var used_cells = grid_map_node.get_used_cells()
	
	var total_spawned = 0
	
	# 각 셀을 순회하며 타일 ID에 따라 오브젝트 스폰
	for cell_pos in used_cells:
		var tile_index = grid_map_node.get_cell_item(cell_pos)
		
		# TileSpawnConfig에서 지형 타입 가져오기
		var terrain_type = TileSpawnConfig.get_terrain_type(tile_index)
		
		# 해당 지형의 랜덤 나무/돌 개수 가져오기
		var tree_count = TileSpawnConfig.get_random_tree_count_by_terrain(terrain_type)
		var stone_count = TileSpawnConfig.get_random_stone_count_by_terrain(terrain_type)
		
		# 나무 리소스 가져오기
		var tree_resource = TileSpawnConfig.get_object_by_terrain(terrain_type, true)
		
		# 돌 리소스 가져오기
		var stone_resource = TileSpawnConfig.get_object_by_terrain(terrain_type, false)
		
		# 오브젝트 스폰
		total_spawned += spawn_objects_at_cell(grid_map_node, cell_pos, tree_resource, stone_resource, tree_count, stone_count)
	
	print("🌳 [Main] 오브젝트 스폰 완료: 총 %d개" % total_spawned)


## 특정 셀에 오브젝트 스폰
## @param grid_map: GridMap 노드
## @param cell_pos: 셀 위치 (Vector3i)
## @param tree_res: 나무 리소스
## @param stone_res: 돌 리소스
## @param tree_count: 나무 개수
## @param stone_count: 돌 개수
## @return: 스폰된 오브젝트 개수
func spawn_objects_at_cell(grid_map: GridMap, cell_pos: Vector3i, tree_res: obsticle, stone_res: obsticle, tree_count: int, stone_count: int) -> int:
	var spawned = 0
	var cell_world_pos = grid_map.map_to_local(cell_pos)
	var cell_global_pos = grid_map.to_global(cell_world_pos)
	var cell_size = grid_map.cell_size
	
	# 나무 스폰
	for i in range(tree_count):
		if tree_res:
			var pos = get_random_pos_in_cell(cell_global_pos, cell_size)
			spawn_obsticle_at_position(tree_res, pos)
			spawned += 1
	
	# 돌 스폰
	for i in range(stone_count):
		if stone_res:
			var pos = get_random_pos_in_cell(cell_global_pos, cell_size)
			spawn_obsticle_at_position(stone_res, pos)
			spawned += 1
	
	return spawned


## 셀 내부의 랜덤 위치 계산
## @param center: 셀 중심 위치 (월드 좌표)
## @param size: 셀 크기
## @return: 랜덤 월드 좌표
func get_random_pos_in_cell(center: Vector3, size: Vector3) -> Vector3:
	var margin = 0.1
	var half_size = size * 0.5 * (1.0 - margin)
	return center + Vector3(
		randf_range(-half_size.x, half_size.x),
		0.05,
		randf_range(-half_size.z, half_size.z)
	)


## obsticle 생성 및 배치
## @param obstacle_data: obsticle 리소스
## @param spawn_pos: 스폰 위치 (월드 좌표)
func spawn_obsticle_at_position(obstacle_data: obsticle, spawn_pos: Vector3):
	var OBSTICLE_SCENE = preload("res://obsticle.tscn")
	var obstacle_instance = OBSTICLE_SCENE.instantiate()
	obstacle_instance.thing = obstacle_data
	
	# 씬 트리에 추가
	add_child(obstacle_instance)
	
	# 위치 설정
	obstacle_instance.global_position = spawn_pos
	
	# ObstacleGrid에 등록
	register_obsticle_to_obstacle_grid(obstacle_instance, spawn_pos)


## ObstacleGrid에 obsticle 등록
## @param obsticle_node: obsticle 노드
## @param world_pos: 월드 좌표
func register_obsticle_to_obstacle_grid(obsticle_node: Node3D, world_pos: Vector3):
	var obstacle_grid = get_node_or_null("ObstacleGrid")
	if not obstacle_grid:
		return
	
	var obsticle_data = obsticle_node.thing
	if not obsticle_data:
		return
	
	# obsticle의 그리드 크기 (ObstacleGrid 타일 개수)
	var grid_width_tiles = obsticle_data.grid_width if "grid_width" in obsticle_data else 3
	var grid_height_tiles = obsticle_data.grid_height if "grid_height" in obsticle_data else 3
	
	# 월드 좌표를 ObstacleGrid의 그리드 좌표로 변환
	var center_grid_pos = obstacle_grid.world_to_grid(world_pos)
	
	# ObstacleGrid에 영역 등록
	obstacle_grid.register_obstacle_area(center_grid_pos, grid_width_tiles, grid_height_tiles)


## inventory UI의 해/달 애니메이션을 재생하는 함수
## 시간대가 변경될 때마다 호출됩니다.
func update_inventory_celestial_body():
	if inventory_ui and inventory_ui.has_method("update_celestial_body"):
		inventory_ui.update_celestial_body()
	else:
		print("❌ inventory_ui를 찾을 수 없거나 update_celestial_body 메서드가 없습니다!")
