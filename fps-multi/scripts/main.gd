extends Node3D

## 메인 씬 스크립트
## 게임 초기화 및 플레이어-HUD 연결

@onready var hud: HUD = $HUD
@onready var multiplayer_spawner = $MultiplayerSpawner

# 로컬 플레이어 참조
var local_player: PlayerController = null

# 클라이언트 스폰 대기용 시그널
signal _spawn_complete_received

# 무기 씬 미리 로드
var weapon_scenes = {
	"assault_rifle": preload("res://scenes/weapons/assault_rifle.tscn"),
	"burst_rifle": preload("res://scenes/weapons/burst_rifle.tscn"),
	"awp": preload("res://scenes/weapons/awp.tscn"),
	"shotgun": preload("res://scenes/weapons/shotgun.tscn"),
	"pistol": preload("res://scenes/weapons/pistol.tscn"),
	"uzi": preload("res://scenes/weapons/uzi.tscn"),
	"fist": preload("res://scenes/weapons/fist.tscn"),
	"knife": preload("res://scenes/weapons/knife.tscn"),
	"katana": preload("res://scenes/weapons/katana.tscn")
}

func _ready():
	print("메인 씬 로딩 시작 (peer ID: %d, 서버: %s)" % [multiplayer.get_unique_id(), multiplayer.is_server()])
	
	# 메인 씬을 시작 씬으로 설정
	if not get_tree().current_scene:
		get_tree().current_scene = self
	
	# 멀티플레이어 모드인지 확인
	if multiplayer.get_peers().size() > 0 or NetworkManager.is_server:
		print("멀티플레이어 모드로 시작 (플레이어 수: %d)" % NetworkManager.players.size())
		
		# 기존 싱글 플레이어 제거
		if has_node("Player"):
			$Player.queue_free()
		
		# 잠시 대기 (모든 플레이어 정보가 동기화될 때까지)
		await get_tree().create_timer(0.3).timeout
		
		# 서버만 모든 플레이어 스폰 후 RPC로 클라이언트에 알림
		if multiplayer.is_server():
			print("서버: 모든 플레이어 스폰 중...")
			for peer_id in NetworkManager.players:
				_spawn_player(peer_id)
			
			# 모든 클라이언트에게 스폰 완료 알림
			_notify_spawn_complete.rpc()
		else:
			# 클라이언트는 서버의 스폰 완료 신호 대기
			print("클라이언트: 서버 스폰 대기 중...")
			await _spawn_complete_received
			print("클라이언트: 스폰 완료 신호 받음")
	else:
		print("싱글플레이어 모드로 시작")
		# 싱글플레이어 모드: 기존 플레이어 사용
		local_player = $Player
		if local_player:
			setup_player(local_player)

# 플레이어 스폰 함수 (서버만 호출)
func _spawn_player(peer_id: int):
	print("[서버] 플레이어 %d 스폰 중..." % peer_id)
	
	var player_scene = load("res://scenes/player/player.tscn")
	var player = player_scene.instantiate()
	
	# 플레이어 이름을 peer_id로 설정 (동기화용)
	player.name = str(peer_id)
	player.set_multiplayer_authority(peer_id)
	
	# 스폰 위치 설정 (원형으로 배치)
	var spawn_index = NetworkManager.players.keys().find(peer_id)
	var angle = (PI * 2.0 / max(1, NetworkManager.players.size())) * spawn_index
	var spawn_radius = 5.0
	var spawn_pos = Vector3(
		cos(angle) * spawn_radius,
		2.0,
		sin(angle) * spawn_radius
	)
	player.position = spawn_pos
	
	print("[서버] 플레이어 %d 위치: %v" % [peer_id, spawn_pos])
	
	# 씬에 추가
	add_child(player, true)
	
	# 모든 클라이언트에게 이 플레이어 스폰 알림
	_spawn_player_on_client.rpc(peer_id, spawn_pos)
	
	# 서버 자신의 플레이어면 설정
	if peer_id == multiplayer.get_unique_id():
		print("★ [서버] 로컬 플레이어 %d 설정 중..." % peer_id)
		local_player = player
		
		await get_tree().process_frame
		await get_tree().process_frame
		setup_player(player)
		print("★ [서버] 로컬 플레이어 %d 설정 완료" % peer_id)
	else:
		print("[서버] 원격 플레이어 %d 스폰 완료" % peer_id)
	
	return player

# 클라이언트에서 플레이어 스폰 (RPC)
@rpc("authority", "call_local", "reliable")
func _spawn_player_on_client(peer_id: int, spawn_pos: Vector3):
	# 서버는 이미 스폰했으므로 무시
	if multiplayer.is_server():
		return
	
	print("[클라이언트] 플레이어 %d 스폰 중... (위치: %v)" % [peer_id, spawn_pos])
	
	var player_scene = load("res://scenes/player/player.tscn")
	var player = player_scene.instantiate()
	
	player.name = str(peer_id)
	player.set_multiplayer_authority(peer_id)
	player.position = spawn_pos
	
	add_child(player, true)
	
	# 자기 자신의 플레이어면 설정
	var my_id = multiplayer.get_unique_id()
	if peer_id == my_id:
		print("★ [클라이언트] 내 플레이어 %d 스폰 완료!" % peer_id)
		local_player = player
		
		await get_tree().process_frame
		await get_tree().process_frame
		setup_player(player)
		print("★ [클라이언트] 로컬 플레이어 %d 설정 완료" % peer_id)
	else:
		print("[클라이언트] 원격 플레이어 %d 스폰 완료" % peer_id)

# 스폰 완료 알림 (서버 → 클라이언트)
@rpc("authority", "call_local", "reliable")
func _notify_spawn_complete():
	if not multiplayer.is_server():
		print("[클라이언트] 모든 플레이어 스폰 완료")
		_spawn_complete_received.emit()

# 플레이어 설정
func setup_player(player: PlayerController):
	print("플레이어 설정 시작: %s" % player.name)
	
	# 카메라 확인
	if player.has_node("CameraController/Camera3D"):
		var camera = player.get_node("CameraController/Camera3D")
		print("카메라 상태: current=%s" % camera.current)
	
	# HUD 연결
	if hud:
		print("HUD 연결 중...")
		hud.setup_player(player)
	
	# 무기 초기 설정
	var weapon_manager = player.get_node_or_null("CameraController/Camera3D/WeaponManager")
	if weapon_manager:
		print("무기 설정 중...")
		setup_weapons_for_player(weapon_manager)
	
	print("플레이어 설정 완료")

# 무기 초기 설정
# 플레이어에게 기본 무기들을 장착
func setup_weapons_for_player(weapon_manager: WeaponManager):
	if not weapon_manager:
		return
	
	# 슬롯 0 (주무기) - 돌격소총
	var assault_rifle = weapon_scenes["assault_rifle"].instantiate()
	weapon_manager.add_weapon(assault_rifle, 0)
	
	# 슬롯 1 (보조무기) - 권총
	var pistol = weapon_scenes["pistol"].instantiate()
	weapon_manager.add_weapon(pistol, 1)
	
	# 슬롯 2 (근접무기) - 주먹
	var fist = weapon_scenes["fist"].instantiate()
	weapon_manager.add_weapon(fist, 2)

# 무기 추가 (런타임에 무기를 추가하고 싶을 때 사용)
# weapon_name: 무기 이름
# slot_index: 슬롯 인덱스
func add_weapon_to_player(weapon_name: String, slot_index: int):
	if not local_player:
		return
	
	var weapon_manager = local_player.get_node_or_null("CameraController/Camera3D/WeaponManager")
	if not weapon_manager:
		return
	
	if not weapon_scenes.has(weapon_name):
		print("무기를 찾을 수 없습니다: ", weapon_name)
		return
	
	var weapon = weapon_scenes[weapon_name].instantiate()
	weapon_manager.add_weapon(weapon, slot_index)
