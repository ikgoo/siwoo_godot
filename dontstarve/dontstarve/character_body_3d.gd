extends CharacterBody3D
# 상수 정의 - 게임 밸런스 조정을 위한 값들
const SPEED = 3.5
const JUMP_VELOCITY = 4.5
const MOVEMENT_DAMPING = 0.2  # 움직임 감쇠 계수
var is_ro = false
# 아이템 리소스
const WOOD = preload("res://item/tems/wood.tres")
const BATTLE_GROUND_WINNER = preload("res://item/tems/battle_ground_winner.tres")
const ITEM_GROUND = preload("res://item_ground.tscn")
@onready var run_sprite = $run
@onready var idle_sprite = $idle
@onready var animation_player = $AnimationPlayer
@onready var tween: Tween
var on_item = null
# 회전 관련 상수
const ROT_SPEED = 180.0  # 초당 회전 속도 (도)
const ROT_STEPS = 8      # 총 회전 단계 수 (45도씩)
@onready var hand = $hand_node/hand_sprite
@export var jobs : job
@onready var hand_2 = $hand2
@onready var hand_node = $hand_node
@onready var hand_sprite = $hand_node/hand_sprite
@onready var breaking_timer = $breaking_timer
@onready var label_3d = $Label3D  # 설명 텍스트를 표시할 Label3D
# attack_timer 제거됨

# 텍스트 표시 관련 변수
var text_timer: Timer = null  # 텍스트 표시를 위한 타이머

# 캐릭터 상태 변수
var dire = 'down'
var idle = true
var last_anim = ""

# 이동 관련 변수
var is_moving_to_target = false  # 목표 위치로 이동 중인지 확인
var target_position = Vector3.ZERO  # 목표 위치
var manual_input_disabled = false  # 수동 입력 비활성화

# 상호작용 관련 변수
var nearby_areas = []  # 근처에 있는 Area3D들
var interaction_target = null  # 현재 상호작용 대상
var previous_axe_state = false  # 이전 프레임의 도끼 보유 상태
var previous_pickaxe_state = false  # 이전 프레임의 곡괭이 보유 상태

# 채굴 상태 변수
var is_mining = false  # 현재 채굴 중인지 여부

# space_area 관련 변수
var objects_in_space_area = []  # space_area 안에 있는 오브젝트들

# 공격 관련 변수
var is_attacking = false          # 현재 공격 중인지 여부
var attack_target = null          # 공격 대상 entity
var attack_tween: Tween          # 적 추적용 Tween (기존 tween과 분리)
var last_enemy_position = Vector3.ZERO  # 적의 마지막 위치 추적
var is_target_in_attack_range = false  # 공격 대상이 space_area 안에 있는지 여부
var is_attack_timer_running = false   # 공격 타이머가 진행 중인지 여부
func get_camera_transform() -> Basis:
	# 부모 노드(메인 씬)에서 카메라 각도 정보를 가져옴
	var main_scene = get_parent()
	if main_scene.has_method("get_camera_basis"):
		return main_scene.get_camera_basis()
	else:
		# 카메라 정보를 가져올 수 없는 경우 기본 transform 사용
		return transform.basis


func anime(dir):
	
	var anim = ""
	var new_dire = dire
	var flip_run = run_sprite.flip_h
	var flip_idle = idle_sprite.flip_h
	
	# 이동 중인지 확인
	var moving = dir != Vector3.ZERO
	
	if moving:
		# 이동 방향에 따른 애니메이션 및 방향 설정
		if dir.z < 0:  # 아래쪽 이동
			anim = "walk_down"
			new_dire = 'down'
		elif dir.z > 0:  # 위쪽 이동
			anim = "walk_up"
			new_dire = 'up'
		elif dir.x > 0:  # 오른쪽 이동
			anim = "walk_l_r"
			new_dire = 'r'
			flip_run = false
		elif dir.x < 0:  # 왼쪽 이동
			anim = "walk_l_r"
			new_dire = 'l'
			flip_run = true
		idle = false
	else:
		# 대기 상태 애니메이션
		if dire == 'down':
			anim = "idle_down"
		elif dire == 'up':
			anim = "idle_up"
		elif dire == 'l':
			anim = "idle_l_r"
			flip_idle = true
			hand_turn(flip_idle)
			
		elif dire == 'r':
			anim = "idle_l_r"
			flip_idle = false
			hand_turn(flip_idle)
		idle = true
	# 애니메이션이 변경된 경우에만 재생 (성능 최적화)
	if anim != last_anim:
		animation_player.play(anim)
		last_anim = anim
	

	run_sprite.flip_h = flip_run
	idle_sprite.flip_h = flip_idle
	# 상태 업데이트
	dire = new_dire

# 물리 처리 함수 - 매 프레임 호출됨
# delta: 프레임 간 경과 시간


func _ready():
	# Tween 노드 생성
	tween = create_tween()
	tween.set_loops(0)  # 무한 루프 방지
	
	# "player" 그룹에 추가 (obsticle이 찾을 수 있도록)
	add_to_group("player")
	
	# 공격 관련 초기화 제거됨

func _physics_process(_delta):
	# Tween 상태 확인 및 출력
	var _is_tween_running = false
	if tween and tween.is_valid():
		_is_tween_running = true
	if attack_tween and attack_tween.is_valid():
		_is_tween_running = true

	
	# 점프 처리
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	# F키 처리 - 공격 시스템
	if Input.is_action_just_pressed("f") and not is_moving_to_target and not is_mining and not is_attacking:
		var nearest_entity = find_nearest_entity()
		if nearest_entity:
			start_attack(nearest_entity)
		else:
			pass
	
	# Tab 키 처리 - making_need UI 열기/닫기
	if Input.is_action_just_pressed("ui_focus_next"):  # Tab 키
		handle_making_need_ui()
	
	# 스페이스바 처리 - 상호작용 (채굴 vs 줍기 구별)
	# 채굴 중이거나 이동 중일 때는 스페이스바 입력을 막음
	if Input.is_action_just_pressed("space_bar") and not is_moving_to_target and not is_mining:
		# 1. 이미 채굴 중인 오브젝트가 있는 경우 계속 채굴
		if on_item and is_mineable_object(on_item):
			handle_mining_interaction(on_item)
		# 2. 새로운 상호작용 대상이 있는 경우
		elif interaction_target:
			var target_object = interaction_target.get_parent()
			
			# entity인 경우 아무것도 하지 않음
			if is_entity_object(target_object):
				return
			
			var interaction_type = get_interaction_type(target_object)
			
			if interaction_type == "mine":
				# 채굴 대상인 경우 - 적절한 도구가 있어야 함
				var has_correct_tool = false
				
				if is_tree_object(target_object) and has_axe_in_hand():
					has_correct_tool = true
				elif is_stone_object(target_object) and has_pickaxe_in_hand():
					has_correct_tool = true
				
				if has_correct_tool:
					# 채굴 범위에 있는지 확인
					if target_object in objects_in_space_area:
						on_item = target_object  # 채굴 대상 설정
						handle_mining_interaction(target_object)
					else:
						move_to_interaction_target()
				else:
					pass
			else:
				# 아이템 줍기인 경우 - 이동해서 줍기
				move_to_interaction_target()

	# 입력 방향 확인 (Tween 중단을 위해 먼저 체크)
	var input_dir = Input.get_vector('a',"d",'s','w')
	
	# WASD 입력이 있고 자동 이동 중이면 Tween 중단
	if input_dir != Vector2.ZERO and (is_moving_to_target or is_attacking):
		interrupt_movement()
	
	# 자동 이동 중이 아닐 때만 수동 입력 처리
	if not manual_input_disabled:
		# 카메라 기준으로 방향 계산 (Y축은 0으로 고정, Z축 방향 반전)
		var camera_transform = get_camera_transform()
		var direction = Vector3.ZERO
		if input_dir != Vector2.ZERO:
			direction = (camera_transform * Vector3(input_dir.x, 0, -input_dir.y)).normalized()
			direction.y = 0  # Y축 움직임 제거 (지상 이동만)
		
		# 애니메이션 처리
		anime(Vector3(input_dir.x,0,input_dir.y))
		
		# 이동 처리
		if direction:
			# 이동 시 속도 설정
			velocity.x = direction.x * SPEED * MOVEMENT_DAMPING
			velocity.z = direction.z * SPEED * MOVEMENT_DAMPING
		else:
			# 정지 시 감속 처리
			velocity.x = move_toward(velocity.x, 0, SPEED)
			velocity.z = move_toward(velocity.z, 0, SPEED)
	
	# 자동 이동 중일 때 애니메이션 처리
	if is_moving_to_target:
		var move_direction = (target_position - global_position).normalized()
		anime(Vector3(move_direction.x, 0, move_direction.z))
	
	# 공격 중일 때 적 위치 추적 및 Tween 업데이트
	if is_attacking and attack_target:
		# 공격 타이머가 이미 실행 중이면 아무것도 하지 않음
		if is_attack_timer_running:
			pass
		# 공격 대상이 범위에 있으면 바로 공격 타이머 시작
		elif is_target_in_attack_range:
			start_attack_timer()
		else:
			track_enemy_position()

	# 물리 이동 적용
	move_and_slide()
	
	# 도구 상태 변화 감지 및 상호작용 대상 업데이트
	var current_axe_state = has_axe_in_hand()
	var current_pickaxe_state = has_pickaxe_in_hand()
	
	if current_axe_state != previous_axe_state:
		update_interaction_target()
		previous_axe_state = current_axe_state
	
	if current_pickaxe_state != previous_pickaxe_state:
		update_interaction_target()
		previous_pickaxe_state = current_pickaxe_state
	
	# hand_node를 카메라와 동일한 Y축 회전값으로 업데이트
	update_hand_node_rotation()

# 클릭한 위치로 이동하는 함수
# target_pos: 목표 위치 (Vector3)
func move_to_position(target_pos: Vector3):
	# Y좌표를 현재 캐릭터 위치로 고정하여 수직 이동 방지
	target_pos.y = global_position.y
	
	# 이전 Tween이 있으면 중지
	if tween:
		tween.kill()
	
	# 새로운 Tween 생성
	tween = create_tween()
	
	# 목표 위치 설정
	target_position = target_pos
	
	is_moving_to_target = true
	manual_input_disabled = true
	
	# 이동 거리 계산 (WASD 이동과 동일한 속도로 설정)
	var distance = global_position.distance_to(target_pos)
	var actual_speed = SPEED * MOVEMENT_DAMPING  # WASD와 동일한 실제 속도 적용
	var move_time = distance / actual_speed  # 실제 이동속도 기준 시간 계산
	
	# Tween으로 부드러운 이동
	tween.tween_property(self, "global_position", target_pos, move_time)
	
	# 이동 완료 시 콜백 연결
	tween.tween_callback(on_move_complete)
	

# 이동 완료 시 호출되는 함수
func on_move_complete():
	# 일반적인 이동 완료 처리
	is_moving_to_target = false
	manual_input_disabled = false
	# 목적지 도착 후 idle 애니메이션으로 전환
	anime(Vector3.ZERO)
	
	if on_item:
		var _interaction_type = get_interaction_type(on_item)
		
		if _interaction_type == "mine":
			# 채굴 처리
			handle_mining_interaction(on_item)
		else:
			# 아이템 줍기 처리  
			handle_pickup_interaction(on_item)

# WASD 입력 시 자동 이동 중단 함수
func interrupt_movement():
	if tween:
		tween.kill()  # 진행 중인 Tween 중단
	
	is_moving_to_target = false
	manual_input_disabled = false
	on_item = null  # 아이템 줍기 취소
	
	# 채굴 중이었다면 채굴도 중단
	if is_mining:
		breaking_timer.stop()
		is_mining = false
	
	# 공격 중이었다면 공격도 중단
	if is_attacking:
		stop_attack()


# Area3D에 무언가 들어왔을 때
func _on_area_3d_area_entered(area):
	nearby_areas.append(area)
	update_interaction_target()

# Area3D에서 무언가 나갔을 때  
func _on_area_3d_area_exited(area):
	nearby_areas.erase(area)
	update_interaction_target()

# 상호작용 대상 업데이트 (도구 유무에 따라 장애물 포함/제외)
func update_interaction_target():
	if nearby_areas.is_empty():
		interaction_target = null
		return
	
	var has_axe = has_axe_in_hand()
	var has_pickaxe = has_pickaxe_in_hand()
	var valid_targets = []
	
	# 도구 유무에 따라 유효한 대상 필터링
	for area in nearby_areas:
		var target_object = area.get_parent()
		
		# entity는 상호작용 대상에서 제외 (공격 시스템 제거로 무시)
		if is_entity_object(target_object):
			continue
		
		# 나무인지 확인
		if is_tree_object(target_object):
			# 도끼를 들고 있을 때만 나무를 대상으로 포함
			if has_axe:
				valid_targets.append(area)
		# 돌인지 확인
		elif is_stone_object(target_object):
			# 곡괭이를 들고 있을 때만 돌을 대상으로 포함
			if has_pickaxe:
				valid_targets.append(area)
		else:
			# 나무나 돌이 아닌 일반 아이템은 항상 포함
			valid_targets.append(area)
	
	# 유효한 대상이 없으면 null
	if valid_targets.is_empty():
		interaction_target = null
		return
	
	# 가장 가까운 유효한 대상 선택
	var closest_area = null
	var closest_distance = INF
	
	for area in valid_targets:
		var distance = global_position.distance_to(area.global_position)
		if distance < closest_distance:
			closest_distance = distance
			closest_area = area
	
	interaction_target = closest_area
	
	

# 상호작용 대상으로 이동하는 함수
func move_to_interaction_target():
	if not interaction_target:
		return
	
	var target_object = interaction_target.get_parent()
	var _interaction_type = get_interaction_type(target_object)
	
	on_item = target_object
	# 대상의 Y좌표도 캐릭터 높이로 고정
	var item_position = interaction_target.global_position
	item_position.y = global_position.y
	move_to_position(item_position)

# 아이템 줍기 확인 및 실행
func check_and_pickup_item():
	if not interaction_target:
		return
		
	# 상호작용 대상이 item_ground인지 확인
	if interaction_target.get_script() and interaction_target.get_script().get_path().get_file() == "item_ground.gd":
		pickup_item(interaction_target)

# 아이템 줍기 함수
func pickup_item(item_node):
	if not item_node or not item_node.thing:
		return
		
	var item = item_node.thing
	
	# 인벤토리에 아이템 추가 시도
	add_item_to_inventory(item)
	
	# 땅에서 아이템 제거
	item_node.queue_free()

# 인벤토리에 아이템 추가 (스마트 스택킹)
func add_item_to_inventory(item: Item):
	# max_count가 1인 아이템은 합치기 로직을 건너뛰고 바로 빈 슬롯에 배치
	if item.max_count <= 1:
		var empty_slot = find_empty_inventory_slot()
		if empty_slot == null:
			return false
		
		# 빈 슬롯에 바로 배치
		empty_slot.thing = item
		
		# UI 업데이트
		if empty_slot.has_method("update_display"):
			empty_slot.update_display()
		
		return true
	
	var remaining_count = item.count
	
	# 1단계: 같은 아이템이 있는 슬롯 찾아서 합치기
	if InventoryManeger.inventory_ui:
		var texture_rect = InventoryManeger.inventory_ui.get_node_or_null("TextureRect2")
		if texture_rect:
			var slots = texture_rect.get_children()
			
			for slot in slots:
				if remaining_count <= 0:
					break
					
				# 같은 아이템이 있는 슬롯 찾기
				if slot.has_method("_ready") and slot.thing and slot.thing.name == item.name:
					var existing_item = slot.thing
					var available_space = existing_item.max_count - existing_item.count
					
					if available_space > 0:
						var add_amount = min(remaining_count, available_space)
						existing_item.count += add_amount
						remaining_count -= add_amount
						
						# UI 업데이트
						if slot.has_method("update_display"):
							slot.update_display()
	
	# 2단계: 남은 아이템을 빈 슬롯에 배치
	while remaining_count > 0:
		var empty_slot = find_empty_inventory_slot()
		if empty_slot == null:
			return false
		
		# 새 아이템 인스턴스 생성
		var new_item = item.duplicate()
		new_item.count = min(remaining_count, item.max_count)
		remaining_count -= new_item.count
		
		# 빈 슬롯에 배치
		empty_slot.thing = new_item
		
		# UI 업데이트
		if empty_slot.has_method("update_display"):
			empty_slot.update_display()
	
	return true

# 빈 인벤토리 슬롯 찾기
func find_empty_inventory_slot():
	if InventoryManeger.inventory_ui:
		var texture_rect = InventoryManeger.inventory_ui.get_node_or_null("TextureRect2")
		if texture_rect:
			var slots = texture_rect.get_children()
			
			for slot in slots:
				if slot.has_method("_ready") and slot.thing == null:
					return slot
	
	return null


# 손에 도끼를 들고 있는지 확인하는 함수
func has_axe_in_hand() -> bool:

	var hand_slot_item = InventoryManeger.hand.thing if InventoryManeger.hand else null

	if hand_slot_item and hand_slot_item.tool == Item.what_tool.axe:
		return true
	return false

# 손에 곡괭이를 들고 있는지 확인하는 함수
func has_pickaxe_in_hand() -> bool:
	var hand_slot_item = InventoryManeger.hand.thing if InventoryManeger.hand else null
	
	if hand_slot_item and hand_slot_item.tool == Item.what_tool.pickaxe:
		return true
	return false

# 대상 오브젝트가 나무인지 확인하는 함수
func is_tree_object(target_object) -> bool:
	# 오브젝트의 스크립트를 확인하여 obsticle 타입인지 체크
	if target_object.has_method("get_script") and target_object.get_script():
		var script_path = target_object.get_script().get_path()
		if script_path.get_file() == "obsticle.gd":
			# obsticle의 thing 속성이 있고 타입이 tree인지 확인
			if target_object.thing:
				var obstacle_data = target_object.thing
				if obstacle_data.type == obsticle.mineable.tree:
					return true
	return false

# 대상 오브젝트가 돌인지 확인하는 함수
func is_stone_object(target_object) -> bool:
	# 오브젝트의 스크립트를 확인하여 obsticle 타입인지 체크
	if target_object.has_method("get_script") and target_object.get_script():
		var script_path = target_object.get_script().get_path()
		if script_path.get_file() == "obsticle.gd":
			# obsticle의 thing 속성이 있고 타입이 stone인지 확인
			if target_object.thing:
				var obstacle_data = target_object.thing
				if obstacle_data.type == obsticle.mineable.stone:
					return true
	return false

# 대상이 채굴 가능한 오브젝트인지 확인하는 함수 (times 변수 유무로 판별)
func is_mineable_object(target_object) -> bool:
	# obsticle 오브젝트인지 확인
	if target_object.has_method("get_script") and target_object.get_script():
		var script_path = target_object.get_script().get_path()
		if script_path.get_file() == "obsticle.gd":
			# thing 속성이 있고 times_mine 변수가 있으면 채굴 가능
			if target_object.thing and "times_mine" in target_object.thing:
				return true
	return false

# 대상이 entity인지 확인하는 함수
func is_entity_object(target_object) -> bool:
	# entity 오브젝트인지 확인
	if target_object.has_method("get_script") and target_object.get_script():
		var script_path = target_object.get_script().get_path()
		if script_path.get_file() == "entity.gd":
			return true
	return false

# 상호작용 타입을 구별하는 함수
func get_interaction_type(target_object) -> String:
	if is_mineable_object(target_object):
		return "mine"    # 채굴
	else:
		return "pickup"  # 줍기

# 채굴 상호작용 처리 함수 (나무, 돌 등)
func handle_mining_interaction(target_object):
	
	if not target_object or not target_object.thing:
		on_item = null
		return
	
	# 적절한 도구가 있는지 확인
	var has_correct_tool = false
	if is_tree_object(target_object) and has_axe_in_hand():
		has_correct_tool = true
	elif is_stone_object(target_object) and has_pickaxe_in_hand():
		has_correct_tool = true
	
	if not has_correct_tool:
		on_item = null
		return
	
	# 채굴 범위에 있는지 확인 (space_area 안에 있는지 체크)
	if target_object not in objects_in_space_area:
		# 채굴 중단 시 timer 정지하고 is_mining을 false로 설정
		breaking_timer.stop()
		is_mining = false
		on_item = null
		return
	
	# 채굴 시작 - timer 시작하고 is_mining을 true로 설정
	is_mining = true
	breaking_timer.start()
	
	# obsticle의 mine_once() 함수 호출하여 한 번 채굴
	var is_completely_mined = target_object.mine_once()
	
	if is_completely_mined:
		# 채굴 완료 시 timer 중단하고 is_mining을 false로 설정
		breaking_timer.stop()
		is_mining = false
		
		# 채굴된 오브젝트 타입에 따라 적절한 아이템 드롭
		if is_tree_object(target_object):
			drop_wood_item(target_object.global_position)
		elif is_stone_object(target_object):
			drop_stone_reward_item(target_object.global_position)
		
		# space_area 리스트에서도 제거
		if target_object in objects_in_space_area:
			objects_in_space_area.erase(target_object)
		
		# 채굴 완료 후 정리
		target_object.queue_free()
		on_item = null

# 아이템 줍기 상호작용 처리 함수
func handle_pickup_interaction(target_object):
	get_parent().add_tem(target_object)
	target_object.queue_free()
	on_item = null


# wood 아이템을 바닥에 드롭하는 함수
func drop_wood_item(drop_position: Vector3):
	
	# 새로운 wood 아이템 인스턴스 생성
	var wood_item = WOOD.duplicate()
	wood_item.count = 1  # 드롭할 wood 개수
	
	# 바닥에 아이템 생성
	var item_ground = ITEM_GROUND.instantiate()
	item_ground.thing = wood_item
	
	# 정확한 나무 위치에 아이템 드롭 (X, Z는 나무 위치 유지, Y는 지면 높이로 설정)
	item_ground.global_position = Vector3(drop_position.x, global_position.y, drop_position.z)
	
	# 메인 씬에 아이템 추가
	get_parent().add_child(item_ground)
	

# stone 채굴 시 battle_ground_winner 아이템을 바닥에 드롭하는 함수
func drop_stone_reward_item(drop_position: Vector3):
	
	# 새로운 battle_ground_winner 아이템 인스턴스 생성
	var reward_item = BATTLE_GROUND_WINNER.duplicate()
	reward_item.count = 1  # 드롭할 아이템 개수
	
	# 바닥에 아이템 생성
	var item_ground = ITEM_GROUND.instantiate()
	item_ground.thing = reward_item
	
	# 정확한 돌 위치에 아이템 드롭 (X, Z는 돌 위치 유지, Y는 지면 높이로 설정)
	item_ground.global_position = Vector3(drop_position.x, global_position.y, drop_position.z)
	
	# 메인 씬에 아이템 추가
	get_parent().add_child(item_ground)
	

# hand_node를 카메라 회전과 동기화하는 함수
func update_hand_node_rotation():
	# 메인 씬에서 카메라 회전값 가져오기
	var main_scene = get_parent()
	if main_scene.has_method("get_camera_basis"):
		var camera_transform = main_scene.get_camera_basis()
		# 카메라의 Y축 회전값을 hand_node에 적용
		var camera_y_rotation = camera_transform.get_euler().y
		hand_node.rotation.y = camera_y_rotation
	else:
		# 카메라 정보를 가져올 수 없는 경우 기본값 유지
		pass

# 기존 hand_anime 함수 - 호환성을 위해 유지 (deprecated)
# sprite: 설정할 텍스처
func hand_anime(things):
	if things:
		hand.texture = things.wear_img
	else:
		hand.texture = null
	

func hand_turn(a:bool):
	if a:
		is_ro = true
		hand_node.rotation.y += 180
		hand_sprite.flip_h = true
	else:
		if is_ro:
			is_ro = false
			hand_node.rotation.y -= 180
		hand_sprite.flip_h = false


func _on_space_area_area_entered(area):
	var target_object: Node3D = area.get_parent()
	
	if not target_object:
		return
	
	# space_area 안에 있는 오브젝트 리스트에 추가
	if target_object not in objects_in_space_area:
		objects_in_space_area.append(target_object)
	
	# 공격 대상 Entity가 범위에 진입한 경우
	if is_entity_object(target_object) and is_attacking and attack_target == target_object:
		is_target_in_attack_range = true
		return
	
	# 이동 중이고 현재 목표가 이 오브젝트인 경우
	if is_moving_to_target and on_item == target_object:
		
		# 공격 대상 로직 제거됨
		
		# 채굴 가능한 오브젝트이고 적절한 도구를 가지고 있는지 확인
		var has_correct_tool = false
		if is_tree_object(target_object) and has_axe_in_hand():
			has_correct_tool = true
		elif is_stone_object(target_object) and has_pickaxe_in_hand():
			has_correct_tool = true
		
		if is_mineable_object(target_object) and has_correct_tool:
			# 이동 중단
			if tween:
				tween.kill()
			is_moving_to_target = false
			manual_input_disabled = false

			# 즉시 채굴 시작
			handle_mining_interaction(target_object)


func _on_space_area_area_exited(area):
	var target_object = area.get_parent()
	
	if not target_object:
		return
	
	# space_area 안에 있는 오브젝트 리스트에서 제거
	if target_object in objects_in_space_area:
		objects_in_space_area.erase(target_object)
	
	# 공격 대상이 범위를 벗어난 경우
	if is_entity_object(target_object) and is_attacking and attack_target == target_object:
		is_target_in_attack_range = false
		return
	
	# 현재 채굴 중인 오브젝트가 범위를 벗어났으면 채굴 중단
	if on_item == target_object:
		# 채굴 중단 시 timer 정지하고 is_mining을 false로 설정
		if is_mining:
			breaking_timer.stop()
			is_mining = false
		on_item = null


# 채굴 타이머가 완료되었을 때 호출되는 함수
# 채굴 상태를 false로 변경하여 다시 스페이스바 입력을 받을 수 있게 함
func _on_breaking_timer_timeout():
	is_mining = false

# ===== 공격 시스템 함수들 =====

# 가장 가까운 Entity 찾기
func find_nearest_entity() -> Node3D:
	var nearest_entity = null
	var nearest_distance = INF
	
	# nearby_areas에서 entity만 필터링
	for area in nearby_areas:
		var target_object = area.get_parent()
		if is_entity_object(target_object):
			var distance = global_position.distance_to(target_object.global_position)
			if distance < nearest_distance:
				nearest_distance = distance
				nearest_entity = target_object
	
	return nearest_entity

# 공격 시작
func start_attack(target_entity: Node3D):
	
	is_attacking = true
	attack_target = target_entity
	last_enemy_position = target_entity.global_position
	
	# 적이 이미 범위 안에 있는지 확인
	if target_entity in objects_in_space_area:
		is_target_in_attack_range = true
		# 바로 공격 타이머 시작 (다음 프레임에서 처리됨)
	else:
		# 적에게 이동 시작
		move_to_enemy(target_entity)

# 적에게 이동하는 함수
func move_to_enemy(target_entity: Node3D):
	
	# 기존 attack_tween이 있으면 중지
	if attack_tween:
		attack_tween.kill()
	
	# 새로운 attack_tween 생성
	attack_tween = create_tween()
	
	# 목표 위치 설정 (적의 현재 위치)
	var enemy_position = target_entity.global_position
	enemy_position.y = global_position.y  # Y축 고정
	
	# 이동 거리 및 시간 계산
	var distance = global_position.distance_to(enemy_position)
	var actual_speed = SPEED * MOVEMENT_DAMPING
	var move_time = distance / actual_speed
	
	
	# 수동 입력 비활성화
	manual_input_disabled = true
	
	# Tween으로 적에게 이동
	attack_tween.tween_property(self, "global_position", enemy_position, move_time)

# 적 위치 추적 및 Tween 업데이트
func track_enemy_position():
	if not attack_target:
		return
	
	var current_enemy_position = attack_target.global_position
	
	# 적의 위치가 변경되었는지 확인 (일정 거리 이상 이동했을 때만)
	var position_change = last_enemy_position.distance_to(current_enemy_position)
	
	if position_change > 0.01:  # 0.01미터 이상 이동했을 때만 업데이트
		last_enemy_position = current_enemy_position
		
		# 기존 Tween 중단하고 새로운 경로로 이동
		move_to_enemy(attack_target)

# attack_timer 시작
func start_attack_timer():
	# 이미 타이머가 실행 중이면 중복 실행 방지
	if is_attack_timer_running:
		return
	
	is_attack_timer_running = true
	
	# 이동 중단
	if attack_tween:
		attack_tween.kill()
	manual_input_disabled = false
	
	# 대기 애니메이션으로 전환
	anime(Vector3.ZERO)
	
	# attack_timer 시작
	var _attack_timer = $attack_timer
	animation_player.play("attack")

# 공격 중단
func stop_attack():
	
	is_attacking = false
	attack_target = null
	last_enemy_position = Vector3.ZERO
	is_target_in_attack_range = false
	is_attack_timer_running = false
	
	# attack_tween 중단
	if attack_tween:
		attack_tween.kill()
		attack_tween = null
	
	manual_input_disabled = false

# attack_timer 완료 시 호출되는 함수
func _on_attack_timer_timeout():
	# 공격 타이머 완료
	is_attack_timer_running = false
	
	if not is_attacking or not attack_target:
		return
	
	# space_area 내에 공격 대상이 있는지 확인
	var target_in_range = false
	for obj in objects_in_space_area:
		if is_entity_object(obj) and obj == attack_target:
			target_in_range = true
			break
	
	if target_in_range:
		# 데미지 처리 (10 데미지, 추후 조정 가능)
		attack_target.take_damage(10)

	
	# 공격 완료 후 상태 초기화
	stop_attack()


# 플레이어가 공격받았을 때 호출되는 함수
# dam: 받은 데미지
func got_attacked(dam):
	print("플레이어가 ", dam, " 데미지를 받았습니다!")
	
	# HP 감소
	InventoryManeger.player_hp -= dam
	
	# HP가 0 이하가 되면 사망 처리
	if InventoryManeger.player_hp <= 0:
		print("플레이어가 사망했습니다!")
		# 추후 사망 처리 로직 추가 예정
		# player_death()
	
	# 피격 효과 (추후 추가 예정)
	# play_hit_sound()
	# show_damage_effect()


# ===== 설명 텍스트 표시 시스템 =====

## obsticle의 signal을 받아서 Label3D에 설명 텍스트를 표시하는 함수
## description_text: 표시할 설명 텍스트
## duration: 텍스트를 표시할 시간 (초)
func show_description_text(description_text: String, duration: float):
	if not label_3d:
		print("Label3D를 찾을 수 없습니다!")
		return
	
	# 텍스트 설정
	label_3d.text = description_text
	label_3d.visible = true
	
	# 기존 타이머가 있으면 제거
	if text_timer:
		text_timer.stop()
		text_timer.queue_free()
		text_timer = null
	
	# 지정된 시간 후 텍스트를 지우는 타이머 생성
	text_timer = Timer.new()
	text_timer.wait_time = duration
	text_timer.one_shot = true
	text_timer.timeout.connect(_on_description_timer_timeout)
	add_child(text_timer)
	text_timer.start()


## 타이머 완료 시 텍스트를 지우는 함수
func _on_description_timer_timeout():
	if label_3d:
		label_3d.text = ""
		label_3d.visible = false
	
	# 타이머 정리
	if text_timer:
		text_timer.queue_free()
		text_timer = null


## making_need UI를 열거나 닫는 함수
## making_note 근처에 있을 때만 작동
func handle_making_need_ui():
	# making_note 근처에 있는지 확인
	if not Globals.is_near_making_note:
		print("making_note 근처에 없습니다")
		return
	
	# resipis 정보가 없으면 리턴
	if not Globals.ob_re_resipis:
		print("레시피 정보가 없습니다")
		return
	
	# 메인 씬에서 making_need UI 찾기
	var main_scene = get_tree().current_scene
	var making_need_ui = main_scene.get_node_or_null("CanvasLayer/making_need")
	
	if not making_need_ui:
		print("making_need UI를 찾을 수 없습니다")
		return
	
	# UI 토글 (보이기/숨기기)
	making_need_ui.visible = !making_need_ui.visible
	
	# UI를 열 때 재료 정보 업데이트
	if making_need_ui.visible:
		if making_need_ui.has_method("update_materials"):
			making_need_ui.update_materials(Globals.ob_re_resipis)
		print("making_need UI 열림")
	else:
		print("making_need UI 닫힘")
