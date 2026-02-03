extends Control

# ========================================
# Auto Scene - Auto Money 관리 씬
# ========================================

# 폰트 로드
const GALMURI_9 = preload("res://Galmuri9.ttf")
# Viewport 클리어 모드: NEVER
const CLEAR_MODE_NEVER := 1

# 씬 파일의 노드 참조
@onready var auto_money_label: Label = $CenterContainer/AutoMoneyLabel
@onready var back_button: Button = $BackButton
@onready var title_label: Label = $CenterContainer/Title
@onready var description_label: Label = $CenterContainer/Description
@onready var shop_menu = $shop_menu

# 설정 패널 노드 참조
@onready var setting_panel: PanelContainer = $SettingPanel
@onready var setting_title_label: Label = $SettingPanel/MarginContainer/VBoxContainer/TitleLabel
@onready var ui_scale_label: Label = $SettingPanel/MarginContainer/VBoxContainer/UIScaleContainer/UIScaleLabel
@onready var ui_scale_minus: Button = $SettingPanel/MarginContainer/VBoxContainer/UIScaleContainer/UIScaleMinus
@onready var ui_scale_value: Label = $SettingPanel/MarginContainer/VBoxContainer/UIScaleContainer/UIScaleValue
@onready var ui_scale_plus: Button = $SettingPanel/MarginContainer/VBoxContainer/UIScaleContainer/UIScalePlus
@onready var char_scale_label: Label = $SettingPanel/MarginContainer/VBoxContainer/CharScaleContainer/CharScaleLabel
@onready var char_scale_minus: Button = $SettingPanel/MarginContainer/VBoxContainer/CharScaleContainer/CharScaleMinus
@onready var char_scale_value: Label = $SettingPanel/MarginContainer/VBoxContainer/CharScaleContainer/CharScaleValue
@onready var char_scale_plus: Button = $SettingPanel/MarginContainer/VBoxContainer/CharScaleContainer/CharScalePlus
@onready var apply_button: Button = $SettingPanel/MarginContainer/VBoxContainer/ButtonContainer/ApplyButton
@onready var setting_close_button: Button = $SettingPanel/MarginContainer/VBoxContainer/ButtonContainer/CloseButton
@onready var setting_button: Button = $setting

# 설정 임시 값 (적용 버튼 누를 때까지 미리보기용)
var temp_ui_scale: float = 1.0
var temp_char_scale: float = 1.0

# 캐릭터 스프라이트 참조
@onready var sprite1: Sprite2D = $Sprite2D
@onready var sprite2: Sprite2D = $Sprite2D2

# 스프라이트 초기 위치/크기 저장 (tscn에서 설정한 값)
var sprite1_initial_pos: Vector2
var sprite2_initial_pos: Vector2
var sprite1_initial_scale: Vector2
var sprite2_initial_scale: Vector2

# 돈 표시용 애니메이션 변수
var displayed_auto_money: float = 0.0
var target_auto_money: int = 0

# 원래 viewport/창 상태 저장
var original_viewport_size: Vector2i
var original_window_size: Vector2i
var original_window_mode: Window.Mode
var original_window_position: Vector2i
var original_always_on_top: bool
var original_borderless: bool
var original_unresizable: bool
var original_clear_color: Color
var viewport_rid: RID

# 창 드래그 상태
var is_dragging: bool = false
var drag_start_mouse: Vector2 = Vector2.ZERO
var drag_start_window: Vector2i = Vector2i.ZERO
var drag_offset_from_origin: Vector2i = Vector2i.ZERO


func _ready():
	# 원래 viewport 크기, 창 모드, 위치, always on top 상태 저장
	viewport_rid = get_viewport().get_viewport_rid()
	original_viewport_size = get_viewport().size
	original_window_size = get_window().size
	original_window_mode = get_window().mode
	original_window_position = get_window().position
	original_always_on_top = get_window().always_on_top
	original_borderless = get_window().borderless
	original_unresizable = get_window().unresizable
	original_clear_color = RenderingServer.get_default_clear_color()
	
	# 스킨 시그널 연결
	Globals.skin_changed.connect(_on_skin_changed)
	
	# 창을 항상 최상위로 설정
	get_window().always_on_top = true
	
	# 창 모드로 전환 (풀스크린이었다면)
	get_window().mode = Window.MODE_WINDOWED
	# 테두리 제거
	get_window().borderless = true
	# 배경 투명화
	get_window().transparent = true
	get_viewport().transparent_bg = true
	RenderingServer.set_default_clear_color(Color(0, 0, 0, 0))
	
	# project.godot 기본 viewport 크기 사용 (F6 실행과 동일하게)
	var default_viewport = Vector2i(1280, 720)
	get_viewport().size = default_viewport
	size = default_viewport  # 루트 Control도 같은 크기로 설정
	
	# 스프라이트 초기 위치/크기 저장 (tscn에서 설정한 값)
	if sprite1:
		sprite1_initial_pos = sprite1.position
		sprite1_initial_scale = sprite1.scale
	if sprite2:
		sprite2_initial_pos = sprite2.position
		sprite2_initial_scale = sprite2.scale
	
	# 창 크기를 viewport의 0.4배의 가장 가까운 자연수로 설정
	var final_window_size = Vector2i(
		roundi(default_viewport.x * 0.4),
		roundi(default_viewport.y * 0.4)
	)
	get_window().size = final_window_size
	
	# 창을 화면 중앙으로 이동
	var screen_size = DisplayServer.screen_get_size()
	get_window().position = Vector2i(
		(screen_size.x - final_window_size.x) / 2,
		(screen_size.y - final_window_size.y) / 2
	)
	
	# 버튼 시그널 연결
	back_button.pressed.connect(_on_back_button_pressed)
	
	# UI 텍스트 번역 적용
	back_button.text = Globals.get_text("AUTO GO BACK")
	# 마우스 필터 설정 (입력이 통과되어 _unhandled_input에서 처리됨)
	$CenterContainer.mouse_filter = Control.MOUSE_FILTER_PASS
	auto_money_label.mouse_filter = Control.MOUSE_FILTER_PASS

	auto_money_label.modulate = Color(1.0, 0.9, 0.3)  # 금색

	
# 초기 값 설정
	displayed_auto_money = Globals.auto_money
	target_auto_money = Globals.auto_money
	update_auto_money_display()
	
	# 현재 스킨 적용
	_apply_current_skin()
	
	# 설정 패널 초기화
	_init_setting_panel()


@warning_ignore("unused_parameter")
func _process(_delta):

	# Globals의 auto_money 변화 시 즉시 반영
	if Globals.auto_money != target_auto_money:
		target_auto_money = Globals.auto_money
		displayed_auto_money = target_auto_money
		update_auto_money_display()


# Auto Money 표시 업데이트
func update_auto_money_display():
	if auto_money_label:
		auto_money_label.text = str(int(displayed_auto_money))


# 돌아가기 버튼 클릭
func _on_back_button_pressed():
	# always on top 상태 복원
	get_window().always_on_top = original_always_on_top
	
	# 창 모드를 원래대로 복원
	get_window().mode = original_window_mode
	
	# Viewport와 창 크기를 원래대로 복원
	get_viewport().size = original_viewport_size
	get_window().size = original_window_size
	
	# 창 위치 복원 (창 모드였다면)
	if original_window_mode == Window.MODE_WINDOWED:
		get_window().position = original_window_position
	get_window().borderless = original_borderless
	get_window().unresizable = original_unresizable
	get_window().transparent = false
	get_viewport().transparent_bg = false
	RenderingServer.set_default_clear_color(original_clear_color)
	
	# 로비로 돌아가기
	get_tree().change_scene_to_file("res://lobby.tscn")


# 클릭 판정용 변수
var click_start_pos: Vector2 = Vector2.ZERO
const CLICK_THRESHOLD: float = 10.0  # 이 거리 이내면 클릭으로 판정
var click_processed: bool = false  # 중복 클릭 방지

# 키보드/마우스 입력 처리 (_unhandled_input: UI가 처리하지 않은 입력만 받음)
func _unhandled_input(event: InputEvent):
	# 키보드 입력: ESC는 돌아가기, 그 외 모든 키는 돈 증가
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_ESCAPE:
			get_viewport().set_input_as_handled()
			_on_back_button_pressed()
		else:
			# 모든 키보드 입력으로 돈 증가
			_on_click()
			get_viewport().set_input_as_handled()
	
	# 마우스 좌클릭
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			is_dragging = true
			click_processed = false
			click_start_pos = DisplayServer.mouse_get_position()
			drag_start_mouse = click_start_pos
			drag_start_window = get_window().position
			drag_offset_from_origin = Vector2i(drag_start_mouse) - drag_start_window
		else:
			# 마우스 릴리즈 시 - 드래그 거리가 짧으면 클릭으로 판정
			if not click_processed:
				var release_pos = DisplayServer.mouse_get_position()
				if click_start_pos.distance_to(release_pos) < CLICK_THRESHOLD:
					_on_click()
					click_processed = true
			is_dragging = false
	elif event is InputEventMouseMotion and is_dragging:
		var mouse_pos: Vector2 = DisplayServer.mouse_get_position()
		get_window().position = Vector2i(mouse_pos) - drag_offset_from_origin


## /** 클릭 시 돈 증가
##  * @returns void
##  */
func _on_click() -> void:
	# auto_money 1 증가 (클릭당 수입은 나중에 업그레이드 가능)
	Globals.auto_money += 1

## /** shop_button을 누르면 shop_menu를 토글한다
##  * @returns void
##  */
func _on_shop_button_button_down():
	if shop_menu:
		shop_menu.visible = !shop_menu.visible

## /** 현재 스킨을 적용한다 (Sprite1, Sprite2 각각)
##  * @returns void
##  */
func _apply_current_skin() -> void:
	# Sprite1 스킨 적용
	var skin1: SkinItem = Globals.get_current_sprite1_skin()
	if skin1:
		skin1.apply_to_scene(self)
	
	# Sprite2 스킨 적용
	var skin2: SkinItem = Globals.get_current_sprite2_skin()
	if skin2:
		skin2.apply_to_scene(self)

## /** 스킨 변경 시그널 핸들러
##  * @param skin_id String 변경된 스킨 ID
##  * @returns void
##  */
func _on_skin_changed(_skin_id: String) -> void:
	_apply_current_skin()

## /** 최대공약수 계산 (유클리드 호제법)
##  * @param a int 첫 번째 수
##  * @param b int 두 번째 수
##  * @returns int 최대공약수
##  */
func _gcd(a: int, b: int) -> int:
	while b != 0:
		var temp = b
		b = a % b
		a = temp
	return a


# ========================================
# 설정 패널 관련 함수
# ========================================

## /** 설정 패널 초기화
##  * @returns void
##  */
func _init_setting_panel() -> void:
	# Globals에서 설정값 가져오기 (없으면 기본값 사용)
	var ui_scale_val: float = 1.0
	var char_scale_val: float = 1.0
	
	if Globals.get("auto_ui_scale") != null:
		ui_scale_val = Globals.auto_ui_scale
	if Globals.get("auto_character_scale") != null:
		char_scale_val = Globals.auto_character_scale
	
	# 임시 값 초기화
	temp_ui_scale = ui_scale_val
	temp_char_scale = char_scale_val
	
	# 라벨 업데이트
	_update_scale_label(ui_scale_value, ui_scale_val)
	_update_scale_label(char_scale_value, char_scale_val)
	
	# 번역 적용
	_update_setting_texts()
	
	# 저장된 배율 즉시 적용
	_apply_ui_scale(ui_scale_val)
	_apply_character_scale(char_scale_val)


## /** 설정 텍스트 번역 업데이트
##  * @returns void
##  */
func _update_setting_texts() -> void:
	setting_title_label.text = Globals.get_text("AUTO SETTING TITLE")
	ui_scale_label.text = Globals.get_text("AUTO UI SCALE")
	char_scale_label.text = Globals.get_text("AUTO CHAR SCALE")
	apply_button.text = Globals.get_text("AUTO SETTING APPLY")
	setting_close_button.text = Globals.get_text("AUTO SETTING CLOSE")
	setting_button.text = Globals.get_text("AUTO SETTING")


## /** 배율 라벨 업데이트
##  * @param label Label 업데이트할 라벨
##  * @param value float 배율 값
##  * @returns void
##  */
func _update_scale_label(label: Label, value: float) -> void:
	label.text = "%.1fx" % value


## /** 설정 버튼 클릭 시 호출
##  * @returns void
##  */
func _on_setting_button_down() -> void:
	if setting_panel:
		setting_panel.visible = !setting_panel.visible
		# 설정 패널이 열릴 때
		if setting_panel.visible:
			# 상점 메뉴 닫기
			if shop_menu:
				shop_menu.visible = false
			# 임시 값을 현재 Globals 값으로 초기화
			temp_ui_scale = Globals.auto_ui_scale if Globals.get("auto_ui_scale") != null else 1.0
			temp_char_scale = Globals.auto_character_scale if Globals.get("auto_character_scale") != null else 1.0
			_update_scale_label(ui_scale_value, temp_ui_scale)
			_update_scale_label(char_scale_value, temp_char_scale)


## /** 설정 닫기 버튼 클릭 시 호출
##  * @returns void
##  */
func _on_setting_close_pressed() -> void:
	if setting_panel:
		setting_panel.visible = false
	# 설정 저장
	Globals.save_settings()


## /** UI 크기 - 버튼 클릭 시 호출
##  * @returns void
##  */
func _on_ui_scale_minus() -> void:
	temp_ui_scale = clampf(temp_ui_scale - 0.1, 0.5, 3.0)
	_update_scale_label(ui_scale_value, temp_ui_scale)


func _on_ui_scale_plus() -> void:
	temp_ui_scale = clampf(temp_ui_scale + 0.1, 0.5, 3.0)
	_update_scale_label(ui_scale_value, temp_ui_scale)


## /** 캐릭터 크기 - 버튼 클릭 시 호출
##  * @returns void
##  */
func _on_char_scale_minus() -> void:
	temp_char_scale = clampf(temp_char_scale - 0.1, 0.5, 3.0)
	_update_scale_label(char_scale_value, temp_char_scale)


func _on_char_scale_plus() -> void:
	temp_char_scale = clampf(temp_char_scale + 0.1, 0.5, 3.0)
	_update_scale_label(char_scale_value, temp_char_scale)


## /** 적용 버튼 클릭 시 호출
##  * - 임시 값을 Globals에 저장하고 실제로 적용
##  * @returns void
##  */
func _on_apply_pressed() -> void:
	# Globals에 저장
	Globals.auto_ui_scale = temp_ui_scale
	Globals.auto_character_scale = temp_char_scale
	
	# 실제 적용
	_apply_ui_scale(temp_ui_scale)
	_apply_character_scale(temp_char_scale)
	
	# 설정 파일에 저장
	Globals.save_settings()


## /** UI 크기 배율 적용
##  * - 창 크기와 UI 요소들의 크기를 조절
##  * - 창 중심 유지 및 화면 경계 체크
##  * @param scale_value float 배율 값 (0.5 ~ 3.0)
##  * @returns void
##  */
func _apply_ui_scale(scale_value: float) -> void:
	# 기본 창 크기 (0.4배 기준)
	var default_viewport = Vector2i(1280, 720)
	var base_window_scale = 0.4
	
	# 현재 창의 중심 위치 저장
	var current_window = get_window()
	var old_size = current_window.size
	var old_center = current_window.position + old_size / 2
	
	# 새 창 크기 계산 (기본 0.4배 * UI 스케일)
	var final_scale = base_window_scale * scale_value
	var new_window_size = Vector2i(
		roundi(default_viewport.x * final_scale),
		roundi(default_viewport.y * final_scale)
	)
	
	# 창 크기 적용
	current_window.size = new_window_size
	
	# 중심 유지하도록 새 위치 계산
	var new_pos = old_center - new_window_size / 2
	
	# 화면 경계 체크 (화면 밖으로 나가지 않도록)
	var screen_size = DisplayServer.screen_get_size()
	new_pos.x = clampi(new_pos.x, 0, screen_size.x - new_window_size.x)
	new_pos.y = clampi(new_pos.y, 0, screen_size.y - new_window_size.y)
	
	# 새 위치 적용
	current_window.position = new_pos


## /** 캐릭터 크기 배율 적용
##  * - 스프라이트들의 크기만 조절 (위치는 tscn에서 설정한 값 유지)
##  * @param scale_value float 배율 값 (0.5 ~ 3.0)
##  * @returns void
##  */
func _apply_character_scale(scale_value: float) -> void:
	# 저장된 초기 위치/크기를 기준으로 배율 적용
	if sprite1:
		sprite1.scale = sprite1_initial_scale * scale_value
		sprite1.position = sprite1_initial_pos
	if sprite2:
		sprite2.scale = sprite2_initial_scale * scale_value
		sprite2.position = sprite2_initial_pos
