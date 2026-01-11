extends Control

# ========================================
# Auto Scene - Auto Money 관리 씬
# ========================================

# 폰트 로드
const GALMURI_9 = preload("res://Galmuri9.ttf")

# 씬 파일의 노드 참조
@onready var auto_money_label: Label = $CenterContainer/AutoMoneyLabel
@onready var back_button: Button = $BackButton
@onready var title_label: Label = $CenterContainer/Title
@onready var description_label: Label = $CenterContainer/Description

# 돈 표시용 애니메이션 변수
var displayed_auto_money: float = 0.0
var target_auto_money: int = 0

# 원래 viewport 크기 및 창 모드 저장
var original_viewport_size: Vector2i
var original_window_mode: Window.Mode
var original_window_position: Vector2i
var original_always_on_top: bool


func _ready():
	# 원래 viewport 크기, 창 모드, 위치, always on top 상태 저장
	original_viewport_size = get_window().size
	original_window_mode = get_window().mode
	original_window_position = get_window().position
	original_always_on_top = get_window().always_on_top
	print("원래 viewport 크기: ", original_viewport_size)
	print("원래 창 모드: ", original_window_mode)
	print("원래 창 위치: ", original_window_position)
	print("원래 always on top: ", original_always_on_top)
	
	# 창을 항상 최상위로 설정
	get_window().always_on_top = true
	print("창을 항상 최상위로 설정")
	
	# 창 모드로 전환 (풀스크린이었다면)
	get_window().mode = Window.MODE_WINDOWED
	
	# Viewport 크기를 1280x640으로 변경
	get_window().size = Vector2i(300, 200)
	
	# 창을 화면 중앙으로 이동
	var screen_size = DisplayServer.screen_get_size()
	var window_size = get_window().size
	get_window().position = Vector2i(
		(screen_size.x - window_size.x) / 2,
		(screen_size.y - window_size.y) / 2
	)
	
	print("Auto Scene viewport 크기: 1280x640 (창 모드, 중앙 정렬)")
	
	# 버튼 시그널 연결
	back_button.pressed.connect(_on_back_button_pressed)
	
	# 레이블 색상 설정
	title_label.modulate = Color(0.8, 1.0, 1.0)
	auto_money_label.modulate = Color(1.0, 0.9, 0.3)  # 금색
	description_label.modulate = Color(0.7, 0.7, 0.7)
	
	# 초기 값 설정
	displayed_auto_money = Globals.auto_money
	target_auto_money = Globals.auto_money
	update_auto_money_display()


func _process(delta):
	# 부드러운 돈 증가 애니메이션
	if displayed_auto_money != target_auto_money:
		var diff = target_auto_money - displayed_auto_money
		var speed = max(abs(diff) * 5.0, 10.0)
		displayed_auto_money = move_toward(displayed_auto_money, target_auto_money, speed * delta)
		update_auto_money_display()
	
	# Globals의 auto_money가 변경되었는지 확인
	if Globals.auto_money != target_auto_money:
		target_auto_money = Globals.auto_money


# Auto Money 표시 업데이트
func update_auto_money_display():
	if auto_money_label:
		auto_money_label.text = "🪙 " + str(int(displayed_auto_money))


# 돌아가기 버튼 클릭
func _on_back_button_pressed():
	# always on top 상태 복원
	get_window().always_on_top = original_always_on_top
	
	# 창 모드를 원래대로 복원
	get_window().mode = original_window_mode
	
	# Viewport 크기를 원래대로 복원
	get_window().size = original_viewport_size
	
	# 창 위치 복원 (창 모드였다면)
	if original_window_mode == Window.MODE_WINDOWED:
		get_window().position = original_window_position
	
	print("창 모드, viewport 크기, 위치, always on top 복원 완료")
	
	# 메인 씬으로 돌아가기
	get_tree().change_scene_to_file("res://world.tscn")


# 키보드 입력 처리
func _input(event: InputEvent):
	if event is InputEventKey and event.pressed and not event.echo:
		# ESC 키는 돌아가기
		if event.keycode == KEY_ESCAPE:
			_on_back_button_pressed()
			get_viewport().set_input_as_handled()
		else:
			# 다른 키는 auto_money 증가
			Globals.auto_money += 1
			print("키 입력! Auto Money +1 (현재: 🪙", Globals.auto_money, ")")
