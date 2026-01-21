extends CharacterBody2D

const SPEED = 100.0
const RUN_SPEED = 150.0  # 달리기 속도

const JUMP_VELOCITY = -300.0  # 최대 점프 높이
const MIN_JUMP_VELOCITY = -200.0  # 최소 점프 높이 (빠르게 뗄 때)

# 가속도 설정
@export var acceleration: float = 800.0  # 가속도 (픽셀/초²)
@export var friction: float = 600.0  # 마찰력/감속도 (픽셀/초²)
@export var air_acceleration: float = 400.0  # 공중 가속도 (픽셀/초²) - 낮을수록 미끄러짐

# 플랫폼 레이어 마스크
const PLATFORM_COLLISION_LAYER = 4  # 플랫폼 전용 collision layer
const NORMAL_COLLISION_LAYER = 1    # 일반 타일 collision layer
const ALL_COLLISION_LAYERS = 5      # 일반 타일 + 플랫폼
 
# S 키를 눌렀을 때 플랫폼 통과 상태 (y 위치 기반)
var platform_out: bool = false
var platform_out_y: float = 0.0  # S키 눌렀을 때의 y 위치
const PLATFORM_DROP_DISTANCE: float = 20.0  # 이 거리만큼 내려가면 다시 충돌 활성화

# 이전 프레임의 S 키 상태 추적
var was_s_key_pressed: bool = false

# 채굴 키 입력 추적 (이전 프레임 상태) - 최대 6개 키 지원
var was_mining_keys_pressed: Array[bool] = [false, false, false, false, false, false]

# 자동 채굴 (키 꾹 누르기) 타이머 - 각 키별로 따로 (최대 6개)
var auto_mining_timers: Array[float] = [0.0, 0.0, 0.0, 0.0, 0.0, 0.0]

# 점프 관련 변수
var is_jumping: bool = false
var jump_hold_time: float = 0.0

# 공중 이동 속도 (점프 전 속도 저장)
var air_speed: float = 0.0

# 캐릭터 상태 enum
enum State {
	IDLE,      # 대기
	WALKING,   # 걷기
	JUMPING,   # 점프
	FALLING,   # 낙하
	MINING     # 채굴 중
}

# 현재 상태
var current_state: State = State.IDLE
# 캐릭터가 바라보는 방향 (1: 오른쪽, -1: 왼쪽)
var facing_direction: int = 1
# 스프라이트 노드 참조 (애니메이션용)
@onready var sprite: AnimatedSprite2D = $sprite if has_node("sprite") else null
@onready var pickaxe: Sprite2D = $pickaxe if has_node("pickaxe") else null
# 애니메이션 플레이어 노드
@onready var animation_player: AnimationPlayer = $AnimationPlayer if has_node("AnimationPlayer") else null

# 현재 재생 중인 애니메이션
var current_animation: String = ""

# 곡괭이 애니메이션 관련 (원호 궤적)
@export var pickaxe_arc_radius: float = 20.0  # 원호 반지름
@export var pickaxe_arc_center_offset: Vector2 = Vector2(5, 5)  # 원호 중심점 오프셋
@export var pickaxe_start_angle: float = -60.0  # 시작 각도 (도, 위쪽)
@export var pickaxe_end_angle: float = -10.0  # 끝 각도 (도, 앞쪽 아래)
@export var pickaxe_rotation_offset: float = 90.0  # 곡괭이 회전 오프셋 (궤적에 수직이 되도록)
@export var pickaxe_animation_duration: float = 0.3  # 애니메이션 총 시간

var pickaxe_animation_time: float = 0.0  # 현재 애니메이션 진행 시간
var is_pickaxe_animating: bool = false  # 애니메이션 진행 중인지

# 차징 시스템
var is_charging: bool = false  # 차징 중인지
var charge_amount: float = 0.0  # 현재 차지량 (0.0 ~ 1.0)
@export var charge_per_hit: float = 0.2  # 키 한 번당 차지량
@export var charge_decay_rate: float = 0.3  # 초당 차지 감소율
@export var charge_decay_delay: float = 1.0  # 차지 감소 시작 대기 시간
var charge_decay_timer: float = 0.0  # 차지 감소 타이머
var last_charge_time: float = 0.0  # 마지막 차징 시간

# 차징 게이지 UI
var charge_bar: ProgressBar = null
var charge_bar_background: Panel = null

# 차징 중 곡괭이 자세
@export var charge_pickaxe_angle: float = -80.0  # 차징 중 곡괭이 각도 (위로 들어올림)
@export var charge_pickaxe_position: Vector2 = Vector2(8, -15)  # 차징 중 곡괭이 위치

# 돌 근처 감지
var current_nearby_rock: Node2D = null  # 현재 근처에 있는 돌
var is_near_mineable_tile: bool = false  # 채굴 가능한 타일 근처에 있는지

# 스태미나 시스템
var max_stamina: float = 100.0
var current_stamina: float = 100.0
var stamina_regen_rate: float = 10.0  # 초당 회복량
var is_tired: bool = false

# 부채꼴 빛 (손전등 효과)
var flashlight: PointLight2D = null
@export var flashlight_enabled: bool = true
@export var flashlight_color: Color = Color(1.0, 0.95, 0.8, 0.6)  # 따뜻한 노란빛
@export var flashlight_energy: float = 0.8
@export var flashlight_scale: float = 1.5

func _ready():
	# player 그룹에 추가 (rock.gd에서 찾을 수 있도록)
	add_to_group("player")
	
	# 초기 collision_mask 설정
	collision_mask = ALL_COLLISION_LAYERS
	# Globals에 캐릭터 참조 저장 (다른 스크립트에서 접근 가능)
	Globals.player = self
	
	# 곡괭이 초기 위치 설정
	if pickaxe:
		update_pickaxe_position()
	
	# 차징 게이지 생성
	create_charge_bar()
	
	# 부채꼴 빛 생성

	
	# 기본 대기 애니메이션 재생
	play_animation("idle")


func _process(delta):
	# 부채꼴 빛 방향 업데이트
	# 카메라가 돌에 고정되어 있으면 계속 돌 쪽을 바라봄
	update_facing_direction_to_rock()
	
	# 곡괭이 애니메이션 업데이트
	update_pickaxe_animation(delta)
	
	# 차징 시스템 업데이트
	update_charging_system(delta)
	
	# 차징 게이지 업데이트
	update_charge_bar()

func _physics_process(delta):
	# 돌 근처 확인
	check_nearby_rocks()
	
	# 타일 근처 확인
	check_nearby_tiles()
	
	# 이전 프레임에서 바닥에 있었는지 기록
	var was_on_floor = is_on_floor()
	
	# 채굴 키 입력 처리 (돌이나 타일 근처에 있을 때, 설치 모드가 아닐 때)
	# 설치 모드(플랫폼/횃불)일 때는 채굴 비활성화
	var is_any_build_mode = Globals.is_build_mode or Globals.is_torch_mode
	
	if (current_nearby_rock or is_near_mineable_tile) and not is_any_build_mode:
		# 현재 사용 가능한 키 개수만큼 순회
		for i in range(Globals.mining_key_count):
			var key = Globals.all_mining_keys[i]
			var is_key_pressed = Input.is_key_pressed(key)
			
			# 키를 방금 눌렀는지 확인
			var key_just_pressed = is_key_pressed and not was_mining_keys_pressed[i]
			
			# 이전 프레임 상태 업데이트
			was_mining_keys_pressed[i] = is_key_pressed
			
			# 키를 처음 누르면 즉시 채굴 + 타이머 리셋
			if key_just_pressed:
				add_charge()
				auto_mining_timers[i] = 0.0
			
			# 키를 꾹 누르고 있으면 자동 채굴
			if is_key_pressed:
				auto_mining_timers[i] += delta
				if auto_mining_timers[i] >= Globals.auto_mining_interval:
					auto_mining_timers[i] = 0.0
					add_charge()
			else:
				auto_mining_timers[i] = 0.0
	else:
		# 돌이나 타일 근처가 아니거나 설치 모드면 키 상태 및 타이머 초기화
		for i in range(6):
			was_mining_keys_pressed[i] = false
			auto_mining_timers[i] = 0.0
	
	# S 키 입력 확인
	var is_s_key_pressed = Input.is_key_pressed(KEY_S)
	var is_s_key_just_pressed = is_s_key_pressed and not was_s_key_pressed
	
	# S 키를 처음 눌렀을 때 y를 1 증가 (one-way collision이 자동으로 통과 처리)
	if (Input.is_action_just_pressed("ui_down") or is_s_key_just_pressed) and is_on_floor():
		global_position.y += 1
	
	# 이전 프레임의 S 키 상태 저장
	was_s_key_pressed = is_s_key_pressed
	
	# 중력 적용 - 바닥에 있지 않으면 계속 떨어짐
	if not is_on_floor():
		velocity += get_gravity() * delta
	
	# Space 키로 점프 - 바닥에 있을 때만 가능
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		is_jumping = true
		velocity.y = JUMP_VELOCITY  # 최대 점프 속도로 시작
	
	# Space 키를 떼면 상승 중일 때 속도 감소 (마리오 스타일)
	if is_jumping and Input.is_action_just_released("ui_accept"):
		# 위로 올라가는 중이면 속도를 최소 점프 속도로 제한
		if velocity.y < MIN_JUMP_VELOCITY:
			velocity.y = MIN_JUMP_VELOCITY
		is_jumping = false

	# A/D 키로 좌우 이동
	var direction = 0
	if Input.is_key_pressed(KEY_D):
		direction = 1  # 오른쪽
	elif Input.is_key_pressed(KEY_A):
		direction = -1  # 왼쪽
	
	# 바닥에 있을 때와 공중에 있을 때 다르게 처리
	if is_on_floor():
		# 바닥에 있을 때: 정상적인 가속/감속 처리
		var is_running = Input.is_key_pressed(KEY_SHIFT)
		var target_speed = RUN_SPEED if is_running else SPEED
		
		if direction != 0:
			# 목표 속도로 가속
			var target_velocity = direction * target_speed
			velocity.x = move_toward(velocity.x, target_velocity, acceleration * delta)
			
			# 스프라이트 방향 전환
			if sprite:
				sprite.flip_h = (direction < 0)
			
			# facing_direction이 변경되면 곡괭이 위치도 업데이트
			if facing_direction != direction:
				facing_direction = direction
				if pickaxe and not is_pickaxe_animating:
					update_pickaxe_position()
		else:
			# 키를 누르지 않으면 마찰력으로 감속
			velocity.x = move_toward(velocity.x, 0, friction * delta)
		
		# 현재 속도를 공중 속도로 저장 (점프 전 속도)
		air_speed = abs(velocity.x)
	else:
		# 공중에 있을 때: 점프 전 속도를 목표로 공중 가속도 적용
		if direction != 0:
			# 목표 속도 (점프 전 속도)
			var target_velocity = direction * air_speed
			# 공중 가속도를 적용하여 부드럽게 목표 속도로 이동
			velocity.x = move_toward(velocity.x, target_velocity, air_acceleration * delta)
			
			# 스프라이트 방향 전환
			if sprite:
				sprite.flip_h = (direction < 0)
			
			# facing_direction이 변경되면 곡괭이 위치도 업데이트
			if facing_direction != direction:
				facing_direction = direction
				if pickaxe and not is_pickaxe_animating:
					update_pickaxe_position()
		# 공중에서는 키를 떼도 속도 유지 (감속 없음)

	move_and_slide()
	
	# 애니메이션 및 상태 갱신
	update_state_and_animation(was_on_floor)
	
	# 착지 감지 (이전 프레임에 공중이었고 현재 바닥에 있으면)
	if (not was_on_floor) and is_on_floor():
		spawn_landing_particles()

# 착지 파티클 생성
func spawn_landing_particles():
	var particles = CPUParticles2D.new()
	particles.emitting = false
	particles.one_shot = true
	particles.amount = 6
	particles.lifetime = 0.4
	particles.explosiveness = 0.9
	particles.direction = Vector2(0, -1)
	particles.spread = 60
	particles.initial_velocity_min = 30
	particles.initial_velocity_max = 60
	particles.gravity = Vector2(0, 150)
	particles.scale_amount_min = 2
	particles.scale_amount_max = 3
	particles.color = Color(0.7, 0.7, 0.7, 0.8)  # 회색 먼지
	particles.position = Vector2(0, 10)  # 발 위치
	add_child(particles)
	particles.emitting = true
	
	# 파티클이 끝나면 자동 삭제
	await get_tree().create_timer(particles.lifetime).timeout
	particles.queue_free()

# === 애니메이션 상태 관리 ===

# 애니메이션을 중복 재생 없이 실행합니다.
func play_animation(anim_name: String):
	if not animation_player:
		return
	if current_animation == anim_name:
		return
	current_animation = anim_name
	animation_player.play(anim_name)

# 상태를 변경하고 대응하는 애니메이션을 재생합니다.
func set_state(new_state: State):
	if current_state == new_state:
		return
	current_state = new_state
	match new_state:
		State.IDLE:
			play_animation("idle")
		State.WALKING:
			play_animation("walk")
		State.JUMPING, State.FALLING:
			play_animation("jump")
		State.MINING:
			play_animation("idle")

# 이동/점프 상황에 따라 애니메이션을 갱신합니다.
func update_state_and_animation(was_on_floor_before: bool):
	var on_floor_now = is_on_floor()
	
	# 점프 착지 애니메이션이 재생 중이면 완료까지 유지
	if animation_player and animation_player.current_animation == "jump_end" and animation_player.is_playing() and on_floor_now:
		return
	
	# 막 착지했을 때는 landing 전용 애니메이션 우선
	if (not was_on_floor_before) and on_floor_now:
		current_state = State.IDLE
		play_animation("jump_end")
		return
	
	var is_moving = abs(velocity.x) > 5.0
	if on_floor_now:
		if is_moving:
			set_state(State.WALKING)
		else:
			set_state(State.IDLE)
	else:
		if velocity.y < 0:
			set_state(State.JUMPING)
		else:
			set_state(State.FALLING)

# === 곡괭이 애니메이션 함수들 ===

# 곡괭이 채굴 애니메이션을 시작합니다.
# 돌을 캘 때마다 호출되며, 애니메이션 중간에 다시 호출되면 자연스럽게 재시작됩니다.
func start_pickaxe_animation():
	if not pickaxe:
		return
	
	# 애니메이션 시작/재시작
	pickaxe_animation_time = 0.0
	is_pickaxe_animating = true

# 곡괭이 애니메이션을 업데이트합니다.
# _process에서 매 프레임 호출되어 원호를 따라 위치를 부드럽게 변경합니다.
# @param delta: 프레임 간 경과 시간
func update_pickaxe_animation(delta: float):
	if not pickaxe:
		return
	
	# 차징 중에는 차징 자세 유지
	if is_charging and not is_pickaxe_animating:
		update_charge_pickaxe_pose()
		return
	
	# 애니메이션 중이 아니면 리턴
	if not is_pickaxe_animating:
		return
	
	# 애니메이션 시간 증가
	pickaxe_animation_time += delta
	
	# 애니메이션 완료 체크
	if pickaxe_animation_time >= pickaxe_animation_duration:
		is_pickaxe_animating = false
		pickaxe_animation_time = pickaxe_animation_duration
	
	# 진행도 계산 (0.0 ~ 1.0)
	var progress = pickaxe_animation_time / pickaxe_animation_duration
	
	# 시작 → 끝 → 시작 (삼각파 형태)
	var lerp_value = 0.0
	if progress < 0.5:
		# 전반부: 0 → 1 (시작 각도에서 끝 각도로)
		lerp_value = progress * 2.0
	else:
		# 후반부: 1 → 0 (끝 각도에서 시작 각도로)
		lerp_value = (1.0 - progress) * 2.0
	
	# 현재 각도 계산 (lerp로 부드럽게 보간)
	var current_angle_deg = lerp(pickaxe_start_angle, pickaxe_end_angle, lerp_value)
	var current_angle_rad = deg_to_rad(current_angle_deg)
	
	# 원호 위의 위치 계산 (극좌표 → 직교좌표)
	# x = center_x + radius * cos(angle)
	# y = center_y + radius * sin(angle)
	var arc_position = Vector2(
		pickaxe_arc_center_offset.x + pickaxe_arc_radius * cos(current_angle_rad),
		pickaxe_arc_center_offset.y + pickaxe_arc_radius * sin(current_angle_rad)
	)
	
	# 곡괭이 위치 및 회전 업데이트
	update_pickaxe_position(arc_position, current_angle_deg)

# facing_direction에 따라 곡괭이의 위치, 방향, 회전을 조정합니다.
# @param target_pos: 목표 위치 (기본값: 원호 시작 위치)
# @param angle_deg: 현재 원호 각도 (기본값: 시작 각도)
func update_pickaxe_position(target_pos: Vector2 = Vector2(-9999, -9999), angle_deg: float = -9999.0):
	if not pickaxe:
		return
	
	# target_pos가 지정되지 않으면 원호 시작 위치 계산
	var final_pos = target_pos
	var final_angle = angle_deg
	if target_pos.x == -9999:
		var start_angle_rad = deg_to_rad(pickaxe_start_angle)
		final_pos = Vector2(
			pickaxe_arc_center_offset.x + pickaxe_arc_radius * cos(start_angle_rad),
			pickaxe_arc_center_offset.y + pickaxe_arc_radius * sin(start_angle_rad)
		)
		final_angle = pickaxe_start_angle
	
	# facing_direction에 따라 위치, flip, 회전 설정
	if facing_direction == 1:
		# 오른쪽을 바라볼 때
		pickaxe.position = final_pos
		pickaxe.flip_h = false
		# 곡괭이 회전 (원호 각도 + 오프셋)
		pickaxe.rotation_degrees = final_angle + pickaxe_rotation_offset
	else:
		# 왼쪽을 바라볼 때 (x 좌표 반전)
		pickaxe.position = Vector2(-final_pos.x, final_pos.y)
		pickaxe.flip_h = true
		# 왼쪽을 볼 때는 각도를 좌우 대칭으로 반전
		# flip_h가 이미 스프라이트를 뒤집으므로, 각도는 음수로만 변경
		pickaxe.rotation_degrees = -(final_angle + pickaxe_rotation_offset)

# === 차징 시스템 함수들 ===

# 플레이어 위에 차징 게이지를 생성합니다.
func create_charge_bar():
	# 배경 패널 생성
	charge_bar_background = Panel.new()
	charge_bar_background.custom_minimum_size = Vector2(54, 12)
	charge_bar_background.modulate = Color(0, 0, 0, 0.7)
	charge_bar_background.z_index = 100
	add_child(charge_bar_background)
	
	# 프로그레스바 생성
	charge_bar = ProgressBar.new()
	charge_bar.custom_minimum_size = Vector2(50, 8)
	charge_bar.max_value = 1.0
	charge_bar.value = 0.0
	charge_bar.show_percentage = false
	charge_bar.z_index = 101
	charge_bar_background.add_child(charge_bar)
	charge_bar.position = Vector2(2, 2)
	
	# 초기에는 숨김
	charge_bar_background.visible = false

# 차징 게이지 위치 및 값을 업데이트합니다.
func update_charge_bar():
	if not charge_bar or not charge_bar_background:
		return
	
	# 차징 중이거나 차지량이 있을 때만 표시
	if charge_amount > 0.0:
		charge_bar_background.visible = true
		charge_bar_background.position = Vector2(-27, -35)
		charge_bar.value = charge_amount
		
		# 차지량에 따라 색상 변경 (빨강 → 노랑 → 초록)
		if charge_amount < 0.5:
			# 0.0 ~ 0.5: 빨강 → 노랑
			var t = charge_amount * 2.0
			charge_bar.modulate = Color(1.0, t, 0.0)
		else:
			# 0.5 ~ 1.0: 노랑 → 초록
			var t = (charge_amount - 0.5) * 2.0
			charge_bar.modulate = Color(1.0 - t, 1.0, 0.0)
	else:
		charge_bar_background.visible = false

# 차징 시스템을 업데이트합니다 (감소 처리).
func update_charging_system(delta: float):
	if charge_amount <= 0.0:
		is_charging = false
		return
	
	# 마지막 차징 후 경과 시간 계산
	var current_time = Time.get_ticks_msec() / 1000.0
	var time_since_last_charge = current_time - last_charge_time
	
	# 대기 시간이 지나면 차지 감소 시작
	if time_since_last_charge >= charge_decay_delay:
		charge_amount -= charge_decay_rate * delta
		if charge_amount < 0.0:
			charge_amount = 0.0
			is_charging = false

# 키 입력 시 차지량을 증가시킵니다.
func add_charge():
	# 첫 번째 클릭 시 카메라 고정 (차징 시작)
	if current_nearby_rock and charge_amount == 0.0:
		if current_nearby_rock.has_method("lock_camera_on_first_hit"):
			current_nearby_rock.lock_camera_on_first_hit()
	
	# 필요 클릭 수에 따라 차지량 계산 (1/필요클릭수)
	# 테스트용으로 1회로 설정
	var dynamic_charge_per_hit = 1.0  # 원래: 1.0 / float(Globals.mining_clicks_required)
	charge_amount += dynamic_charge_per_hit
	last_charge_time = Time.get_ticks_msec() / 1000.0
	
	if charge_amount >= 1.0:
		charge_amount = 1.0
		release_charge()
	else:
		is_charging = true
		# 차징 중 곡괭이 자세로 변경
		update_charge_pickaxe_pose()

# 차지가 가득 차면 실행됩니다 (곡괭이 스윙 + 돌 채굴).
func release_charge():
	# 곡괭이 스윙 애니메이션 시작
	start_pickaxe_animation()
	
	# 근처 돌에 채굴 신호 전송
	if current_nearby_rock and current_nearby_rock.has_method("mine_from_player"):
		current_nearby_rock.mine_from_player()
	
	# 차지 초기화
	charge_amount = 0.0
	is_charging = false

# 차징 중 곡괭이 자세를 업데이트합니다.
func update_charge_pickaxe_pose():
	if not pickaxe or is_pickaxe_animating:
		return
	
	# 차징 중에는 곡괭이를 위로 들어올림
	if facing_direction == 1:
		pickaxe.position = charge_pickaxe_position
		pickaxe.rotation_degrees = charge_pickaxe_angle
		pickaxe.flip_h = false
	else:
		pickaxe.position = Vector2(-charge_pickaxe_position.x, charge_pickaxe_position.y)
		# flip_h가 스프라이트를 뒤집으므로, 각도는 음수로만 변경
		pickaxe.rotation_degrees = -charge_pickaxe_angle
		pickaxe.flip_h = true

# 돌 근처에 있는지 확인합니다.
func check_nearby_rocks():
	var rocks = get_tree().get_nodes_in_group("rocks")
	current_nearby_rock = null
	
	for rock in rocks:
		if rock and global_position.distance_to(rock.global_position) < 50:
			current_nearby_rock = rock
			return true
	
	return false

# 카메라가 돌에 고정되어 있으면 계속 돌 쪽을 바라봅니다.
func update_facing_direction_to_rock():
	if not current_nearby_rock:
		return
	
	# 돌의 카메라 고정 상태 확인
	var is_camera_locked_to_rock = false
	if current_nearby_rock.has_method("is_camera_locked_to_this"):
		is_camera_locked_to_rock = current_nearby_rock.is_camera_locked_to_this()
	elif "is_camera_locked" in current_nearby_rock:
		is_camera_locked_to_rock = current_nearby_rock.is_camera_locked
	
	# 카메라가 고정되어 있으면 돌 쪽을 바라봄
	if is_camera_locked_to_rock:
		var direction_to_rock = sign(current_nearby_rock.global_position.x - global_position.x)
		if direction_to_rock != 0:
			var new_facing_direction = int(direction_to_rock)
			
			# 방향이 변경되었을 때만 업데이트
			if facing_direction != new_facing_direction:
				facing_direction = new_facing_direction
				
				# 스프라이트 방향 전환
				if sprite:
					sprite.flip_h = (facing_direction < 0)
				
				# 차징 중이면 곡괭이 자세도 업데이트
				if is_charging and not is_pickaxe_animating:
					update_charge_pickaxe_pose()

# === 부채꼴 빛 (손전등) 함수들 ===

# 부채꼴 모양의 빛 텍스처를 코드로 생성합니다 (부드러운 경계).
func create_cone_texture(size: int, angle_degrees: float) -> ImageTexture:
	var image = Image.create(size, size, false, Image.FORMAT_RGBA8)
	var center = Vector2(size / 2.0, size / 2.0)
	var half_angle = deg_to_rad(angle_degrees / 2.0)
	# 경계 부드럽게 하기 위한 페더링 범위 (라디안)
	var feather_angle = deg_to_rad(15.0)
	
	for x in range(size):
		for y in range(size):
			var pos = Vector2(x, y)
			var dir = pos - center
			var distance = dir.length()
			var max_distance = size / 2.0
			
			# 거리에 따른 감쇠 (부드러운 페이드아웃)
			var distance_factor = 1.0 - pow(distance / max_distance, 1.5)
			if distance_factor < 0:
				distance_factor = 0
			
			# 각도 계산 (오른쪽 방향이 0도)
			var angle = atan2(dir.y, dir.x)
			var abs_angle = abs(angle)
			
			# 각도에 따른 감쇠 (부드러운 경계)
			var angle_factor = 1.0
			if abs_angle > half_angle:
				# 경계 바깥 - 페더링 적용
				var over_angle = abs_angle - half_angle
				if over_angle < feather_angle:
					angle_factor = 1.0 - (over_angle / feather_angle)
				else:
					angle_factor = 0.0
			else:
				# 경계 안쪽 - 가장자리로 갈수록 약간 어두워짐
				angle_factor = 1.0 - (abs_angle / half_angle) * 0.3
			
			var alpha = distance_factor * angle_factor
			image.set_pixel(x, y, Color(1, 1, 1, alpha))
	
	return ImageTexture.create_from_image(image)

# 빛 각도 애니메이션용 변수
var flashlight_angle_offset: float = 0.0
var flashlight_angle_time: float = 0.0


## 채굴 가능한 타일이 Area2D 안에 있는지 확인합니다.
func check_nearby_tiles():
	# breakable_tile 노드들 찾기
	var tilemaps = get_tree().get_nodes_in_group("breakable_tilemaps")
	
	# 그룹이 비어있으면 수동으로 찾기
	if tilemaps.is_empty():
		var tile_map_node = get_tree().root.get_node_or_null("main/TileMap")
		if tile_map_node:
			var breakable1 = tile_map_node.get_node_or_null("map_1/breakable_tile")
			var breakable2 = tile_map_node.get_node_or_null("map_2/breakable_tile")
			if breakable1:
				tilemaps.append(breakable1)
			if breakable2:
				tilemaps.append(breakable2)
	
	var was_near = is_near_mineable_tile
	is_near_mineable_tile = false
	
	# Area2D 반지름 가져오기
	var area = get_node_or_null("Area2D")
	var mining_radius = 50.0  # 기본값
	if area:
		var collision_shape = area.get_node_or_null("CollisionShape2D")
		if collision_shape and collision_shape.shape is CircleShape2D:
			mining_radius = collision_shape.shape.radius
	
	# 각 타일맵에서 채굴 가능한 타일이 Area2D 안에 있는지 확인
	for tilemap in tilemaps:
		if not tilemap or not tilemap is TileMap:
			continue
		
		# 캐릭터 주변의 타일들 확인
		var char_local_pos = tilemap.to_local(global_position)
		var char_tile_pos = tilemap.local_to_map(char_local_pos)
		
		# Area2D 반지름 기준으로 검색 범위 계산 (타일 단위)
		var search_range = int(mining_radius / 16) + 1  # 타일 크기 16 기준
		
		for x_offset in range(-search_range, search_range + 1):
			for y_offset in range(-search_range, search_range + 1):
				var check_tile_pos = char_tile_pos + Vector2i(x_offset, y_offset)
				var tile_exists = tilemap.get_cell_source_id(0, check_tile_pos) != -1
				
				if tile_exists:
					# 타일의 월드 위치 계산
					var tile_world_pos = tilemap.to_global(tilemap.map_to_local(check_tile_pos))
					var distance = global_position.distance_to(tile_world_pos)
					
					# Area2D 안에 있으면
					if distance <= mining_radius:
						is_near_mineable_tile = true
						return
	
	return

## 캐릭터 발이 플랫폼 타일 안에 있는지 확인합니다.
## 발이 플랫폼 상단보다 아래에 있으면 true (플랫폼 무시해야 함)
func is_inside_any_platform() -> bool:
	# platform 타일맵 찾기
	var tile_map_node = get_tree().root.get_node_or_null("main/TileMap")
	if not tile_map_node:
		return false
	
	var platform_tilemaps: Array[TileMap] = []
	var platform1 = tile_map_node.get_node_or_null("map_1/platform")
	var platform2 = tile_map_node.get_node_or_null("map_2/platform")
	
	if platform1 and platform1 is TileMap:
		platform_tilemaps.append(platform1)
	if platform2 and platform2 is TileMap:
		platform_tilemaps.append(platform2)
	
	if platform_tilemaps.is_empty():
		return false
	
	# 캐릭터 발 위치
	var feet_y = global_position.y
	
	for platform_tilemap in platform_tilemaps:
		if not platform_tilemap.visible:
			continue
		
		# 캐릭터 위치의 타일 확인
		var local_pos = platform_tilemap.to_local(global_position)
		var tile_pos = platform_tilemap.local_to_map(local_pos)
		
		# 현재 위치와 바로 위 타일 확인
		for y_offset in range(-1, 1):
			var check_tile_pos = tile_pos + Vector2i(0, y_offset)
			var source_id = platform_tilemap.get_cell_source_id(0, check_tile_pos)
			
			if source_id != -1:
				# 플랫폼 타일의 상단 y 좌표
				var tile_center = platform_tilemap.to_global(platform_tilemap.map_to_local(check_tile_pos))
				var tile_top_y = tile_center.y - 8  # 타일 상단 (16픽셀 타일 기준)
				
				# 발이 플랫폼 상단보다 아래에 있으면 → 플랫폼 안에 있음
				if feet_y > tile_top_y + 2:  # 2픽셀 여유
					return true
	
	return false
