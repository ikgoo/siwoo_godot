extends Node2D

# 알바 스텟 (export로 설정)
@export var price: int = 100  # 구매 가격
@export var money_amount: int = 1  # 초당 돈 증가량

# 강화 시스템
var upgrade_level: int = 0  # 현재 강화 레벨
var base_money_amount: int = 1  # 기본 수입량
var upgrade_cost_multiplier: float = 2.0  # 강화 비용 배율

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
	# 기본 수입량 저장
	base_money_amount = money_amount
	
	# 초당 돈 증가량에 알바 수입 추가
	Globals.money_per_second += money_amount
	print("알바 고용 완료! 초당 수입 +", money_amount, "원, 현재 초당 수입: ", Globals.money_per_second, "원/초")
	
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
	# 구매 가능 여부에 따라 시각 효과 업데이트
	update_visual_feedback()
	
	# 플레이어가 영역 안에 있고 F키를 누르면 강화
	if is_character_inside and Input.is_action_just_pressed("f"):
		upgrade_alba()

# 현재 강화 비용 계산
func get_upgrade_cost() -> int:
	return int(price * pow(upgrade_cost_multiplier, upgrade_level))

# 강화 후 수입량 계산
func get_upgraded_income() -> int:
	return base_money_amount * (upgrade_level + 2)  # 레벨 0: 2배, 레벨 1: 3배, ...

# 알바 정보 텍스트 생성
func get_alba_info_text() -> String:
	var cost = get_upgrade_cost()
	var current_income = money_amount
	var next_income = get_upgraded_income()
	var income_increase = next_income - current_income
	
	return "알바 강화 (Lv.%d)\n가격: %d원\n현재 수입: %d원/초\n강화 후: %d원/초 (+%d)" % [upgrade_level, cost, current_income, next_income, income_increase]

# 알바 강화
func upgrade_alba():
	var cost = get_upgrade_cost()
	
	# 돈이 충분한지 확인
	if Globals.money >= cost:
		# 돈 차감
		Globals.money -= cost
		print("알바 강화 비용 차감: ", cost, "원, 남은 돈: ", Globals.money)
		
		# 이전 수입량 제거
		Globals.money_per_second -= money_amount
		
		# 강화 레벨 증가
		upgrade_level += 1
		
		# 새로운 수입량 계산
		money_amount = get_upgraded_income()
		
		# 새로운 수입량 추가
		Globals.money_per_second += money_amount
		
		print("알바 강화 완료! Lv.", upgrade_level, ", 초당 수입: ", money_amount, "원/초")
		
		# 강화 효과 (반짝임)
		spawn_upgrade_effect()
		
		# UI 업데이트
		if ui_node and ui_node.has_node("upgrade_thing"):
			var upgrade_label = ui_node.get_node("upgrade_thing")
			upgrade_label.text = get_alba_info_text()
	else:
		print("돈이 부족합니다! 필요: ", cost, "원, 보유: ", Globals.money, "원")

# 구매 가능 여부에 따른 시각 효과
func update_visual_feedback():
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
		
		# UI에 알바 정보 표시
		if ui_node and ui_node.has_node("upgrade_thing"):
			var upgrade_label = ui_node.get_node("upgrade_thing")
			upgrade_label.text = get_alba_info_text()

# 플레이어가 영역에서 나갔을 때
func _on_area_2d_body_exited(body):
	if body is CharacterBody2D:
		is_character_inside = false
		print("플레이어가 알바 영역에서 나갔습니다!")
		
		# UI 알바 정보 초기화
		if ui_node and ui_node.has_node("upgrade_thing"):
			var upgrade_label = ui_node.get_node("upgrade_thing")
			upgrade_label.text = ""
