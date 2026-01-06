extends Node2D

# 알바 스텟 (export로 설정)
@export var price: int = 2000  # 구매 가격
@export var money_amount: int = 50  # 초당 돈 증가량 (기본)
# 에디터에서 지정할 커스텀 이미지
@export var alba_texture: Texture2D
# 펫/스프라이트 크기 배율
@export var pet_scale: Vector2 = Vector2(1.0, 1.0)
# 펫 전체 크기 스케일 (단일 값)
@export var pet_scale_factor: float = 1.0
# 펫 텍스처 (없으면 알바 스프라이트 재사용)
@export var pet_texture: Texture2D

# 펫 노드 참조
var pet_sprite: Sprite2D = null
# 알바 인스턴스 순번 (1,2,3...)에 따라 펫 오프셋을 곱해 배치
var alba_order: int = 1
# 펫 추적 설정
@export var pet_offset: Vector2 = Vector2(-40, -10)  # 캐릭터 기준 뒤쪽 위치
@export var pet_follow_speed: float = 5.0  # 따라오는 속도 (높을수록 빠름)

# 강화 시스템 (export로 설정 가능)
@export var upgrade_costs: Array[int] = [2000, 3000, 4000]  # 각 레벨별 강화 비용
@export var upgrade_incomes: Array[int] = [120, 200, 350]  # 각 레벨별 강화 후 수입

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
	# 알바 그룹에 추가하고 순번 계산
	add_to_group("alba")
	alba_order = get_tree().get_nodes_in_group("alba").size()
	
	# 초당 돈 증가량에 알바 수입 추가
	Globals.money_per_second += money_amount
	print("알바 고용 완료! 초당 수입 +💎", money_amount, ", 현재 초당 수입: 💎", Globals.money_per_second, "/초")
	
	# 스프라이트 텍스처 교체
	if sprite and alba_texture:
		sprite.texture = alba_texture
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
		return "알바 (MAX)\n현재 수입: 💎%d/초\n더 이상 강화 불가" % money_amount
	
	var cost = get_upgrade_cost()
	var current_income = money_amount
	var next_income = get_upgraded_income()
	var income_increase = next_income - current_income
	
	return "알바 강화 (Lv.%d)\n가격: 💎%d\n현재 수입: 💎%d/초\n강화 후: 💎%d/초 (+%d)" % [upgrade_level, cost, current_income, next_income, income_increase]

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
		print("알바 강화 💎 차감: ", cost, ", 남은 돈: 💎", Globals.money)
		
		# 이전 수입량 제거
		Globals.money_per_second -= money_amount
		
		# 새로운 수입량 적용 (강화 전에 계산)
		money_amount = get_upgraded_income()
		
		# 강화 레벨 증가
		upgrade_level += 1
		
		# 새로운 수입량 추가
		Globals.money_per_second += money_amount
		
		print("알바 강화 완료! Lv.", upgrade_level, ", 초당 수입: 💎", money_amount, "/초")
		
		# 강화 효과 (반짝임)
		spawn_upgrade_effect()
		
		# 액션 텍스트 업데이트
		Globals.show_action_text(get_alba_info_text())
	else:
		print("💎 부족! 필요: 💎", cost, ", 보유: 💎", Globals.money)

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
	pet_sprite = Sprite2D.new()
	# 텍스처 우선순위: pet_texture > alba_texture > sprite.texture
	if pet_texture:
		pet_sprite.texture = pet_texture
	elif alba_texture:
		pet_sprite.texture = alba_texture
	elif sprite:
		pet_sprite.texture = sprite.texture
	pet_sprite.z_index = Globals.player.z_index - 1
	add_child(pet_sprite)
	pet_sprite.scale = _get_pet_scale()
	# 시작 위치를 플레이어 뒤쪽으로 배치
	pet_sprite.global_position = Globals.player.global_position + get_facing_offset()

func update_pet_follow(delta: float):
	if not pet_sprite or not Globals.player:
		return
	var target_pos = Globals.player.global_position + get_facing_offset()
	var t = clamp(pet_follow_speed * delta, 0.0, 1.0)
	pet_sprite.global_position = pet_sprite.global_position.lerp(target_pos, t)
	
	# 캐릭터가 좌우를 바라보는 속성이 있으면 펫도 반전
	if "facing_direction" in Globals.player:
		pet_sprite.flip_h = Globals.player.facing_direction < 0

# 캐릭터 바라보는 방향에 따라 펫 오프셋을 좌우로 전환한다.
func get_facing_offset() -> Vector2:
	var dir = 1
	if "facing_direction" in Globals.player:
		dir = Globals.player.facing_direction
	var dist = abs(pet_offset.x) * max(1, alba_order)
	return Vector2(-dir * dist, pet_offset.y)

# 스케일을 최소값으로 보정하여 너무 작아지는 것을 방지
func _get_pet_scale() -> Vector2:
	var s = pet_scale * pet_scale_factor
	var min_scale = 0.05
	s.x = max(min_scale, abs(s.x))
	s.y = max(min_scale, abs(s.y))
	return s
