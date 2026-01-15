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
 
# S 키를 눌렀을 때 플랫폼 통과 상태 (0.2초 동안)
var platform_out: bool = false
var platform_out_timer: float = 0.0
const PLATFORM_OUT_DURATION: float = 0.2  # 0.2초

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

# 플랫폼 모드 enum
enum PlatformMode {
	NONE,      # 일반 모드
	PLACE,     # 플랫폼 설치 모드
	REMOVE     # 플랫폼 제거 모드
}

# 현재 상태
var current_state: State = State.IDLE
# 현재 플랫폼 모드
var platform_mode: PlatformMode = PlatformMode.NONE
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

# === 타일 파괴 시스템 ===
# breakable_tile TileMap 참조
var breakable_tilemap: TileMap = null
# 채굴 가능 상태인지 (캐릭터가 채굴 범위 내에 있음)
var can_mine_tile: bool = false
# 채굴 범위 (픽셀 단위) - Area2D의 CircleShape2D 반지름과 동일하게 설정
@export var mining_range: float = 51.0
# 연속 채굴 타이머
var _mining_timer: float = 0.0
# 채굴 간격 (초) - 꾹 누르고 있을 때 이 간격마다 채굴
@export var mining_interval: float = 0.15
# 현재 타겟 타일
var _current_target_tile: Variant = null  # {tile_pos, world_pos, distance} 또는 null
# 하이라이트 표시용 Sprite2D
var _tile_highlight: Sprite2D = null
# 하이라이트 색상 (반투명)
@export var highlight_color: Color = Color(1.0, 1.0, 0.3, 0.5)  # 노란색 반투명

# === 플랫폼 설치/제거 시스템 ===
# platform TileMap 참조
var platform_tilemap: TileMap = null
# maps TileMap 참조 (충돌 검사용)
var maps_tilemap: TileMap = null
# 플랫폼 타일 ID
# platform TileMap은 TileSet_platform을 사용
# TileSet_platform의 sources/0 = TileSetAtlasSource_35kre (KakaoTalk_20521.png)
# Atlas Coords: x=6, y=0 (사용자가 지정한 위치)
const PLATFORM_TILE_SOURCE_ID = 0
const PLATFORM_TILE_COORDS = Vector2i(6, 0)
# 모드별 하이라이트 색상
var platform_place_color: Color = Color(0.3, 1.0, 0.3, 0.5)  # 초록색
var platform_remove_color: Color = Color(1.0, 0.3, 0.3, 0.5)  # 빨간색
var mining_highlight_color: Color = Color(1.0, 1.0, 0.3, 0.5)  # 노란색

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
	if flashlight_enabled:
		create_flashlight()
	
	# breakable_tile TileMap 찾기 (타일 파괴 시스템)
	find_breakable_tilemap()
	
	# platform과 maps TileMap 찾기 (플랫폼 설치/제거 시스템)
	find_platform_tilemaps()
	
	# 기본 대기 애니메이션 재생
	play_animation("idle")

func _input(event: InputEvent):
	# 아무 키나 누르면 돈 1씩 증가
	if event is InputEventKey and event.pressed and not event.echo:
		Globals.money += 1
		print("키 입력! 돈 +1 (현재: 💎", Globals.money, ")")
	
	# 플랫폼 모드 전환 (2번 키: 설치 모드, 3번 키: 제거 모드)
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_2:
			# 설치 모드 토글
			if platform_mode == PlatformMode.PLACE:
				platform_mode = PlatformMode.NONE
				print("🔧 플랫폼 설치 모드 해제")
			else:
				platform_mode = PlatformMode.PLACE
				print("🔧 플랫폼 설치 모드 활성화")
		
		elif event.keycode == KEY_3:
			# 제거 모드 토글
			if platform_mode == PlatformMode.REMOVE:
				platform_mode = PlatformMode.NONE
				print("🔧 플랫폼 제거 모드 해제")
			else:
				platform_mode = PlatformMode.REMOVE
				print("🔧 플랫폼 제거 모드 활성화")
		
		# B키로 플랫폼 설치/제거
		elif event.keycode == KEY_B:
			handle_platform_action()
	

func _process(delta):
	# 부채꼴 빛 방향 업데이트
	update_flashlight_direction()
	# 카메라가 돌에 고정되어 있으면 계속 돌 쪽을 바라봄
	update_facing_direction_to_rock()
	
	# 곡괭이 애니메이션 업데이트
	update_pickaxe_animation(delta)
	
	# 차징 시스템 업데이트
	update_charging_system(delta)
	
	# 차징 게이지 업데이트
	update_charge_bar()
	
	# 타일 타겟팅 업데이트 (마우스 방향 기준)
	update_tile_targeting()
	
	# 좌클릭으로 타일 파괴 (꾹 누르면 연속 채굴)
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		# 타이머 감소
		_mining_timer -= delta
		
		# 타겟 타일이 있고, 타이머가 0 이하일 때 채굴
		if _current_target_tile != null and _mining_timer <= 0:
			mine_targeted_tile()
			_mining_timer = mining_interval  # 타이머 리셋
	else:
		# 마우스 떼면 타이머 리셋 (다음 클릭 시 즉시 채굴)
		_mining_timer = 0.0

func _physics_process(delta):
	# 돌 근처 확인
	check_nearby_rocks()
	
	# 이전 프레임에서 바닥에 있었는지 기록
	var was_on_floor = is_on_floor()
	
	# 채굴 키 입력 처리 (돌 근처에 있을 때만)
	if current_nearby_rock:
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
		# 돌 근처가 아니면 키 상태 및 타이머 초기화
		for i in range(6):
			was_mining_keys_pressed[i] = false
			auto_mining_timers[i] = 0.0
	
	# S 키 입력 확인
	var is_s_key_pressed = Input.is_key_pressed(KEY_S)
	var is_s_key_just_pressed = is_s_key_pressed and not was_s_key_pressed
	
	# S 키를 처음 눌렀을 때 platform_out 활성화
	if Input.is_action_just_pressed("ui_down") or is_s_key_just_pressed:
		platform_out = true
		platform_out_timer = PLATFORM_OUT_DURATION
	
	# 이전 프레임의 S 키 상태 저장
	was_s_key_pressed = is_s_key_pressed
	
	# platform_out 타이머 감소
	if platform_out:
		platform_out_timer -= delta
		if platform_out_timer <= 0.0:
			platform_out = false
	
	# collision_mask 설정
	# 1. velocity.y < 0 (위로 올라갈 때) 플랫폼 통과
	# 2. platform_out == true (S 키로 1초간) 플랫폼 통과
	if velocity.y < 0 or platform_out:
		collision_mask = NORMAL_COLLISION_LAYER  # 플랫폼 레이어 무시
	else:
		collision_mask = ALL_COLLISION_LAYERS  # 모든 레이어 충돌
	
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
	var dynamic_charge_per_hit = 1.0 / float(Globals.mining_clicks_required)
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

# 부채꼴 빛을 생성합니다.
func create_flashlight():
	flashlight = PointLight2D.new()
	flashlight.color = flashlight_color
	flashlight.energy = flashlight_energy
	flashlight.texture_scale = flashlight_scale
	flashlight.blend_mode = Light2D.BLEND_MODE_ADD
	
	# 부채꼴 텍스처 생성 (크기 128, 각도 115도 - 중간값)
	flashlight.texture = create_cone_texture(128, 115)
	
	# 플레이어 위치에서 시작
	flashlight.position = Vector2.ZERO
	flashlight.z_index = -1
	
	add_child(flashlight)
	update_flashlight_direction()

# 부채꼴 빛의 방향을 캐릭터가 바라보는 방향으로 업데이트합니다.
func update_flashlight_direction():
	if not flashlight:
		return
	
	# 각도 부드럽게 흔들림 (110~120도 사이)
	flashlight_angle_time += get_process_delta_time() * 2.0
	flashlight_angle_offset = sin(flashlight_angle_time) * 0.03  # 스케일로 약간의 변화
	flashlight.texture_scale = flashlight_scale + flashlight_angle_offset
	
	if facing_direction == 1:
		# 오른쪽을 바라볼 때
		flashlight.rotation_degrees = 0
	else:
		# 왼쪽을 바라볼 때
		flashlight.rotation_degrees = 180

# === 타일 파괴 시스템 함수들 ===

## breakable_tile TileMap을 씬에서 찾습니다.
## 실제로 타일이 있는 TileMap을 찾습니다.
func find_breakable_tilemap():
	print("🔍 breakable_tile 검색 시작...")
	
	# TileMap 노드 찾기 (tilemaps 또는 TileMap 이름)
	var tilemaps_node = get_tree().current_scene.get_node_or_null("tilemaps")
	if not tilemaps_node:
		tilemaps_node = get_tree().current_scene.get_node_or_null("TileMap")
	print("  - tilemaps 노드: ", tilemaps_node)
	
	var candidates: Array[TileMap] = []
	
	if tilemaps_node:
		# map_1과 map_2 둘 다 확인
		for map_name in ["map_1", "map_2"]:
			var map_node = tilemaps_node.get_node_or_null(map_name)
			if map_node:
				var bt = map_node.get_node_or_null("breakable_tile")
				if bt and bt is TileMap:
					var cell_count = bt.get_used_cells(0).size()
					print("  - ", map_name, "/breakable_tile: 타일 ", cell_count, "개")
					if cell_count > 0:
						candidates.append(bt)
	
	# 타일이 있는 것 중에서 선택 (가장 타일이 많은 것)
	if candidates.size() > 0:
		breakable_tilemap = candidates[0]
		for candidate in candidates:
			if candidate.get_used_cells(0).size() > breakable_tilemap.get_used_cells(0).size():
				breakable_tilemap = candidate
	
	# 그래도 못 찾았으면 전체 씬에서 검색
	if not breakable_tilemap:
		print("  - find_child로 전체 검색 중...")
		var all_breakables = []
		_find_all_breakable_tiles(get_tree().current_scene, all_breakables)
		for bt in all_breakables:
			if bt.get_used_cells(0).size() > 0:
				breakable_tilemap = bt
				break
	
	if breakable_tilemap:
		print("✅ breakable_tile TileMap 발견! 경로: ", breakable_tilemap.get_path())
		print("   타일 개수: ", breakable_tilemap.get_used_cells(0).size())
		# 하이라이트 노드 생성
		create_tile_highlight()
	else:
		print("⚠️ breakable_tile TileMap을 찾을 수 없습니다.")

## 재귀적으로 breakable_tile 노드들을 찾습니다.
func _find_all_breakable_tiles(node: Node, result: Array):
	if node.name == "breakable_tile" and node is TileMap:
		result.append(node)
	for child in node.get_children():
		_find_all_breakable_tiles(child, result)

## platform과 maps TileMap을 씬에서 찾습니다.
## breakable_tilemap과 같은 맵(map_1 또는 map_2)의 것을 찾습니다.
func find_platform_tilemaps():
	print("🔍 platform과 maps TileMap 검색 시작...")
	
	# breakable_tilemap이 없으면 찾을 수 없음
	if not breakable_tilemap or not is_instance_valid(breakable_tilemap):
		print("⚠️ breakable_tilemap이 없어서 platform을 찾을 수 없습니다.")
		return
	
	# breakable_tilemap의 부모가 어느 맵인지 확인 (map_1 또는 map_2)
	var current_map = breakable_tilemap.get_parent()
	if not current_map:
		print("⚠️ breakable_tilemap의 부모를 찾을 수 없습니다.")
		return
	
	print("  - 현재 사용 중인 맵: ", current_map.name)
	
	# 같은 맵에서 platform과 maps 찾기
	var pt = current_map.get_node_or_null("platform")
	if pt and pt is TileMap:
		platform_tilemap = pt
		print("  - ", current_map.name, "/platform 발견!")
	
	var mt = current_map.get_node_or_null("maps")
	if mt and mt is TileMap:
		maps_tilemap = mt
		print("  - ", current_map.name, "/maps 발견!")
	
	if platform_tilemap:
		print("✅ platform TileMap 발견! 경로: ", platform_tilemap.get_path())
		# 플랫폼을 보이게 설정
		platform_tilemap.visible = true
		print("   플랫폼 표시 활성화!")
	else:
		print("⚠️ ", current_map.name, "에 platform TileMap이 없습니다.")
	
	if maps_tilemap:
		print("✅ maps TileMap 발견! 경로: ", maps_tilemap.get_path())
	else:
		print("⚠️ ", current_map.name, "에 maps TileMap이 없습니다.")

## 타일 하이라이트 Sprite2D를 생성합니다.
func create_tile_highlight():
	# 타일 크기 가져오기 (TileSet에서)
	var tile_size := Vector2i(32, 32)  # 기본값
	if breakable_tilemap.tile_set:
		tile_size = breakable_tilemap.tile_set.tile_size
	
	print("📐 타일 크기: ", tile_size)
	
	# 흰색 사각형 텍스처 생성
	var image = Image.create(tile_size.x, tile_size.y, false, Image.FORMAT_RGBA8)
	image.fill(Color.WHITE)
	var texture = ImageTexture.create_from_image(image)
	
	# Sprite2D 생성
	_tile_highlight = Sprite2D.new()
	_tile_highlight.texture = texture
	_tile_highlight.modulate = highlight_color
	_tile_highlight.z_index = 100  # 타일보다 훨씬 위에 표시
	_tile_highlight.visible = false
	
	# breakable_tilemap과 같은 부모에 추가 (좌표계 일치)
	breakable_tilemap.get_parent().add_child(_tile_highlight)
	
	print("✅ 하이라이트 Sprite2D 생성 완료! 부모: ", _tile_highlight.get_parent().name)

## 타겟 타일을 업데이트합니다 (캐릭터→마우스 방향 raycast).
func update_tile_targeting():
	# 플랫폼 모드일 때는 다른 타겟팅 로직 사용
	if platform_mode != PlatformMode.NONE:
		update_platform_targeting()
		return
	
	# 일반 채굴 모드
	if not breakable_tilemap or not is_instance_valid(breakable_tilemap):
		_current_target_tile = null
		can_mine_tile = false
		update_highlight_visibility()
		return
	
	# 캐릭터에서 마우스 방향으로 raycast해서 타일 찾기
	var new_target = raycast_to_tile()
	
	# 타겟 업데이트
	if new_target == null:
		_current_target_tile = null
		can_mine_tile = false
	else:
		_current_target_tile = new_target
		can_mine_tile = true
	
	# 하이라이트 업데이트
	update_highlight_visibility()

## 캐릭터에서 마우스 방향으로 raycast해서 처음 닿는 타일을 찾습니다.
## @returns: {tile_pos: Vector2i, world_pos: Vector2, distance: float} 또는 null
var _debug_raycast_timer: float = 0.0  # 디버그 출력 간격 조절용
func raycast_to_tile():
	if not breakable_tilemap or not is_instance_valid(breakable_tilemap):
		return null
	
	# 마우스 월드 좌표
	var mouse_pos = get_global_mouse_position()
	# 캐릭터에서 마우스로 향하는 방향
	var direction = (mouse_pos - global_position).normalized()
	
	# 방향이 없으면 (마우스가 캐릭터 위치에 있으면) 리턴
	if direction.length() < 0.01:
		return null
	
	# 타일 크기
	var tile_size := Vector2(32, 32)
	if breakable_tilemap.tile_set:
		tile_size = Vector2(breakable_tilemap.tile_set.tile_size)
	
	# DDA 알고리즘으로 ray가 지나가는 타일들을 순서대로 검사
	var ray_start = global_position
	var step_size = tile_size.x / 4.0  # 작은 단위로 이동
	var max_steps = int(mining_range / step_size) + 1
	
	# 디버그: TileMap에 타일이 있는지 확인 (1초에 한 번만 출력)
	_debug_raycast_timer += get_process_delta_time()
	var should_debug = _debug_raycast_timer > 1.0
	if should_debug:
		_debug_raycast_timer = 0.0
		var used_cells = breakable_tilemap.get_used_cells(0)
		print("🔍 raycast 디버그 - 사용 타일 수: ", used_cells.size(), ", 캐릭터 위치: ", global_position, ", 마우스: ", mouse_pos)
		if used_cells.size() > 0:
			print("   처음 몇 개 타일 좌표: ", used_cells.slice(0, min(5, used_cells.size())))
	
	for i in range(max_steps):
		var check_pos = ray_start + direction * (step_size * i)
		var distance = global_position.distance_to(check_pos)
		
		# 채굴 범위 초과하면 중단
		if distance > mining_range:
			break
		
		# 이 위치의 타일 좌표 계산
		var local_pos = breakable_tilemap.to_local(check_pos)
		var tile_pos = breakable_tilemap.local_to_map(local_pos)
		
		# 이 타일이 존재하는지 확인
		var source_id = breakable_tilemap.get_cell_source_id(0, tile_pos)
		if source_id != -1:
			# 겉쪽 타일인지 확인 (상하좌우 중 하나라도 비어있어야 함)
			if is_surface_tile(tile_pos):
				# 타일 발견! 이게 첫 번째로 닿는 타일
				var tile_world_pos = breakable_tilemap.to_global(breakable_tilemap.map_to_local(tile_pos))
				if should_debug:
					print("   ✅ 타일 발견! tile_pos=", tile_pos, ", world_pos=", tile_world_pos)
				return {
					"tile_pos": tile_pos,
					"world_pos": tile_world_pos,
					"distance": global_position.distance_to(tile_world_pos)
				}
			# 겉쪽 타일이 아니면 계속 탐색 (통과)
	
	return null

## 타일이 겉쪽(표면) 타일인지 확인합니다.
## 상하좌우 4방향 중 하나라도 비어있으면 겉쪽 타일입니다.
## @param tile_pos: 확인할 타일의 맵 좌표
## @returns: 겉쪽 타일이면 true
func is_surface_tile(tile_pos: Vector2i) -> bool:
	if not breakable_tilemap:
		return false
	
	# 상하좌우 4방향 (대각선 제외)
	var directions = [
		Vector2i(0, -1),  # 위
		Vector2i(0, 1),   # 아래
		Vector2i(-1, 0),  # 왼쪽
		Vector2i(1, 0)    # 오른쪽
	]
	
	for dir in directions:
		var neighbor_pos = tile_pos + dir
		var neighbor_source = breakable_tilemap.get_cell_source_id(0, neighbor_pos)
		# 인접 타일이 비어있으면 (-1) 겉쪽 타일
		if neighbor_source == -1:
			return true
	
	# 4방향 모두 막혀있으면 내부 타일
	return false

## 하이라이트 표시를 업데이트합니다.
var _debug_highlight_timer: float = 0.0
func update_highlight_visibility():
	if not _tile_highlight:
		return
	
	# 플랫폼 모드일 때는 update_platform_targeting에서 처리
	if platform_mode != PlatformMode.NONE:
		return
	
	# 타겟 타일이 있고, 실제로 타일이 존재할 때만 하이라이트
	if _current_target_tile != null and breakable_tilemap:
		# 타일이 실제로 존재하는지 확인
		var source_id = breakable_tilemap.get_cell_source_id(0, _current_target_tile.tile_pos)
		if source_id != -1:
			# 타일의 정확한 월드 좌표 계산 (map_to_local은 타일 중심 반환)
			var tile_world_pos = breakable_tilemap.to_global(breakable_tilemap.map_to_local(_current_target_tile.tile_pos))
			
			# Sprite2D는 중심이 원점이므로 그대로 설정
			_tile_highlight.global_position = tile_world_pos
			_tile_highlight.modulate = mining_highlight_color  # 채굴 모드 색상
			_tile_highlight.visible = true
			
			# 디버그: 하이라이트 위치 출력 (1초에 한 번)
			_debug_highlight_timer += get_process_delta_time()
			if _debug_highlight_timer > 1.0:
				_debug_highlight_timer = 0.0
				print("🟡 하이라이트 위치: ", tile_world_pos, ", visible: ", _tile_highlight.visible, ", modulate: ", _tile_highlight.modulate)
			return
	
	# 타겟이 없거나 타일이 없으면 하이라이트 비활성화
	_tile_highlight.visible = false

## 플랫폼 모드에서 타겟 타일을 업데이트합니다.
func update_platform_targeting():
	if not _tile_highlight or not platform_tilemap or not is_instance_valid(platform_tilemap):
		_current_target_tile = null
		can_mine_tile = false
		if _tile_highlight:
			_tile_highlight.visible = false
		return
	
	# 마우스 위치를 월드 좌표로 변환
	var mouse_pos = get_global_mouse_position()
	
	# 캐릭터와 마우스 사이의 거리 확인 (Area2D 범위 내에 있어야 함)
	var distance = global_position.distance_to(mouse_pos)
	if distance > mining_range:
		_current_target_tile = null
		can_mine_tile = false
		_tile_highlight.visible = false
		return
	
	# 마우스 위치의 타일 좌표 계산
	var local_pos = platform_tilemap.to_local(mouse_pos)
	var tile_pos = platform_tilemap.local_to_map(local_pos)
	
	# 설치 모드: breakable_tile, maps, platform 모두 비어있어야 함
	if platform_mode == PlatformMode.PLACE:
		var is_empty = true
		
		# breakable_tile 체크
		if breakable_tilemap and is_instance_valid(breakable_tilemap):
			var breakable_id = breakable_tilemap.get_cell_source_id(0, tile_pos)
			if breakable_id != -1:
				is_empty = false
		
		# maps 체크
		if maps_tilemap and is_instance_valid(maps_tilemap):
			var maps_id = maps_tilemap.get_cell_source_id(0, tile_pos)
			if maps_id != -1:
				is_empty = false
		
		# platform 체크
		var platform_id = platform_tilemap.get_cell_source_id(0, tile_pos)
		if platform_id != -1:
			is_empty = false
		
		# 빈 타일이면 하이라이트 표시
		if is_empty:
			var tile_world_pos = platform_tilemap.to_global(platform_tilemap.map_to_local(tile_pos))
			_current_target_tile = {
				"tile_pos": tile_pos,
				"world_pos": tile_world_pos,
				"distance": distance
			}
			can_mine_tile = true
			_tile_highlight.global_position = tile_world_pos
			_tile_highlight.modulate = platform_place_color
			_tile_highlight.visible = true
		else:
			_current_target_tile = null
			can_mine_tile = false
			_tile_highlight.visible = false
	
	# 제거 모드: platform 타일이 있어야 함
	elif platform_mode == PlatformMode.REMOVE:
		var platform_id = platform_tilemap.get_cell_source_id(0, tile_pos)
		
		# 플랫폼이 있으면 하이라이트 표시
		if platform_id != -1:
			var tile_world_pos = platform_tilemap.to_global(platform_tilemap.map_to_local(tile_pos))
			_current_target_tile = {
				"tile_pos": tile_pos,
				"world_pos": tile_world_pos,
				"distance": distance
			}
			can_mine_tile = true
			_tile_highlight.global_position = tile_world_pos
			_tile_highlight.modulate = platform_remove_color
			_tile_highlight.visible = true
		else:
			_current_target_tile = null
			can_mine_tile = false
			_tile_highlight.visible = false

## 플랫폼 설치/제거를 처리합니다 (B키).
func handle_platform_action():
	if not platform_tilemap or not is_instance_valid(platform_tilemap):
		print("⚠️ platform TileMap이 없습니다.")
		return
	
	if _current_target_tile == null:
		print("⚠️ 타겟 타일이 없습니다.")
		return
	
	var tile_pos = _current_target_tile.tile_pos
	
	# 설치 모드
	if platform_mode == PlatformMode.PLACE:
		platform_tilemap.set_cell(0, tile_pos, PLATFORM_TILE_SOURCE_ID, PLATFORM_TILE_COORDS)
		print("✅ 플랫폼 설치: ", tile_pos)
	
	# 제거 모드
	elif platform_mode == PlatformMode.REMOVE:
		platform_tilemap.erase_cell(0, tile_pos)
		print("✅ 플랫폼 제거: ", tile_pos)
	
	# 타겟팅 즉시 업데이트 (설치/제거 후 상태 반영)
	update_platform_targeting()

## 현재 타겟 타일을 파괴합니다.
func mine_targeted_tile():
	print("⛏️ mine_targeted_tile() 호출됨")
	# 타겟 타일이 없으면 아무것도 안 함
	if _current_target_tile == null:
		print("   ❌ _current_target_tile이 null!")
		return
	
	# 타일이 실제로 존재하는지 한 번 더 확인
	var tile_pos = _current_target_tile.tile_pos
	var source_id = breakable_tilemap.get_cell_source_id(0, tile_pos)
	print("   타일 위치: ", tile_pos, ", source_id: ", source_id)
	if source_id == -1:
		# 타일이 이미 없음 - 타겟 초기화
		print("   ❌ 타일이 이미 없음!")
		_current_target_tile = null
		can_mine_tile = false
		update_highlight_visibility()
		return
	
	print("   ✅ 타일 파괴 시작!")
	# 타일 파괴
	break_tile(breakable_tilemap, tile_pos)
	
	# 파괴 후 즉시 타겟팅 업데이트 (다음 타일로 하이라이트 이동)
	_current_target_tile = raycast_to_tile()
	can_mine_tile = (_current_target_tile != null)
	update_highlight_visibility()

## 특정 TileMap의 타일을 파괴합니다.
## @param tilemap: 대상 TileMap
## @param tile_pos: 파괴할 타일의 맵 좌표
func break_tile(tilemap: TileMap, tile_pos: Vector2i):
	# 타일 정보 가져오기 (파티클 효과용)
	var source_id = tilemap.get_cell_source_id(0, tile_pos)
	if source_id == -1:
		return  # 이미 빈 타일
	
	# 타일 월드 좌표 (파티클 생성 위치)
	var tile_world_pos = tilemap.to_global(tilemap.map_to_local(tile_pos))
	
	# terrain = -1로 타일 제거 + 주변 자동 업데이트
	# terrain_set: 0, terrain: -1 (제거)
	var cells_to_remove: Array[Vector2i] = [tile_pos]
	tilemap.set_cells_terrain_connect(0, cells_to_remove, 0, -1)
	
	# 파괴 효과 생성
	spawn_tile_break_particles(tile_world_pos)
	
	# 곡괭이 스윙 애니메이션
	start_pickaxe_animation()
	
	print("💥 타일 파괴! 위치: ", tile_pos)

## 파괴된 타일 주변의 타일들을 terrain으로 업데이트합니다.
## @param tilemap: 대상 TileMap
## @param removed_pos: 제거된 타일의 위치
func update_surrounding_terrain(tilemap: TileMap, removed_pos: Vector2i):
	if not tilemap.tile_set:
		return
	
	# 더 넓은 범위로 업데이트 (3x3 + 추가 범위)
	var cells_to_update: Array[Vector2i] = []
	
	# -2 ~ +2 범위의 모든 타일 확인
	for x in range(-2, 3):
		for y in range(-2, 3):
			var check_pos = removed_pos + Vector2i(x, y)
			var source_id = tilemap.get_cell_source_id(0, check_pos)
			if source_id != -1:
				cells_to_update.append(check_pos)
	
	if cells_to_update.is_empty():
		return
	
	# grass_terrain은 terrain 1번
	# terrain_set 0, terrain 1 (grass_terrain) 사용
	tilemap.set_cells_terrain_connect(0, cells_to_update, 0, 1)

## 타일 파괴 시 파티클 효과를 생성합니다.
## @param pos: 파티클 생성 위치 (월드 좌표)
func spawn_tile_break_particles(pos: Vector2):
	var particles = CPUParticles2D.new()
	particles.emitting = false
	particles.one_shot = true
	particles.amount = 8
	particles.lifetime = 0.5
	particles.explosiveness = 0.95
	particles.direction = Vector2(0, -1)
	particles.spread = 90
	particles.initial_velocity_min = 40
	particles.initial_velocity_max = 80
	particles.gravity = Vector2(0, 200)
	particles.scale_amount_min = 2
	particles.scale_amount_max = 4
	particles.color = Color(0.6, 0.5, 0.4, 0.9)  # 흙/돌 색상
	particles.global_position = pos
	
	# 씬 루트에 추가 (캐릭터에 종속되지 않도록)
	get_tree().current_scene.add_child(particles)
	particles.emitting = true
	
	# 파티클 종료 후 자동 삭제
	await get_tree().create_timer(particles.lifetime + 0.1).timeout
	if is_instance_valid(particles):
		particles.queue_free()
