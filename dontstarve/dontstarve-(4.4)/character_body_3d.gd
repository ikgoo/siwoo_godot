extends CharacterBody3D
# 상수 정의 - 게임 밸런스 조정을 위한 값들
const SPEED = 5
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
@onready var attack_timer = $attack_timer

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
var is_attacking = false  # 현재 공격 중인지 여부
var attack_target = null  # 공격 대상
var attack_tracking_timer: Timer = null  # 공격 중 대상 추적 타이머
var on_target = []
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
	
	# 공격 추적 타이머 초기화
	attack_tracking_timer = Timer.new()
	attack_tracking_timer.wait_time = 0.3  # 0.3초마다 위치 업데이트
	attack_tracking_timer.timeout.connect(_on_attack_tracking_timer_timeout)
	add_child(attack_tracking_timer)

func _physics_process(_delta):
	# 점프 처리
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	# F키 처리 - 공격
	if Input.is_action_just_pressed("f") and not is_moving_to_target and not is_mining and not is_attacking:
		handle_attack_input()

	
	# 스페이스바 처리 - 상호작용 (채굴 vs 줍기 구별)
	# 채굴 중이거나 이동 중일 때는 스페이스바 입력을 막음
	if Input.is_action_just_pressed("space_bar") and not is_moving_to_target and not is_mining:
		# 1. 이미 채굴 중인 오브젝트가 있는 경우 계속 채굴
		if on_item and is_mineable_object(on_item):
			print("채굴 중인 오브젝트 계속 채굴...")
			handle_mining_interaction(on_item)
		# 2. 새로운 상호작용 대상이 있는 경우
		elif interaction_target:
			var target_object = interaction_target.get_parent()
			
			# entity인 경우 아무것도 하지 않음
			if is_entity_object(target_object):
				print("Entity는 상호작용할 수 없습니다")
				return
			
			var interaction_type = get_interaction_type(target_object)
			
			print("스페이스바 입력 - 상호작용 타입: ", interaction_type)
			
			if interaction_type == "mine":
				# 채굴 대상인 경우 - 적절한 도구가 있어야 함
				var has_correct_tool = false
				var tool_name = ""
				
				if is_tree_object(target_object) and has_axe_in_hand():
					has_correct_tool = true
					tool_name = "도끼"
				elif is_stone_object(target_object) and has_pickaxe_in_hand():
					has_correct_tool = true
					tool_name = "곡괭이"
				
				if has_correct_tool:
					# 채굴 범위에 있는지 확인
					if target_object in objects_in_space_area:
						print("채굴 시작! (", tool_name, " 사용)")
						on_item = target_object  # 채굴 대상 설정
						handle_mining_interaction(target_object)
					else:
						print("채굴 범위 밖 - 대상으로 이동합니다!")
						move_to_interaction_target()
				else:
					if is_tree_object(target_object):
						print("나무를 베려면 도끼가 필요합니다!")
					elif is_stone_object(target_object):
						print("돌을 캐려면 곡괭이가 필요합니다!")
					else:
						print("채굴하려면 적절한 도구가 필요합니다!")
			else:
				# 아이템 줍기인 경우 - 이동해서 줍기
				move_to_interaction_target()

	# 입력 방향 확인 (Tween 중단을 위해 먼저 체크)
	var input_dir = Input.get_vector('a',"d",'s','w')
	
	# WASD 입력이 있고 자동 이동 중이면 Tween 중단
	if input_dir != Vector2.ZERO and is_moving_to_target:
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

	# 물리 이동 적용
	move_and_slide()
	
	# 도구 상태 변화 감지 및 상호작용 대상 업데이트
	var current_axe_state = has_axe_in_hand()
	var current_pickaxe_state = has_pickaxe_in_hand()
	
	if current_axe_state != previous_axe_state:
		print("도끼 상태 변화: ", previous_axe_state, " → ", current_axe_state)
		update_interaction_target()
		previous_axe_state = current_axe_state
	
	if current_pickaxe_state != previous_pickaxe_state:
		print("곡괭이 상태 변화: ", previous_pickaxe_state, " → ", current_pickaxe_state)
		update_interaction_target()
		previous_pickaxe_state = current_pickaxe_state
	
	# hand_node를 카메라와 동일한 Y축 회전값으로 업데이트
	update_hand_node_rotation()

# 클릭한 위치로 이동하는 함수
# target_pos: 목표 위치 (Vector3)
func move_to_position(target_pos: Vector3):
	print("=== move_to_position 호출 ===")
	print("현재 위치: ", global_position)
	print("목표 위치: ", target_pos)
	
	# Y좌표를 현재 캐릭터 위치로 고정하여 수직 이동 방지
	target_pos.y = global_position.y
	print("Y 좌표 보정 후 목표 위치: ", target_pos)
	
	# 이전 Tween이 있으면 중지
	if tween:
		print("기존 Tween 중단")
		tween.kill()
	
	# 새로운 Tween 생성
	tween = create_tween()
	print("새로운 Tween 생성: ", tween)
	
	# 목표 위치 설정
	target_position = target_pos
	
	is_moving_to_target = true
	manual_input_disabled = true
	print("이동 상태 설정 완료")
	
	# 이동 거리 계산 (WASD 이동과 동일한 속도로 설정)
	var distance = global_position.distance_to(target_pos)
	var actual_speed = SPEED * MOVEMENT_DAMPING  # WASD와 동일한 실제 속도 적용
	var move_time = distance / actual_speed  # 실제 이동속도 기준 시간 계산
	
	print("거리: ", distance, ", 속도: ", actual_speed, ", 시간: ", move_time)
	
	# Tween으로 부드러운 이동
	tween.tween_property(self, "global_position", target_pos, move_time)
	print("Tween 애니메이션 시작")
	
	# 이동 완료 시 콜백 연결
	tween.tween_callback(on_move_complete)
	print("이동 완료 콜백 연결")
	

# 이동 완료 시 호출되는 함수
func on_move_complete():
	is_moving_to_target = false
	manual_input_disabled = false
	# 목적지 도착 후 idle 애니메이션으로 전환
	anime(Vector3.ZERO)
	
	if on_item:
		var interaction_type = get_interaction_type(on_item)
		print("목적지 도달! 상호작용 타입: ", interaction_type)
		
		if interaction_type == "attack":
			# 공격 처리 (이미 is_attacking 상태)
			check_attack_execution()
		elif interaction_type == "mine":
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
		print("이동 중단으로 인해 채굴도 중단됨")
	
	print("자동 이동이 중단되었습니다")


# Area3D에 무언가 들어왔을 때
func _on_area_3d_area_entered(area):
	print("Area 감지: ", area.name)
	
	# collision_mask가 8인 경우 공격 대상으로 추가
	if area.collision_mask == 8:
		var target_object: Node3D = area.get_parent()
		on_target.append([target_object, target_object.global_position.distance_to(global_position)])
		print("공격 대상 추가: ", target_object.name)
	
	nearby_areas.append(area)
	update_interaction_target()

# Area3D에서 무언가 나갔을 때  
func _on_area_3d_area_exited(area):
	print("Area 벗어남: ", area.name)
	
	# collision_mask가 8인 경우 공격 대상에서 제거
	if area.collision_mask == 8:
		var target_object = area.get_parent()
		for i in range(len(on_target)):
			if on_target[i][0] == target_object:
				on_target.remove_at(i)
				print("공격 대상 제거: ", target_object.name)
				break
	
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
		
		# entity는 상호작용 대상에서 제외
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
	
	# 디버깅 로그
	if interaction_target:
		var target_object = interaction_target.get_parent()
		if is_tree_object(target_object):
			print("상호작용 대상: 나무 (", target_object.name, ") - 도끼 보유: ", has_axe)
		elif is_stone_object(target_object):
			print("상호작용 대상: 돌 (", target_object.name, ") - 곡괭이 보유: ", has_pickaxe)
		else:
			print("상호작용 대상: 아이템 (", target_object.name, ")")
	

# 상호작용 대상으로 이동하는 함수
func move_to_interaction_target():
	print("=== move_to_interaction_target 호출 ===")
	if not interaction_target:
		print("상호작용 대상이 없습니다")
		return
	
	var target_object = interaction_target.get_parent()
	var interaction_type = get_interaction_type(target_object)
	
	print("상호작용 대상 ", target_object.name, "로 이동합니다 (타입: ", interaction_type, ")")
	on_item = target_object
	# 대상의 Y좌표도 캐릭터 높이로 고정
	var item_position = interaction_target.global_position
	item_position.y = global_position.y
	print("이동 목표 위치: ", item_position)
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
		print("줍을 아이템이 없습니다")
		return
		
	var item = item_node.thing
	print("아이템을 주웠습니다: ", item.name)
	print("아이템 정보: ", item)
	
	# 인벤토리에 아이템 추가 시도
	add_item_to_inventory(item)
	
	# 땅에서 아이템 제거
	item_node.queue_free()

# 인벤토리에 아이템 추가
func add_item_to_inventory(item: Item):
	# 인벤토리 매니저를 통해 아이템 추가
	print("인벤토리에 아이템 추가 시도: ", item.name)
	
	# 빈 슬롯 찾기
	for i in range(InventoryManeger.inventory.size()):
		if InventoryManeger.inventory[i].is_empty():
			InventoryManeger.inventory[i] = [item]
			print("인벤토리 슬롯 ", i, "에 아이템 추가됨: ", item.name)
			return true
	
	print("인벤토리가 가득 찼습니다!")
	return false


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
	if is_entity_object(target_object):
		return "attack"  # 공격
	elif is_mineable_object(target_object):
		return "mine"    # 채굴
	else:
		return "pickup"  # 줍기

# 채굴 상호작용 처리 함수 (나무, 돌 등)
func handle_mining_interaction(target_object):
	print("채굴 상호작용 시작: ", target_object.name)
	
	if not target_object or not target_object.thing:
		print("채굴할 대상이 없습니다")
		on_item = null
		return
	
	# 적절한 도구가 있는지 확인
	var has_correct_tool = false
	if is_tree_object(target_object) and has_axe_in_hand():
		has_correct_tool = true
	elif is_stone_object(target_object) and has_pickaxe_in_hand():
		has_correct_tool = true
	
	if not has_correct_tool:
		if is_tree_object(target_object):
			print("나무를 베려면 도끼가 필요합니다!")
		elif is_stone_object(target_object):
			print("돌을 캐려면 곡괭이가 필요합니다!")
		else:
			print("채굴하려면 적절한 도구가 필요합니다!")
		on_item = null
		return
	
	# 채굴 범위에 있는지 확인 (space_area 안에 있는지 체크)
	if target_object not in objects_in_space_area:
		print("채굴 대상이 범위를 벗어났습니다! 채굴 중단")
		# 채굴 중단 시 timer 정지하고 is_mining을 false로 설정
		breaking_timer.stop()
		is_mining = false
		on_item = null
		return
	
	# 채굴 시작 - timer 시작하고 is_mining을 true로 설정
	print("채굴 시도 중...")
	is_mining = true
	breaking_timer.start()
	
	# obsticle의 mine_once() 함수 호출하여 한 번 채굴
	var is_completely_mined = target_object.mine_once()
	
	if is_completely_mined:
		print("채굴 완료! 오브젝트가 완전히 채굴되었습니다.")
		
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
	else:
		print("채굴 진행 중... 더 채굴이 필요합니다. 계속 스페이스바를 누르세요!")
		# on_item은 그대로 유지하여 계속 채굴 가능하게 함

# 아이템 줍기 상호작용 처리 함수
func handle_pickup_interaction(target_object):
	print("아이템 줍기: ", target_object.name)
	get_parent().add_tem(target_object)
	target_object.queue_free()
	on_item = null


# wood 아이템을 바닥에 드롭하는 함수
func drop_wood_item(drop_position: Vector3):
	print("wood 아이템 드롭 시작")
	
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
	
	print("wood 아이템이 드롭되었습니다: ", wood_item.name, " x", wood_item.count, " 위치: ", item_ground.global_position)

# stone 채굴 시 battle_ground_winner 아이템을 바닥에 드롭하는 함수
func drop_stone_reward_item(drop_position: Vector3):
	print("battle_ground_winner 아이템 드롭 시작")
	
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
	
	print("battle_ground_winner 아이템이 드롭되었습니다: ", reward_item.name, " x", reward_item.count, " 위치: ", item_ground.global_position)

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
	print("=== space_area에 오브젝트 진입 ===")
	var target_object: Node3D = area.get_parent()
	
	if not target_object:
		return
	
	print("진입한 오브젝트: ", target_object.name)
	
	# space_area 안에 있는 오브젝트 리스트에 추가
	if target_object not in objects_in_space_area:
		objects_in_space_area.append(target_object)
		print("space_area 오브젝트 추가: ", target_object.name, " (총 ", objects_in_space_area.size(), "개)")
	
	# 이동 중이고 현재 목표가 이 오브젝트인 경우
	if is_moving_to_target and on_item == target_object:
		print("목표 오브젝트에 도달! 이동 중단")
		
		# 채굴 가능한 오브젝트이고 적절한 도구를 가지고 있는지 확인
		var has_correct_tool = false
		if is_tree_object(target_object) and has_axe_in_hand():
			has_correct_tool = true
		elif is_stone_object(target_object) and has_pickaxe_in_hand():
			has_correct_tool = true
		
		if is_mineable_object(target_object) and has_correct_tool:
			print("채굴 범위 진입 - 이동 중단하고 채굴 시작!")
			
			# 이동 중단
			if tween:
				tween.kill()
			is_moving_to_target = false
			manual_input_disabled = false

			# 즉시 채굴 시작
			handle_mining_interaction(target_object)
		else:
			# 일반 아이템인 경우 기존 로직 사용
			print("일반 아이템 - 이동 완료 대기")


func _on_space_area_area_exited(area):
	print("=== space_area에서 오브젝트 이탈 ===")
	var target_object = area.get_parent()
	
	if not target_object:
		return
	
	print("이탈한 오브젝트: ", target_object.name)
	
	# space_area 안에 있는 오브젝트 리스트에서 제거
	if target_object in objects_in_space_area:
		objects_in_space_area.erase(target_object)
		print("space_area 오브젝트 제거: ", target_object.name, " (총 ", objects_in_space_area.size(), "개)")
	
	# 현재 채굴 중인 오브젝트가 범위를 벗어났으면 채굴 중단
	if on_item == target_object:
		print("채굴 중인 오브젝트가 범위를 벗어났습니다! 채굴 중단")
		# 채굴 중단 시 timer 정지하고 is_mining을 false로 설정
		if is_mining:
			breaking_timer.stop()
			is_mining = false
		on_item = null


# 채굴 타이머가 완료되었을 때 호출되는 함수
# 채굴 상태를 false로 변경하여 다시 스페이스바 입력을 받을 수 있게 함
func _on_breaking_timer_timeout():
	print("채굴 타이머 완료 - 다시 채굴 가능")
	is_mining = false

# =========================
# 공격 시스템
# =========================

# F키 입력 처리 - 공격 대상 탐지 및 공격 시작
func handle_attack_input():
	print("=== 공격 입력 감지 ===")
	
	# 공격 쿨다운 체크
	if not attack_timer.is_stopped():
		return
	
	# 손에 든 무기 확인
	var weapon = get_weapon_in_hand()
	if weapon == null:
		print("손에 무기가 없습니다!")
		return
	
	# 근처에서 공격 가능한 몹 찾기
	var target = find_nearest_attackable_target()
	if target == null:
		print("공격할 대상이 근처에 없습니다!")
		return
	
	# 공격 시작
	start_attack(target, weapon)

# 손에 든 무기 가져오기
func get_weapon_in_hand() -> Item:
	var hand_slot_item = InventoryManeger.hand.thing if InventoryManeger.hand else null
	
	if hand_slot_item == null:
		return null
	
	# 무기이거나 데미지가 있는 아이템인지 확인
	if hand_slot_item.tool == Item.what_tool.weapon or hand_slot_item.damage > 0:
		return hand_slot_item
	
	return null

# 근처에서 공격 가능한 대상 찾기
func find_nearest_attackable_target():
	if on_target:
		var close = -1
		for i in range(len(on_target)):
			on_target[i][1] = on_target[i][0].global_position.distance_to(global_position)
			if close != -1:
				if on_target[close][1] > on_target[i][1]:
					close = i
			else:
				close = i
		return on_target[close][0]
	return null
# 모든 잠재적 공격 대상 찾기
func get_all_potential_targets() -> Array:
	var targets = []
	var scene_root = get_tree().current_scene
	
	# 재귀적으로 모든 노드 검색
	_collect_potential_targets(scene_root, targets)
	
	return targets

# 재귀적으로 공격 대상 수집
func _collect_potential_targets(node: Node, targets: Array):
	# Area3D나 collision이 있는 노드 체크
	if node is Area3D or node is RigidBody3D or node is CharacterBody3D:
		if node != self:  # 자기 자신은 제외
			targets.append(node)
	
	# 자식 노드들도 검색
	for child in node.get_children():
		_collect_potential_targets(child, targets)

# 유효한 공격 대상인지 확인
func is_valid_attack_target(node: Node) -> bool:
	# 자기 자신은 공격 불가
	if node == self:
		return false
	
	# collision_mask가 4인지 확인
	var has_mask_4 = false
	
	if node is Area3D:
		has_mask_4 = (node.collision_mask & 4) != 0
	elif node is RigidBody3D:
		has_mask_4 = (node.collision_mask & 4) != 0
	elif node is CharacterBody3D:
		has_mask_4 = (node.collision_mask & 4) != 0
	
	if has_mask_4:
		print("공격 가능한 대상 발견: ", node.name, " (collision_mask: ", node.collision_mask, ")")
	
	return has_mask_4

# 공격 시작
func start_attack(target: Node, weapon: Item):
	print("=== 공격 시작 ===")
	print("대상: ", target.name)
	print("무기: ", weapon.name, " (데미지: ", weapon.damage, ")")
	
	attack_target = target
	is_attacking = true
	
	# 대상으로 이동
	move_to_attack_target()

# 공격 대상으로 이동
func move_to_attack_target():
	if not attack_target:
		print("공격 대상이 없습니다!")
		is_attacking = false
		return
	
	print("공격 대상으로 이동: ", attack_target.name)
	on_item = attack_target
	
	# 대상의 Y좌표도 캐릭터 높이로 고정 (obsticle 이동 방식과 동일)
	var item_position = attack_target.global_position
	item_position.y = global_position.y
	print("이동 목표 위치: ", item_position)
	move_to_position(item_position)
	
	# 공격 중 실시간 위치 추적 타이머 시작
	start_attack_tracking_timer()

# 공격 실행 체크
func check_attack_execution():
	if not is_attacking or not attack_target:
		return
	
	# 대상과의 거리 체크
	var distance = global_position.distance_to(attack_target.global_position)
	if distance <= 2.0:  # 공격 범위 내
		execute_attack()
	else:
		print("대상이 너무 멀어서 공격할 수 없습니다 (거리: ", distance, ")")
		is_attacking = false
		attack_target = null
		stop_attack_tracking_timer()

# 실제 공격 실행
func execute_attack():
	print("=== 공격 실행 ===")
	
	var weapon = get_weapon_in_hand()
	if not weapon:
		print("무기가 사라졌습니다!")
		is_attacking = false
		attack_target = null
		stop_attack_tracking_timer()
		return
	
	var damage = weapon.damage
	print("데미지 ", damage, " 공격!")
	
	# 대상이 데미지를 받을 수 있는 함수가 있다면 호출
	if attack_target.has_method("take_damage"):
		attack_target.take_damage(damage)
	elif attack_target.has_method("damage"):
		attack_target.damage(damage)
	else:
		print("대상이 데미지를 받을 수 없습니다: ", attack_target.name)
	
	
	# 공격 상태 해제
	is_attacking = false
	attack_target = null
	
	# 공격 추적 타이머 중단
	stop_attack_tracking_timer()

# 공격 중 대상 추적 타이머를 시작하는 함수
# 지속적으로 대상의 위치를 업데이트하여 움직이는 적을 추적
func start_attack_tracking_timer():
	if attack_tracking_timer and not attack_tracking_timer.is_stopped():
		attack_tracking_timer.stop()
	
	if attack_tracking_timer:
		print("공격 추적 타이머 시작 - 0.3초마다 대상 위치 업데이트")
		attack_tracking_timer.start()

# 공격 추적 타이머를 중단하는 함수
func stop_attack_tracking_timer():
	if attack_tracking_timer and not attack_tracking_timer.is_stopped():
		print("공격 추적 타이머 중단")
		attack_tracking_timer.stop()

# 공격 추적 타이머 타임아웃 콜백 함수
# 0.3초마다 호출되어 대상의 현재 위치로 이동 경로를 업데이트
func _on_attack_tracking_timer_timeout():
	if not is_attacking or not attack_target:
		stop_attack_tracking_timer()
		return
	
	# 대상이 아직 유효한지 확인
	if not is_instance_valid(attack_target):
		print("공격 대상이 무효해졌습니다!")
		is_attacking = false
		attack_target = null
		stop_attack_tracking_timer()
		return
	
	# 대상과의 거리 계산
	var distance = global_position.distance_to(attack_target.global_position)
	print("대상과의 거리: ", distance)
	
	# 공격 범위 내에 있으면 공격 실행
	if distance <= 2.0:
		print("공격 범위 내 진입! 공격 실행")
		execute_attack()
		return
	
	# 대상이 너무 멀어지면 새로운 경로로 이동
	if distance > 15.0:
		print("대상이 너무 멀어져서 공격 포기")
		is_attacking = false
		attack_target = null
		stop_attack_tracking_timer()
		return
	
	# 현재 이동 중이 아니거나 목표 위치가 많이 달라졌으면 새로운 이동 시작
	var current_target_position = attack_target.global_position
	current_target_position.y = global_position.y
	
	var distance_to_current_target = target_position.distance_to(current_target_position)
	
	# 목표 위치가 1.5미터 이상 바뀌었거나 이동이 완료된 상태면 새로운 이동 시작
	if distance_to_current_target > 1.5 or not is_moving_to_target:
		print("대상 위치 업데이트! 새로운 경로로 이동: ", current_target_position)
		move_to_position(current_target_position)
	
