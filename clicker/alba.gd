extends Node2D

# 알바 데이터 리소스 (선택적 - 리소스 기반 설정 시 사용)
@export var alba_data: AlbaData

# 알바 스텟 (export로 설정)
@export var price: int = 600  # 구매 가격
@export var money_amount: int = 25  # 초당 돈 증가량 (기본)
# 프리셋 선택 (alba1/alba2 값을 한 씬에서 설정)
@export_enum("custom", "alba1", "alba2") var alba_preset: String = "custom"
# 에디터에서 선택할 알바 스킨 (단일 텍스처만 사용)
@export var alba_texture: Texture2D  # custom 스킨
@export_enum("alba1", "alba2", "custom") var alba_variant: String = "custom"
# 펫/스프라이트 크기 배율
@export var pet_scale: Vector2 = Vector2(1.0, 1.0)
# 펫 전체 크기 스케일 (단일 값)
@export var pet_scale_factor: float = 1.0
var pet_texture: Texture2D = null  # 상점(alba_buy)에서 전달받을 펫 텍스처

# 펫 노드 참조
var pet_sprite: Sprite2D = null
# 알바 인스턴스 순번 (1,2,3...)에 따라 펫 오프셋을 곱해 배치
var alba_order: int = 1
# === 펫 추적 설정 (스티어링 방식) ===
@export var pet_offset: Vector2 = Vector2(-40, -10)  # 캐릭터 기준 뒤쪽 위치
@export var max_speed: float = 180.0  # 최대 속도 (빠르게!)
@export var steering_force: float = 6.0  # 조향력 (민첩도)
@export var arrive_radius: float = 60.0  # 감속 시작 거리
@export var stop_radius: float = 15.0  # 정지 거리
@export var bob_amplitude: float = 6.0  # 둥둥 효과 크기
@export var bob_frequency: float = 2.5  # 둥둥 효과 속도
@export var flip_speed: float = 8.0  # 방향 전환 속도

# === 펫 내부 변수 ===
var time_elapsed: float = 0.0  # 둥둥 효과용 시간
var pet_velocity: Vector2 = Vector2.ZERO  # 펫의 현재 속도
var current_visual_scale_x: float = 1.0  # 좌우 반전용 스케일
var _last_facing_direction: int = 1  # 이전 바라보는 방향
var _pet_current_facing: int = 1  # 펫이 현재 사용 중인 방향

# 강화 시스템 (export로 설정 가능)
@export var upgrade_costs: Array[int] = [1000, 2000, 4000]  # 각 레벨별 강화 비용
@export var upgrade_incomes: Array[int] = [50, 100, 150]  # 각 레벨별 강화 후 수입

var upgrade_level: int = 0  # 현재 강화 레벨 (0 = 기본, 1~3 = 강화)

# Area2D 노드 참조
@onready var area_2d = $Area2D if has_node("Area2D") else null

# 플레이어가 영역 안에 있는지 추적
var is_character_inside: bool = false

# UI 노드 참조
var ui_node: Control = null

# 시각 효과용 스프라이트
@onready var sprite: Sprite2D = $Sprite2D if has_node("Sprite2D") else null


# 구매 가능 표시용 파티클
var glow_particles: CPUParticles2D

func _ready():
	# 프리셋 적용 (alba1/alba2 값을 이 스크립트에서 바로 설정)
	apply_alba_preset()
	
	# 알바 그룹에 추가하고 순번 계산
	add_to_group("alba")
	alba_order = get_tree().get_nodes_in_group("alba").size()
	
	# 초당 돈 증가량에 알바 수입 추가
	Globals.money_per_second += money_amount
	print("알바 고용 완료! 초당 수입 +", money_amount, ", 현재 초당 수입: ", Globals.money_per_second, "/초")
	
	# 스프라이트 텍스처 교체
	if sprite:
		var base_tex = _get_alba_texture()
		if base_tex:
			sprite.texture = base_tex
	# 스프라이트 크기 적용
	if sprite:
		sprite.scale = _get_pet_scale()
	
	# 펫 스프라이트 생성 (캐릭터 뒤를 따르게)
	create_pet_sprite()
	
	# Area2D 시그널 연결
	if area_2d:
		area_2d.body_entered.connect(_on_area_2d_body_entered)
		area_2d.body_exited.connect(_on_area_2d_body_exited)
	
	# UI 노드 찾기
	var parent = get_tree().current_scene
	if parent:
		var canvas_layer = parent.get_node_or_null("CanvasLayer")
		if canvas_layer:
			ui_node = canvas_layer.get_node_or_null("UI")
	
	# 구매 가능 표시 파티클 생성
	glow_particles = CPUParticles2D.new()
	glow_particles.emitting = true
	glow_particles.amount = 15
	glow_particles.lifetime = 1.2
	glow_particles.explosiveness = 0.0
	glow_particles.direction = Vector2(0, -1)
	glow_particles.spread = 180
	glow_particles.initial_velocity_min = 10
	glow_particles.initial_velocity_max = 20
	glow_particles.gravity = Vector2(0, -20)
	glow_particles.scale_amount_min = 2
	glow_particles.scale_amount_max = 3
	glow_particles.color = Color(0.3, 0.8, 1.0, 0.6)  # 파란색 (알바)
	glow_particles.visible = false
	add_child(glow_particles)
	
	# Globals Signal 구독	
	Globals.money_changed.connect(_on_money_changed)


func load_from_resource():
	if not alba_data:
		return
	
	# 가격 및 수입 정보
	price = alba_data.initial_price
	money_amount = alba_data.initial_income
	
	# 업그레이드 정보
	upgrade_costs = alba_data.upgrade_costs.duplicate()
	upgrade_incomes = alba_data.upgrade_incomes.duplicate()
	
	# 펫 설정
	pet_scale = alba_data.pet_scale
	pet_offset = alba_data.pet_offset
	
	print("✅ 알바 리소스 로드 완료: ", alba_data.alba_name)


func _process(_delta):
	# 펫 추적 업데이트
	update_pet_follow(_delta)
	
	# 구매 가능 여부에 따라 시각 효과 업데이트
	update_visual_feedback()
	
	# 플레이어가 영역 안에 있고 F키를 누르면 강화
	if is_character_inside and Input.is_action_just_pressed("f"):
		upgrade_alba()

# 현재 강화 비용 계산
func get_upgrade_cost() -> int:
	if upgrade_level < upgrade_costs.size():
		return upgrade_costs[upgrade_level]
	return -1  # MAX 레벨

# 강화 후 수입량 계산
func get_upgraded_income() -> int:
	if upgrade_level < upgrade_incomes.size():
		return upgrade_incomes[upgrade_level]
	return money_amount  # MAX 레벨이면 현재 수입 유지

# MAX 레벨 체크
func is_max_level() -> bool:
	return upgrade_level >= upgrade_costs.size()

# 알바 정보 텍스트 생성
func get_alba_info_text() -> String:
	# MAX 레벨 체크
	if is_max_level():
		return "알바 (MAX)\n현재 수입: %d/초\n더 이상 강화 불가" % money_amount
	
	var cost = get_upgrade_cost()
	var current_income = money_amount
	var next_income = get_upgraded_income()
	var income_increase = next_income - current_income
	
	return "알바 강화 (Lv.%d)\n가격: %d\n현재 수입: %d/초\n강화 후: %d/초 (+%d)" % [upgrade_level, cost, current_income, next_income, income_increase]

# 알바 강화
func upgrade_alba():
	# MAX 레벨 체크
	if is_max_level():
		print("이미 MAX 레벨입니다!")
		return
	
	var cost = get_upgrade_cost()
	
	# 돈이 충분한지 확인
	if Globals.money >= cost:
		# 돈 차감
		Globals.money -= cost
		print("알바 강화 차감: ", cost, ", 남은 돈: ", Globals.money)
		
		# 이전 수입량 제거
		Globals.money_per_second -= money_amount
		
		# 새로운 수입량 적용 (강화 전에 계산)
		money_amount = get_upgraded_income()
		
		# 강화 레벨 증가
		upgrade_level += 1
		
		# 새로운 수입량 추가
		Globals.money_per_second += money_amount
		
		print("알바 강화 완료! Lv.", upgrade_level, ", 초당 수입: ", money_amount, "/초")
		
		# 강화 효과 (반짝임)
		spawn_upgrade_effect()
		
		# 액션 텍스트 업데이트
		Globals.show_action_text(get_alba_info_text())
	else:
		print("부족! 필요: ", cost, ", 보유: ", Globals.money)

# 구매 가능 여부에 따른 시각 효과
func update_visual_feedback():
	# MAX 레벨이면 파티클 끄기
	if is_max_level():
		glow_particles.visible = false
		if sprite:
			sprite.modulate = Color(0.6, 0.6, 0.6)  # 회색 (MAX)
		return
	
	var cost = get_upgrade_cost()
	var can_afford = Globals.money >= cost
	
	# 구매 가능하면 파란색 파티클, 불가능하면 회색
	if can_afford:
		glow_particles.color = Color(0.3, 0.8, 1.0, 0.6)  # 파란색
		glow_particles.visible = true
		if sprite:
			sprite.modulate = Color(1.2, 1.2, 1.2)  # 밝게
	else:
		glow_particles.color = Color(0.5, 0.5, 0.5, 0.4)  # 회색
		glow_particles.visible = is_character_inside  # 플레이어가 가까이 있을 때만
		if sprite:
			sprite.modulate = Color(0.8, 0.8, 0.8)  # 어둡게

# 강화 시 반짝임 효과
func spawn_upgrade_effect():
	var particles = CPUParticles2D.new()
	particles.emitting = false
	particles.one_shot = true
	particles.amount = 25
	particles.lifetime = 0.8
	particles.explosiveness = 1.0
	particles.direction = Vector2(0, -1)
	particles.spread = 180
	particles.initial_velocity_min = 50
	particles.initial_velocity_max = 100
	particles.gravity = Vector2(0, -30)
	particles.scale_amount_min = 3
	particles.scale_amount_max = 5
	particles.color = Color(0.3, 0.8, 1.0)  # 파란색
	add_child(particles)
	particles.emitting = true
	
	# 스프라이트 펄스 효과
	if sprite:
		var tween = create_tween()
		tween.tween_property(sprite, "scale", Vector2(1.3, 1.3), 0.2)
		tween.tween_property(sprite, "scale", Vector2(1.0, 1.0), 0.2)
	
	# 파티클 자동 삭제
	await get_tree().create_timer(particles.lifetime).timeout
	particles.queue_free()

# 돈이 변경되었을 때 호출 (Signal)
func _on_money_changed(_new_amount: int, _delta: int):
	# 구매 가능 여부가 변경되었을 수 있으므로 시각 효과 업데이트
	update_visual_feedback()

# 플레이어가 영역에 들어왔을 때
func _on_area_2d_body_entered(body):
	if body is CharacterBody2D:
		is_character_inside = true
		print("플레이어가 알바 영역에 들어왔습니다!")
		
		# 액션 텍스트로 알바 정보 표시
		Globals.show_action_text(get_alba_info_text())

# 플레이어가 영역에서 나갔을 때
func _on_area_2d_body_exited(body):
	if body is CharacterBody2D:
		is_character_inside = false
		print("플레이어가 알바 영역에서 나갔습니다!")
		
		# 액션 텍스트 숨김
		Globals.hide_action_text()

# === 펫 관련 로직 ===

func create_pet_sprite():
	if pet_sprite:
		return
	if not Globals.player:
		# 플레이어가 아직 없으면 다음 프레임에 다시 시도
		call_deferred("create_pet_sprite")
		return
	
	# 펫 초기 방향 설정 (플레이어 방향과 동일)
	if "facing_direction" in Globals.player:
		_pet_current_facing = Globals.player.facing_direction
		_last_facing_direction = Globals.player.facing_direction
		current_visual_scale_x = float(_pet_current_facing)
	
	pet_sprite = Sprite2D.new()
	# 텍스처 우선순위: 상점 전달 텍스처 > alba_variant 스킨 > 현재 스프라이트 텍스처
	if pet_texture:
		pet_sprite.texture = pet_texture
	else:
		var base_tex = _get_alba_texture()
		if base_tex:
			pet_sprite.texture = base_tex
		elif sprite and sprite.texture:
			pet_sprite.texture = sprite.texture
	pet_sprite.z_index = Globals.player.z_index - 1
	add_child(pet_sprite)
	pet_sprite.scale = _get_pet_scale()
	# 시작 위치를 플레이어 뒤쪽으로 배치
	pet_sprite.global_position = Globals.player.global_position + get_facing_offset()

func update_pet_follow(delta: float):
	if not pet_sprite or not Globals.player:
		return
	
	time_elapsed += delta
	
	# 1. 둥둥 효과 (Y축 오프셋) 계산 - 각 펫마다 다른 위상
	var bob_offset = sin(time_elapsed * bob_frequency + alba_order * 0.8) * bob_amplitude
	
	# 2. 타겟 위치 계산 (순번별 오프셋 + 둥둥 효과 적용)
	var base_offset = get_facing_offset_for_direction(_pet_current_facing)
	var target = Globals.player.global_position + base_offset + Vector2(0, bob_offset)
	var distance = pet_sprite.global_position.distance_to(target)
	
	# 3. 스티어링 기반 이동
	var desired_velocity = Vector2.ZERO
	
	if distance > stop_radius:
		var direction = pet_sprite.global_position.direction_to(target)
		var speed_factor = clamp(distance / arrive_radius, 0.0, 1.0)
		desired_velocity = direction * max_speed * speed_factor
	
	var steering = (desired_velocity - pet_velocity) * steering_force * delta
	pet_velocity += steering
	
	# 실제 위치 업데이트
	pet_sprite.global_position += pet_velocity * delta
	
	# 4. 방향 전환 (기존 로직 유지)
	var player_dir = 1
	if "facing_direction" in Globals.player:
		player_dir = Globals.player.facing_direction
	
	update_pet_facing(player_dir, delta)

# 펫 방향 전환 처리
func update_pet_facing(player_dir: int, delta: float):
	# 플레이어 방향이 바뀌었는지 감지
	if player_dir != _last_facing_direction:
		_last_facing_direction = player_dir
		_pet_current_facing = player_dir
	
	# 즉시 방향 전환 (접히는 효과 없이)
	var target_scale_x = 1.0 if pet_velocity.x >= 0 else -1.0
	
	# 움직임이 있을 때만 방향 전환
	if abs(pet_velocity.x) > 5.0:
		current_visual_scale_x = target_scale_x  # 즉시 반전
	
	var base_scale = _get_pet_scale()
	pet_sprite.scale = Vector2(base_scale.x * current_visual_scale_x, base_scale.y)

# 캐릭터 바라보는 방향에 따라 펫 오프셋을 좌우로 전환한다.
func get_facing_offset() -> Vector2:
	var dir = 1
	if "facing_direction" in Globals.player:
		dir = Globals.player.facing_direction
	var dist = abs(pet_offset.x) * max(1, alba_order)
	return Vector2(-dir * dist, pet_offset.y)

# 지정한 방향에 따라 펫 오프셋을 계산한다.
func get_facing_offset_for_direction(dir: int) -> Vector2:
	var dist = abs(pet_offset.x) * max(1, alba_order)
	return Vector2(-dir * dist, pet_offset.y)

# 스케일을 최소값으로 보정하여 너무 작아지는 것을 방지
func _get_pet_scale() -> Vector2:
	var s = pet_scale * pet_scale_factor
	var min_scale = 0.05
	s.x = max(min_scale, abs(s.x))
	s.y = max(min_scale, abs(s.y))
	return s

# alba1/alba2 프리셋 값을 적용한다.
func apply_alba_preset():
	match alba_preset:
		"alba1":
			price = 2000
			money_amount = 50
			upgrade_costs = [2000, 3000, 4000]
			upgrade_incomes = [120, 200, 350]
		"alba2":
			price = 4000
			money_amount = 400
			upgrade_costs = [5000, 6000]
			upgrade_incomes = [600, 800]
		_:
			# custom은 에디터 값 그대로 사용
			pass

# 알바 스킨 선택
func _get_alba_texture() -> Texture2D:
	return alba_texture
