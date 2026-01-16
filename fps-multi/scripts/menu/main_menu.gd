extends Control

## 메인 메뉴
## 싱글플레이, 서버 생성, 서버 참가 선택

@onready var title_label = $VBoxContainer/TitleLabel
@onready var single_player_btn = $VBoxContainer/ButtonContainer/SinglePlayerBtn
@onready var create_server_btn = $VBoxContainer/ButtonContainer/CreateServerBtn
@onready var join_server_btn = $VBoxContainer/ButtonContainer/JoinServerBtn
@onready var settings_btn = $VBoxContainer/ButtonContainer/SettingsBtn
@onready var quit_btn = $VBoxContainer/ButtonContainer/QuitBtn
@onready var version_label = $VersionLabel

func _ready():
	print("메인 메뉴 로딩 시작")
	
	# 버튼 연결
	if single_player_btn:
		single_player_btn.pressed.connect(_on_single_player_pressed)
	if create_server_btn:
		create_server_btn.pressed.connect(_on_create_server_pressed)
	if join_server_btn:
		join_server_btn.pressed.connect(_on_join_server_pressed)
	if settings_btn:
		settings_btn.pressed.connect(_on_settings_pressed)
	if quit_btn:
		quit_btn.pressed.connect(_on_quit_pressed)
	
	# 페이드 인 효과
	modulate.a = 0
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 1.0, 0.5)
	
	print("메인 메뉴 로딩 완료")

# 싱글플레이 시작
func _on_single_player_pressed():
	print("싱글플레이 시작")
	get_tree().change_scene_to_file("res://scenes/main.tscn")

# 서버 생성 화면으로
func _on_create_server_pressed():
	print("서버 생성")
	get_tree().change_scene_to_file("res://scenes/menu/server_create.tscn")

# 서버 참가 화면으로
func _on_join_server_pressed():
	print("서버 참가")
	get_tree().change_scene_to_file("res://scenes/menu/server_join.tscn")

# 설정 (나중에 구현)
func _on_settings_pressed():
	print("설정")

# 게임 종료
func _on_quit_pressed():
	get_tree().quit()

