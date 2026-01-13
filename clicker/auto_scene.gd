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
	print("원래 viewport 크기: ", original_viewport_size)
	print("원래 창 모드: ", original_window_mode)
	print("원래 창 위치: ", original_window_position)
	print("원래 always on top: ", original_always_on_top)
	
	# 창을 항상 최상위로 설정
	get_window().always_on_top = true
	print("창을 항상 최상위로 설정")
	
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
	
	# 창 크기를 viewport의 0.4배의 가장 가까운 자연수로 설정
	var final_window_size = Vector2i(
		roundi(default_viewport.x * 0.4),
		roundi(default_viewport.y * 0.4)
	)
	get_window().size = final_window_size
	print("창 크기 설정 후: ", final_window_size)
	
	# 창을 화면 중앙으로 이동
	var screen_size = DisplayServer.screen_get_size()
	get_window().position = Vector2i(
		(screen_size.x - final_window_size.x) / 2,
		(screen_size.y - final_window_size.y) / 2
	)
	
	print("Auto Scene - Viewport: ", default_viewport, ", 창: ", final_window_size)
	
	# 버튼 시그널 연결
	back_button.pressed.connect(_on_back_button_pressed)
	# CenterContainer의 마우스 필터 설정 (드래그 가능하게)
	$CenterContainer.mouse_filter = Control.MOUSE_FILTER_STOP
	auto_money_label.mouse_filter = Control.MOUSE_FILTER_IGNORE

	auto_money_label.modulate = Color(1.0, 0.9, 0.3)  # 금색

	
# 초기 값 설정
	displayed_auto_money = Globals.auto_money
	target_auto_money = Globals.auto_money
	update_auto_money_display()
	
	# 현재 스킨 적용
	_apply_current_skin()


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
	
	print("창 모드, viewport 크기, 위치, always on top 복원 완료")
	
	# 로비로 돌아가기
	get_tree().change_scene_to_file("res://lobby.tscn")


# 키보드 입력 처리
func _input(event: InputEvent):
	if event is InputEventKey and event.pressed and not event.echo:
		# ESC 키는 돌아가기
		if event.keycode == KEY_ESCAPE:
			# 씬 전환 전에 입력 처리 완료 표시
			if get_viewport():
				get_viewport().set_input_as_handled()
			_on_back_button_pressed()
		else:
			# 다른 키는 auto_money 증가
			Globals.auto_money += 1
			print("키 입력! Auto Money +1 (현재: 🪙", Globals.auto_money, ")")
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			is_dragging = true
			# 클릭한 지점(화면 좌표)과 창 좌상단 사이의 오프셋 저장
			drag_start_mouse = DisplayServer.mouse_get_position()
			drag_start_window = get_window().position
			drag_offset_from_origin = Vector2i(drag_start_mouse) - drag_start_window
		else:
			is_dragging = false
	elif event is InputEventMouseMotion and is_dragging:
		# 클릭 지점이 창 안에서 유지되도록 오프셋을 적용해 이동
		var mouse_pos: Vector2 = DisplayServer.mouse_get_position()
		get_window().position = Vector2i(mouse_pos) - drag_offset_from_origin

## /** shop_button을 누르면 shop_menu를 토글한다
##  * @returns void
##  */
func _on_shop_button_button_down():
	if shop_menu:
		shop_menu.visible = !shop_menu.visible
		print("shop_menu visible: ", shop_menu.visible)

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
	
	print("스킨 적용 완료 - Sprite1: ", Globals.current_sprite1_skin, ", Sprite2: ", Globals.current_sprite2_skin)

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
