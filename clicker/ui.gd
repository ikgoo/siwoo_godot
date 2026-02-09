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
@onready var tutorial_reset_button = $SettingPanel/VBoxContainer/TutorialResetButton
@onready var close_button = $SettingPanel/VBoxContainer/CloseButton
@onready var vbox_container = $SettingPanel/VBoxContainer

# UI 클릭 사운드
@onready var click_sfx: AudioStreamPlayer = $ClickSFX

# 모드 아이콘 참조 (status의 자식 노드들)
@onready var pickaxe_slot: Sprite2D = $status/pickaxe
@onready var torch_slot: Sprite2D = $status/torch
@onready var platform_slot: Sprite2D = $status/platform

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

# 클리어 진행도 표시
var goal_progress_bar : ProgressBar
var goal_label : Label  # 목표 금액 텍스트

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
	Globals.build_mode_changed.connect(_on_build_mode_changed)
	
	# 초기 돈 표시
	displayed_money = Globals.money
	target_money = Globals.money
	label.text = str(Globals.money)
	
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
	
	# === 클리어 진행도 프로그레스 바 (화면 상단 중앙) ===
	var viewport_size = get_viewport_rect().size
	
	# 목표 금액 레이블
	goal_label = Label.new()
	goal_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	goal_label.position = Vector2(viewport_size.x / 2 - 150, 5)
	goal_label.size = Vector2(300, 20)
	goal_label.add_theme_font_override("font", GALMURI_9)
	goal_label.add_theme_font_size_override("font_size", 14)
	goal_label.modulate = Color(1.0, 0.9, 0.3)  # 금색
	goal_label.text = Globals.get_text("UI GOAL INIT") % format_money(Globals.goal_money)
	add_child(goal_label)
	
	# 프로그레스 바
	goal_progress_bar = ProgressBar.new()
	goal_progress_bar.position = Vector2(viewport_size.x / 2 - 150, 25)
	goal_progress_bar.size = Vector2(300, 20)
	goal_progress_bar.min_value = 0
	goal_progress_bar.max_value = Globals.goal_money
	goal_progress_bar.value = 0
	goal_progress_bar.show_percentage = false
	# 스타일 설정
	var style_bg = StyleBoxFlat.new()
	style_bg.bg_color = Color(0.2, 0.2, 0.2, 0.8)
	style_bg.corner_radius_top_left = 5
	style_bg.corner_radius_top_right = 5
	style_bg.corner_radius_bottom_left = 5
	style_bg.corner_radius_bottom_right = 5
	goal_progress_bar.add_theme_stylebox_override("background", style_bg)
	var style_fill = StyleBoxFlat.new()
	style_fill.bg_color = Color(1.0, 0.8, 0.2, 1.0)  # 금색
	style_fill.corner_radius_top_left = 5
	style_fill.corner_radius_top_right = 5
	style_fill.corner_radius_bottom_left = 5
	style_fill.corner_radius_bottom_right = 5
	goal_progress_bar.add_theme_stylebox_override("fill", style_fill)
	add_child(goal_progress_bar)
	
	# 초기 수입 계산
	last_money = Globals.money
	
	# 설정 버튼 연결 (클릭 사운드 포함)
	setting_button.pressed.connect(_on_setting_button_pressed)
	setting_button.pressed.connect(play_click_sound)
	tutorial_reset_button.pressed.connect(_on_tutorial_reset_button_pressed)
	tutorial_reset_button.pressed.connect(play_click_sound)
	close_button.pressed.connect(_on_close_button_pressed)
	close_button.pressed.connect(play_click_sound)
	
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
	
	# 초기 모드 아이콘 설정 (기본: pickaxe)
	_on_build_mode_changed(Globals.get_current_mode())

func _process(delta):
	# 키 개수가 변경되었으면 UI 업데이트
	if last_key_count != Globals.mining_key_count:
		update_key_settings_ui()
		last_key_count = Globals.mining_key_count
	
	# 플레이 시간 업데이트
	playtime_seconds += delta
	playtime_label.text = format_playtime(playtime_seconds)
	
	# 클리어 진행도 업데이트
	if goal_progress_bar and not Globals.is_game_cleared:
		goal_progress_bar.value = min(Globals.money, Globals.goal_money)
		goal_label.text = Globals.get_text("UI GOAL") % [format_money(Globals.money), format_money(Globals.goal_money)]
		
		# 목표 달성 체크
		if Globals.money >= Globals.goal_money:
			trigger_game_clear()
	
	# 부드러운 돈 증가 애니메이션 (Tween 없이 수동으로)
	if displayed_money != target_money:
		var diff = target_money - displayed_money
		# 차이가 크면 빠르게, 작으면 천천히
		var speed = max(abs(diff) * 5.0, 10.0)
		displayed_money = move_toward(displayed_money, target_money, speed * delta)
		label.text = str(int(displayed_money))
	
	# 초당 수입 적용 (money_per_second) - 알바 등 자동 수입
	passive_income_timer += delta
	if passive_income_timer >= 1.0:
		passive_income_timer -= 1.0
		if Globals.money_per_second > 0:
			Globals.money += Globals.money_per_second
			# 자동 수입 라벨 업데이트
			passive_income_label.text = Globals.get_text("UI PASSIVE INCOME") % Globals.money_per_second
	
	# 초당 수입 계산 (1초마다 업데이트)
	income_update_timer += delta
	if income_update_timer >= 1.0:
		var money_diff = Globals.money - last_money
		income_per_second = money_diff
		last_money = Globals.money
		income_update_timer = 0.0
		
		# 초당 수입 표시 업데이트
		var suffix = Globals.get_text("UI INCOME SUFFIX")
		if income_per_second > 0:
			income_label.text = "+" + str(int(income_per_second)) + suffix
			income_label.modulate = Color(0.7, 1.0, 0.7)  # 초록색
		elif income_per_second < 0:
			income_label.text = str(int(income_per_second)) + suffix
			income_label.modulate = Color(1.0, 0.5, 0.5)  # 빨간색
		else:
			income_label.text = "0" + suffix
			income_label.modulate = Color(0.7, 0.7, 0.7)  # 회색
	

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
	tier_notification.text = Globals.get_text("UI TIER UP") % new_tier
	
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

## /** 튜토리얼 초기화 버튼 클릭
##  * Globals.reset_tutorial()을 호출하여 튜토리얼을 초기화하고 씬을 재시작합니다.
##  * @returns void
##  */
func _on_tutorial_reset_button_pressed():
	print("🔵 [UI] 튜토리얼 초기화 버튼 클릭됨!")
	
	# 게임 일시정지 해제 (설정창에서 일시정지되어 있을 수 있음)
	get_tree().paused = false
	print("▶️ [UI] 게임 일시정지 해제")
	
	# 설정 패널 즉시 숨김 (두 가지 방법 모두 사용)
	setting_panel.hide()
	setting_panel.visible = false
	waiting_for_key = null
	print("🔵 [UI] 설정 패널 숨김 완료: visible =", setting_panel.visible, ", is_visible =", setting_panel.is_visible())
	
	# 튜토리얼 초기화 실행
	Globals.reset_tutorial()
	print("🔄 [UI] 튜토리얼 초기화 완료 - 씬을 재시작합니다...")
	
	# 반투명 오버레이 생성 (설정 패널이 완전히 가려지도록)
	var overlay = ColorRect.new()
	overlay.color = Color(0, 0, 0, 0.8)
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.z_index = 2999
	add_child(overlay)
	
	# 확인 메시지 표시
	var feedback_label = Label.new()
	feedback_label.text = Globals.get_text("UI TUTORIAL RESTART")
	feedback_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	feedback_label.position = Vector2(get_viewport_rect().size.x / 2 - 200, get_viewport_rect().size.y / 2 - 25)
	feedback_label.size = Vector2(400, 50)
	feedback_label.add_theme_font_override("font", GALMURI_9)
	feedback_label.add_theme_font_size_override("font_size", 24)
	feedback_label.modulate = Color(1.0, 0.9, 0.3)  # 금색
	feedback_label.z_index = 3000
	add_child(feedback_label)
	
	# 1.5초 후 씬 재시작
	await get_tree().create_timer(1.5).timeout
	print("🔄 [UI] 씬 재시작 실행!")
	get_tree().reload_current_scene()

## /** UI 클릭 사운드를 재생한다
##  * 버튼, 키 입력 필드 등 UI 요소 클릭 시 호출
##  * Globals.play_click_sound()를 호출하여 전역 사운드 재생
##  * @returns void
##  */
func play_click_sound():
	Globals.play_click_sound()

# 키 입력 필드 클릭 (범용)
func _on_key_input_gui_input(event: InputEvent, key_index: int):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		play_click_sound()
		if key_index < key_inputs.size():
			waiting_for_key = key_inputs[key_index]
			waiting_for_key_index = key_index
			key_inputs[key_index].text = Globals.get_text("UI PRESS KEY")

# 사용 불가능한 키 목록 (이동 및 시스템 키)
const BLOCKED_KEYS: Array[int] = [
	KEY_W, KEY_A, KEY_S, KEY_D,  # 이동 키
	KEY_SPACE,  # 점프 키
	KEY_SHIFT,  # 달리기 키
	KEY_ESCAPE,  # ESC
]

# 키 입력 감지
func _input(event: InputEvent):
	# ESC 키는 esc_menu.gd에서 직접 처리 (자식이 _input을 먼저 받으므로)
	
	if waiting_for_key and event is InputEventKey and event.pressed:
		var keycode = event.keycode
		
		# 사용 불가능한 키 체크
		if keycode in BLOCKED_KEYS:
			waiting_for_key.text = Globals.get_text("UI KEY BLOCKED")
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
		lbl.text = Globals.get_text("UI MINING KEY N") % (i + 1)
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

# ========================================
# 클리어 시스템
# ========================================

## 돈을 읽기 쉬운 형식으로 변환 (1000000 → 1,000,000)
func format_money(amount: int) -> String:
	var str_amount = str(amount)
	var result = ""
	var count = 0
	for i in range(str_amount.length() - 1, -1, -1):
		if count > 0 and count % 3 == 0:
			result = "," + result
		result = str_amount[i] + result
		count += 1
	return result

## 게임 클리어 처리
func trigger_game_clear():
	if Globals.is_game_cleared:
		return
	
	Globals.is_game_cleared = true
	
	# 포인트 계산
	var clear_time = playtime_seconds
	var points = Globals.calculate_clear_points(clear_time)
	Globals.game_clear_points = points
	Globals.total_points += points
	
	print("🎉 게임 클리어! 시간: %.1f초, 포인트: %d" % [clear_time, points])
	
	# 클리어 화면 표시
	show_clear_screen(clear_time, points)

## 클리어 화면 표시
func show_clear_screen(clear_time: float, points: int):
	# 반투명 배경 패널
	var overlay = ColorRect.new()
	overlay.color = Color(0, 0, 0, 0.8)
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.z_index = 2000
	add_child(overlay)
	
	# 클리어 메시지 컨테이너
	var container = VBoxContainer.new()
	container.set_anchors_preset(Control.PRESET_CENTER)
	container.position = Vector2(-150, -150)
	container.z_index = 2001
	add_child(container)
	
	# 축하 메시지
	var title = Label.new()
	title.text = Globals.get_text("UI GAME CLEAR")
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_override("font", GALMURI_9)
	title.add_theme_font_size_override("font_size", 36)
	title.modulate = Color(1.0, 0.9, 0.3)  # 금색
	container.add_child(title)
	
	# 클리어 시간
	var time_label = Label.new()
	time_label.text = Globals.get_text("UI CLEAR TIME") % format_playtime(clear_time)
	time_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	time_label.add_theme_font_override("font", GALMURI_9)
	time_label.add_theme_font_size_override("font_size", 24)
	container.add_child(time_label)
	
	# 획득 포인트
	var points_label = Label.new()
	points_label.text = Globals.get_text("UI POINTS EARNED") % format_money(points)
	points_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	points_label.add_theme_font_override("font", GALMURI_9)
	points_label.add_theme_font_size_override("font_size", 28)
	points_label.modulate = Color(0.5, 1.0, 0.5)  # 연두색
	container.add_child(points_label)
	
	# 누적 포인트
	var total_label = Label.new()
	total_label.text = Globals.get_text("UI TOTAL POINTS") % format_money(Globals.total_points)
	total_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	total_label.add_theme_font_override("font", GALMURI_9)
	total_label.add_theme_font_size_override("font_size", 20)
	total_label.modulate = Color(0.8, 0.8, 0.8)
	container.add_child(total_label)
	
	# 빈 공간
	var spacer = Control.new()
	spacer.custom_minimum_size = Vector2(0, 30)
	container.add_child(spacer)
	
	# 계속하기 버튼
	var continue_btn = Button.new()
	continue_btn.text = Globals.get_text("UI CONTINUE")
	continue_btn.add_theme_font_override("font", GALMURI_9)
	continue_btn.add_theme_font_size_override("font_size", 20)
	continue_btn.custom_minimum_size = Vector2(200, 50)
	continue_btn.pressed.connect(func(): get_tree().change_scene_to_file("res://auto_scene.tscn"))
	container.add_child(continue_btn)


# ========================================
# 모드 아이콘 투명도 시스템
# ========================================

## 모드 변경 시그널 핸들러 - 아이콘 visible 업데이트
## - 채굴 모드 (기본): pickaxe만 보임 (breakable_tile 부술 수 있음)
## - 횃불 설치 모드: torch만 보임
## - 플랫폼 설치 모드: platform만 보임
func _on_build_mode_changed(mode: String):
	# 모든 아이콘을 숨김
	pickaxe_slot.visible = false
	torch_slot.visible = false
	platform_slot.visible = false
	
	# 현재 모드에 해당하는 아이콘만 표시
	match mode:
		"pickaxe":
			pickaxe_slot.visible = true
		"torch":
			torch_slot.visible = true
		"platform":
			platform_slot.visible = true
