extends Control

@onready var label = $money
@onready var upgrade_thing = $upgrade_thing

# 돈 표시용 변수 (애니메이션을 위해)
var displayed_money : float = 0.0
var target_money : int = 0
var money_tween : Tween

# 티어 업 알림 레이블
var tier_notification : Label

# 초당 수입 표시 레이블
var income_label : Label
var passive_income_label : Label  # 초당 자동 수입 표시
var last_money : int = 0
var income_per_second : float = 0.0
var income_update_timer : float = 0.0
var passive_income_timer : float = 0.0  # 초당 수입 적용 타이머

# 피버 모드 표시
var fever_label : Label

# 액션바 표시
var action_bar_label : Label

func _ready():
	# Globals의 Signal 구독
	Globals.money_changed.connect(_on_money_changed)
	Globals.tier_up.connect(_on_tier_up)
	Globals.action_text_changed.connect(_on_action_text_changed)
	
	# 초기 돈 표시
	displayed_money = Globals.money
	target_money = Globals.money
	label.text = '$' + str(Globals.money)
	
	# 티어 업 알림 레이블 생성 (화면 중앙 살짝 아래, 액션바 스타일)
	tier_notification = Label.new()
	tier_notification.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tier_notification.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	tier_notification.position = Vector2(get_viewport_rect().size.x / 2 - 150, get_viewport_rect().size.y * 0.65)
	tier_notification.size = Vector2(300, 50)
	tier_notification.modulate = Color(1, 1, 1, 0)  # 투명하게 시작
	tier_notification.z_index = 1000
	# 폰트 크기 및 스타일
	tier_notification.add_theme_font_size_override("font_size", 32)
	add_child(tier_notification)
	
	# 초당 수입 표시 레이블 생성 (돈 표시 아래)
	income_label = Label.new()
	income_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	income_label.position = label.position + Vector2(0, 30)
	income_label.add_theme_font_size_override("font_size", 16)
	income_label.modulate = Color(0.7, 1.0, 0.7)  # 연한 초록색
	add_child(income_label)
	
	# 초당 자동 수입 표시 레이블 (초당 수입 표시 아래)
	passive_income_label = Label.new()
	passive_income_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	passive_income_label.position = label.position + Vector2(0, 50)
	passive_income_label.add_theme_font_size_override("font_size", 14)
	passive_income_label.modulate = Color(1.0, 0.9, 0.3)  # 금색
	add_child(passive_income_label)
	
	# 피버 모드 표시 레이블 (화면 상단 중앙)
	fever_label = Label.new()
	fever_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	fever_label.position = Vector2(get_viewport_rect().size.x / 2 - 150, 50)
	fever_label.size = Vector2(300, 40)
	fever_label.add_theme_font_size_override("font_size", 28)
	fever_label.modulate = Color(1, 1, 1, 0)  # 투명하게 시작
	fever_label.z_index = 1000
	add_child(fever_label)
	
	# 액션바 레이블 (화면 하단 중앙)
	action_bar_label = Label.new()
	action_bar_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	action_bar_label.position = Vector2(get_viewport_rect().size.x / 2 - 150, get_viewport_rect().size.y - 100)
	action_bar_label.size = Vector2(300, 40)
	action_bar_label.add_theme_font_size_override("font_size", 24)
	action_bar_label.modulate = Color(1, 1, 1, 0)  # 투명하게 시작
	action_bar_label.z_index = 1000
	add_child(action_bar_label)
	
	# 초기 수입 계산
	last_money = Globals.money

func _process(delta):
	# 부드러운 돈 증가 애니메이션 (Tween 없이 수동으로)
	if displayed_money != target_money:
		var diff = target_money - displayed_money
		# 차이가 크면 빠르게, 작으면 천천히
		var speed = max(abs(diff) * 5.0, 10.0)
		displayed_money = move_toward(displayed_money, target_money, speed * delta)
		label.text = '$' + str(int(displayed_money))
	
	# 초당 수입 적용 (money_per_second)
	passive_income_timer += delta
	if passive_income_timer >= 1.0:
		if Globals.money_per_second > 0:
			# 피버 배율 적용
			var passive_income = int(Globals.money_per_second * Globals.fever_multiplier)
			Globals.money += passive_income
		passive_income_timer = 0.0
	
	# 초당 수입 계산 (1초마다 업데이트)
	income_update_timer += delta
	if income_update_timer >= 1.0:
		var money_diff = Globals.money - last_money
		income_per_second = money_diff
		last_money = Globals.money
		income_update_timer = 0.0
		
		# 초당 수입 표시 업데이트
		if income_per_second > 0:
			income_label.text = "💰 +" + str(int(income_per_second)) + "/초"
			income_label.modulate = Color(0.7, 1.0, 0.7)  # 초록색
		elif income_per_second < 0:
			income_label.text = "💸 " + str(int(income_per_second)) + "/초"
			income_label.modulate = Color(1.0, 0.5, 0.5)  # 빨간색
		else:
			income_label.text = "💤 0/초"
			income_label.modulate = Color(0.7, 0.7, 0.7)  # 회색
	
	# 초당 자동 수입 표시 업데이트
	if Globals.money_per_second > 0:
		var actual_passive = int(Globals.money_per_second * Globals.fever_multiplier)
		passive_income_label.text = "⚡ 자동 수입: +" + str(actual_passive) + "/초"
		# 피버 중이면 색상 변경
		if Globals.is_fever_active:
			passive_income_label.modulate = Color(1.0, 0.5, 0.2)  # 주황색
		else:
			passive_income_label.modulate = Color(1.0, 0.9, 0.3)  # 금색
	else:
		passive_income_label.text = ""
	
	# 피버 모드 표시 업데이트
	if Globals.is_fever_active:
		fever_label.text = "🔥 FEVER x" + str(Globals.fever_multiplier) + " 🔥"
		# 펄스 효과
		var pulse = 1.0 + sin(Time.get_ticks_msec() / 100.0) * 0.1
		fever_label.scale = Vector2(pulse, pulse)
		# 색상 변화 (빨강-주황)
		var color_shift = (sin(Time.get_ticks_msec() / 200.0) + 1.0) / 2.0
		fever_label.modulate = Color(1.0, 0.3 + color_shift * 0.4, 0.1, 1.0)
	else:
		fever_label.modulate = Color(1, 1, 1, 0)  # 투명

# 돈이 변경되었을 때 호출되는 콜백
func _on_money_changed(new_amount: int, delta_money: int):
	target_money = new_amount
	
	# 돈이 증가했을 때 약간의 스케일 효과
	if delta_money > 0:
		var tween = create_tween()
		tween.tween_property(label, "scale", Vector2(1.2, 1.2), 0.1)
		tween.tween_property(label, "scale", Vector2(1.0, 1.0), 0.1)

# 티어가 올라갔을 때 호출되는 콜백
func _on_tier_up(new_tier: int):
	# 티어 업 알림 표시 (액션바 스타일)
	tier_notification.text = "🎉 티어 " + str(new_tier) + " 달성! 🎉"
	
	# 페이드 인 → 유지 → 페이드 아웃
	var tween = create_tween()
	tween.tween_property(tier_notification, "modulate:a", 1.0, 0.3)
	tween.tween_interval(2.0)
	tween.tween_property(tier_notification, "modulate:a", 0.0, 0.5)
	
	# 약간의 위아래 움직임 효과
	var move_tween = create_tween()
	var original_y = tier_notification.position.y
	move_tween.tween_property(tier_notification, "position:y", original_y - 10, 0.3)
	move_tween.tween_property(tier_notification, "position:y", original_y, 0.3)

# 액션 텍스트가 변경되었을 때 호출되는 콜백
func _on_action_text_changed(text: String, should_show: bool):
	if should_show:
		action_bar_label.text = text
		# 페이드 인
		var tween = create_tween()
		tween.tween_property(action_bar_label, "modulate:a", 1.0, 0.2)
	else:
		# 페이드 아웃
		var tween = create_tween()
		tween.tween_property(action_bar_label, "modulate:a", 0.0, 0.2)
