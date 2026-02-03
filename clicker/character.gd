extends CharacterBody2D

const SPEED = 70.0  # 걷기 속도 (100 → 70)
const RUN_SPEED = 110.0  # 달리기 속도 (150 → 110)

const JUMP_VELOCITY = -180.0  # 최대 점프 높이
const MIN_JUMP_VELOCITY = -120.0  # 최소 점프 높이 (빠르게 뗄 때)

# 중력 배율 (기본 중력에 곱해짐)
const GRAVITY_SCALE = 0.7  # 중력을 30% 낮춤

# 가속도 설정
@export var acceleration: float = 1000.0  # 가속도 (픽셀/초²) - 반응성 유지
@export var friction: float = 1500.0  # 마찰력/감속도 (픽셀/초²) - 미끄러짐 감소
@export var air_acceleration: float = 1500.0  # 공중 가속도 (픽셀/초²) - 빠른 공중 제어

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

# 이전 프레임의 Space 키 상태 추적
var was_space_key_pressed: bool = false

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
	RUNNING,   # 달리기
	JUMPING,   # 점프
	FALLING,   # 낙하
	MINING,    # 채굴 중
	SITTING    # 앉기
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
@export var pickaxe_swing_angle: float = 25.0  # 스윙 각도 범위 (도) - 앞쪽으로만 스윙
@export var pickaxe_animation_duration: float = 0.25  # 애니메이션 총 시간

var pickaxe_animation_time: float = 0.0  # 현재 애니메이션 진행 시간
var is_pickaxe_animating: bool = false  # 애니메이션 진행 중인지

# 에디터에서 설정한 곡괭이 초기 위치/회전 (기준점)
var pickaxe_initial_position: Vector2 = Vector2.ZERO
var pickaxe_initial_rotation: float = 0.0

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

# 차징 중 곡괭이 자세 (에디터 기본 위치 기준 오프셋)
@export var charge_angle_offset: float = -15.0  # 차징 시 추가 회전 각도 (살짝 위로)
@export var charge_position_offset: Vector2 = Vector2(0, -2)  # 차징 시 추가 위치 오프셋 (살짝 위로)

# 돌 근처 감지
var current_nearby_rock: Node2D = null  # 현재 근처에 있는 돌 (rock.gd)
var current_nearby_tilemap: TileMap = null  # 현재 근처에 있는 타일맵 (breakable_tile.gd)

# 스태미나 시스템
var max_stamina: float = 100.0
var current_stamina: float = 100.0
var stamina_regen_rate: float = 10.0  # 초당 회복량
var is_tired: bool = false

# 부채꼴 빛 (손전등 효과)
var flashlight: PointLight2D = null
@export var flashlight_enabled: bool = false  # 비활성화
@export var flashlight_color: Color = Color(1.0, 0.95, 0.8, 0.6)  # 따뜻한 노란빛
@export var flashlight_energy: float = 0.8
@export var flashlight_scale: float = 1.5

# 설치 모드용 프리뷰
var torch_scene: PackedScene = null
var platform_tile_source_id: int = -1  # 플랫폼 타일 소스 ID

# 설치 모드 하이라이트 (설치 가능: 초록, 불가능: 빨강)
var build_highlight_sprite: Sprite2D = null
var build_highlight_pulse_time: float = 0.0

func _ready():
	# player 그룹에 추가 (rock.gd에서 찾을 수 있도록)
	add_to_group("player")
	
	# 초기 collision_mask 설정
	collision_mask = ALL_COLLISION_LAYERS
	# Globals에 캐릭터 참조 저장 (다른 스크립트에서 접근 가능)
	Globals.player = self
	
	# FollowPoint 생성 (요정이 따라다닐 지점)
	if sprite and not sprite.has_node("FollowPoint"):
		var follow_point = Marker2D.new()
		follow_point.name = "FollowPoint"
		follow_point.position = Vector2(-30, 0)  # 플레이어 뒤쪽
		sprite.add_child(follow_point)
	
	# 에디터에서 설정한 곡괭이 초기 위치/회전 저장 (애니메이션 기준점)
	if pickaxe:
		pickaxe_initial_position = pickaxe.position
		pickaxe_initial_rotation = pickaxe.rotation_degrees
	
	# 차징 게이지 생성
	create_charge_bar()
	
	# 부채꼴 빛 생성
	if flashlight_enabled:
		create_flashlight()
	
	# 설치용 씬 로드
	if ResourceLoader.exists("res://torch.tscn"):
		torch_scene = load("res://torch.tscn")
		print("✅ torch.tscn 로드 완료")
	else:
		print("❌ torch.tscn을 찾을 수 없음!")
	
	# 설치 모드 하이라이트 생성
	create_build_highlight_sprite()
	
	# 기본 대기 애니메이션 재생
	play_animation("idle")

# 2, 3번 키 이전 프레임 상태 추적
var was_key_2_pressed: bool = false
var was_key_3_pressed: bool = false

# 좌클릭 홀드 채굴 시스템
var is_mining_held: bool = false
var mining_hold_timer: float = 0.0
var mining_hold_interval: float = 0.5  # 0.5초마다 채굴 (티어에 따라 변동)

func _input(event: InputEvent):
	# 마우스 좌클릭: 돌 캐기 (breakable_tile)
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			# 좌클릭 시작
			if not is_mining_held:
				is_mining_held = true
				mining_hold_timer = 0.0  # 타이머 초기화 (홀드 채굴용)
				# 첫 클릭 시 즉시 채굴 실행
				try_mine_breakable_tile()
		else:
			# 좌클릭 해제
			is_mining_held = false
	
	# 마우스 우클릭: 횃불/플랫폼 설치
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT:
		if event.pressed:
			# 횃불 설치 모드
			if Globals.is_torch_mode and torch_scene:
				place_torch()
			# 플랫폼 설치 모드
			elif Globals.is_build_mode:
				place_platform()

## breakable_tile 채굴을 시도합니다 (모든 tilemap 검사)
func try_mine_breakable_tile():
	# 모든 breakable_tile을 검사하여 마우스 방향에 타일이 있는지 확인
	var tilemaps = get_tree().get_nodes_in_group("breakable_tiles")
	var nearest_tile = null
	var nearest_tilemap = null
	var nearest_distance = 999999.0
	
	for tilemap in tilemaps:
		if not tilemap or not tilemap.has_method("get_nearest_breakable_tile"):
			continue
		
		# 각 tilemap의 마우스 방향 타일 검사
		var tile_info = tilemap.get_nearest_breakable_tile()
		if tile_info and tile_info.has("distance"):
			if tile_info.distance < nearest_distance:
				nearest_distance = tile_info.distance
				nearest_tile = tile_info
				nearest_tilemap = tilemap
	
	# 타일을 찾았으면 채굴
	if nearest_tilemap and nearest_tilemap.has_method("mine_nearest_tile"):
		start_pickaxe_animation()
		nearest_tilemap.mine_nearest_tile()

## 설치 모드 키 입력을 처리합니다 (_physics_process에서 호출)
func handle_build_mode_input():
	# 2번 키: 횃불 설치 모드 토글
	var is_key_2_pressed = Input.is_key_pressed(KEY_2)
	if is_key_2_pressed and not was_key_2_pressed:
		Globals.is_torch_mode = not Globals.is_torch_mode
		Globals.is_build_mode = false  # 플랫폼 모드는 해제
	was_key_2_pressed = is_key_2_pressed
	
	# 3번 키: 플랫폼 설치 모드 토글
	var is_key_3_pressed = Input.is_key_pressed(KEY_3)
	if is_key_3_pressed and not was_key_3_pressed:
		Globals.is_build_mode = not Globals.is_build_mode
		Globals.is_torch_mode = false  # 횃불 모드는 해제
	was_key_3_pressed = is_key_3_pressed

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
	
	# 설치 모드 하이라이트 업데이트
	update_build_highlight(delta)

func _physics_process(delta):
	# 설치 모드 키 입력 처리
	handle_build_mode_input()
	
	# 디버그: breakable_tiles 그룹 확인 (한 번만)
	_debug_check_tilemaps()
	
	# 돌 근처 확인
	check_nearby_rocks()
	
	# 좌클릭 홀드 채굴 처리 (모드 상관없이 항상 가능)
	if is_mining_held:
		mining_hold_timer += delta
		# 티어별 채굴 속도 배율 (누적): 1→2: 1.8배, 2→3: 1.5배, 3→4: 1.3배, 4→5: 1.2배
		var tier_multipliers = [1.0, 1.8, 2.7, 3.51, 4.212]  # 티어 1~5
		var tier_idx = clampi(Globals.mining_tier - 1, 0, tier_multipliers.size() - 1)
		var speed_bonus = tier_multipliers[tier_idx]
		var current_interval = mining_hold_interval / speed_bonus
		if mining_hold_timer >= current_interval:
			mining_hold_timer = 0.0
			try_mine_breakable_tile()
	
	# 이전 프레임에서 바닥에 있었는지 기록
	var was_on_floor = is_on_floor()
	
	# 채굴 키 입력 처리 - 튜토리얼 중에는 F키만, 아니면 모든 키
	# 상호작용 UI가 표시 중이면 채굴 무시 (알바 구매, 업그레이드 등)
	var can_mine = (current_nearby_rock or current_nearby_tilemap) and not Globals.is_action_text_visible
	if can_mine:
		if Globals.is_tutorial_active:
			# 튜토리얼 중: F키(첫 번째 키)만 사용
			var key = Globals.all_mining_keys[0]
			var is_key_pressed = Input.is_key_pressed(key)
			var key_just_pressed = is_key_pressed and not was_mining_keys_pressed[0]
			was_mining_keys_pressed[0] = is_key_pressed
			
			if key_just_pressed:
				add_charge()
				auto_mining_timers[0] = 0.0
			
			if is_key_pressed:
				auto_mining_timers[0] += delta
				if auto_mining_timers[0] >= Globals.auto_mining_interval:
					auto_mining_timers[0] = 0.0
					add_charge()
			else:
				auto_mining_timers[0] = 0.0
		else:
			# 튜토리얼 아님: 모든 활성화된 키 사용
			for i in range(Globals.mining_key_count):
				var key = Globals.all_mining_keys[i]
				var is_key_pressed = Input.is_key_pressed(key)
				var key_just_pressed = is_key_pressed and not was_mining_keys_pressed[i]
				was_mining_keys_pressed[i] = is_key_pressed
				
				if key_just_pressed:
					add_charge()
					auto_mining_timers[i] = 0.0
				
				if is_key_pressed:
					auto_mining_timers[i] += delta
					if auto_mining_timers[i] >= Globals.auto_mining_interval:
						auto_mining_timers[i] = 0.0
						add_charge()
				else:
					auto_mining_timers[i] = 0.0
	else:
		# 돌/타일맵 근처가 아니면 키 상태 및 타이머 초기화
		for i in range(6):
			was_mining_keys_pressed[i] = false
			auto_mining_timers[i] = 0.0
	
	# S 키 입력 확인
	var is_s_key_pressed = Input.is_key_pressed(KEY_S)
	var is_s_key_just_pressed = is_s_key_pressed and not was_s_key_pressed
	
	# Space 키 입력 확인 (점프 전에 먼저 확인)
	var is_space_pressed = Input.is_key_pressed(KEY_SPACE)
	var is_space_just_pressed = is_space_pressed and not was_space_key_pressed
	
	# S 키를 누른 상태에서 스페이스바를 누르면 플랫폼 통과 활성화
	if is_s_key_pressed and is_space_just_pressed and is_on_floor():
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
		velocity += get_gravity() * GRAVITY_SCALE * delta
	
	# Space 키로 점프 - 바닥에 있을 때만 가능 (S키를 누르지 않은 경우)
	if is_space_just_pressed and is_on_floor() and not is_s_key_pressed:
		is_jumping = true
		velocity.y = JUMP_VELOCITY  # 최대 점프 속도로 시작
	
	# Space 키를 떼면 상승 중일 때 속도 감소 (마리오 스타일)
	var is_space_just_released = not is_space_pressed and was_space_key_pressed
	if is_jumping and is_space_just_released:
		# 위로 올라가는 중이면 속도를 최소 점프 속도로 제한
		if velocity.y < MIN_JUMP_VELOCITY:
			velocity.y = MIN_JUMP_VELOCITY
		is_jumping = false
	
	# 이전 프레임의 Space 키 상태 저장
	was_space_key_pressed = is_space_pressed

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
					reset_pickaxe_to_initial()
		else:
			# 키를 누르지 않으면 마찰력으로 감속
			velocity.x = move_toward(velocity.x, 0, friction * delta)
		
		# 현재 속도를 공중 속도로 저장 (점프 전 속도)
		air_speed = abs(velocity.x)
	else:
		# 공중에 있을 때: 빠른 공중 제어
		if direction != 0:
			# Shift 키 상태에 따라 목표 속도 결정
			var is_running = Input.is_key_pressed(KEY_SHIFT)
			var target_speed = RUN_SPEED if is_running else SPEED
			var target_velocity = direction * target_speed
			
			# 공중 가속도를 적용하여 빠르게 목표 속도로 이동
			velocity.x = move_toward(velocity.x, target_velocity, air_acceleration * delta)
			
			# 스프라이트 방향 전환
			if sprite:
				sprite.flip_h = (direction < 0)
			
			# facing_direction이 변경되면 곡괭이 위치도 업데이트
			if facing_direction != direction:
				facing_direction = direction
				if pickaxe and not is_pickaxe_animating:
					reset_pickaxe_to_initial()
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
		State.RUNNING:
			play_animation("run")
		State.JUMPING, State.FALLING:
			play_animation("jump")
		State.MINING:
			play_animation("idle")
		State.SITTING:
			play_animation("sit")

# 이동/점프 상황에 따라 애니메이션을 갱신합니다.
func update_state_and_animation(was_on_floor_before: bool):
	var on_floor_now = is_on_floor()
	
	# S키를 누르고 있고 바닥에 있으면 앉기 애니메이션 우선
	if Input.is_key_pressed(KEY_S) and on_floor_now:
		set_state(State.SITTING)
		return
	
	# 점프 착지 애니메이션 처리
	if animation_player and animation_player.current_animation == "jump_end":
		if animation_player.is_playing() and on_floor_now:
			# 재생 중이면 완료까지 유지
			return
		elif not animation_player.is_playing() and on_floor_now:
			# 애니메이션이 끝났으면 current_animation 리셋하여 idle이 재생되도록 함
			current_animation = ""
	
	# 막 착지했을 때는 landing 전용 애니메이션 우선
	if (not was_on_floor_before) and on_floor_now:
		current_state = State.FALLING  # IDLE이 아닌 FALLING으로 설정 (애니메이션 끝난 후 IDLE 전환 가능하도록)
		play_animation("jump_end")
		return
	
	var is_moving = abs(velocity.x) > 5.0
	if on_floor_now:
		if is_moving:
			# Shift 키를 누르고 있으면 달리기, 아니면 걷기
			if Input.is_key_pressed(KEY_SHIFT):
				set_state(State.RUNNING)
			else:
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
# _process에서 매 프레임 호출되어 에디터에서 설정한 위치를 기준으로 스윙합니다.
# @param delta: 프레임 간 경과 시간
func update_pickaxe_animation(delta: float):
	if not pickaxe:
		return
	
	# 차징 중에는 차징 자세 유지
	if is_charging and not is_pickaxe_animating:
		update_charge_pickaxe_pose()
		return
	
	# 애니메이션 중이 아니면 기본 위치로 복귀
	if not is_pickaxe_animating:
		reset_pickaxe_to_initial()
		return
	
	# 애니메이션 시간 증가
	pickaxe_animation_time += delta
	
	# 애니메이션 완료 체크
	if pickaxe_animation_time >= pickaxe_animation_duration:
		is_pickaxe_animating = false
		pickaxe_animation_time = 0.0
		reset_pickaxe_to_initial()
		return
	
	# 진행도 계산 (0.0 ~ 1.0)
	var progress = pickaxe_animation_time / pickaxe_animation_duration
	
	# 스윙 애니메이션: 위로 들기 → 아래로 내려치기 → 원위치
	# 사인파 형태로 부드러운 스윙
	var swing_progress = sin(progress * PI)  # 0 → 1 → 0 곡선
	
	# 스윙 각도 계산 (에디터 기본 회전에서 swing_angle만큼 회전)
	var swing_offset = pickaxe_swing_angle * swing_progress
	
	# facing_direction에 따라 회전 방향 결정
	if facing_direction == 1:
		# 오른쪽: 시계 방향 스윙 (각도 증가)
		pickaxe.rotation_degrees = pickaxe_initial_rotation + swing_offset
		pickaxe.position = pickaxe_initial_position
		pickaxe.flip_h = false
	else:
		# 왼쪽: 반시계 방향 스윙 (x 반전, 각도 반전)
		pickaxe.rotation_degrees = -pickaxe_initial_rotation - swing_offset
		pickaxe.position = Vector2(-pickaxe_initial_position.x, pickaxe_initial_position.y)
		pickaxe.flip_h = true

# 곡괭이를 에디터에서 설정한 초기 위치로 복귀시킵니다.
func reset_pickaxe_to_initial():
	if not pickaxe:
		return
	
	if facing_direction == 1:
		# 오른쪽을 바라볼 때: 에디터 설정 그대로
		pickaxe.position = pickaxe_initial_position
		pickaxe.rotation_degrees = pickaxe_initial_rotation
		pickaxe.flip_h = false
	else:
		# 왼쪽을 바라볼 때: x 좌표와 각도 반전
		pickaxe.position = Vector2(-pickaxe_initial_position.x, pickaxe_initial_position.y)
		pickaxe.rotation_degrees = -pickaxe_initial_rotation
		pickaxe.flip_h = true

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
	if charge_amount == 0.0:
		if current_nearby_rock and current_nearby_rock.has_method("lock_camera_on_first_hit"):
			current_nearby_rock.lock_camera_on_first_hit()
		# 타일맵은 별도의 카메라 고정 없이 진행 (필요시 추가 가능)
	
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
	
	# 1. 일반 돌 근처에 채굴 신호 전송
	if current_nearby_rock and current_nearby_rock.has_method("mine_from_player"):
		print("⛏️ rock 채굴 시도")
		current_nearby_rock.mine_from_player()
	# 2. 타일맵 돌 채굴
	elif current_nearby_tilemap and current_nearby_tilemap.has_method("mine_nearest_tile"):
		print("⛏️ breakable_tile 채굴 시도")
		current_nearby_tilemap.mine_nearest_tile()
	else:
		print("❌ 채굴 대상 없음 - rock:", current_nearby_rock, " tilemap:", current_nearby_tilemap)
	
	# 차지 초기화
	charge_amount = 0.0
	is_charging = false

# 차징 중 곡괭이 자세를 업데이트합니다.
# 에디터 기본 위치에서 오프셋을 적용하여 위로 들어올린 자세를 만듭니다.
func update_charge_pickaxe_pose():
	if not pickaxe or is_pickaxe_animating:
		return
	
	# 에디터 기본 위치 + 오프셋으로 차징 자세 계산
	var charge_pos = pickaxe_initial_position + charge_position_offset
	var charge_rot = pickaxe_initial_rotation + charge_angle_offset
	
	if facing_direction == 1:
		# 오른쪽: 에디터 설정 기준
		pickaxe.position = charge_pos
		pickaxe.rotation_degrees = charge_rot
		pickaxe.flip_h = false
	else:
		# 왼쪽: x 좌표와 각도 반전
		pickaxe.position = Vector2(-charge_pos.x, charge_pos.y)
		pickaxe.rotation_degrees = -charge_rot
		pickaxe.flip_h = true

# 돌 또는 파괴 가능한 타일 근처에 있는지 확인합니다.
func check_nearby_rocks():
	var rocks = get_tree().get_nodes_in_group("rocks")
	var previous_tilemap = current_nearby_tilemap
	current_nearby_rock = null
	current_nearby_tilemap = null
	
	# 1. 일반 돌 (rocks 그룹) 확인
	for rock in rocks:
		if rock and global_position.distance_to(rock.global_position) < 50:
			current_nearby_rock = rock
			return true
	
	# 2. 파괴 가능한 타일맵 (breakable_tiles 그룹) 확인
	var tilemaps = get_tree().get_nodes_in_group("breakable_tiles")
	for tilemap in tilemaps:
		if tilemap and tilemap.has_method("has_nearby_breakable_tile"):
			var has_tile = tilemap.has_nearby_breakable_tile()
			if has_tile:
				current_nearby_tilemap = tilemap
				return true
	
	return false

# 디버그용: 한 번만 출력
var _debug_printed: bool = false
func _debug_check_tilemaps():
	if _debug_printed:
		return
	_debug_printed = true
	var tilemaps = get_tree().get_nodes_in_group("breakable_tiles")
	print("📋 breakable_tiles 그룹 노드 수:", tilemaps.size())
	for tm in tilemaps:
		print("  - ", tm.name, " tile_set:", tm.tile_set != null)

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

# === 설치 모드 함수들 ===

## 마우스 위치에 횃불을 설치합니다 (타일 그리드에 맞춤).
func place_torch():
	if not torch_scene:
		print("❌ 횃불 씬이 로드되지 않음")
		return
	
	var mouse_pos = get_global_mouse_position()
	
	# 타일 크기 (8x8 - 16x16을 0.5 스케일)
	var tile_size = 8.0
	
	# 마우스 위치를 타일 그리드에 맞춤 (타일 중앙 좌표)
	var tile_x = int(floor(mouse_pos.x / tile_size))
	var tile_y = int(floor(mouse_pos.y / tile_size))
	var snapped_pos = Vector2(tile_x * tile_size + tile_size / 2, tile_y * tile_size + tile_size / 2)
	
	# 캐릭터와의 거리 체크 (너무 멀면 설치 불가)
	var max_place_distance = 80.0
	var distance = global_position.distance_to(snapped_pos)
	if distance > max_place_distance:
		print("❌ 거리 초과: %.1f / %.1f" % [distance, max_place_distance])
		return
	
	# 해당 위치에 타일이 있는지 체크 (모든 TileMap에서 확인)
	if _is_position_inside_any_tile(snapped_pos):
		return  # 메시지는 _is_position_inside_any_tile에서 출력
	
	# breakable_tile(파괴 가능한 타일) 체크 - 벽 안에는 설치 불가
	if _is_position_inside_breakable_tile(snapped_pos):
		print("❌ 벽 타일 안에는 횃불 설치 불가")
		return
	
	# 폭포 타일 체크 - 폭포 위에는 설치 불가
	if _is_position_on_waterfall(snapped_pos):
		print("❌ 폭포 위에는 횃불 설치 불가")
		return
	
	# 해당 타일에 이미 횃불이 있는지 체크
	if _has_torch_at_tile(tile_x, tile_y, tile_size):
		print("❌ 이미 횃불 있음 at (%d, %d)" % [tile_x, tile_y])
		return
	
	# 횃불 인스턴스 생성
	var torch_instance = torch_scene.instantiate()
	torch_instance.global_position = snapped_pos
	torch_instance.scale = Vector2(0.5, 0.5)  # 크기를 절반으로 축소
	
	# map_2/torchs 노드에 추가 (없으면 현재 씬에 추가)
	var torchs_container = get_tree().current_scene.get_node_or_null("tile_map/map_2/torchs")
	if torchs_container:
		torchs_container.add_child(torch_instance)
	else:
		get_tree().current_scene.add_child(torch_instance)
	
	print("✅ 횃불 설치 완료 at %v" % snapped_pos)

## 마우스 위치에 플랫폼을 설치합니다.
## 아래에 블록이 있으면 지지대용(1,1), 없으면 공중용(1,0) 타일 사용
func place_platform():
	var mouse_pos = get_global_mouse_position()
	
	# 캐릭터와의 거리 체크
	var max_place_distance = 80.0
	var distance = global_position.distance_to(mouse_pos)
	if distance > max_place_distance:
		print("❌ 플랫폼 거리 초과: %.1f / %.1f" % [distance, max_place_distance])
		return
	
	# 해당 위치에 타일이 있는지 체크 (모든 TileMap에서 확인)
	if _is_position_inside_any_tile(mouse_pos):
		print("❌ 플랫폼 설치: 타일 중복")
		return
	
	# breakable_tile(파괴 가능한 타일) 체크 - 벽 안에는 설치 불가
	if _is_position_inside_breakable_tile(mouse_pos):
		print("❌ 벽 타일 안에는 플랫폼 설치 불가")
		return
	
	# TileMap 노드 찾기 (대문자 주의!)
	var tile_map_node = get_tree().current_scene.get_node_or_null("TileMap")
	if not tile_map_node:
		print("❌ TileMap 노드를 찾을 수 없음")
		return
	
	# platform TileMap 찾기 (map_2 우선, 없으면 map_1)
	var platform_tilemap = tile_map_node.get_node_or_null("map_2/platform")
	if not platform_tilemap:
		platform_tilemap = tile_map_node.get_node_or_null("map_1/platform")
	if not platform_tilemap:
		print("❌ platform TileMap을 찾을 수 없음")
		return
	
	# 마우스 위치를 타일 좌표로 변환
	var local_pos = platform_tilemap.to_local(mouse_pos)
	var tile_pos = platform_tilemap.local_to_map(local_pos)
	
	# 이미 타일이 있는지 확인
	if platform_tilemap.get_cell_source_id(0, tile_pos) != -1:
		print("❌ 플랫폼 이미 존재 at %v" % tile_pos)
		return
	
	# === 16x16 플랫폼 타일 설치 (source 7: mine_clicker-16_platform.png) ===
	# 아래 타일 좌표
	var below_pos = tile_pos + Vector2i(0, 1)
	
	# 아래에 블록이 있는지 확인
	var has_block_below = _check_block_below_for_platform(below_pos, platform_tilemap)
	
	# atlas 좌표 결정: 아래 블록 있으면 (2,1) 지지대용, 없으면 (1,1) 공중용
	var atlas_coords = Vector2i(2, 1) if has_block_below else Vector2i(1, 1)
	
	# 플랫폼 타일 설치 (source_id: 7 = mine_clicker-16_platform.png)
	platform_tilemap.set_cell(0, tile_pos, 7, atlas_coords)
	print("✅ 플랫폼 설치 완료 at %v (atlas: %v, 아래 블록: %s)" % [tile_pos, atlas_coords, has_block_below])

## 플랫폼 설치 시 아래 위치에 블록이 있는지 확인합니다.
## @param below_tile_pos: 확인할 타일 좌표 (플랫폼 바로 아래)
## @param platform_tilemap: 플랫폼 TileMap (좌표 변환용)
## @returns: 블록이 있으면 true
func _check_block_below_for_platform(below_tile_pos: Vector2i, platform_tilemap: TileMap) -> bool:
	# 타일 좌표를 월드 좌표로 변환
	var local_pos = platform_tilemap.map_to_local(below_tile_pos)
	var world_pos = platform_tilemap.to_global(local_pos)
	
	print("🔍 아래 블록 체크 - tile_pos: %v, world_pos: %v" % [below_tile_pos, world_pos])
	
	# 1. breakable_tiles 그룹의 TileMap에서 확인
	var tilemaps = get_tree().get_nodes_in_group("breakable_tiles")
	print("  breakable_tiles 개수: ", tilemaps.size())
	for tilemap in tilemaps:
		if not tilemap is TileMap:
			continue
		var tm_local = tilemap.to_local(world_pos)
		var tm_tile_pos = tilemap.local_to_map(tm_local)
		print("  - %s: tm_tile_pos=%v" % [tilemap.name, tm_tile_pos])
		for layer_idx in range(tilemap.get_layers_count()):
			var source_id = tilemap.get_cell_source_id(layer_idx, tm_tile_pos)
			if source_id != -1:
				print("    ✅ 블록 발견! layer=%d, source=%d" % [layer_idx, source_id])
				return true
	
	# 2. maps TileMap (일반 타일)에서 확인
	# tile_map 노드 찾기 (여러 경로 시도)
	var tile_map_node = get_tree().current_scene.get_node_or_null("tile_map")
	if not tile_map_node:
		tile_map_node = get_tree().current_scene.get_node_or_null("TileMap")
	if not tile_map_node:
		tile_map_node = get_tree().current_scene.get_node_or_null("tilemaps")
	
	if tile_map_node:
		# map_2 우선, 없으면 map_1
		var maps_tilemap = tile_map_node.get_node_or_null("map_2/maps")
		if not maps_tilemap:
			maps_tilemap = tile_map_node.get_node_or_null("map_1/maps")
		
		if maps_tilemap and maps_tilemap.tile_set:
			var maps_tile_size = maps_tilemap.tile_set.tile_size
			var maps_local = maps_tilemap.to_local(world_pos)
			var maps_tile_pos = maps_tilemap.local_to_map(maps_local)
			print("  - maps: tile_size=%v, maps_tile_pos=%v" % [maps_tile_size, maps_tile_pos])
			
			# 주변 타일도 확인 (타일 크기 차이로 인한 오차 보정)
			var check_positions = [
				maps_tile_pos,
				maps_tile_pos + Vector2i(0, -1),  # 위
				maps_tile_pos + Vector2i(0, 1),   # 아래
				maps_tile_pos + Vector2i(-1, 0),  # 왼쪽
				maps_tile_pos + Vector2i(1, 0),   # 오른쪽
			]
			
			for check_pos in check_positions:
				for layer_idx in range(maps_tilemap.get_layers_count()):
					var source_id = maps_tilemap.get_cell_source_id(layer_idx, check_pos)
					if source_id != -1:
						print("    ✅ maps 블록 발견! pos=%v, layer=%d, source=%d" % [check_pos, layer_idx, source_id])
						if check_pos == maps_tile_pos:
							return true
		else:
			print("  ⚠️ maps TileMap을 찾지 못함 또는 tile_set 없음")
	else:
		print("  ⚠️ tile_map 노드를 찾지 못함")
	
	print("  ❌ 아래 블록 없음")
	return false

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


## 특정 위치가 어떤 TileMap의 타일 안에 있는지 확인합니다.
## @param world_pos: 월드 좌표
## @returns: 타일 안에 있으면 true
func _is_position_inside_any_tile(world_pos: Vector2) -> bool:
	# 씬의 모든 TileMap 노드 찾기
	var tilemaps = _get_all_tilemaps(get_tree().current_scene)
	
	for tilemap in tilemaps:
		if not tilemap is TileMap:
			continue
		
		# breakable_tiles 그룹의 TileMap은 제외 (파괴 가능한 타일)
		if tilemap.is_in_group("breakable_tiles"):
			continue
		
		# 비활성화된 맵(map_1, map_2)의 타일은 무시
		var parent = tilemap.get_parent()
		while parent:
			if not parent.visible:
				break
			parent = parent.get_parent()
		if parent and not parent.visible:
			continue
		
		# TileMap의 로컬 좌표로 변환
		var local_pos = tilemap.to_local(world_pos)
		var tile_pos = tilemap.local_to_map(local_pos)
		
		# 모든 레이어에서 타일 확인
		# 설치 가능한 TileMap들은 체크 제외
		var tilemap_name = tilemap.name.to_lower()
		# - background: 배경 (장식용)
		# - ui_tile: UI용 타일
		# - platform: 플랫폼 (별도 체크)
		# - inside_cave 계열: 벽 장식 (설치 허용)
		if tilemap_name in ["background", "ui_tile", "platform"] or tilemap_name.begins_with("inside_cave"):
			continue
		
		# 모든 레이어에서 타일 확인
		for layer_idx in range(tilemap.get_layers_count()):
			var source_id = tilemap.get_cell_source_id(layer_idx, tile_pos)
			if source_id != -1:
				# 단단한 타일 발견! 설치 불가 (로그 제거 - 너무 많이 출력됨)
				return true
	
	return false


## /** breakable_tile(파괴 가능한 벽) 위치 체크
##  * @param world_pos Vector2 월드 좌표
##  * @returns bool 해당 위치에 breakable_tile이 있으면 true
##  */
func _is_position_inside_breakable_tile(world_pos: Vector2) -> bool:
	# breakable_tiles 그룹의 TileMap만 확인
	var breakable_tilemaps = get_tree().get_nodes_in_group("breakable_tiles")
	
	for tilemap in breakable_tilemaps:
		if not tilemap is TileMap:
			continue
		
		# TileMap의 로컬 좌표로 변환
		var local_pos = tilemap.to_local(world_pos)
		var tile_pos = tilemap.local_to_map(local_pos)
		
		# 모든 레이어에서 타일 확인
		for layer_idx in range(tilemap.get_layers_count()):
			var source_id = tilemap.get_cell_source_id(layer_idx, tile_pos)
			if source_id != -1:
				# breakable_tile 발견!
				return true
	
	return false


## /** background 타일맵의 폭포 타일 위치 체크
##  * @param world_pos Vector2 월드 좌표
##  * @returns bool 해당 위치에 폭포 타일이 있으면 true
##  */
func _is_position_on_waterfall(world_pos: Vector2) -> bool:
	# tile_map_manager 그룹에서 타일맵 매니저 찾기
	var tile_map_managers = get_tree().get_nodes_in_group("tile_map_manager")
	
	for manager in tile_map_managers:
		# background TileMap 찾기 (map_1/background)
		var background = manager.get_node_or_null("map_1/background")
		if not background or not (background is TileMap):
			continue
		
		# TileMap의 로컬 좌표로 변환
		var local_pos = background.to_local(world_pos)
		var tile_pos = background.local_to_map(local_pos)
		
		# background 레이어(0번)에서 타일 확인
		var source_id = background.get_cell_source_id(0, tile_pos)
		if source_id != -1:
			# TileSet 가져오기
			var tile_set = background.tile_set
			if tile_set:
				var source = tile_set.get_source(source_id)
				if source is TileSetAtlasSource:
					var atlas_source = source as TileSetAtlasSource
					# 폭포 텍스처인지 확인 (파일 경로에 "warterfall" 포함)
					if atlas_source.texture and "warterfall" in atlas_source.texture.resource_path:
						return true
	
	return false


## 노드와 모든 자식에서 TileMap을 재귀적으로 찾습니다.
func _get_all_tilemaps(node: Node) -> Array:
	var result = []
	
	if node is TileMap:
		result.append(node)
	
	for child in node.get_children():
		result.append_array(_get_all_tilemaps(child))
	
	return result


## 특정 타일 좌표에 횃불이 있는지 확인합니다.
## @param tile_x: 타일 X 좌표
## @param tile_y: 타일 Y 좌표
## @param tile_size: 타일 크기
## @returns: 횃불이 있으면 true
func _has_torch_at_tile(tile_x: int, tile_y: int, tile_size: float) -> bool:
	# torchs 컨테이너에서 확인
	var torchs_container = get_tree().current_scene.get_node_or_null("tile_map/map_2/torchs")
	if torchs_container:
		for torch in torchs_container.get_children():
			var torch_tile_x = int(floor(torch.global_position.x / tile_size))
			var torch_tile_y = int(floor(torch.global_position.y / tile_size))
			if torch_tile_x == tile_x and torch_tile_y == tile_y:
				return true
	
	# 루트에 직접 추가된 횃불도 확인 (torch 그룹 사용)
	var all_torches = get_tree().get_nodes_in_group("torches")
	for torch in all_torches:
		var torch_tile_x = int(floor(torch.global_position.x / tile_size))
		var torch_tile_y = int(floor(torch.global_position.y / tile_size))
		if torch_tile_x == tile_x and torch_tile_y == tile_y:
			return true
	
	return false

## ========================================
## 설치 모드 하이라이트 시스템
## ========================================


func create_build_highlight_sprite():
	build_highlight_sprite = Sprite2D.new()
	build_highlight_sprite.name = "BuildHighlightSprite"
	build_highlight_sprite.z_index = 100  # 타일 위에 표시
	build_highlight_sprite.visible = false
	build_highlight_sprite.scale = Vector2(0.5, 0.5)  # 횃불과 동일한 크기로 축소
	
	# 16x16 테두리 텍스처 생성
	var size = 16
	var border = 2
	var image = Image.create(size, size, false, Image.FORMAT_RGBA8)
	image.fill(Color(0, 0, 0, 0))  # 투명 배경
	
	# 테두리만 그리기 (기본 초록색)
	var highlight_color = Color(0.3, 1.0, 0.3, 0.8)  # 초록색
	for x in range(size):
		for y in range(size):
			# 테두리 영역인지 확인
			if x < border or x >= size - border or y < border or y >= size - border:
				image.set_pixel(x, y, highlight_color)
	
	var texture = ImageTexture.create_from_image(image)
	build_highlight_sprite.texture = texture
	
	# 씬에 추가
	add_child(build_highlight_sprite)
	print("✅ 설치 모드 하이라이트 스프라이트 생성 완료 (8x8)")


func update_build_highlight(delta):
	if not build_highlight_sprite:
		return
	
	# 횃불 모드 또는 플랫폼 모드일 때만 하이라이트 표시
	if not Globals.is_torch_mode and not Globals.is_build_mode:
		build_highlight_sprite.visible = false
		return
	
	# 마우스 위치 가져오기
	var mouse_pos = get_global_mouse_position()
	var tile_size = 8.0  # 실제 표시 크기 (16x16을 0.5 스케일)
	
	# 타일 그리드에 맞춘 위치 계산
	var tile_x = int(floor(mouse_pos.x / tile_size))
	var tile_y = int(floor(mouse_pos.y / tile_size))
	var snapped_pos = Vector2(tile_x * tile_size + tile_size / 2, tile_y * tile_size + tile_size / 2)
	
	# 하이라이트 위치 업데이트
	build_highlight_sprite.global_position = snapped_pos
	build_highlight_sprite.visible = true
	
	# 설치 가능 여부에 따라 색상 변경
	var can_place = false
	if Globals.is_torch_mode:
		can_place = can_place_torch_at(mouse_pos)
	elif Globals.is_build_mode:
		can_place = can_place_platform_at(mouse_pos)
	
	if can_place:
		# 초록색 (설치 가능)
		build_highlight_sprite.modulate = Color(0.3, 1.0, 0.3, 0.7)
	else:
		# 빨간색 (설치 불가)
		build_highlight_sprite.modulate = Color(1.0, 0.3, 0.3, 0.7)
	
	# 펄스 애니메이션 (알파 값 변화)
	build_highlight_pulse_time += delta * 4.0
	var pulse = (sin(build_highlight_pulse_time) + 1.0) / 2.0  # 0.0 ~ 1.0
	var alpha = 0.4 + pulse * 0.3  # 0.4 ~ 0.7
	build_highlight_sprite.modulate.a = alpha


func can_place_torch_at(mouse_pos: Vector2) -> bool:
	if not torch_scene:
		return false
	
	var tile_size = 8.0
	var tile_x = int(floor(mouse_pos.x / tile_size))
	var tile_y = int(floor(mouse_pos.y / tile_size))
	var snapped_pos = Vector2(tile_x * tile_size + tile_size / 2, tile_y * tile_size + tile_size / 2)
	
	# 1. 거리 체크
	var max_place_distance = 80.0
	if global_position.distance_to(snapped_pos) > max_place_distance:
		return false
	
	# 2. 타일 중복 체크
	if _is_position_inside_any_tile(snapped_pos):
		return false
	
	# 3. breakable_tile 체크
	if _is_position_inside_breakable_tile(snapped_pos):
		return false
	
	# 4. 폭포 타일 체크
	if _is_position_on_waterfall(snapped_pos):
		return false
	
	# 5. 횃불 중복 체크
	if _has_torch_at_tile(tile_x, tile_y, tile_size):
		return false
	
	return true


func can_place_platform_at(mouse_pos: Vector2) -> bool:
	# 1. 거리 체크
	var max_place_distance = 80.0
	if global_position.distance_to(mouse_pos) > max_place_distance:
		return false
	
	# 2. 타일 중복 체크
	if _is_position_inside_any_tile(mouse_pos):
		return false
	
	# 3. breakable_tile 체크
	if _is_position_inside_breakable_tile(mouse_pos):
		return false
	
	# 4. platform TileMap에 이미 타일이 있는지 체크
	var tile_map_node = get_tree().current_scene.get_node_or_null("TileMap")
	if tile_map_node:
		var platform_tilemap = tile_map_node.get_node_or_null("map_2/platform")
		if not platform_tilemap:
			platform_tilemap = tile_map_node.get_node_or_null("map_1/platform")
		
		if platform_tilemap:
			var local_pos = platform_tilemap.to_local(mouse_pos)
			var tile_pos = platform_tilemap.local_to_map(local_pos)
			if platform_tilemap.get_cell_source_id(0, tile_pos) != -1:
				return false  # 이미 플랫폼이 있음
	
	return true
