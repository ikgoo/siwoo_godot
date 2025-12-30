extends Node2D

enum upgrade {
	money_up,
	money_time,
	money_randomize,
	money_per_second  # 초당 돈 증가 (광물 채굴 시 증가)
}
@export var type : upgrade

# 현재 업그레이드 단계 (0부터 시작)
var current_level: int = 0

# 현재 업그레이드 단계의 비용 가져오기
func get_current_cost() -> int:
	match type:
		upgrade.money_time:  # 곡괭이 속도 (pv)
			if current_level < Globals.pickaxe_speed_costs.size():
				return Globals.pickaxe_speed_costs[current_level]
			else:
				return -1  # MAX
		upgrade.money_up:  # 다이아몬드 획득량 (dv)
			if current_level < Globals.diamond_value_upgrades.size():
				return Globals.diamond_value_upgrades[current_level].x
			else:
				return -1  # MAX
		upgrade.money_per_second:  # 초당 다이아몬드 (da)
			if current_level < Globals.diamond_per_second_upgrades.size():
				return Globals.diamond_per_second_upgrades[current_level].x
			else:
				return -1  # MAX
		_:
			return 0

# 현재 업그레이드 단계의 증가량 가져오기 (표시용)
func get_current_increment() -> int:
	match type:
		upgrade.money_time:  # 곡괭이 속도는 레벨당 +10
			return 10
		upgrade.money_up:  # 다이아몬드 획득량
			if current_level < Globals.diamond_value_upgrades.size():
				return Globals.diamond_value_upgrades[current_level].y
			else:
				return 800  # MAX
		upgrade.money_per_second:  # 초당 다이아몬드
			if current_level < Globals.diamond_per_second_upgrades.size():
				return Globals.diamond_per_second_upgrades[current_level].y
			else:
				return 25  # MAX
		_:
			return 0

# Area2D 노드 참조
@onready var area_2d = $Area2D2

# 플레이어가 영역 안에 있는지 추적하는 변수
var is_character_inside: bool = false

# UI 노드 참조
var ui_node: Control = null

# 시각 효과용 스프라이트 (있다면)
@onready var sprite: Sprite2D = $Sprite2D if has_node("Sprite2D") else null

# 구매 가능 여부 표시용 파티클
var glow_particles: CPUParticles2D

func _ready():
	# Area2D의 body_shape_entered/exited 시그널 연결
	if area_2d:
		area_2d.body_shape_entered.connect(_on_area_2d_body_shape_entered)
		area_2d.body_shape_exited.connect(_on_area_2d_body_shape_exited)
	
	# UI 노드 찾기 (CanvasLayer/UI 경로)
	var parent = get_tree().current_scene
	if parent:
		var canvas_layer = parent.get_node_or_null("CanvasLayer")
		if canvas_layer:
			ui_node = canvas_layer.get_node_or_null("UI")
	
	# 구매 가능 표시 파티클 생성
	glow_particles = CPUParticles2D.new()
	glow_particles.emitting = true
	glow_particles.amount = 20
	glow_particles.lifetime = 1.5
	glow_particles.explosiveness = 0.0
	glow_particles.direction = Vector2(0, -1)
	glow_particles.spread = 180
	glow_particles.initial_velocity_min = 10
	glow_particles.initial_velocity_max = 20
	glow_particles.gravity = Vector2(0, -20)
	glow_particles.scale_amount_min = 2
	glow_particles.scale_amount_max = 4
	glow_particles.color = Color(0.3, 1.0, 0.3, 0.6)  # 초록색 (구매 가능)
	glow_particles.visible = false
	add_child(glow_particles)
	
	# Globals Signal 구독
	Globals.money_changed.connect(_on_money_changed)

# 업그레이드 정보 텍스트 생성
func get_upgrade_info_text() -> String:
	var cost = get_current_cost()
	
	# MAX 레벨 체크
	var is_max = false
	match type:
		upgrade.money_time:  # 곡괭이 속도
			is_max = (current_level >= Globals.pickaxe_speed_costs.size())
		upgrade.money_up:  # 다이아몬드 획득량
			is_max = (current_level >= Globals.diamond_value_upgrades.size())
		upgrade.money_per_second:  # 초당 다이아몬드
			is_max = (current_level >= Globals.diamond_per_second_upgrades.size())
	
	if is_max or cost == -1:
		return "MAX"
	
	var type_name = ""
	var effect_text = ""
	
	match type:
		upgrade.money_up:
			type_name = "다이아몬드 획득량"
			var new_value = Globals.diamond_value_upgrades[current_level].y
			effect_text = "획득량: %d" % new_value
		upgrade.money_time:
			type_name = "곡괭이 속도"
			var new_speed = 100.0 + ((current_level + 1) * 10.0)
			effect_text = "속도: %.0f" % new_speed
		upgrade.money_randomize:
			type_name = "랜덤"
			effect_text = "미구현"
		upgrade.money_per_second:
			type_name = "초당 다이아몬드"
			var new_value = Globals.diamond_per_second_upgrades[current_level].y
			effect_text = "추가량: +%d/초" % new_value
	
	return "가격: %d원\n효과: %s\n%s" % [cost, type_name, effect_text]

# 업그레이드 처리
func _process(_delta):
	# 구매 가능 여부에 따라 시각 효과 업데이트
	update_visual_feedback()
	
	# 플레이어가 영역 안에 있고 F키를 누르면 업그레이드
	if is_character_inside and Input.is_action_just_pressed("f"):
		# 현재 단계의 비용 가져오기
		var cost = get_current_cost()
		
		# MAX 레벨 체크
		if cost == -1:
			print("이미 최대 레벨입니다!")
			return
		
		# 돈이 충분한지 확인
		if Globals.money >= cost:
			# 돈 차감
			Globals.money -= cost
			print("돈 차감: ", cost, "원, 남은 돈: ", Globals.money)
			
			# 구매 효과 (반짝임)
			spawn_purchase_effect()
			
			# 타입에 따라 업그레이드 적용
			match type:
				upgrade.money_up:
					# 다이아몬드 획득량 레벨 증가
					Globals.diamond_value_level += 1
					Globals.update_diamond_value()
					print("업그레이드 완료! 다이아몬드 획득량 Lv ", Globals.diamond_value_level, " (획득량: ", Globals.money_up, ")")
				upgrade.money_time:
					# 곡괭이 속도 레벨 증가
					Globals.pickaxe_speed_level += 1
					Globals.update_pickaxe_speed()
					print("업그레이드 완료! 곡괭이 속도 Lv ", Globals.pickaxe_speed_level, " (속도: ", Globals.money_times, ")")
				upgrade.money_randomize:
					# 미구현
					print("money_randomize 업그레이드는 아직 구현되지 않았습니다.")
				upgrade.money_per_second:
					# 초당 다이아몬드 레벨 증가
					Globals.diamond_per_second_level += 1
					Globals.update_diamond_per_second()
					print("업그레이드 완료! 초당 다이아몬드 Lv ", Globals.diamond_per_second_level, " (추가량: +", Globals.money_per_second_upgrade, "/초)")
			
			# 업그레이드 단계 증가
			current_level += 1
			
			# UI 업데이트 (다음 단계 정보 표시)
			if ui_node and ui_node.has_node("upgrade_thing"):
				var upgrade_label = ui_node.get_node("upgrade_thing")
				upgrade_label.text = get_upgrade_info_text()
		else:
			print("돈이 부족합니다! 필요: ", cost, "원, 보유: ", Globals.money, "원")

# 구매 가능 여부에 따른 시각 효과
func update_visual_feedback():
	# MAX 레벨 체크
	var is_max = false
	match type:
		upgrade.money_time:
			is_max = (current_level >= Globals.pickaxe_speed_costs.size())
		upgrade.money_up:
			is_max = (current_level >= Globals.diamond_value_upgrades.size())
		upgrade.money_per_second:
			is_max = (current_level >= Globals.diamond_per_second_upgrades.size())
	
	# 마지막 단계면 파티클 끄기
	if is_max:
		glow_particles.visible = false
		if sprite:
			sprite.modulate = Color(0.5, 0.5, 0.5)  # 회색 (MAX)
		return
	
	var cost = get_current_cost()
	var can_afford = Globals.money >= cost
	
	# 구매 가능하면 초록색 파티클, 불가능하면 빨간색
	if can_afford:
		glow_particles.color = Color(0.3, 1.0, 0.3, 0.6)  # 초록색
		glow_particles.visible = true
		if sprite:
			sprite.modulate = Color(1.2, 1.2, 1.2)  # 밝게
	else:
		glow_particles.color = Color(1.0, 0.3, 0.3, 0.4)  # 빨간색
		glow_particles.visible = is_character_inside  # 플레이어가 가까이 있을 때만
		if sprite:
			sprite.modulate = Color(0.8, 0.8, 0.8)  # 어둡게

# 구매 시 반짝임 효과
func spawn_purchase_effect():
	var particles = CPUParticles2D.new()
	particles.emitting = false
	particles.one_shot = true
	particles.amount = 30
	particles.lifetime = 1.0
	particles.explosiveness = 1.0
	particles.direction = Vector2(0, -1)
	particles.spread = 180
	particles.initial_velocity_min = 50
	particles.initial_velocity_max = 120
	particles.gravity = Vector2(0, -50)
	particles.scale_amount_min = 3
	particles.scale_amount_max = 6
	particles.color = Color(1, 1, 0.3)  # 금색
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
func _on_area_2d_body_shape_entered(_body_rid, body, _body_shape_index, _local_shape_index):
	# 들어온 body가 CharacterBody2D 타입인지 확인
	if body is CharacterBody2D:
		is_character_inside = true
		print("플레이어가 업그레이드 영역에 들어왔습니다!")
		
		# UI에 업그레이드 정보 표시
		if ui_node and ui_node.has_method("set_upgrade_info"):
			ui_node.set_upgrade_info(get_upgrade_info_text())
		elif ui_node and ui_node.has_node("upgrade_thing"):
			var upgrade_label = ui_node.get_node("upgrade_thing")
			upgrade_label.text = get_upgrade_info_text()

# 플레이어가 영역에서 나갔을 때
func _on_area_2d_body_shape_exited(_body_rid, body, _body_shape_index, _local_shape_index):
	# 나간 body가 CharacterBody2D 타입인지 확인
	if body is CharacterBody2D:
		is_character_inside = false
		print("플레이어가 업그레이드 영역에서 나갔습니다!")
		
		# UI 업그레이드 정보 초기화
		if ui_node and ui_node.has_method("clear_upgrade_info"):
			ui_node.clear_upgrade_info()
		elif ui_node and ui_node.has_node("upgrade_thing"):
			var upgrade_label = ui_node.get_node("upgrade_thing")
			upgrade_label.text = ""
