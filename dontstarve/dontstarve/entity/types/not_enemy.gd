extends entity
class_name not_enemy

## 수동적인 생물 (공격하지 않음)

## 플레이어가 인식 범위에 들어왔을 때 호출되는 함수
## 수동적인 생물은 플레이어를 공격하지 않습니다
## player: 들어온 플레이어 노드
## entity_node: 이 entity를 가진 씬 노드 (StaticBody3D)
func on_player_enter(player, entity_node):
	print("수동적인 생물이 플레이어를 인식했습니다.")
	# TODO: 비공격적 반응 (관찰, 배회 등)
