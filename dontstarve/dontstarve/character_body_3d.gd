extends CharacterBody3D
# 상수 정의 - 게임 밸런스 조정을 위한 값들
const SPEED = 3.5
const JUMP_VELOCITY = 4.5
const MOVEMENT_DAMPING = 0.2  # 움직임 감쇠 계수

# 개발자 모드 설정
@export var dev_mode: bool = true  ## 개발자 모드 활성화 시 이동 속도 100배 증가
# ==== 수면 시스템 Export 설정 ====
@export_group("수면 스태미나")
@export var sleep_stamina_max: float = 120.0  ## 최대 수면 스태미나 (2일 = 10분)
@export var sleep_regen_per_sec: float = 0.2  ## 초당 회복량 (10분에 120 도달)
@export var sleep_effect_threshold: float = 80.0  ## 효과 시작 임계치 (1일 반 후부터 졸림)

@export_group("수면 이동속도")
@export var sleep_min_speed_factor: float = 0.7  ## 최저 이동 속도 배율 (1.0 = 정상, 0.7 = 30% 감소)

@export_group("수면 셰이더 - 블러")
@export var sleep_blur_samples: int = 9  ## 블러 샘플 수 (1~25, 높을수록 부드럽지만 느림)
@export var sleep_blur_radius_max: float = 2.0  ## 최대 블러 반경

@export_group("수면 셰이더 - 비네팅")
@export var sleep_vignette_strength_max: float = 0.6  ## 최대 비네팅 강도 (화면 가장자리 어둡게)
@export var sleep_vignette_size: float = 0.6  ## 비네팅 크기 (작을수록 중심이 좁음)

@export_group("수면 셰이더 - 채도")
@export var sleep_desat_max: float = 0.6  ## 최대 채도 감소 (1.0이면 완전 흑백)

var is_ro = false
# 아이템 리소스
const WOOD = preload("res://item/tems/wood.tres")
const BATTLE_GROUND_WINNER = preload("res://item/tems/battle_ground_winner.tres")
const ITEM_GROUND = preload("res://item_ground.tscn")
@onready var run_sprite = get_node_or_null("run")
@onready var idle_sprite = get_node_or_null("idle")
@onready var animation_player = get_node_or_null("AnimationPlayer")
var on_item = null
# 회전 관련 상수
const ROT_SPEED = 180.0  # 초당 회전 속도 (도)
const ROT_STEPS = 8      # 총 회전 단계 수 (45도씩)
@onready var hand = get_node_or_null("hand_node/hand_sprite")
@export_group("직업")
@export var jobs : job
@onready var hand_2 = get_node_or_null("hand2")
@onready var hand_node = get_node_or_null("hand_node")
@onready var hand_sprite = get_node_or_null("hand_node/hand_sprite")
@onready var breaking_timer = get_node_or_null("breaking_timer")
@onready var label_3d = get_node_or_null("Label3D")  # 설명 텍스트를 표시할 Label3D
# attack_timer 제거됨

# 텍스트 표시 관련 변수
var text_timer: Timer = null  # 텍스트 표시를 위한 타이머

# 캐릭터 상태 변수
var dire = 'down'
var idle = true
var last_anim = ""

# 수면 스태미나 - 시간 경과에 따라 회복되어 MAX에 도달하면 이벤트 발생
var sleep_stamina: float = 0.0
var sleep_stamina_full_invoked: bool = false
var sleep_effect_message_shown: bool = false  # "너무 졸려" 메시지 표시 여부

# (삭제됨) 졸림 화면 오버레이 - 외부 shader 파일 사용으로 교체

# 이동 관련 변수
var is_moving_to_target = false  # 목표 위치로 이동 중인지 확인
var target_position = Vector3.ZERO  # 목표 위치
var movement_target_object = null  # 이동의 목적이 되는 오브젝트 (채굴/수집/줍기 대상)
var manual_input_disabled = false  # 수동 입력 비활성화

# 상호작용 관련 변수
var nearby_areas = []  # 근처에 있는 Area3D들
var interaction_target = null  # 현재 상호작용 대상
var previous_axe_state = false  # 이전 프레임의 도끼 보유 상태
var previous_pickaxe_state = false  # 이전 프레임의 곡괭이 보유 상태
var cant_move = false
# 퀵슬롯 키 입력 상태 추적
var quickslot_key_states = {
	KEY_1: false, KEY_2: false, KEY_3: false,
	KEY_4: false, KEY_5: false, KEY_6: false,
	KEY_7: false, KEY_8: false, KEY_9: false
}

# 채굴 상태 변수
var is_mining = false  # 현재 채굴 중인지 여부

# space_area 관련 변수
var objects_in_space_area = []  # space_area 안에 있는 오브젝트들
@onready var cantmove = $cantmove

# 공격 관련 변수
var is_attacking = false          # 현재 공격 중인지 여부
var attack_target = null          # 공격 대상 entity
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
	# "player" 그룹에 추가 (obsticle이 찾을 수 있도록)
	add_to_group("player")
	
	# 화면 오버레이 생성/셰이더 적용은 외부 씬(UI)에서 관리하도록 변경

func _physics_process(_delta):
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
	
	# 숫자 키 처리 - 퀵슬롯 시스템 (1~9번 슬롯)
	handle_quickslot_input()
	
	# 스페이스바 처리 - 상호작용 (채굴 vs 줍기 구별)
	# 채굴 중이거나 이동 중일 때는 스페이스바 입력을 막음
	if Input.is_action_just_pressed("space_bar"):
		print("🔧 [스페이스바] 눌림 - is_moving: ", is_moving_to_target, " | is_mining: ", is_mining)
		
		if is_moving_to_target or is_mining:
			print("  ❌ 이동 중이거나 채굴 중이라서 무시됨")
			return
		
		# 1. space_area 안에 있는 item_ground 우선 처리
		var nearest_item = find_nearest_item_in_space_area()
		if nearest_item:
			print("  📦 [스페이스바] space_area 내 아이템 발견 - 즉시 줍기")
			handle_pickup_interaction(nearest_item)
			return
		
		# 2. 마우스에 obsticle이 걸려있는 경우 처리
		if Globals.mouse_on_obsticle:
			handle_space_bar_obsticle_interaction(Globals.mouse_on_obsticle)
			return
		
		# 3. 이미 채굴 중인 오브젝트가 있는 경우 계속 채굴
		if on_item and is_mineable_object(on_item):
			print("  ✅ 이미 채굴 중인 오브젝트: ", on_item.name)
			handle_mining_interaction(on_item)
		# 4. 새로운 상호작용 대상이 있는 경우
		elif interaction_target:
			var target_object = get_game_object_from_area(interaction_target)
			print("  🎯 상호작용 대상: ", target_object.name if target_object else "없음")
			
			# entity인 경우 아무것도 하지 않음
			if is_entity_object(target_object):
				print("  ❌ Entity는 상호작용 불가")
				return
			
			# collectable 타입인지 먼저 확인
			if is_collectable_obsticle(target_object):
				print("  📦 collectable 타입 - 수집 처리")
				if target_object in objects_in_space_area:
					# 범위 안에 있으면 즉시 수집
					print("  ✅ 범위 내 - 즉시 수집")
					handle_collectable_interaction(target_object)
				else:
					# 범위 밖이면 이동
					print("  🚶 범위 밖 - 이동 시작")
					move_to_interaction_target()
				return
			
			var interaction_type = get_interaction_type(target_object)
			print("  📋 상호작용 타입: ", interaction_type)
			
			# 디버그: target_object의 thing 정보 출력
			if target_object and target_object.has_method("get_script") and target_object.get_script():
				print("  🔍 [디버그] 스크립트: ", target_object.get_script().get_path().get_file())
				if "thing" in target_object:
					print("  🔍 [디버그] thing 존재: ", target_object.thing != null)
					if target_object.thing:
						print("  🔍 [디버그] thing.name: ", target_object.thing.name if "name" in target_object.thing else "이름없음")
						print("  🔍 [디버그] thing.type: ", target_object.thing.type if "type" in target_object.thing else "타입없음")
			
			if interaction_type == "mine":
				# 채굴 대상인 경우 - 적절한 도구가 있어야 함
				var has_correct_tool = false
				
				print("  🔨 채굴 가능 여부 체크:")
				print("    - is_tree: ", is_tree_object(target_object), " | has_moon_axe: ", has_moon_axe_in_hand())
				print("    - is_stone: ", is_stone_object(target_object), " | has_moon_pickaxe: ", has_moon_pickaxe_in_hand())
				print("    - is_moon_tree: ", is_moon_tree_object(target_object), " | has_axe: ", has_axe_in_hand())
				print("    - is_moon_stone: ", is_moon_stone_object(target_object), " | has_pickaxe: ", has_pickaxe_in_hand())
				
				# 일반 tree와 stone은 moon 도구로만 부술 수 있음
				if is_tree_object(target_object) and has_moon_axe_in_hand():
					has_correct_tool = true
				elif is_stone_object(target_object) and has_moon_pickaxe_in_hand():
					has_correct_tool = true
				# moon_tree와 moon_stone은 일반 도구로도 부술 수 있음
				elif is_moon_tree_object(target_object) and (has_axe_in_hand() or has_moon_axe_in_hand()):
					has_correct_tool = true
				elif is_moon_stone_object(target_object) and (has_pickaxe_in_hand() or has_moon_pickaxe_in_hand()):
					has_correct_tool = true
				
				print("  🔧 올바른 도구: ", has_correct_tool)
				
				if has_correct_tool:
					# 채굴 범위에 있는지 확인
					if target_object in objects_in_space_area:
						print("  ✅ 범위 내에 있음 - 채굴 시작")
						on_item = target_object  # 채굴 대상 설정
						handle_mining_interaction(target_object)
					else:
						print("  🚶 범위 밖 - 이동 시작")
						move_to_interaction_target()
				else:
					print("  ❌ 올바른 도구가 없음")
			else:
				# 아이템 줍기인 경우 - 이동해서 줍기
				print("  📦 아이템 줍기 - 이동 시작")
				move_to_interaction_target()
		else:
			print("  ❌ 상호작용 대상이 없음")

	# cant_move가 true면 움직임 차단
	if cant_move:
		velocity.x = 0
		velocity.z = 0
		move_and_slide()
		return
	
	# 입력 방향 확인 (Tween 중단을 위해 먼저 체크)
	var input_dir = Input.get_vector('a',"d",'s','w')
	
	# WASD 입력이 있고 자동 이동 중이면 Tween 중단
	if input_dir != Vector2.ZERO and (is_moving_to_target or is_attacking):
		interrupt_movement()
	
	# 자동 이동 중일 때 물리 기반 이동 처리
	if is_moving_to_target:
		var distance_to_target = global_position.distance_to(target_position)
		
		# 목표 지점에 충분히 가까우면 이동 완료
		if distance_to_target < 0.1:
			velocity.x = 0
			velocity.z = 0
			on_move_complete()
		else:
			# 목표 방향으로 이동
			var move_direction = (target_position - global_position).normalized()
			var speed_scale = lerp(1.0, sleep_min_speed_factor, get_sleepiness_strength())
			var actual_speed = SPEED * (100.0 if dev_mode else 1.0)
			velocity.x = move_direction.x * actual_speed * MOVEMENT_DAMPING * speed_scale
			velocity.z = move_direction.z * actual_speed * MOVEMENT_DAMPING * speed_scale
			
			# 애니메이션 처리
			anime(Vector3(move_direction.x, 0, move_direction.z))
	# 수동 입력 처리
	elif not manual_input_disabled:
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
			var speed_scale = lerp(1.0, sleep_min_speed_factor, get_sleepiness_strength())
			var actual_speed = SPEED * (100.0 if dev_mode else 1.0)
			velocity.x = direction.x * actual_speed * MOVEMENT_DAMPING * speed_scale
			velocity.z = direction.z * actual_speed * MOVEMENT_DAMPING * speed_scale
		else:
			# 정지 시 감속 처리
			var actual_speed = SPEED * (100.0 if dev_mode else 1.0)
			velocity.x = move_toward(velocity.x, 0, actual_speed)
			velocity.z = move_toward(velocity.z, 0, actual_speed)
	
	# 공격 중일 때 적 위치 추적 및 물리 기반 이동
	if is_attacking and attack_target:
		# 공격 타이머가 이미 실행 중이면 아무것도 하지 않음
		if is_attack_timer_running:
			velocity.x = 0
			velocity.z = 0
		# 공격 대상이 범위에 있으면 바로 공격 타이머 시작
		elif is_target_in_attack_range:
			start_attack_timer()
		else:
			# 적에게 물리 기반으로 이동
			var enemy_position = attack_target.global_position
			var distance_to_enemy = global_position.distance_to(enemy_position)
			
			if distance_to_enemy > 0.1:
				var move_direction = (enemy_position - global_position).normalized()
				var speed_scale = lerp(1.0, sleep_min_speed_factor, get_sleepiness_strength())
				var actual_speed = SPEED * (100.0 if dev_mode else 1.0)
				velocity.x = move_direction.x * actual_speed * MOVEMENT_DAMPING * speed_scale
				velocity.z = move_direction.z * actual_speed * MOVEMENT_DAMPING * speed_scale
				
				# 애니메이션 처리
				anime(Vector3(move_direction.x, 0, move_direction.z))

	# 수면 스태미나 회복 처리
	if sleep_stamina < sleep_stamina_max:
		sleep_stamina = min(sleep_stamina_max, sleep_stamina + sleep_regen_per_sec * _delta)
		
		# sleep_effect_threshold에 도달했을 때 메시지 표시 (1회만)
		if sleep_stamina >= sleep_effect_threshold and not sleep_effect_message_shown:
			sleep_effect_message_shown = true
			show_description_text("너무 졸려", 3.0)
		
		# sleep_stamina_max에 도달했을 때 애니메이션 실행 (1회만)
		if sleep_stamina >= sleep_stamina_max and not sleep_stamina_full_invoked:
			sleep_stamina_full_invoked = true
			on_sleep_stamina_full()

	# 졸림 오버레이 갱신은 외부(UI)에서 shader 파라미터로 제어

	# Entity(layer 6) 충돌 무시를 위해 이동 전 위치 저장
	var position_before_move = global_position
	
	# 물리 이동 적용
	move_and_slide()
	
	# Entity(layer 6)한테 밀렸는지 확인하고 무시
	for i in get_slide_collision_count():
		var collision = get_slide_collision(i)
		var collider = collision.get_collider()
		
		# 충돌한 오브젝트가 Entity(layer 6)인지 확인
		if collider.collision_layer & (1 << 5):  # layer 6 = 2^5 = 32
			# 플레이어는 Entity를 통과하도록 원래 이동 방향으로 계속 이동
			var move_distance = velocity * _delta
			global_position = position_before_move + move_distance
			break  # 한 번만 처리

## 졸림 강도 계산 (0.0 ~ 1.0)
## sleep_stamina가 sleep_effect_threshold 이상일 때 효과 시작
## sleep_stamina가 높을수록 졸림 강도 증가
func get_sleepiness_strength() -> float:
	if sleep_stamina < sleep_effect_threshold:
		return 0.0  # 임계치 미만이면 효과 없음
	
	# sleep_effect_threshold ~ sleep_stamina_max 구간을 0.0 ~ 1.0으로 매핑
	var range_max := sleep_stamina_max - sleep_effect_threshold
	if range_max <= 0.0:
		return 1.0
	
	var s := (sleep_stamina - sleep_effect_threshold) / range_max
	return clamp(s, 0.0, 1.0)

## 외부 셰이더 머티리얼을 업데이트하는 함수
## 사용법: UI 스크립트의 _process()에서 player.update_sleep_overlay_external(material) 호출
func update_sleep_overlay_external(material: ShaderMaterial):
	if material == null:
		return
	
	var s := get_sleepiness_strength()
	
	# 비네팅/채도/블러는 제곱으로 부드럽게 증가
	var k := s * s
	
	# 블러 효과
	var blur_radius := sleep_blur_radius_max * k
	material.set_shader_parameter("blur_samples", sleep_blur_samples)
	material.set_shader_parameter("blur_radius", blur_radius)
	
	# 비네팅 효과
	var vignette_strength := sleep_vignette_strength_max * k
	material.set_shader_parameter("vignette_strength", vignette_strength)
	material.set_shader_parameter("vignette_size", sleep_vignette_size)
	
	# 채도 감소
	var desat := sleep_desat_max * k
	material.set_shader_parameter("desaturation", desat)
	
	# 눈꺼풀 효과 제거 (항상 0)
	material.set_shader_parameter("eyelid_amount", 0.0)
	
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
	
	# 목표 위치 설정
	target_position = target_pos
	
	is_moving_to_target = true
	manual_input_disabled = true
	
	print("물리 기반 이동 시작: ", target_pos)
	

# 이동 완료 시 호출되는 함수
func on_move_complete():
	# 일반적인 이동 완료 처리
	is_moving_to_target = false
	manual_input_disabled = false
	movement_target_object = null  # 이동 목적 초기화
	# 목적지 도착 후 idle 애니메이션으로 전환
	anime(Vector3.ZERO)
	
	# on_item은 space_area 진입 시 처리되므로 여기서는 아무것도 하지 않음
	# (collectable, 채굴, 아이템 줍기 모두 _on_space_area_body_entered에서 처리)

# WASD 입력 시 자동 이동 중단 함수
func interrupt_movement():
	is_moving_to_target = false
	manual_input_disabled = false
	on_item = null  # 아이템 줍기 취소
	movement_target_object = null  # 이동 목적 초기화
	
	# velocity 초기화
	velocity.x = 0
	velocity.z = 0
	
	# 채굴 중이었다면 채굴도 중단
	if is_mining:
		breaking_timer.stop()
		is_mining = false
	
	# 공격 중이었다면 공격도 중단
	if is_attacking:
		stop_attack()
	
	# making_veiw의 설치 대기 중이었다면 취소
	var main_scene = get_parent()
	if main_scene:
		var making_veiw = main_scene.get_node_or_null("making_veiw")
		if making_veiw and making_veiw.has_method("cancel_placement"):
			if making_veiw.waiting_for_character:
				making_veiw.cancel_placement()


# Area3D에 Area가 들어왔을 때 (item_ground 등)
func _on_area_3d_area_entered(area):
	nearby_areas.append(area)
	update_interaction_target()

# Area3D에서 Area가 나갔을 때
func _on_area_3d_area_exited(area):
	nearby_areas.erase(area)
	update_interaction_target()

# Area3D에 Body가 들어왔을 때 (obsticle, entity 등)
func _on_area_3d_body_entered(body):
	print("📍 [Area3D] body 진입: ", body.name, " | collision_layer: ", body.collision_layer if body is CollisionObject3D else "N/A")
	nearby_areas.append(body)
	update_interaction_target()
	print("  → interaction_target 설정됨: ", interaction_target.name if interaction_target else "없음")
	
	# 제작대인지 확인하고 InventoryManeger에 등록
	if body.has_method("get_script") and body.get_script():
		var script_path = body.get_script().get_path()
		if script_path.get_file() == "obsticle.gd":
			if body.thing and body.thing.type == obsticle.mineable.craft_table:
				InventoryManeger.add_nearby_craft_table(body)

# Area3D에서 Body가 나갔을 때
func _on_area_3d_body_exited(body):
	nearby_areas.erase(body)
	update_interaction_target()
	
	# 제작대인지 확인하고 InventoryManeger에서 제거
	if body.has_method("get_script") and body.get_script():
		var script_path = body.get_script().get_path()
		if script_path.get_file() == "obsticle.gd":
			if body.thing and body.thing.type == obsticle.mineable.craft_table:
				InventoryManeger.remove_nearby_craft_table(body)

# Area3D 또는 StaticBody3D에서 실제 게임 오브젝트를 찾는 헬퍼 함수
# Area3D -> Sprite3D -> obsticle 또는 StaticBody3D(obsticle) 등의 구조를 처리
func get_game_object_from_area(node) -> Node3D:
	# StaticBody3D나 CharacterBody3D인 경우 그대로 반환 (이미 게임 오브젝트)
	if node is StaticBody3D or node is CharacterBody3D:
		return node
	
	# Area3D인 경우 부모를 확인
	if node is Area3D:
		var parent = node.get_parent()
		
		# 부모가 Sprite3D인 경우, 그 부모(obsticle)를 찾음
		if parent and parent.get_script() and parent.get_script().get_path().get_file() == "sprite_3d.gd":
			return parent.get_parent()
		
		# 그 외의 경우 부모를 그대로 반환
		return parent
	
	# 그 외의 경우 null 반환
	return null

# 상호작용 대상 업데이트 (도구 유무에 따라 장애물 포함/제외)
func update_interaction_target():
	if nearby_areas.is_empty():
		interaction_target = null
		return
	
	var has_axe = has_axe_in_hand()
	var has_pickaxe = has_pickaxe_in_hand()
	var has_moon_axe = has_moon_axe_in_hand()
	var has_moon_pickaxe = has_moon_pickaxe_in_hand()
	var valid_targets = []
	
	# 도구 유무에 따라 유효한 대상 필터링
	for area in nearby_areas:
		var target_object = get_game_object_from_area(area)
		
		# entity는 상호작용 대상에서 제외 (공격 시스템 제거로 무시)
		if is_entity_object(target_object):
			continue
		
		# obsticle의 type이 nothing인 경우 제외
		if is_nothing_obsticle(target_object):
			continue
		
		# 일반 나무인지 확인
		if is_tree_object(target_object):
			# moon_axe를 들고 있을 때만 일반 나무를 대상으로 포함
			if has_moon_axe:
				valid_targets.append(area)
		# 일반 돌인지 확인
		elif is_stone_object(target_object):
			# moon_pickaxe를 들고 있을 때만 일반 돌을 대상으로 포함
			if has_moon_pickaxe:
				valid_targets.append(area)
		# moon_tree인지 확인
		elif is_moon_tree_object(target_object):
			# 일반 도끼나 moon_axe를 들고 있을 때 moon_tree를 대상으로 포함
			if has_axe or has_moon_axe:
				valid_targets.append(area)
		# moon_stone인지 확인
		elif is_moon_stone_object(target_object):
			# 일반 곡괭이나 moon_pickaxe를 들고 있을 때 moon_stone을 대상으로 포함
			if has_pickaxe or has_moon_pickaxe:
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
	
	var target_object = get_game_object_from_area(interaction_target)
	var _interaction_type = get_interaction_type(target_object)
	
	on_item = target_object
	movement_target_object = target_object  # 이동 목적 오브젝트 설정
	
	# 이미 범위 안에 있는지 확인
	if target_object in objects_in_space_area:
		print("  ✅ [클릭] 이미 범위 내 - 즉시 상호작용")
		# 채굴 가능한 오브젝트면 즉시 채굴
		if _interaction_type == "mine":
			handle_mining_interaction(target_object)
		# collectable이면 즉시 수집
		elif is_collectable_obsticle(target_object):
			handle_collectable_interaction(target_object)
		# 아이템이면 즉시 줍기
		else:
			handle_pickup_interaction(target_object)
		movement_target_object = null  # 즉시 상호작용 완료 시 초기화
		return
	
	# 범위 밖이면 이동
	print("  🚶 [클릭] 범위 밖 - 이동 시작 (목적: ", target_object.name, ")")
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


## space_area 안에 있는 가장 가까운 item_ground를 찾는 함수
func find_nearest_item_in_space_area() -> Node3D:
	var nearest_item = null
	var nearest_distance = INF
	
	# objects_in_space_area에서 item_ground만 필터링
	for obj in objects_in_space_area:
		# item_ground 스크립트를 가지고 있는지 확인
		if obj.get_script() and obj.get_script().get_path().get_file() == "item_ground.gd":
			if obj.thing:
				# 플레이어와의 거리 계산
				var distance = global_position.distance_to(obj.global_position)
				if distance < nearest_distance:
					nearest_distance = distance
					nearest_item = obj
	
	return nearest_item

## 범위 내의 가장 가까운 아이템 하나만 줍는 함수
func pickup_all_items_in_range():
	# space_area 노드 찾기
	var space_area = get_node_or_null("Area3D")
	if not space_area:
		return
	
	# space_area 안에 있는 모든 Area3D 가져오기
	var overlapping_areas = space_area.get_overlapping_areas()
	
	if overlapping_areas.is_empty():
		return
	
	var nearest_item = null
	var nearest_distance = INF
	
	# 각 Area를 확인하여 가장 가까운 item_ground 찾기
	for area in overlapping_areas:
		# Area의 부모가 item_ground인지 확인
		var parent = area.get_parent()
		if not parent:
			continue
		
		# item_ground 스크립트를 가지고 있는지 확인
		if parent.get_script() and parent.get_script().get_path().get_file() == "item_ground.gd":
			if parent.thing:
				# 플레이어와의 거리 계산
				var distance = global_position.distance_to(parent.global_position)
				if distance < nearest_distance:
					nearest_distance = distance
					nearest_item = parent
	
	# 가장 가까운 아이템 하나만 줍기
	if nearest_item:
		add_item_to_inventory(nearest_item.thing)
		nearest_item.queue_free()
		print("📦 [아이템 줍기] ", nearest_item.thing.name, " 획득 (거리: ", nearest_distance, ")")
		return  # 아이템 하나를 주웠으면 즉시 종료

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

# 손에 달 도끼를 들고 있는지 확인하는 함수
func has_moon_axe_in_hand() -> bool:
	var hand_slot_item = InventoryManeger.hand.thing if InventoryManeger.hand else null
	
	if hand_slot_item and hand_slot_item.tool == Item.what_tool.moon_axe:
		return true
	return false

# 손에 달 곡괭이를 들고 있는지 확인하는 함수
func has_moon_pickaxe_in_hand() -> bool:
	var hand_slot_item = InventoryManeger.hand.thing if InventoryManeger.hand else null
	
	if hand_slot_item and hand_slot_item.tool == Item.what_tool.moon_pickaxe:
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

# 대상 오브젝트가 달 나무인지 확인하는 함수
func is_moon_tree_object(target_object) -> bool:
	# 오브젝트의 스크립트를 확인하여 obsticle 타입인지 체크
	if target_object.has_method("get_script") and target_object.get_script():
		var script_path = target_object.get_script().get_path()
		if script_path.get_file() == "obsticle.gd":
			# obsticle의 thing 속성이 있고 타입이 moon_tree인지 확인
			if target_object.thing:
				var obstacle_data = target_object.thing
				if obstacle_data.type == obsticle.mineable.moon_tree:
					return true
	return false

# 대상 오브젝트가 달 돌인지 확인하는 함수
func is_moon_stone_object(target_object) -> bool:
	# 오브젝트의 스크립트를 확인하여 obsticle 타입인지 체크
	if target_object.has_method("get_script") and target_object.get_script():
		var script_path = target_object.get_script().get_path()
		if script_path.get_file() == "obsticle.gd":
			# obsticle의 thing 속성이 있고 타입이 moon_stone인지 확인
			if target_object.thing:
				var obstacle_data = target_object.thing
				if obstacle_data.type == obsticle.mineable.moon_stone:
					return true
	return false

## 대상 오브젝트의 타입이 nothing인지 확인하는 함수
func is_nothing_obsticle(target_object) -> bool:
	# 오브젝트의 스크립트를 확인하여 obsticle 타입인지 체크
	if target_object.has_method("get_script") and target_object.get_script():
		var script_path = target_object.get_script().get_path()
		if script_path.get_file() == "obsticle.gd":
			# obsticle의 thing 속성이 있고 타입이 nothing인지 확인
			if target_object.thing:
				var obstacle_data = target_object.thing
				if obstacle_data.type == obsticle.mineable.nothing:
					return true
	return false

## 대상 오브젝트가 수집 가능한 obsticle인지 확인하는 함수
func is_collectable_obsticle(target_object) -> bool:
	# 오브젝트의 스크립트를 확인하여 obsticle 타입인지 체크
	if target_object.has_method("get_script") and target_object.get_script():
		var script_path = target_object.get_script().get_path()
		if script_path.get_file() == "obsticle.gd":
			# obsticle의 thing 속성이 있고 타입이 collectable인지 확인
			if target_object.thing:
				var obstacle_data = target_object.thing
				if obstacle_data.type == obsticle.mineable.collectable and obstacle_data.is_collectable == 1:
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

## obsticle에 맞는 올바른 도구를 가지고 있는지 확인하는 함수
func has_correct_tool_for_obstacle(target_object) -> bool:
	if not target_object or not target_object.thing:
		return false
	
	# 일반 tree와 stone은 moon 도구로만 부술 수 있음
	if is_tree_object(target_object) and has_moon_axe_in_hand():
		return true
	elif is_stone_object(target_object) and has_moon_pickaxe_in_hand():
		return true
	# moon_tree와 moon_stone은 일반 도구로도 부술 수 있음
	elif is_moon_tree_object(target_object) and (has_axe_in_hand() or has_moon_axe_in_hand()):
		return true
	elif is_moon_stone_object(target_object) and (has_pickaxe_in_hand() or has_moon_pickaxe_in_hand()):
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
	
	# 이미 채굴 중이면 무시 (연타 방지)
	if is_mining:
		print("  ⚠️ [채굴] 이미 채굴 중 - 무시")
		return
	
	# 적절한 도구가 있는지 확인
	var has_correct_tool = false
	# 일반 tree와 stone은 moon 도구로만 부술 수 있음
	if is_tree_object(target_object) and has_moon_axe_in_hand():
		has_correct_tool = true
	elif is_stone_object(target_object) and has_moon_pickaxe_in_hand():
		has_correct_tool = true
	# moon_tree와 moon_stone은 일반 도구로도 부술 수 있음
	elif is_moon_tree_object(target_object) and (has_axe_in_hand() or has_moon_axe_in_hand()):
		has_correct_tool = true
	elif is_moon_stone_object(target_object) and (has_pickaxe_in_hand() or has_moon_pickaxe_in_hand()):
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
	
	# 채굴 성공 시 도구 내구도 감소
	use_tool_durability()
	
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

## collectable 타입 obsticle 수집 처리 함수
func handle_collectable_interaction(target_object):
	if not target_object or not target_object.thing:
		on_item = null
		return
	
	# obsticle의 collect_items() 함수 호출
	if target_object.has_method("collect_items"):
		target_object.collect_items()
	
	# 수집 완료 후 on_item 초기화
	on_item = null

## 대상 오브젝트가 space_area 안에 있는지 확인하는 함수
func is_in_space_area(target_object) -> bool:
	return target_object in objects_in_space_area

## 스페이스바로 마우스에 걸린 obsticle 상호작용 처리
func handle_space_bar_obsticle_interaction(obsticle_node):
	if not obsticle_node or not obsticle_node.thing:
		return
	
	var thing = obsticle_node.thing
	print("  🎯 [스페이스바] 마우스에 걸린 obsticle: ", thing.name)
	
	# collectable 타입이고 is_collectable이 1이면 수집
	if thing.type == obsticle.mineable.collectable and thing.is_collectable == 1:
		print("  📦 collectable 타입 - 수집 처리")
		if obsticle_node in objects_in_space_area:
			# 범위 안에 있으면 즉시 수집
			print("  ✅ 범위 내 - 즉시 수집")
			if obsticle_node.has_method("collect_items"):
				obsticle_node.collect_items()
		else:
			# 범위 밖이면 이동
			print("  🚶 범위 밖 - 이동 시작")
			on_item = obsticle_node
			move_to_position(obsticle_node.global_position)
	# 채굴 가능한 타입인 경우
	elif is_mineable_object(obsticle_node):
		print("  ⛏️ 채굴 가능 타입 - 채굴 처리")
		# 도구 체크
		var has_correct_tool = false
		
		if is_tree_object(obsticle_node) and has_moon_axe_in_hand():
			has_correct_tool = true
		elif is_stone_object(obsticle_node) and has_moon_pickaxe_in_hand():
			has_correct_tool = true
		elif is_moon_tree_object(obsticle_node) and (has_axe_in_hand() or has_moon_axe_in_hand()):
			has_correct_tool = true
		elif is_moon_stone_object(obsticle_node) and (has_pickaxe_in_hand() or has_moon_pickaxe_in_hand()):
			has_correct_tool = true
		
		if has_correct_tool:
			if obsticle_node in objects_in_space_area:
				# 범위 안에 있으면 즉시 채굴
				print("  ✅ 범위 내 + 올바른 도구 - 즉시 채굴")
				on_item = obsticle_node
				handle_mining_interaction(obsticle_node)
			else:
				# 범위 밖이면 이동
				print("  🚶 범위 밖 - 이동 시작")
				on_item = obsticle_node
				move_to_position(obsticle_node.global_position)
		else:
			print("  ❌ 올바른 도구가 없음")
	else:
		print("  ℹ️ 일반 obsticle - 상호작용 없음")


# wood 아이템을 바닥에 드롭하는 함수
func drop_wood_item(drop_position: Vector3):
	
	# 새로운 wood 아이템 인스턴스 생성
	var wood_item = WOOD.duplicate()
	wood_item.count = 1  # 드롭할 wood 개수
	
	# 바닥에 아이템 생성
	var item_ground = ITEM_GROUND.instantiate()
	item_ground.thing = wood_item
	
	# 정확한 나무 위치에 아이템 드롭 (X, Z는 나무 위치 유지, Y는 지면 높이 0.05로 설정)
	item_ground.global_position = Vector3(drop_position.x, 0.05, drop_position.z)
	
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
	
	# 정확한 돌 위치에 아이템 드롭 (X, Z는 돌 위치 유지, Y는 지면 높이 0.05로 설정)
	item_ground.global_position = Vector3(drop_position.x, 0.05, drop_position.z)
	
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


## space_area에 Area3D가 진입했을 때 (item_ground 등)
func _on_space_area_area_entered(area):
	print("🟢 [space_area] area 진입 감지: ", area.name, " | collision_layer: ", area.collision_layer if area is CollisionObject3D else "N/A")
	
	# Area의 부모가 item_ground인지 확인
	var parent = area.get_parent()
	if not parent:
		return
	
	# item_ground 스크립트를 가지고 있는지 확인
	if parent.get_script() and parent.get_script().get_path().get_file() == "item_ground.gd":
		print("  📦 [space_area] item_ground 감지: ", parent.thing.name if parent.thing else "없음")
		
		# space_area 안에 있는 오브젝트 리스트에 추가
		if parent not in objects_in_space_area:
			objects_in_space_area.append(parent)
		
		# 이동 중이고 이동 목적이 이 아이템이면 자동 줍기
		if is_moving_to_target and parent == on_item:
			print("  ✅ [space_area] 아이템 도착 - 자동 줍기")
			
			# 이동 중단
			is_moving_to_target = false
			manual_input_disabled = false
			velocity.x = 0
			velocity.z = 0
			
			# 즉시 줍기
			handle_pickup_interaction(parent)
			
			# 이동 목적 달성 후 초기화
			on_item = null

## space_area에 Area3D가 나갔을 때
func _on_space_area_area_exited(area):
	# Area의 부모가 item_ground인지 확인
	var parent = area.get_parent()
	if not parent:
		return
	
	# item_ground 스크립트를 가지고 있는지 확인
	if parent.get_script() and parent.get_script().get_path().get_file() == "item_ground.gd":
		# space_area 안에 있는 오브젝트 리스트에서 제거
		if parent in objects_in_space_area:
			objects_in_space_area.erase(parent)

func _on_space_area_body_entered(body):
	print("🔵 [space_area] body 진입 감지: ", body.name, " | collision_layer: ", body.collision_layer if body is CollisionObject3D else "N/A")
	
	var target_object: Node3D = get_game_object_from_area(body)
	
	if not target_object:
		print("  ❌ target_object를 찾을 수 없음")
		return
	
	# space_area 안에 있는 오브젝트 리스트에 추가
	if target_object not in objects_in_space_area:
		objects_in_space_area.append(target_object)
	
	print("🔵 [space_area 진입] 오브젝트: ", target_object.name if target_object else "없음")
	print("  - is_moving: ", is_moving_to_target)
	print("  - on_item: ", on_item.name if on_item else "없음")
	print("  - target_object == on_item: ", target_object == on_item)
	
	# 공격 대상 Entity가 범위에 진입한 경우
	if is_entity_object(target_object) and is_attacking and attack_target == target_object:
		is_target_in_attack_range = true
		return
	
	# collectable 타입인 경우 - 이동 중이고 이동 목적과 일치할 때 자동 채집
	if is_collectable_obsticle(target_object) and is_moving_to_target and target_object == on_item:
		print("  🍎 [space_area] collectable 도착 - 자동 채집 시작")
		
		# 이동 중단
		is_moving_to_target = false
		manual_input_disabled = false
		velocity.x = 0
		velocity.z = 0
		
		# 즉시 채집
		handle_collectable_interaction(target_object)
		
		# 이동 목적 달성 후 초기화
		on_item = null
		return
	
	# 아이템 줍기 - 이동 중이고 이동 목적과 일치할 때 자동 줍기
	if target_object.get_script() and target_object.get_script().get_path().get_file() == "item_ground.gd":
		if is_moving_to_target and target_object == on_item:
			print("  📦 [space_area] 아이템 도착 - 자동 줍기")
			
			# 이동 중단
			is_moving_to_target = false
			manual_input_disabled = false
			velocity.x = 0
			velocity.z = 0
			
			# 즉시 줍기
			handle_pickup_interaction(target_object)
			
			# 이동 목적 달성 후 초기화
			on_item = null
			return
	
	# 채굴 가능한 오브젝트인 경우 - 이동 중이고 이동 목적과 일치할 때만 자동 채굴 시작
	if is_mineable_object(target_object) and is_moving_to_target and target_object == movement_target_object:
		print("  🎯 [space_area] 이동 목적 오브젝트 도착: ", target_object.name)
		# 적절한 도구를 가지고 있는지 확인
		var has_correct_tool = false
		# 일반 tree와 stone은 moon 도구로만 부술 수 있음
		if is_tree_object(target_object) and has_moon_axe_in_hand():
			has_correct_tool = true
		elif is_stone_object(target_object) and has_moon_pickaxe_in_hand():
			has_correct_tool = true
		# moon_tree와 moon_stone은 일반 도구로도 부술 수 있음
		elif is_moon_tree_object(target_object) and (has_axe_in_hand() or has_moon_axe_in_hand()):
			has_correct_tool = true
		elif is_moon_stone_object(target_object) and (has_pickaxe_in_hand() or has_moon_pickaxe_in_hand()):
			has_correct_tool = true
		
		if has_correct_tool:
			print("  ✅ [space_area] 채굴 가능 + 올바른 도구 → 이동 중단 및 채굴 시작")
			
			# 이동 중단
			is_moving_to_target = false
			manual_input_disabled = false
			velocity.x = 0
			velocity.z = 0
			
			# 즉시 채굴 시작
			handle_mining_interaction(target_object)
			
			# 이동 목적 달성 후 초기화
			movement_target_object = null
		else:
			print("  ❌ [space_area] 올바른 도구 없음 - has_tool: ", has_correct_tool)
	elif is_mineable_object(target_object) and is_moving_to_target and target_object != movement_target_object:
		print("  ⚠️ [space_area] 다른 오브젝트 통과 중 (목적: ", movement_target_object.name if movement_target_object else "없음", " | 현재: ", target_object.name, ")")


func _on_space_area_body_exited(body):
	var target_object = get_game_object_from_area(body)
	
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
		var target_object = get_game_object_from_area(area)
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
		# 적에게 물리 기반 이동 시작 (_physics_process에서 처리됨)
		is_target_in_attack_range = false


# attack_timer 시작
func start_attack_timer():
	# 이미 타이머가 실행 중이면 중복 실행 방지
	if is_attack_timer_running:
		return
	
	is_attack_timer_running = true
	manual_input_disabled = false
	
	# velocity 초기화 (이동 중단)
	velocity.x = 0
	velocity.z = 0
	
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
	
	# velocity 초기화
	velocity.x = 0
	velocity.z = 0
	
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
		attack_target.thing.take_damage(10)
		attack_target.set_hp()
		attack_target.thing.bhaver()
		
		# 무기 내구도 감소
		use_tool_durability()

	
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


# 수면 스태미나가 가득 찼을 때 호출되는 함수
func on_sleep_stamina_full():
	# 메인 씬에서 CanvasLayer/TextureRect/AnimationPlayer 찾기
	var main_scene = get_tree().current_scene
	if not main_scene:
		print("메인 씬을 찾을 수 없습니다")
		return
	
	var canvas_layer = main_scene.get_node_or_null("CanvasLayer")
	if not canvas_layer:
		print("CanvasLayer를 찾을 수 없습니다")
		return
	
	var texture_rect = canvas_layer.get_node_or_null("TextureRect")
	if not texture_rect:
		print("TextureRect를 찾을 수 없습니다")
		return
	
	var sleep_anim_player = texture_rect.get_node_or_null("AnimationPlayer")
	if not sleep_anim_player:
		print("AnimationPlayer를 찾을 수 없습니다")
		return
	
	# "open" 애니메이션 재생
	if sleep_anim_player.has_animation("open"):
		sleep_anim_player.play("open")
		print("수면 애니메이션 'open' 재생")
	else:
		print("'open' 애니메이션을 찾을 수 없습니다")


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
## making_note 근처에 있으면 재료 정보 표시, 없으면 빈 상태로 표시
func handle_making_need_ui():
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
		# making_note 근처에 있는지 확인
		if Globals.is_near_making_note and Globals.ob_re_resipis:
			# 근처에 있으면 재료 정보 업데이트
			if making_need_ui.has_method("update_materials"):
				# 저장된 재료 투입 현황도 함께 전달
				making_need_ui.update_materials(Globals.ob_re_resipis, Globals.ob_re_contributed)
			print("making_need UI 열림 - 재료 정보 표시")
		else:
			# 근처에 없으면 빈 상태로 표시 (재료 목록 비우기)
			if making_need_ui.has_method("clear_materials"):
				making_need_ui.clear_materials()
				making_need_ui.current_resipis = null
				making_need_ui.contributed_materials.clear()
			print("making_need UI 열림 - 빈 상태 (making_note 근처 아님)")
	else:
		print("making_need UI 닫힘")


## 숫자 키 입력을 처리하여 퀵슬롯 시스템 구현
func handle_quickslot_input():
	# 각 키에 대해 "just pressed" 상태 확인
	var keys_to_check = [
		[KEY_1, 0], [KEY_2, 1], [KEY_3, 2],
		[KEY_4, 3], [KEY_5, 4], [KEY_6, 5],
		[KEY_7, 6], [KEY_8, 7], [KEY_9, 8]
	]
	
	for key_data in keys_to_check:
		var key_code = key_data[0]
		var slot_index = key_data[1]
		var is_pressed = Input.is_physical_key_pressed(key_code)
		
		# just pressed 감지: 현재 눌려있고 이전에는 안 눌려있었음
		if is_pressed and not quickslot_key_states[key_code]:
			use_quickslot(slot_index)
		
		# 키 상태 업데이트
		quickslot_key_states[key_code] = is_pressed


## 특정 슬롯의 아이템을 사용/장착하는 함수
## slot_index: 슬롯 인덱스 (0부터 시작)
func use_quickslot(slot_index: int):
	# 인벤토리 UI 찾기
	var main_scene = get_tree().current_scene
	if not main_scene:
		return
	
	var inventory_ui = main_scene.get_node_or_null("CanvasLayer/inventory")
	if not inventory_ui:
		print("인벤토리 UI를 찾을 수 없습니다")
		return
	
	var texture_rect = inventory_ui.get_node_or_null("TextureRect2")
	if not texture_rect:
		print("TextureRect2를 찾을 수 없습니다")
		return
	
	var slots = texture_rect.get_children()
	
	# 슬롯 인덱스 범위 확인
	if slot_index < 0 or slot_index >= slots.size():
		print("잘못된 슬롯 인덱스: ", slot_index)
		return
	
	var slot = slots[slot_index]
	var item = slot.thing
	
	# 슬롯이 비어있으면 리턴
	if not item:
		print("슬롯 ", slot_index + 1, "번이 비어있습니다")
		return
	
	# 아이템 타입에 따라 처리
	handle_item_use(item, slot)


## 아이템 타입에 따라 사용/장착 처리
## item: 사용할 아이템
## slot: 아이템이 있던 슬롯
func handle_item_use(item: Item, slot):
	# 1. 손에 들 수 있는 아이템 확인 (무기/도구 포함)
	if item.can_hand:
		equip_weapon(item, slot)
		print("아이템을 손에 장착: ", item.name)
		return
	
	# 2. 방어구 확인 (일단 pass)
	if item.wear != Item.wears_op.nothing:
		print("방어구 장착 (미구현): ", item.name)
		pass
		return
	
	# 3. 음식 확인 (일단 pass)
	if item.eatable:
		print("음식 먹기 (미구현): ", item.name)
		pass
		return
	
	print("사용할 수 없는 아이템: ", item.name)


## 무기/도구를 손 장비 슬롯에 장착하는 함수
## weapon: 장착할 무기/도구
## slot: 무기가 있던 인벤토리 슬롯
func equip_weapon(weapon: Item, slot):
	# can_hand 체크 - 손에 들 수 있는 아이템인지 확인
	if not weapon.can_hand:
		print("이 아이템은 손에 들 수 없습니다: ", weapon.name)
		return
	
	# hand 장비 슬롯 가져오기 (InventoryManeger.hand는 item_slot 노드)
	var hand_slot = InventoryManeger.hand
	if not hand_slot:
		print("hand 슬롯을 찾을 수 없습니다")
		return
	
	# 현재 hand 슬롯에 무기가 있는지 확인
	if hand_slot.thing:
		# 기존 무기를 눌린 슬롯으로 이동 (스왑)
		var old_weapon = hand_slot.thing
		slot.thing = old_weapon
		slot.update_display()
		print("기존 무기를 ", slot.slot_no + 1, "번 슬롯으로 이동: ", old_weapon.name)
	else:
		# hand 슬롯이 비어있으면 인벤토리 슬롯만 비우기
		slot.thing = null
		slot.update_display()
	
	# 새 무기를 hand 슬롯에 장착
	hand_slot.thing = weapon
	hand_slot.update_display()
	
	# 손 장비 업데이트
	InventoryManeger.equipped_hand = weapon
	InventoryManeger.change_hand_equipment.emit(weapon)
	
	# 애니메이션 업데이트
	var main_scene = get_tree().current_scene
	if main_scene and main_scene.has_method("anime_update"):
		main_scene.anime_update(weapon)
	
	print("무기 장착 완료: ", weapon.name, " (hand 슬롯)")

func got_attack(dam):
	cant_move = true
	cantmove.start()
	animation_player.play("got_attack")

func _on_timer_timeout():
	cant_move = false


func use_tool_durability():
	# hand 슬롯 가져오기
	var hand_slot = InventoryManeger.hand
	if not hand_slot or not hand_slot.thing:
		return
	
	var tool_item = hand_slot.thing
	
	# 내구도 시스템이 없는 아이템은 무시
	if not tool_item.negudo:
		return
	
	# 내구도 감소
	var is_broken = tool_item.use_durability()
	
	# UI 업데이트
	hand_slot.update_display()
	
	# 도구가 파괴되었으면 슬롯에서 제거
	if is_broken:
		print("🔨 [내구도] 도구가 파괴되었습니다: ", tool_item.name)
		hand_slot.thing = null
		hand_slot.update_display()
		
		# 손 장비 업데이트
		InventoryManeger.equipped_hand = null
		InventoryManeger.change_hand_equipment.emit(null)
		
		# 애니메이션 업데이트 (맨손)
		var main_scene = get_tree().current_scene
		if main_scene and main_scene.has_method("anime_update"):
			main_scene.anime_update(null)
	else:
		print("🔧 [내구도] ", tool_item.name, " 내구도: ", int(tool_item.negudo_per), "%")
