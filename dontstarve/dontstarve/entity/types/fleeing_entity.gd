extends passive_entity
class_name fleeing_entity

## 도망가는 생물 클래스
## 플레이어나 위협을 감지하면 반대 방향으로 도망갑니다

## 도망 특성
@export var flee_detection_range : float = 8.0 ## 위협 감지 범위
@export var flee_speed_multiplier : float = 1.5 ## 도망 시 속도 배율
@export var flee_distance : float = 15.0 ## 도망가는 거리
@export var panic_duration : float = 5.0 ## 공황 상태 지속 시간 (초)
@export var can_be_caught : bool = true ## 잡을 수 있는지 여부

## 플레이어가 인식 범위에 들어왔을 때 호출되는 함수
## 도망가는 생물은 플레이어나 위협을 감지하면 반대 방향으로 도망갑니다
## player: 들어온 플레이어 노드
## entity_node: 이 entity를 가진 씬 노드 (StaticBody3D)
func on_player_enter(player, entity_node):
	print("생물이 겁에 질려 도망갑니다!")
	# TODO: 플레이어 위치 기준으로 반대 방향 계산
	# TODO: flee_speed_multiplier를 적용하여 속도 증가
	# TODO: flee_distance만큼 도망가기
	# TODO: panic_duration 동안 공황 상태 유지
	# TODO: can_be_caught가 true면 잡기 시도 가능하도록 설정
