extends Control

## 서버 참가 UI
## IP 주소와 포트 입력하여 서버 접속

@onready var ip_edit = $Panel/VBoxContainer/IPContainer/IPEdit
@onready var port_edit = $Panel/VBoxContainer/PortContainer/PortEdit
@onready var join_btn = $Panel/VBoxContainer/ButtonContainer/JoinBtn
@onready var cancel_btn = $Panel/VBoxContainer/ButtonContainer/CancelBtn
@onready var status_label = $Panel/VBoxContainer/StatusLabel

func _ready():
	# 기본값 설정
	ip_edit.text = "127.0.0.1"  # 로컬 테스트용
	port_edit.text = str(NetworkManager.DEFAULT_PORT)
	
	# 버튼 연결
	join_btn.pressed.connect(_on_join_pressed)
	cancel_btn.pressed.connect(_on_cancel_pressed)
	
	# NetworkManager 시그널 연결
	NetworkManager.connection_succeeded.connect(_on_connection_succeeded)
	NetworkManager.connection_failed.connect(_on_connection_failed)
	
	# 페이드 인
	modulate.a = 0
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 1.0, 0.3)

# 서버 참가 버튼
func _on_join_pressed():
	var ip_address = ip_edit.text.strip_edges()
	var port = int(port_edit.text)
	
	# 유효성 검사
	if ip_address.is_empty():
		status_label.text = "IP 주소를 입력하세요"
		status_label.modulate = Color.RED
		return
	
	if port < 1024 or port > 65535:
		status_label.text = "포트는 1024-65535 사이여야 합니다"
		status_label.modulate = Color.RED
		return
	
	# 버튼 비활성화
	join_btn.disabled = true
	cancel_btn.disabled = true
	status_label.text = "서버에 접속 중..."
	status_label.modulate = Color.YELLOW
	
	# 서버 접속
	NetworkManager.join_server(ip_address, port)
	
	# 타임아웃 설정 (5초)
	await get_tree().create_timer(5.0).timeout
	if join_btn.disabled:
		_on_connection_failed()

# 접속 성공
func _on_connection_succeeded():
	status_label.text = "접속 성공!"
	status_label.modulate = Color.GREEN
	
	# 잠시 후 로비로 이동
	await get_tree().create_timer(0.5).timeout
	get_tree().change_scene_to_file("res://scenes/menu/lobby.tscn")

# 접속 실패
func _on_connection_failed():
	status_label.text = "서버 접속 실패. IP와 포트를 확인하세요"
	status_label.modulate = Color.RED
	join_btn.disabled = false
	cancel_btn.disabled = false

# 취소 버튼
func _on_cancel_pressed():
	get_tree().change_scene_to_file("res://scenes/menu/main_menu.tscn")

