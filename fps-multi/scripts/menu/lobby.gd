extends Control

## 로비 (대기실)
## 플레이어 목록 표시 및 게임 시작

@onready var server_name_label = $Panel/VBoxContainer/ServerNameLabel
@onready var player_list = $Panel/VBoxContainer/PlayerListScroll/PlayerList
@onready var ready_btn = $Panel/VBoxContainer/ButtonContainer/ReadyBtn
@onready var start_btn = $Panel/VBoxContainer/ButtonContainer/StartBtn
@onready var leave_btn = $Panel/VBoxContainer/ButtonContainer/LeaveBtn
@onready var status_label = $Panel/VBoxContainer/StatusLabel

# 플레이어 아이템 씬
var player_item_scene = preload("res://scenes/menu/player_item.tscn")

# 준비 상태
var is_ready = false

func _ready():
	# 서버 이름 표시
	if NetworkManager and NetworkManager.server_info:
		server_name_label.text = "대기실 - " + NetworkManager.server_info.name
	else:
		server_name_label.text = "대기실"
	
	# 버튼 연결
	ready_btn.pressed.connect(_on_ready_pressed)
	start_btn.pressed.connect(_on_start_pressed)
	leave_btn.pressed.connect(_on_leave_pressed)
	
	# 시작 버튼은 호스트만 표시
	start_btn.visible = NetworkManager.is_server
	
	# NetworkManager 시그널 연결
	NetworkManager.player_connected.connect(_on_player_connected)
	NetworkManager.player_disconnected.connect(_on_player_disconnected)
	
	# 기존 플레이어 표시
	_refresh_player_list()
	
	# 페이드 인
	modulate.a = 0
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 1.0, 0.3)

# 플레이어 목록 새로고침
func _refresh_player_list():
	# 기존 목록 제거
	for child in player_list.get_children():
		child.queue_free()
	
	# 플레이어 추가
	for peer_id in NetworkManager.players:
		var player_info = NetworkManager.players[peer_id]
		_add_player_item(peer_id, player_info)
	
	# 빈 슬롯 추가
	var empty_slots = NetworkManager.server_info.max_players - NetworkManager.players.size()
	for i in range(empty_slots):
		_add_empty_slot()
	
	_update_status()

# 플레이어 아이템 추가
func _add_player_item(peer_id: int, player_info: Dictionary):
	var item = player_item_scene.instantiate()
	player_list.add_child(item)
	
	var player_name = player_info.name
	var is_host = (peer_id == 1)
	var is_ready_status = player_info.is_ready
	
	if is_host:
		player_name += " (호스트)"
	
	# HBoxContainer 안에 있는 Label들 접근
	var name_label = item.get_node("HBoxContainer/NameLabel")
	var status_label = item.get_node("HBoxContainer/StatusLabel")
	
	if name_label:
		name_label.text = player_name
	if status_label:
		status_label.text = "✓ 준비" if is_ready_status else "○ 대기"
		status_label.modulate = Color.GREEN if is_ready_status else Color.GRAY

# 빈 슬롯 추가
func _add_empty_slot():
	var item = player_item_scene.instantiate()
	player_list.add_child(item)
	
	# HBoxContainer 안에 있는 Label들 접근
	var name_label = item.get_node("HBoxContainer/NameLabel")
	var status_label = item.get_node("HBoxContainer/StatusLabel")
	
	if name_label:
		name_label.text = "빈 슬롯"
	if status_label:
		status_label.text = "○"
	item.modulate.a = 0.5

# 새 플레이어 연결
func _on_player_connected(peer_id: int, player_info: Dictionary):
	print("로비: 플레이어 %d 연결" % peer_id)
	_refresh_player_list()

# 플레이어 연결 해제
func _on_player_disconnected(peer_id: int):
	print("로비: 플레이어 %d 연결 해제" % peer_id)
	_refresh_player_list()

# 준비 버튼
func _on_ready_pressed():
	is_ready = not is_ready
	ready_btn.text = "준비 취소" if is_ready else "준비"
	ready_btn.modulate = Color.YELLOW if is_ready else Color.WHITE
	
	# 내 준비 상태 업데이트
	var my_id = multiplayer.get_unique_id()
	
	if multiplayer.is_server():
		# 서버는 직접 업데이트하고 모든 클라이언트에 알림
		NetworkManager.players[my_id].is_ready = is_ready
		for peer_id in multiplayer.get_peers():
			NetworkManager._update_player_ready.rpc_id(peer_id, my_id, is_ready)
	else:
		# 클라이언트는 서버에 요청
		NetworkManager.set_player_ready.rpc_id(1, my_id, is_ready)
	
	_refresh_player_list()

# 게임 시작 버튼 (호스트만)
func _on_start_pressed():
	if not NetworkManager.is_server:
		return
	
	# 모든 플레이어가 준비되었는지 확인
	if not NetworkManager.all_players_ready():
		status_label.text = "모든 플레이어가 준비되지 않았습니다"
		status_label.modulate = Color.RED
		return
	
	status_label.text = "게임 시작!"
	status_label.modulate = Color.GREEN
	
	# 모든 클라이언트에게 게임 시작 알림
	NetworkManager.start_game.rpc()

# 나가기 버튼
func _on_leave_pressed():
	NetworkManager.disconnect_from_server()
	get_tree().change_scene_to_file("res://scenes/menu/main_menu.tscn")

# 상태 업데이트
func _update_status():
	var player_count = NetworkManager.players.size()
	var max_players = NetworkManager.server_info.max_players
	status_label.text = "플레이어: %d / %d" % [player_count, max_players]
	status_label.modulate = Color.WHITE
