extends Control

# 폰트 로드
const GALMURI_9 = preload("res://Galmuri9.ttf")

@onready var label = $money
@onready var upgrade_thing = $upgrade_thing
@onready var action_bar_label = $upgrade_thing
@onready var setting_button = $SettingButton
@onready var setting_panel = $SettingPanel
@onready var key1_input = $SettingPanel/VBoxContainer/Key1Container/Key1Input
@onready var key2_input = $SettingPanel/VBoxContainer/Key2Container/Key2Input
@onready var close_button = $SettingPanel/VBoxContainer/CloseButton
@onready var vbox_container = $SettingPanel/VBoxContainer

# ESC 메뉴 (씬 파일에서 로드)
var esc_menu: Panel = null
const ESC_MENU_SCENE = preload("res://esc_menu.tscn")

# 동적으로 생성된 키 입력 필드들
var key_inputs: Array[LineEdit] = []
var key_containers: Array[HBoxContainer] = []

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

# 플레이 시간 표시
var playtime_label : Label
var playtime_seconds : float = 0.0  # 플레이 시간 (초)

# 채굴 키 설정
var waiting_for_key : LineEdit = null  # 키 입력 대기 중인 입력 필드
var waiting_for_key_index : int = -1  # 어떤 키 인덱스를 변경 중인지
var last_key_count : int = 2  # 이전에 표시된 키 개수 (업데이트 감지용)

func _ready():
	# UI 그룹에 추가 (wall.gd에서 숨기기/보이기 위해)
	add_to_group("ui")
	
	# 부모 CanvasLayer도 ui 그룹에 추가
	if get_parent():
		get_parent().add_to_group("ui")
	
	# Globals의 Signal 구독
	Globals.money_changed.connect(_on_money_changed)
	Globals.tier_up.connect(_on_tier_up)
	Globals.action_text_changed.connect(_on_action_text_changed)
	
	# 초기 돈 표시
	displayed_money = Globals.money
	target_money = Globals.money
	label.text = '💎' + str(Globals.money)
	
	# 티어 업 알림 레이블 생성 (화면 중앙 살짝 아래, 액션바 스타일)
	tier_notification = Label.new()
	tier_notification.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tier_notification.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	tier_notification.position = Vector2(get_viewport_rect().size.x / 2 - 150, get_viewport_rect().size.y * 0.65)
	tier_notification.size = Vector2(300, 50)
	tier_notification.modulate = Color(1, 1, 1, 0)  # 투명하게 시작
	tier_notification.z_index = 1000
	# 폰트 크기 및 스타일
	tier_notification.add_theme_font_override("font", GALMURI_9)
	tier_notification.add_theme_font_size_override("font_size", 32)
	add_child(tier_notification)
	
	# 초당 수입 표시 레이블 생성 (돈 표시 아래)
	income_label = Label.new()
	income_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	income_label.position = label.position + Vector2(0, 30)
	income_label.add_theme_font_override("font", GALMURI_9)
	income_label.add_theme_font_size_override("font_size", 16)
	income_label.modulate = Color(0.7, 1.0, 0.7)  # 연한 초록색
	add_child(income_label)
	
	# 초당 자동 수입 표시 레이블 (초당 수입 표시 아래)
	passive_income_label = Label.new()
	passive_income_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	passive_income_label.position = label.position + Vector2(0, 50)
	passive_income_label.add_theme_font_override("font", GALMURI_9)
	passive_income_label.add_theme_font_size_override("font_size", 14)
	passive_income_label.modulate = Color(1.0, 0.9, 0.3)  # 금색
	add_child(passive_income_label)
	
	# 피버 모드 표시 레이블 (화면 상단 중앙)
	fever_label = Label.new()
	fever_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	fever_label.position = Vector2(get_viewport_rect().size.x / 2 - 150, 50)
	fever_label.size = Vector2(300, 40)
	fever_label.add_theme_font_override("font", GALMURI_9)
	fever_label.add_theme_font_size_override("font_size", 28)
	fever_label.modulate = Color(1, 1, 1, 0)  # 투명하게 시작
	fever_label.z_index = 1000
	add_child(fever_label)
	
	# 액션바는 tscn의 upgrade_thing 사용 (이미 @onready로 참조됨)
	action_bar_label.modulate = Color(1, 1, 1, 0)  # 투명하게 시작
	
	# 플레이 시간 레이블 (오른쪽 상단)
	playtime_label = Label.new()
	playtime_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	playtime_label.position = Vector2(get_viewport_rect().size.x - 150, 10)
	playtime_label.size = Vector2(140, 30)
	playtime_label.add_theme_font_override("font", GALMURI_9)
	playtime_label.add_theme_font_size_override("font_size", 18)
	playtime_label.modulate = Color(0.9, 0.9, 0.9)  # 연한 회색
	playtime_label.text = "00:00:00"
	add_child(playtime_label)
	
	# 초기 수입 계산
	last_money = Globals.money
	
	# 설정 버튼 연결
	setting_button.pressed.connect(_on_setting_button_pressed)
	close_button.pressed.connect(_on_close_button_pressed)
	
	# 기존 Key1, Key2 입력 필드를 배열에 추가
	key_inputs.append(key1_input)
	key_inputs.append(key2_input)
	
	# 키 입력 필드 클릭 시 키 대기 모드
	key1_input.gui_input.connect(func(event): _on_key_input_gui_input(event, 0))
	key2_input.gui_input.connect(func(event): _on_key_input_gui_input(event, 1))
	
	# 초기 키 이름 표시
	key1_input.text = OS.get_keycode_string(Globals.all_mining_keys[0])
	key2_input.text = OS.get_keycode_string(Globals.all_mining_keys[1])
	
	# 추가 키 입력 UI 생성
	update_key_settings_ui()
	
	# ESC 메뉴 씬 로드
	load_esc_menu()

func _process(delta):
	# 키 개수가 변경되었으면 UI 업데이트
	if last_key_count != Globals.mining_key_count:
		update_key_settings_ui()
		last_key_count = Globals.mining_key_count
	
	# 플레이 시간 업데이트
	playtime_seconds += delta
	playtime_label.text = format_playtime(playtime_seconds)
	
	# 부드러운 돈 증가 애니메이션 (Tween 없이 수동으로)
	if displayed_money != target_money:
		var diff = target_money - displayed_money
		# 차이가 크면 빠르게, 작으면 천천히
		var speed = max(abs(diff) * 5.0, 10.0)
		displayed_money = move_toward(displayed_money, target_money, speed * delta)
		label.text = '💎' + str(int(displayed_money))
	
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
			income_label.text = "+" + str(int(income_per_second)) + "/초"
			income_label.modulate = Color(0.7, 1.0, 0.7)  # 초록색
		elif income_per_second < 0:
			income_label.text = str(int(income_per_second)) + "/초"
			income_label.modulate = Color(1.0, 0.5, 0.5)  # 빨간색
		else:
			income_label.text = "0/초"
			income_label.modulate = Color(0.7, 0.7, 0.7)  # 회색
	
	# 초당 자동 수입 표시 업데이트
	if Globals.money_per_second > 0:
		var actual_passive = int(Globals.money_per_second * Globals.fever_multiplier)
		passive_income_label.text = "자동 수입: +" + str(actual_passive) + "/초"
		# 피버 중이면 색상 변경
		if Globals.is_fever_active:
			passive_income_label.modulate = Color(1.0, 0.5, 0.2)  # 주황색
		else:
			passive_income_label.modulate = Color(1.0, 0.9, 0.3)  # 금색
	else:
		passive_income_label.text = ""
	
	# 피버 모드 표시 업데이트
	if Globals.is_fever_active:
		fever_label.text = "FEVER x" + str(Globals.fever_multiplier)
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
	
	# 돈이 증가했을 때 중앙 기점으로 커졌다 작아지는 효과
	if delta_money > 0:
		# pivot_offset을 중앙으로 설정
		label.pivot_offset = label.size / 2.0
		
		var tween = create_tween()
		tween.set_ease(Tween.EASE_OUT)
		tween.set_trans(Tween.TRANS_BACK)
		tween.tween_property(label, "scale", Vector2(1.3, 1.3), 0.15)
		tween.set_ease(Tween.EASE_IN_OUT)
		tween.set_trans(Tween.TRANS_QUAD)
		tween.tween_property(label, "scale", Vector2(1.0, 1.0), 0.2)

# 티어가 올라갔을 때 호출되는 콜백
func _on_tier_up(new_tier: int):
	# 티어 업 알림 표시 (액션바 스타일)
	tier_notification.text = "티어 " + str(new_tier) + " 달성!"
	
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

# 설정 버튼 클릭
func _on_setting_button_pressed():
	setting_panel.visible = true

# 닫기 버튼 클릭
func _on_close_button_pressed():
	setting_panel.visible = false
	waiting_for_key = null

# 키 입력 필드 클릭 (범용)
func _on_key_input_gui_input(event: InputEvent, key_index: int):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if key_index < key_inputs.size():
			waiting_for_key = key_inputs[key_index]
			waiting_for_key_index = key_index
			key_inputs[key_index].text = "키를 누르세요..."

# 사용 불가능한 키 목록 (이동 및 시스템 키)
const BLOCKED_KEYS: Array[int] = [
	KEY_W, KEY_A, KEY_S, KEY_D,  # 이동 키
	KEY_SPACE,  # 점프 키
	KEY_SHIFT,  # 달리기 키
	KEY_ESCAPE,  # ESC
]

# 키 입력 감지
func _input(event: InputEvent):
	# ESC 키로 메뉴 토글
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		if esc_menu and esc_menu.visible:
			esc_menu.close_menu()
		else:
			if esc_menu:
				esc_menu.open_menu()
		get_viewport().set_input_as_handled()
		return
	
	if waiting_for_key and event is InputEventKey and event.pressed:
		var keycode = event.keycode
		
		# 사용 불가능한 키 체크
		if keycode in BLOCKED_KEYS:
			waiting_for_key.text = "사용 불가!"
			# 1초 후 원래 키 표시
			await get_tree().create_timer(0.5).timeout
			if waiting_for_key_index >= 0 and waiting_for_key_index < Globals.all_mining_keys.size():
				waiting_for_key.text = OS.get_keycode_string(Globals.all_mining_keys[waiting_for_key_index])
			waiting_for_key = null
			waiting_for_key_index = -1
			get_viewport().set_input_as_handled()
			return
		
		var key_name = OS.get_keycode_string(keycode)
		
		# 해당 인덱스의 키 저장
		if waiting_for_key_index >= 0 and waiting_for_key_index < Globals.all_mining_keys.size():
			Globals.all_mining_keys[waiting_for_key_index] = keycode
			waiting_for_key.text = key_name
		
		waiting_for_key = null
		waiting_for_key_index = -1
		get_viewport().set_input_as_handled()

# 키 설정 UI 업데이트 (키 개수에 따라 동적으로 생성)
func update_key_settings_ui():
	var key_count = Globals.mining_key_count
	var key_names = ["F", "J", "D", "K", "S", "L"]
	
	# 기존 동적 생성된 컨테이너 삭제
	for container in key_containers:
		if is_instance_valid(container):
			container.queue_free()
	key_containers.clear()
	
	# key_inputs에서 기본 2개 제외하고 초기화
	while key_inputs.size() > 2:
		key_inputs.pop_back()
	
	# 3번째 키부터 동적 생성 (Key 3, 4, 5, 6)
	for i in range(2, key_count):
		var container = HBoxContainer.new()
		container.name = "Key%dContainer" % (i + 1)
		
		# 라벨 생성
		var lbl = Label.new()
		lbl.text = "채굴 키 %d:" % (i + 1)
		lbl.add_theme_font_override("font", GALMURI_9)
		lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		container.add_child(lbl)
		
		# 입력 필드 생성
		var input = LineEdit.new()
		input.custom_minimum_size = Vector2(100, 0)
		input.add_theme_font_override("font", GALMURI_9)
		input.text = OS.get_keycode_string(Globals.all_mining_keys[i])
		input.max_length = 10
		input.editable = false
		container.add_child(input)
		
		# 클릭 이벤트 연결
		var key_idx = i
		input.gui_input.connect(func(event): _on_key_input_gui_input(event, key_idx))
		
		# VBoxContainer에 Close 버튼 앞에 추가
		var close_btn_index = vbox_container.get_child_count() - 1
		vbox_container.add_child(container)
		vbox_container.move_child(container, close_btn_index)
		
		key_containers.append(container)
		key_inputs.append(input)
	
	# 기존 Key1, Key2도 현재 값으로 업데이트
	if key_inputs.size() >= 2:
		key_inputs[0].text = OS.get_keycode_string(Globals.all_mining_keys[0])
		key_inputs[1].text = OS.get_keycode_string(Globals.all_mining_keys[1])

# 플레이 시간을 HH:MM:SS 형식으로 변환
func format_playtime(seconds: float) -> String:
	var total_seconds = int(seconds)
	var hours = total_seconds / 3600
	var minutes = (total_seconds % 3600) / 60
	var secs = total_seconds % 60
	return "%02d:%02d:%02d" % [hours, minutes, secs]

# ========================================
# ESC 메뉴 시스템
# ========================================

# ESC 메뉴 씬 로드
func load_esc_menu():
	esc_menu = ESC_MENU_SCENE.instantiate()
	add_child(esc_menu)
