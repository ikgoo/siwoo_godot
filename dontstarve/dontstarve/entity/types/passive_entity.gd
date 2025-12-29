extends entity
class_name passive_entity

## 수동적인 생물 클래스
## 플레이어를 공격하지 않으며, 주로 도망가거나 가만히 있습니다

## 수동적 특성
@export var is_friendly : bool = false ## 우호적 여부
@export var flee_when_attacked : bool = true ## 공격받으면 도망가는지 여부
@export var wander_enabled : bool = true ## 배회 활성화 여부
@export var wander_range : float = 5.0 ## 배회 범위
@export var wander_interval : float = 3.0 ## 배회 간격 (초)

## 플레이어가 인식 범위에 들어왔을 때 호출되는 함수
## 수동적인 생물은 플레이어를 공격하지 않으며, 배회를 멈추거나 도망갑니다
## player: 들어온 플레이어 노드
## entity_node: 이 entity를 가진 씬 노드 (StaticBody3D)
func on_player_enter(player, entity_node):
	print("수동적 생물이 플레이어를 인식했습니다.")
	# TODO: 배회 멈추기
	# TODO: flee_when_attacked가 true면 도망 준비
	# TODO: 상호작용 UI 표시 (잡기, 먹이주기 등)


