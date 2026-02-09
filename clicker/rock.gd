extends Node2D
@onready var progress_bar = $ProgressBar
@onready var timer = $Timer
@onready var sprite = $Sprite2D if has_node("Sprite2D") else null

# 캐릭터가 영역 안에 있는지 추적하는 변수
var is_character_inside : bool = false
@onready var normal_sound = $normal_sound
@onready var good_sound = $good_sound
@onready var dirt_sound_1: AudioStreamPlayer = $dirt_sound_1
@onready var dirt_sound_2: AudioStreamPlayer = $dirt_sound_2

# 오디오 풀링 시스템
var normal_sound_pool: Array[AudioStreamPlayer] = []
var good_sound_pool: Array[AudioStreamPlayer] = []
var dirt_sound_pool_1: Array[AudioStreamPlayer] = []
var dirt_sound_pool_2: Array[AudioStreamPlayer] = []
const AUDIO_POOL_SIZE: int = 5  # 풀 크기

# 카메라 고정 관련 변수
var is_camera_locked : bool = false  # 카메라가 이 돌에 고정되었는지
var time_since_last_mining : float = 0.0  # 마지막 채굴 후 경과 시간
const CAMERA_UNLOCK_TIME : float = 5.0  # 5초 후 카메라 고정 해제

# 바위 흔들림 효과
var shake_amount : float = 0.0
var original_position : Vector2 = Vector2.ZERO
const GALMURI_9 = preload("uid://dqloen3424vrx")

# 채굴 시스템 변수
var go_down = false
var now_time : float = 0.0
var max_time : float = 10.0  # 채굴 완료까지 필요한 시간
var decay_rate : float = 3.0  # 초당 감소 속도 (프레임 독립적)
var mining_speed : float = 1.0  # F키 한 번당 채굴 진행도 (기본값)
var decay_delay : float = 5.0  # 게이지 감소 대기 시간 (5초)
var last_hit_time : float = 0.0  # 마지막으로 F키를 누른 시간

# 파티클 시스템 (스프라이트 기반)
var dust_texture : Texture2D  # 먼지 스프라이트 텍스처

# 마우스 클릭 추적 (사용 안 함 - 차징 시스템 사용)
# var mouse_just_clicked : bool = false

# 채굴 키 입력 추적 (사용 안 함 - character.gd에서 처리)
# var was_mining_key1_pressed : bool = false
# var was_mining_key2_pressed : bool = false

# 대기시간 시스템 (사용 안 함)
var is_cooldown : bool = false  # 대기시간 중인지 여부
var cooldown_time : float = 0.0  # 대기시간 (초) - 0으로 설정하여 비활성화
var cooldown_timer : float = 0.0  # 현재 대기시간 타이머

func _ready():
	# rocks 그룹에 추가 (캐릭터가 찾을 수 있도록)
	add_to_group("rocks")
	
	# 먼지 스프라이트 텍스처 로드
	dust_texture = load("res://CONCEPT/asset/mine_clicker32-dust.png")
	
	
	# 스프라이트 원래 위치 저장
	if sprite:
		original_position = sprite.position
	
	# 프로그레스바 숨김 (차징 시스템 사용)
	if progress_bar:
		progress_bar.visible = false
	
	# 오디오 풀 초기화
	_init_audio_pool()

# 마우스 클릭 처리는 이제 사용 안 함 (차징 시스템 사용)
# func _input(event):
# 	if is_character_inside and event is InputEventMouseButton:
# 		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
# 			mouse_just_clicked = true

func _physics_process(delta):
	# 대기시간 처리
	if is_cooldown:
		cooldown_timer -= delta
		if cooldown_timer <= 0.0:
			is_cooldown = false
			cooldown_timer = 0.0
	
	# 카메라 고정 해제 체크 (5초 동안 채굴하지 않거나 영역을 벗어나면)
	if is_camera_locked:
		if not is_character_inside:
			# 영역을 벗어나면 즉시 카메라 고정 해제
			unlock_camera()
		else:
			# 영역 안에 있지만 채굴하지 않으면 타이머 증가
			time_since_last_mining += delta
			if time_since_last_mining >= CAMERA_UNLOCK_TIME:
				unlock_camera()
	
	# 키 입력 처리는 이제 character.gd에서 처리
	# (차징 시스템 사용)
	
	# 5초 경과 후 게이지 감소 시작
	if now_time > 0 and not is_cooldown:
		var current_time = Time.get_ticks_msec() / 1000.0
		var time_since_last_hit = current_time - last_hit_time
		
		if time_since_last_hit >= decay_delay:
			# 5초가 지났으면 감소 시작
			if not go_down:
				go_down = true
				timer.start()
	
	# 프레임 독립적 감소 (delta 사용)
	if go_down:
		if now_time > 0:
			now_time -= decay_rate * delta
			if now_time < 0:
				now_time = 0
	
	# 프로그레스바 업데이트
	if is_cooldown:
		# 대기시간 중에는 프로그레스바를 대기시간 표시로 사용
		progress_bar.value = (cooldown_time - cooldown_timer) / cooldown_time * max_time
	else:
		progress_bar.value = now_time
	
	# 프로그레스바 색상 변경 (진행도에 따라)
	update_progress_color()
	
	# 바위 흔들림 효과 업데이트 (비활성화)
	# update_shake_effect(delta)

# 첫 번째 클릭 시 카메라를 고정합니다 (차징 시작).
func lock_camera_on_first_hit():
	# 카메라 고정 (처음 클릭 시)
	if not is_camera_locked:
		lock_camera()
	
	# 채굴 타이머 리셋
	time_since_last_mining = 0.0

# 카메라가 이 돌에 고정되어 있는지 반환합니다.
func is_camera_locked_to_this() -> bool:
	return is_camera_locked

# 플레이어로부터 채굴 신호를 받습니다 (차징 시스템).
func mine_from_player():
	# 캐릭터가 영역 안에 있고 채굴 가능한 상태인지 확인
	if not is_character_inside or is_cooldown:
		return
	
	# 채굴 타이머 리셋
	time_since_last_mining = 0.0
	
	# 즉시 채굴 완료
	complete_mining()

# 채굴 완료 함수
func complete_mining():
	# 곡괭이 애니메이션은 character.gd에서 이미 실행됨
	
	# 피버 배율 적용
	var money_gained = int(Globals.money_up * Globals.fever_multiplier)
	
	# x3, x2 확률 체크 (Globals에서 관리)
	# x3 먼저 체크 (더 희귀함)
	var random_roll = randf()
	var is_x3 = random_roll < Globals.x3_chance
	var is_x2 = not is_x3 and random_roll < (Globals.x3_chance + Globals.x2_chance)
	
	if is_x3:
		money_gained *= 3
	elif is_x2:
		money_gained *= 2
	
	Globals.money += money_gained
	Globals.rock_mined.emit(money_gained)
	
	now_time = 0
	
	# 대기시간 없음 (즉시 다시 채굴 가능)
	
	# 먼지 스프라이트 파티클 발생
	spawn_dust_particles(8)
	
	# 떠오르는 텍스트 생성 (x3이면 특별, x2이면 크리티컬)
	if is_x3:
		spawn_floating_text_jackpot("+" + str(money_gained) + "!!")
	elif is_x2:
		spawn_floating_text_critical("+" + str(money_gained) + "!")
	else:
		spawn_floating_text("+" + str(money_gained))

# 프로그레스바 색상 업데이트 (초록 → 노랑 → 빨강) + 애니메이션
func update_progress_color():
	# 대기시간 중에는 회색으로 표시
	if is_cooldown:
		progress_bar.modulate = Color(0.5, 0.5, 0.5, 0.7)  # 회색 (대기 중)
		progress_bar.scale = Vector2(1.0, 1.0)
		return
	
	var progress_ratio = now_time / max_time
	
	# 진행도가 있으면 프로그레스바 펄스 효과
	if now_time > 0 and is_character_inside:
		# 펄스 효과 (시간에 따라 크기 변화)
		var pulse = 1.0 + sin(Time.get_ticks_msec() / 100.0) * 0.1
		progress_bar.scale = Vector2(pulse, pulse)
	else:
		progress_bar.scale = Vector2(1.0, 1.0)
	
	# 진행도에 따른 색상 변경 (부드러운 그라디언트)
	if progress_ratio < 0.33:
		# 초록색
		progress_bar.modulate = Color(0.3, 1.0, 0.3)
	elif progress_ratio < 0.66:
		# 노란색
		progress_bar.modulate = Color(1.0, 1.0, 0.3)
	else:
		# 빨간색 + 밝기 증가 (거의 완료)
		var brightness = 1.0 + (progress_ratio - 0.66) * 0.5
		progress_bar.modulate = Color(1.0 * brightness, 0.3, 0.3)


# 먼지 스프라이트 파티클 생성 (위로 올라갔다 중력에 의해 떨어짐)
func spawn_dust_particles(amount: int):
	for i in range(amount):
		var dust_sprite = Sprite2D.new()
		
		# 처음에는 왼쪽 이미지 (큰 먼지)로 시작
		var atlas_tex = AtlasTexture.new()
		atlas_tex.atlas = dust_texture
		atlas_tex.region = Rect2(0, 0, 16, 16)  # 왼쪽 이미지
		dust_sprite.texture = atlas_tex
		
		# 크기 설정 (0.4 ~ 0.7 배율) - 살짝 줄임
		var scale_val = randf_range(0.4, 0.7)
		dust_sprite.scale = Vector2(scale_val, scale_val)
		
		# 픽셀 아트 필터 설정
		dust_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		
		add_child(dust_sprite)
		
		# 물리 시뮬레이션으로 중력 효과 구현
		_animate_dust_with_gravity(dust_sprite, atlas_tex)

# 중력 효과가 있는 먼지 파티클 애니메이션
func _animate_dust_with_gravity(dust_sprite: Sprite2D, atlas_tex: AtlasTexture):
	# 초기 속도 (위쪽으로 튀어오름)
	var angle = randf_range(-150, -30) * PI / 180.0  # 위쪽 방향
	var speed = randf_range(30, 60)
	var velocity = Vector2(cos(angle), sin(angle)) * speed
	
	# 중력 값
	var gravity = 120.0
	
	# 총 수명
	var lifetime = randf_range(0.5, 0.8)
	var elapsed = 0.0
	
	# 회전 속도
	var rotation_speed = randf_range(-4.0, 4.0)
	
	# 스프라이트 전환 여부 (한 번만 전환)
	var switched_sprite = false
	
	# 스프라이트 전환 시점 (30% ~ 50% 사이 랜덤)
	var switch_progress = randf_range(0.3, 0.5)
	
	# 매 프레임 업데이트
	while elapsed < lifetime and is_instance_valid(dust_sprite):
		var delta = get_process_delta_time()
		elapsed += delta
		
		# 중력 적용 (속도의 y값 증가)
		velocity.y += gravity * delta
		
		# 위치 업데이트
		dust_sprite.position += velocity * delta
		
		# 회전
		dust_sprite.rotation += rotation_speed * delta
		
		# 진행도 계산
		var progress = elapsed / lifetime
		
		# 랜덤 시점에서 오른쪽 이미지(작은 먼지)로 전환
		if not switched_sprite and progress > switch_progress:
			atlas_tex.region = Rect2(16, 0, 16, 16)  # 오른쪽 이미지로 변경
			switched_sprite = true
		
		# 페이드아웃 (후반부에만)
		if progress > 0.5:
			dust_sprite.modulate.a = 1.0 - (progress - 0.5) * 2.0
		
		await get_tree().process_frame
	
	# 삭제
	if is_instance_valid(dust_sprite):
		dust_sprite.queue_free()

# 오디오 풀 초기화
func _init_audio_pool():
	# normal_sound 풀 생성
	if normal_sound and normal_sound.stream:
		for i in range(AUDIO_POOL_SIZE):
			var player = AudioStreamPlayer.new()
			player.stream = normal_sound.stream
			player.volume_db = normal_sound.volume_db
			player.bus = normal_sound.bus
			add_child(player)
			normal_sound_pool.append(player)
	
	# good_sound 풀 생성
	if good_sound and good_sound.stream:
		for i in range(AUDIO_POOL_SIZE):
			var player = AudioStreamPlayer.new()
			player.stream = good_sound.stream
			player.volume_db = good_sound.volume_db
			player.bus = good_sound.bus
			add_child(player)
			good_sound_pool.append(player)
	
	# dirt_sound_1 풀 생성
	if dirt_sound_1 and dirt_sound_1.stream:
		for i in range(AUDIO_POOL_SIZE):
			var player = AudioStreamPlayer.new()
			player.stream = dirt_sound_1.stream
			player.volume_db = dirt_sound_1.volume_db
			player.bus = "SFX"
			add_child(player)
			dirt_sound_pool_1.append(player)
	
	# dirt_sound_2 풀 생성
	if dirt_sound_2 and dirt_sound_2.stream:
		for i in range(AUDIO_POOL_SIZE):
			var player = AudioStreamPlayer.new()
			player.stream = dirt_sound_2.stream
			player.volume_db = dirt_sound_2.volume_db
			player.bus = "SFX"
			add_child(player)
			dirt_sound_pool_2.append(player)

# 두 흙 사운드 중 랜덤으로 하나 재생
func _play_random_dirt_sound():
	if randi() % 2 == 0:
		_play_from_pool(dirt_sound_pool_1)
	else:
		_play_from_pool(dirt_sound_pool_2)

# 풀에서 사용 가능한 플레이어 찾아서 재생
func _play_from_pool(pool: Array[AudioStreamPlayer]):
	for player in pool:
		if not player.playing:
			player.play()
			return
	# 모든 플레이어가 사용 중이면 첫 번째 플레이어 재시작
	if pool.size() > 0:
		pool[0].play()

# 떠오르는 텍스트 생성
func spawn_floating_text(text: String):
	# 두 흙 사운드 중 랜덤 재생
	_play_random_dirt_sound()
	# floating_text.gd의 정적 함수 사용
	var floating_text_script = load("res://floating_text.gd")
	if floating_text_script:
		# 금색으로 표시
		floating_text_script.create(self, Vector2(0, -20), text, Color(1.0, 0.9, 0.3))

# 크리티컬 떠오르는 텍스트 생성 (x2 보너스)
func spawn_floating_text_critical(text: String):
	_play_from_pool(good_sound_pool)
	var floating_text_script = load("res://floating_text.gd")
	if floating_text_script:
		# 핑크-보라색으로 표시
		floating_text_script.create(self, Vector2(0, -20), text, Color(1.0, 0.3, 0.8))

# 잭팟 떠오르는 텍스트 생성 (x3 보너스)
func spawn_floating_text_jackpot(text: String):
	_play_from_pool(good_sound_pool)
	var floating_text_script = load("res://floating_text.gd")
	if floating_text_script:
		# 파란색으로 표시 (잭팟!)
		floating_text_script.create(self, Vector2(0, -20), text, Color(0.3, 0.6, 1.0))


func _on_area_2d_body_shape_entered(_body_rid, body, _body_shape_index, _local_shape_index):
	# 들어온 body가 CharacterBody2D 타입인지 확인
	if body is CharacterBody2D:
		is_character_inside = true


func _on_area_2d_body_shape_exited(_body_rid, body, _body_shape_index, _local_shape_index):
	# 나간 body가 CharacterBody2D 타입인지 확인
	if body is CharacterBody2D:
		is_character_inside = false
		
		# 영역을 벗어나면 카메라 고정 해제
		if is_camera_locked:
			unlock_camera()


func _on_timer_timeout():
	go_down = true

# 카메라를 이 돌 위치에 고정
func lock_camera():
	is_camera_locked = true
	time_since_last_mining = 0.0
	
	# 카메라에 신호 전송
	var camera = get_tree().get_first_node_in_group("camera")
	if camera and camera.has_method("lock_to_target"):
		camera.lock_to_target(global_position)

# 카메라 고정 해제
func unlock_camera():
	is_camera_locked = false
	time_since_last_mining = 0.0
	
	# 카메라에 신호 전송
	var camera = get_tree().get_first_node_in_group("camera")
	if camera and camera.has_method("unlock_from_target"):
		camera.unlock_from_target()

# 바위 흔들림 효과
func update_shake_effect(delta):
	if not sprite:
		return
	
	# 진행도가 있으면 흔들림
	if now_time > 0 and is_character_inside:
		# 진행도에 따라 흔들림 강도 증가
		var progress_ratio = now_time / max_time
		shake_amount = lerp(shake_amount, 2.0 + progress_ratio * 3.0, delta * 10.0)
		
		# 랜덤 흔들림
		var shake_offset = Vector2(
			randf_range(-shake_amount, shake_amount),
			randf_range(-shake_amount, shake_amount)
		)
		sprite.position = original_position + shake_offset
	else:
		# 흔들림 감소
		shake_amount = lerp(shake_amount, 0.0, delta * 10.0)
		sprite.position = lerp(sprite.position, original_position, delta * 10.0)
