extends Node2D
@onready var progress_bar = $ProgressBar
@onready var timer = $Timer
@onready var sprite = $Sprite2D if has_node("Sprite2D") else null

# 캐릭터가 영역 안에 있는지 추적하는 변수
var is_character_inside : bool = false

# 카메라 고정 관련 변수
var is_camera_locked : bool = false  # 카메라가 이 돌에 고정되었는지
var time_since_last_mining : float = 0.0  # 마지막 채굴 후 경과 시간
const CAMERA_UNLOCK_TIME : float = 5.0  # 5초 후 카메라 고정 해제

# 바위 흔들림 효과
var shake_amount : float = 0.0
var original_position : Vector2 = Vector2.ZERO

# 채굴 시스템 변수
var go_down = false
var now_time : float = 0.0
var max_time : float = 10.0  # 채굴 완료까지 필요한 시간
var decay_rate : float = 3.0  # 초당 감소 속도 (프레임 독립적)
var mining_speed : float = 1.0  # F키 한 번당 채굴 진행도 (기본값)
var decay_delay : float = 5.0  # 게이지 감소 대기 시간 (5초)
var last_hit_time : float = 0.0  # 마지막으로 F키를 누른 시간

# 파티클 시스템
var complete_particles : CPUParticles2D
var mining_particles : CPUParticles2D  # 채굴 중 지속 파티클

# 마우스 클릭 추적
var mouse_just_clicked : bool = false

# 채굴 키 입력 추적 (이전 프레임 상태)
var was_mining_key1_pressed : bool = false
var was_mining_key2_pressed : bool = false

# 대기시간 시스템 (사용 안 함)
var is_cooldown : bool = false  # 대기시간 중인지 여부
var cooldown_time : float = 0.0  # 대기시간 (초) - 0으로 설정하여 비활성화
var cooldown_timer : float = 0.0  # 현재 대기시간 타이머

func _ready():
	# 완료 파티클 생성 (채굴 완료 시)
	complete_particles = CPUParticles2D.new()
	complete_particles.emitting = false
	complete_particles.one_shot = true
	complete_particles.amount = 15
	complete_particles.lifetime = 0.8
	complete_particles.explosiveness = 1.0
	complete_particles.direction = Vector2(0, -1)
	complete_particles.spread = 180
	complete_particles.initial_velocity_min = 80
	complete_particles.initial_velocity_max = 150
	complete_particles.gravity = Vector2(0, 150)
	complete_particles.scale_amount_min = 3
	complete_particles.scale_amount_max = 6
	complete_particles.color = Color(1, 0.9, 0.3)  # 금색 (보상)
	add_child(complete_particles)
	
	# 채굴 중 파티클 생성 (지속적으로 발생)
	mining_particles = CPUParticles2D.new()
	mining_particles.emitting = false
	mining_particles.amount = 8
	mining_particles.lifetime = 0.5
	mining_particles.direction = Vector2(0, -1)
	mining_particles.spread = 45
	mining_particles.initial_velocity_min = 30
	mining_particles.initial_velocity_max = 60
	mining_particles.gravity = Vector2(0, 100)
	mining_particles.scale_amount_min = 1.5
	mining_particles.scale_amount_max = 3
	mining_particles.color = Color(0.6, 0.4, 0.2, 0.8)  # 갈색 돌 파편
	add_child(mining_particles)
	
	
	# 스프라이트 원래 위치 저장
	if sprite:
		original_position = sprite.position

func _input(event):
	# 캐릭터가 영역 안에 있고 마우스 왼쪽 버튼 클릭 시
	if is_character_inside and event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			mouse_just_clicked = true

func _physics_process(delta):
	# 대기시간 처리
	if is_cooldown:
		cooldown_timer -= delta
		if cooldown_timer <= 0.0:
			is_cooldown = false
			cooldown_timer = 0.0
			print("바위 채굴 가능!")
	
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
	
	# 캐릭터가 영역 안에 있을 때
	if is_character_inside and not is_cooldown:
		# 설정된 채굴 키 입력 감지 (키를 누르는 순간만)
		var is_mining_key1_pressed = Input.is_key_pressed(Globals.mining_key1)
		var is_mining_key2_pressed = Input.is_key_pressed(Globals.mining_key2)
		
		# 키를 방금 눌렀는지 확인 (이전 프레임에는 안 눌렸고 현재 프레임에 눌림)
		var mining_key1_just_pressed = is_mining_key1_pressed and not was_mining_key1_pressed
		var mining_key2_just_pressed = is_mining_key2_pressed and not was_mining_key2_pressed
		
		# 이전 프레임 상태 업데이트
		was_mining_key1_pressed = is_mining_key1_pressed
		was_mining_key2_pressed = is_mining_key2_pressed
		
		# 채굴 키 또는 마우스 클릭으로 채굴 진행
		if mining_key1_just_pressed or mining_key2_just_pressed or mouse_just_clicked:
			# 채굴 진행 (클릭 한 번당 증가량)
			# 기본 1.0에 시간 배율(money_times)을 곱함
			var progress_per_click = 1.0 * (Globals.money_times / 100.0)
			now_time += progress_per_click
			
			# 마지막 클릭 시간 갱신
			last_hit_time = Time.get_ticks_msec() / 1000.0
			
			# 타이머 정지 (5초 대기 후 감소)
			go_down = false
			timer.stop()
			
			# 채굴 파티클 발생 (짧게)
			spawn_hit_particles(3)
			
			# 카메라 고정 (처음 채굴 시작 시)
			if not is_camera_locked:
				lock_camera()
			
			# 채굴 타이머 리셋
			time_since_last_mining = 0.0
			
			# 채굴 완료 체크
			if now_time >= max_time:
				complete_mining()
			
			# 마우스 클릭 플래그 리셋
			mouse_just_clicked = false
	
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

# 채굴 완료 함수
func complete_mining():
	# 피버 배율 적용
	var money_gained = int(Globals.money_up * Globals.fever_multiplier)
	Globals.money += money_gained
	
	# 초당 돈 증가 적용 (업그레이드 수치만큼 초당 수입에 추가)
	if Globals.money_per_second_upgrade > 0:
		Globals.money_per_second += Globals.money_per_second_upgrade
		print("💎 초당 수입 증가! +", Globals.money_per_second_upgrade, "원/초 (현재 총 ", Globals.money_per_second, "원/초)")
	
	# 피버 중이면 특별 메시지
	if Globals.is_fever_active:
		print("🔥 피버 채굴! +", money_gained, "원 (", Globals.fever_multiplier, "배), 현재 돈: ", Globals.money)
	else:
		print("돈 획득! +", money_gained, "원, 현재 돈: ", Globals.money)
	
	now_time = 0
	
	# 대기시간 없음 (즉시 다시 채굴 가능)
	
	# 완료 파티클 발생 (피버 중이면 색상 변경)
	if Globals.is_fever_active:
		complete_particles.color = Color(1.0, 0.3, 0.1)  # 빨강-주황 (피버)
	else:
		complete_particles.color = Color(1.0, 0.9, 0.3)  # 금색 (일반)
	
	# 파티클이 이미 발생 중이면 재시작
	complete_particles.restart()
	
	# 떠오르는 텍스트 생성
	spawn_floating_text("+" + str(money_gained) + "원")

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


func spawn_hit_particles(amount: int):
	var particles = CPUParticles2D.new()
	particles.emitting = false
	particles.one_shot = true
	particles.amount = amount
	particles.lifetime = 0.5
	particles.explosiveness = 0.8
	particles.direction = Vector2(0, -1)
	particles.spread = 45
	particles.initial_velocity_min = 50
	particles.initial_velocity_max = 100
	particles.gravity = Vector2(0, 200)
	particles.scale_amount_min = 2
	particles.scale_amount_max = 4
	particles.color = Color(0.6, 0.4, 0.2)  # 갈색 (돌 파편)
	add_child(particles)
	particles.emitting = true
	
	# 파티클이 끝나면 자동 삭제
	await get_tree().create_timer(particles.lifetime).timeout
	particles.queue_free()

# 떠오르는 텍스트 생성
func spawn_floating_text(text: String):
	# floating_text.gd의 정적 함수 사용
	var floating_text_script = load("res://floating_text.gd")
	if floating_text_script:
		# 금색으로 표시
		floating_text_script.create(self, Vector2(0, -20), text, Color(1.0, 0.9, 0.3))

func _on_area_2d_body_shape_entered(_body_rid, body, _body_shape_index, _local_shape_index):
	# 들어온 body가 CharacterBody2D 타입인지 확인
	if body is CharacterBody2D:
		is_character_inside = true
		print("캐릭터가 바위 영역에 들어왔습니다!")


func _on_area_2d_body_shape_exited(_body_rid, body, _body_shape_index, _local_shape_index):
	# 나간 body가 CharacterBody2D 타입인지 확인
	if body is CharacterBody2D:
		is_character_inside = false
		print("캐릭터가 바위 영역에서 나갔습니다!")
		
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
		print("카메라가 돌에 고정되었습니다!")

# 카메라 고정 해제
func unlock_camera():
	is_camera_locked = false
	time_since_last_mining = 0.0
	
	# 카메라에 신호 전송
	var camera = get_tree().get_first_node_in_group("camera")
	if camera and camera.has_method("unlock_from_target"):
		camera.unlock_from_target()
		print("카메라 고정이 해제되었습니다!")

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
