extends Panel

# ========================================
# ESC 메뉴 - 게임 일시정지 및 나가기
# ========================================

# 씬 파일의 노드 참조
@onready var title_label: Label = $VBoxContainer/Title
@onready var resume_button: Button = $VBoxContainer/ResumeButton
@onready var setting_button: Button = $VBoxContainer/SettingButton
@onready var exit_button: Button = $VBoxContainer/ExitButton

# 설정 씬 프리로드
var setting_scene: PackedScene = preload("res://setting.tscn")
var setting_instance: Node = null


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
	
	if setting_button:
		setting_button.pressed.connect(_on_setting_pressed)
	
	if exit_button:
		exit_button.pressed.connect(_on_exit_to_auto_pressed)
	
	# UI 텍스트 번역 적용
	_update_ui_texts()


## UI 텍스트에 번역 적용
func _update_ui_texts():
	title_label.text = Globals.get_text("MENU TITLE")
	resume_button.text = Globals.get_text("MENU RESUME")
	setting_button.text = Globals.get_text("MENU SETTING")
	exit_button.text = Globals.get_text("MENU EXIT")


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
	close_menu()


# 설정 버튼
func _on_setting_pressed():
	# 설정 화면 열기
	if setting_instance == null:
		setting_instance = setting_scene.instantiate()
		# 설정 화면 닫힘 시그널 연결
		setting_instance.closed.connect(_on_setting_closed)
		get_tree().root.add_child(setting_instance)
	
	# 현재 메뉴 숨기기
	visible = false


# 설정 화면이 닫혔을 때
func _on_setting_closed():
	# 설정 인스턴스 제거
	if setting_instance:
		setting_instance.queue_free()
		setting_instance = null
	
	# ESC 메뉴 다시 표시
	visible = true
	
	# 언어 변경 시 UI 텍스트 업데이트
	_update_ui_texts()


# Auto Scene으로 나가기 버튼
func _on_exit_to_auto_pressed():
	# 게임 재개 (씬 전환 전에)
	get_tree().paused = false
	
	# auto_scene.tscn으로 이동
	get_tree().change_scene_to_file("res://auto_scene.tscn")
