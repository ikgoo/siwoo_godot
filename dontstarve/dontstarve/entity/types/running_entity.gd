extends entity
class_name running_entity

## 도망가는 생물 (기본 클래스)
@export var running_recog : int ## 도망 감지 범위

## 플레이어가 인식 범위에 들어왔을 때 호출되는 함수
## 도망가는 생물의 기본 동작
## player: 들어온 플레이어 노드
## entity_node: 이 entity를 가진 씬 노드 (StaticBody3D)
func on_player_enter(player, entity_node):
	print("생물이 플레이어를 감지하고 도망 준비를 합니다.")
	# TODO: running_recog 범위 내에서 플레이어 감지
	# TODO: 도망 로직 구현
