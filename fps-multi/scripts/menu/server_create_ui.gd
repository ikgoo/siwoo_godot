extends Control

## 서버 생성 UI
## 서버 이름, 포트, 최대 인원, UPNP 설정

@onready var server_name_edit = $Panel/VBoxContainer/ServerNameContainer/ServerNameEdit
@onready var port_edit = $Panel/VBoxContainer/PortContainer/PortEdit
@onready var max_players_spin = $Panel/VBoxContainer/MaxPlayersContainer/MaxPlayersSpin
@onready var upnp_check = $Panel/VBoxContainer/UPNPCheck
@onready var create_btn = $Panel/VBoxContainer/ButtonContainer/CreateBtn
@onready var cancel_btn = $Panel/VBoxContainer/ButtonContainer/CancelBtn
@onready var status_label = $Panel/VBoxContainer/StatusLabel

func _ready():
	# 기본값 설정
	server_name_edit.text = "My Server"
	port_edit.text = str(NetworkManager.DEFAULT_PORT)
	max_players_spin.value = 4
	
	# 버튼 연결
	create_btn.pressed.connect(_on_create_pressed)
	cancel_btn.pressed.connect(_on_cancel_pressed)
	
	# NetworkManager 시그널 연결
	NetworkManager.server_created.connect(_on_server_created)
	NetworkManager.server_creation_failed.connect(_on_server_creation_failed)
	
	# 페이드 인
	modulate.a = 0
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 1.0, 0.3)

# 서버 생성 버튼
func _on_create_pressed():
	var server_name = server_name_edit.text.strip_edges()
	var port = int(port_edit.text)
	var max_players = int(max_players_spin.value)
	var use_upnp = upnp_check.button_pressed
	
	# 유효성 검사
	if server_name.is_empty():
		status_label.text = "서버 이름을 입력하세요"
		status_label.modulate = Color.RED
		return
	
	if port < 1024 or port > 65535:
		status_label.text = "포트는 1024-65535 사이여야 합니다"
		status_label.modulate = Color.RED
		return
	
	# 버튼 비활성화
	create_btn.disabled = true
	cancel_btn.disabled = true
	status_label.text = "서버 생성 중..."
	status_label.modulate = Color.YELLOW
	
	# 서버 생성
	NetworkManager.create_server(server_name, port, max_players, use_upnp)

# 서버 생성 성공
func _on_server_created():
	status_label.text = "서버 생성 성공!"
	status_label.modulate = Color.GREEN
	
	# 잠시 후 로비로 이동
	await get_tree().create_timer(0.5).timeout
	get_tree().change_scene_to_file("res://scenes/menu/lobby.tscn")

# 서버 생성 실패
func _on_server_creation_failed(error: String):
	status_label.text = error
	status_label.modulate = Color.RED
	create_btn.disabled = false
	cancel_btn.disabled = false

# 취소 버튼
func _on_cancel_pressed():
	get_tree().change_scene_to_file("res://scenes/menu/main_menu.tscn")

