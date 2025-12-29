extends aggressive_entity
class_name moon_creature

## 달 위상 전용 생물 클래스
## 특정 달 위상에서만 등장하며, 달빛을 받으면 강화됩니다

## 달 관련 특성
@export var moonlight_damage_boost : float = 1.3 ## 달빛 아래 데미지 증가 배율
@export var moonlight_speed_boost : float = 1.2 ## 달빛 아래 속도 증가 배율
@export var glow_in_moonlight : bool = true ## 달빛 아래 발광 효과
@export var howl_on_spawn : bool = true ## 스폰 시 울부짖기 (사운드 효과)

## 플레이어가 인식 범위에 들어왔을 때 호출되는 함수
## 달 위상 전용 생물은 특정 달 위상에서만 등장하며, 달빛을 받으면 강화됩니다
## player: 들어온 플레이어 노드
## entity_node: 이 entity를 가진 씬 노드 (StaticBody3D)
func on_player_enter(player, entity_node):
	print("달의 생물이 플레이어를 발견했습니다!")
	# TODO: 현재 달 위상 체크 (moon_phase_spawn 사용)
	# TODO: 달빛 아래면 moonlight_damage_boost와 moonlight_speed_boost 적용
	# TODO: glow_in_moonlight가 true면 발광 효과 활성화
	# TODO: howl_on_spawn이 true면 울부짖기 사운드 재생
	
	# 부모 클래스의 추적 시작
	super.on_player_enter(player, entity_node)
