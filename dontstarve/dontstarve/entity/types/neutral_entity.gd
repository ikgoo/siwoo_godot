extends entity
class_name neutral_entity

## 중립 생물 클래스
## 평소에는 공격하지 않지만, 공격받으면 반격합니다

## 중립 특성
@export var revenge_damage : int = 15 ## 반격 데미지
@export var revenge_duration : float = 10.0 ## 적대 상태 지속 시간 (초)
@export var revenge_speed_multiplier : float = 1.3 ## 반격 시 속도 배율
@export var call_allies : bool = true ## 주변 동료 호출 여부
@export var ally_call_range : float = 15.0 ## 동료 호출 범위

## 플레이어가 인식 범위에 들어왔을 때 호출되는 함수
## 중립 생물은 평소에는 공격하지 않지만, 공격받으면 반격합니다
## player: 들어온 플레이어 노드
## entity_node: 이 entity를 가진 씬 노드 (StaticBody3D)
func on_player_enter(player, entity_node):
	print("중립 생물이 경계하고 있습니다.")
	# TODO: 평소에는 무반응, 플레이어 관찰만
	# TODO: 공격받으면 revenge_duration 동안 적대 상태로 전환
	# TODO: call_allies가 true면 ally_call_range 내 동료들 호출
	# TODO: 반격 시 revenge_damage와 revenge_speed_multiplier 적용


