extends entity
class_name enemy

## 공격 관련 스탯
@export var damage : int ## 공격 데미지
@export var att_cool : int ## 공격 쿨타임 (초)

## 플레이어가 인식 범위에 들어왔을 때 호출되는 함수
## 적 생물의 기본 공격 동작
## player: 들어온 플레이어 노드
## entity_node: 이 entity를 가진 씬 노드 (StaticBody3D)
func on_player_enter(player, entity_node):
	print("적이 플레이어를 발견했습니다! 데미지: ", damage)
	# TODO: 플레이어 공격 시작
	# TODO: att_cool 쿨타임 체크
