extends Node

## 네트워크 매니저 (싱글톤)
## 서버/클라이언트 생성 및 플레이어 관리

# 시그널
signal player_connected(peer_id: int, player_info: Dictionary)
signal player_disconnected(peer_id: int)
signal server_created()
signal server_creation_failed(error: String)
signal connection_succeeded()
signal connection_failed()

# 네트워크 설정
const DEFAULT_PORT = 7777
const MAX_CLIENTS = 3  # 호스트 제외 3명 = 총 4명

# 서버 정보
var server_info = {
	"name": "My Server",
	"port": DEFAULT_PORT,
	"max_players": 4
}

# 플레이어 정보 {peer_id: {name, is_ready}}
var players = {}
var local_player_name = "Player"

# 네트워크 상태
var is_server = false
var is_client = false

# UPNP 인스턴스
var upnp: UPNP = null

func _ready():
	print("NetworkManager 초기화 시작")
	
	# 멀티플레이어 시그널 연결
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	multiplayer.connected_to_server.connect(_on_connected_to_server)
	multiplayer.connection_failed.connect(_on_connection_failed)
	multiplayer.server_disconnected.connect(_on_server_disconnected)
	
	print("NetworkManager 초기화 완료")

# 서버 생성
# server_name: 서버 이름
# port: 포트 번호
# max_players: 최대 플레이어 수
# use_upnp: UPNP 사용 여부
func create_server(server_name: String, port: int = DEFAULT_PORT, max_players: int = 4, use_upnp: bool = false):
	server_info.name = server_name
	server_info.port = port
	server_info.max_players = max_players
	
	var peer = ENetMultiplayerPeer.new()
	var error = peer.create_server(port, max_players - 1)  # 호스트 제외
	
	if error != OK:
		server_creation_failed.emit("서버 생성 실패: 포트 %d가 이미 사용 중일 수 있습니다." % port)
		return
	
	multiplayer.multiplayer_peer = peer
	is_server = true
	
	# 호스트도 플레이어로 추가
	var host_id = multiplayer.get_unique_id()
	players[host_id] = {
		"name": local_player_name,
		"is_ready": false
	}
	
	print("서버 생성 성공! 포트: %d" % port)
	
	# UPNP 시도
	if use_upnp:
		_setup_upnp(port)
	
	server_created.emit()

# 클라이언트로 서버 접속
# ip_address: 서버 IP
# port: 서버 포트
func join_server(ip_address: String, port: int = DEFAULT_PORT):
	var peer = ENetMultiplayerPeer.new()
	var error = peer.create_client(ip_address, port)
	
	if error != OK:
		connection_failed.emit()
		print("서버 접속 실패: %s:%d" % [ip_address, port])
		return
	
	multiplayer.multiplayer_peer = peer
	is_client = true
	print("서버에 접속 시도 중: %s:%d" % [ip_address, port])

# UPNP 설정 (자동 포트 포워딩)
func _setup_upnp(port: int):
	upnp = UPNP.new()
	
	var discover_result = upnp.discover()
	if discover_result != UPNP.UPNP_RESULT_SUCCESS:
		print("UPNP 장치를 찾을 수 없습니다.")
		return
	
	if upnp.get_gateway() and upnp.get_gateway().is_valid_gateway():
		var map_result = upnp.add_port_mapping(port, port, "FPS_Multi", "UDP")
		if map_result != UPNP.UPNP_RESULT_SUCCESS:
			print("UPNP 포트 매핑 실패")
		else:
			print("UPNP 포트 매핑 성공! 외부 IP: %s" % upnp.query_external_address())
	else:
		print("유효한 UPNP 게이트웨이를 찾을 수 없습니다.")

# 연결 해제
func disconnect_from_server():
	if multiplayer.multiplayer_peer:
		multiplayer.multiplayer_peer.close()
		multiplayer.multiplayer_peer = null
	
	players.clear()
	is_server = false
	is_client = false
	
	# UPNP 포트 매핑 제거
	if upnp:
		upnp.delete_port_mapping(server_info.port)
		upnp = null

# 새 플레이어 연결 시
func _on_peer_connected(id: int):
	print("플레이어 연결: %d (총 %d명)" % [id, players.size()])
	
	if is_server:
		# 서버에서 기존 플레이어 정보를 새 플레이어에게 전송
		print("서버: 기존 플레이어 정보를 %d에게 전송 중..." % id)
		for peer_id in players:
			if peer_id != id:
				rpc_id(id, "_register_player", peer_id, players[peer_id])
				print("  -> 플레이어 %d 정보 전송" % peer_id)

# 플레이어 연결 해제 시
func _on_peer_disconnected(id: int):
	print("플레이어 연결 해제: %d" % id)
	players.erase(id)
	player_disconnected.emit(id)

# 서버 접속 성공
func _on_connected_to_server():
	print("서버 접속 성공!")
	var my_id = multiplayer.get_unique_id()
	
	# 로컬에도 자신의 정보 등록
	players[my_id] = {"name": local_player_name, "is_ready": false}
	print("클라이언트: 내 정보 로컬 등록 완료 (ID: %d)" % my_id)
	
	# 서버에 내 정보 등록 요청
	print("클라이언트: 서버에 등록 요청 (ID: %d)" % my_id)
	rpc_id(1, "_register_player", my_id, {"name": local_player_name, "is_ready": false})
	
	connection_succeeded.emit()

# 서버 접속 실패
func _on_connection_failed():
	print("서버 접속 실패")
	multiplayer.multiplayer_peer = null
	is_client = false
	connection_failed.emit()

# 서버 연결 끊김
func _on_server_disconnected():
	print("서버와 연결이 끊어졌습니다")
	multiplayer.multiplayer_peer = null
	is_client = false
	players.clear()

# 플레이어 등록 (RPC)
@rpc("any_peer", "reliable")
func _register_player(id: int, player_info: Dictionary):
	print("플레이어 등록: %d (이름: %s)" % [id, player_info.name])
	players[id] = player_info
	player_connected.emit(id, player_info)
	print("현재 등록된 플레이어: %d명" % players.size())
	
	# 서버인 경우 다른 모든 플레이어에게 브로드캐스트
	if is_server and multiplayer.get_remote_sender_id() != 0:
		print("서버: 플레이어 %d 정보를 다른 플레이어들에게 브로드캐스트" % id)
		for peer_id in multiplayer.get_peers():
			if peer_id != id:
				print("  -> 플레이어 %d에게 전송" % peer_id)
				rpc_id(peer_id, "_register_player", id, player_info)

# 플레이어 준비 상태 변경
@rpc("any_peer", "reliable")
func set_player_ready(id: int, ready: bool):
	if players.has(id):
		players[id].is_ready = ready
		print("플레이어 %d 준비 상태 변경: %s" % [id, ready])
		
		# 서버에서 받았으면 모든 클라이언트에 브로드캐스트
		if multiplayer.is_server():
			print("서버: 준비 상태를 모든 클라이언트에 브로드캐스트")
			for peer_id in multiplayer.get_peers():
				rpc_id(peer_id, "_update_player_ready", id, ready)
	else:
		print("경고: 플레이어 %d를 찾을 수 없음" % id)

# 준비 상태 업데이트 (서버에서 클라이언트로)
@rpc("authority", "reliable")
func _update_player_ready(id: int, ready: bool):
	if players.has(id):
		players[id].is_ready = ready
		print("준비 상태 업데이트 받음: 플레이어 %d = %s" % [id, ready])
		# 로비 UI 새로고침을 위한 시그널 (필요하면)
		player_connected.emit(id, players[id])
	else:
		print("경고: 플레이어 %d를 찾을 수 없음" % id)

# 모든 플레이어가 준비되었는지 확인
func all_players_ready() -> bool:
	for id in players:
		if not players[id].is_ready:
			return false
	return true

# 게임 시작 (서버만)
@rpc("authority", "call_local", "reliable")
func start_game():
	print("게임 시작 신호 받음! (서버: %s)" % is_server)
	# 게임 씬으로 전환
	get_tree().change_scene_to_file("res://scenes/main.tscn")

# 로컬 플레이어 이름 설정
func set_local_player_name(player_name: String):
	local_player_name = player_name

# 외부 IP 가져오기 (UPNP 사용 시)
func get_external_ip() -> String:
	if upnp:
		return upnp.query_external_address()
	return ""

