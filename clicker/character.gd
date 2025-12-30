extends CharacterBody2D

const SPEED = 100.0
const RUN_SPEED = 200.0  # 달리기 속도

const JUMP_VELOCITY = -400.0  # 최대 점프 높이
const MIN_JUMP_VELOCITY = -200.0  # 최소 점프 높이 (빠르게 뗄 때)

# 가속도 설정
@export var acceleration: float = 800.0  # 가속도 (픽셀/초²)
@export var friction: float = 600.0  # 마찰력/감속도 (픽셀/초²)
@export var air_acceleration: float = 400.0  # 공중 가속도 (픽셀/초²) - 낮을수록 미끄러짐

# 플랫폼 레이어 마스크
const PLATFORM_COLLISION_LAYER = 4  # 플랫폼 전용 collision layer
const NORMAL_COLLISION_LAYER = 1    # 일반 타일 collision layer
const ALL_COLLISION_LAYERS = 5      # 일반 타일 + 플랫폼

# S 키를 눌렀을 때 플랫폼 통과 상태 (0.4초 동안)
var platform_out: bool = false
var platform_out_timer: float = 0.0
const PLATFORM_OUT_DURATION: float = 0.4  # 0.4초

# 이전 프레임의 S 키 상태 추적
var was_s_key_pressed: bool = false

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
@onready var sprite: Sprite2D = $Sprite2D if has_node("Sprite2D") else null

# 스태미나 시스템
var max_stamina: float = 100.0
var current_stamina: float = 100.0
var stamina_regen_rate: float = 10.0  # 초당 회복량
var is_tired: bool = false

func _ready():
	# 초기 collision_mask 설정
	collision_mask = ALL_COLLISION_LAYERS
	# Globals에 캐릭터 참조 저장 (다른 스크립트에서 접근 가능)
	Globals.player = self

func _physics_process(delta):
	# S 키 입력 확인
	var is_s_key_pressed = Input.is_key_pressed(KEY_S)
	var is_s_key_just_pressed = is_s_key_pressed and not was_s_key_pressed
	
	# S 키를 처음 눌렀을 때 platform_out 활성화
	if Input.is_action_just_pressed("ui_down") or is_s_key_just_pressed:
		platform_out = true
		platform_out_timer = PLATFORM_OUT_DURATION
	
	# S 키를 계속 누르고 있으면 타이머 갱신
	if is_s_key_pressed and platform_out:
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
			facing_direction = direction
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
			facing_direction = direction
		# 공중에서는 키를 떼도 속도 유지 (감속 없음)

	# 착지 감지 (이전 프레임에 공중이었고 현재 바닥에 있으면)
	var was_in_air = velocity.y > 0
	move_and_slide()
	
	if was_in_air and is_on_floor():
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
