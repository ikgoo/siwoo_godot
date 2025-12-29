extends aggressive_entity
class_name pack_entity

## 무리 생물 클래스
## 리더를 따라 이동하며, 무리가 많을수록 강해집니다

## 무리 특성
@export var is_pack_leader : bool = false ## 무리 리더 여부
@export var pack_bonus_per_member : float = 0.1 ## 무리원 1명당 능력치 증가 (10%)
@export var max_pack_bonus : float = 0.5 ## 최대 무리 보너스 (50%)
@export var pack_detection_range : float = 20.0 ## 무리원 감지 범위
@export var follow_leader : bool = true ## 리더 따라가기 여부
@export var leader_distance : float = 3.0 ## 리더와의 유지 거리

## 플레이어가 인식 범위에 들어왔을 때 호출되는 함수
## 무리 생물은 리더를 따라 이동하며, 무리가 많을수록 강해집니다
## player: 들어온 플레이어 노드
## entity_node: 이 entity를 가진 씬 노드 (StaticBody3D)
func on_player_enter(player, entity_node):
	print("무리 생물이 동료들과 함께 반응합니다!")
	# TODO: pack_detection_range 내 같은 종족 개수 확인
	# TODO: 무리 보너스 계산 (pack_bonus_per_member * 무리원 수, 최대 max_pack_bonus)
	# TODO: is_pack_leader가 false면 리더 위치 찾아서 함께 공격
	# TODO: 한 마리 공격하면 무리 전체가 반응하도록 신호 전송
	
	# 부모 클래스의 추적 시작
	super.on_player_enter(player, entity_node)


