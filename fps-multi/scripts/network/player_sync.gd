extends Node

## 플레이어 동기화 스크립트
## 각 플레이어에 추가되어 멀티플레이어 동기화 처리

func _ready():
	var player = get_parent() as CharacterBody3D
	if not player:
		return
	
	# 싱글플레이어 모드면 아무것도 안 함
	if multiplayer.get_peers().size() == 0:
		return
	
	# 멀티플레이어 권한 설정
	var peer_id = str(player.name).to_int()
	if peer_id > 0:
		player.set_multiplayer_authority(peer_id)
	
	print("플레이어 %d 동기화 시작 (로컬: %s, 내 ID: %d)" % [peer_id, player.is_multiplayer_authority(), multiplayer.get_unique_id()])
	
	# 잠시 대기 후 설정 (씬 트리에 완전히 추가된 후)
	await get_tree().process_frame
	
	# 카메라 설정
	if player.has_node("CameraController/Camera3D"):
		var camera = player.get_node("CameraController/Camera3D")
		
		if player.is_multiplayer_authority():
			# 로컬 플레이어: 카메라 활성화
			camera.current = true
			camera.make_current()
			print("플레이어 %d: 카메라 활성화 (로컬 플레이어) - current: %s" % [peer_id, camera.current])
		else:
			# 원격 플레이어: 카메라 비활성화
			camera.current = false
			print("플레이어 %d: 카메라 비활성화 (원격 플레이어)" % peer_id)
	
	# 메시 설정
	if player.has_node("MeshInstance3D"):
		var mesh = player.get_node("MeshInstance3D")
		
		if not player.is_multiplayer_authority():
			# 원격 플레이어만 메시 표시
			mesh.visible = true
			# 다른 색으로 표시
			var material = StandardMaterial3D.new()
			material.albedo_color = Color(0.3, 0.7, 1.0)  # 파란색
			mesh.material_override = material
			print("플레이어 %d: 메시 표시 (원격 플레이어)" % peer_id)
		else:
			# 로컬 플레이어는 메시 숨김
			mesh.visible = false
			print("플레이어 %d: 메시 숨김 (로컬 플레이어)" % peer_id)
	
	# 플레이어 이름 표시
	_create_name_tag(player, peer_id)

# 이름 태그 생성
func _create_name_tag(player: CharacterBody3D, peer_id: int):
	var player_name = "Player %d" % peer_id
	
	if NetworkManager.players.has(peer_id):
		player_name = NetworkManager.players[peer_id].name
	
	# PlayerNameTag 노드 찾기
	var name_tag_parent = player.get_node_or_null("PlayerNameTag")
	if not name_tag_parent:
		name_tag_parent = Node3D.new()
		name_tag_parent.name = "PlayerNameTag"
		name_tag_parent.position = Vector3(0, 2.2, 0)
		player.add_child(name_tag_parent)
	
	# Label3D로 이름 표시
	var name_label = Label3D.new()
	name_label.text = player_name
	name_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	name_label.no_depth_test = true
	name_label.font_size = 32
	name_label.outline_size = 8
	name_tag_parent.add_child(name_label)
	
	# 로컬 플레이어는 이름 숨기기
	if player.is_multiplayer_authority():
		name_tag_parent.visible = false
