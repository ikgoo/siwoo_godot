extends aggressive_entity
class_name nocturnal_entity

## 야행성 생물 클래스
## 밤에만 활동하며, 낮에는 숨거나 약화됩니다

## 야행성 특성
@export var night_only_spawn : bool = true ## 밤에만 스폰 여부
@export var day_weakness_multiplier : float = 0.5 ## 낮 시간 약화 배율 (50% 약화)
@export var night_power_multiplier : float = 1.3 ## 밤 시간 강화 배율 (30% 강화)
@export var hide_during_day : bool = true ## 낮에 숨기 여부
@export var light_sensitive : bool = true ## 빛에 민감 (횃불 등에 약함)
@export var light_damage_per_second : float = 2.0 ## 빛에 노출 시 초당 데미지

## 플레이어가 인식 범위에 들어왔을 때 호출되는 함수
## 야행성 생물은 밤에만 활동하며, 낮에는 숨거나 약화됩니다
## player: 들어온 플레이어 노드
## entity_node: 이 entity를 가진 씬 노드 (StaticBody3D)
func on_player_enter(player, entity_node):
	print("야행성 생물과 조우했습니다!")
	# TODO: 현재 시간(낮/밤) 체크
	# TODO: 밤이면 공격 시작 + night_power_multiplier 적용
	# TODO: 낮이면 day_weakness_multiplier 적용 또는 hide_during_day면 숨기
	# TODO: light_sensitive면 플레이어의 횃불 체크 후 light_damage_per_second 적용
	
	# 부모 클래스의 추적 시작
	super.on_player_enter(player, entity_node)
