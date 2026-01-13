extends Panel

# ========================================
# ESC 메뉴 - 게임 일시정지 및 나가기
# ========================================

# 씬 파일의 노드 참조
@onready var resume_button: Button = $VBoxContainer/ResumeButton
@onready var exit_button: Button = $VBoxContainer/ExitButton


func _ready():
	# 초기에는 숨김
	visible = false
	z_index = 2000
	
	# 일시정지 중에도 작동하도록 설정
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	# 스타일 설정
	var style_box = StyleBoxFlat.new()
	style_box.bg_color = Color(0.1, 0.1, 0.1, 0.9)
	style_box.border_color = Color(0.5, 0.5, 0.5, 1.0)
	add_theme_stylebox_override("panel", style_box)
	
	# 버튼 시그널 연결
	if resume_button:
		resume_button.pressed.connect(_on_resume_pressed)
		print("계속하기 버튼 연결됨")
	else:
		print("⚠️ 계속하기 버튼을 찾을 수 없음!")
	
	if exit_button:
		exit_button.pressed.connect(_on_exit_to_auto_pressed)
		print("나가기 버튼 연결됨")
	else:
		print("⚠️ 나가기 버튼을 찾을 수 없음!")


## ESC 키 입력 처리 - 메뉴 토글
func _input(event: InputEvent):
	# ESC 키가 눌렸을 때
	if event.is_action_pressed("ui_cancel"):
		# 메뉴가 열려있으면 닫기, 닫혀있으면 열기
		if visible:
			close_menu()
		else:
			open_menu()
		# 다른 노드로 입력 전파 방지
		get_viewport().set_input_as_handled()


# 메뉴 열기
func open_menu():
	visible = true
	get_tree().paused = true


# 메뉴 닫기
func close_menu():
	visible = false
	get_tree().paused = false


# 계속하기 버튼
func _on_resume_pressed():
	print("계속하기 버튼 클릭됨")
	close_menu()


# Auto Scene으로 나가기 버튼
func _on_exit_to_auto_pressed():
	print("나가기 버튼 클릭됨!")
	
	# 게임 재개 (씬 전환 전에)
	get_tree().paused = false
	print("일시정지 해제됨")
	
	# auto_scene.tscn으로 이동
	print("auto_scene.tscn으로 이동 시도...")
	var result = get_tree().change_scene_to_file("res://auto_scene.tscn")
	if result != OK:
		print("⚠️ 씬 전환 실패! 에러 코드: ", result)
