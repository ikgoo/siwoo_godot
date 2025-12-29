extends aggressive_entity
class_name boss_entity

## 보스급 생물 클래스
## 높은 체력과 특수 공격 패턴을 가진 강력한 적

## 보스 전용 스탯
@export var phase_count : int = 3 ## 페이즈 개수 (HP 구간별 행동 변화)
@export var phase_hp_thresholds : Array[float] = [0.75, 0.5, 0.25] ## 페이즈 전환 HP 비율
@export var enrage_damage_multiplier : float = 1.5 ## 분노 시 데미지 배율
@export var special_attack_cooldown : float = 10.0 ## 특수 공격 쿨타임
@export var is_immune_to_knockback : bool = true ## 넉백 면역 여부
@export var boss_music : AudioStream
## 플레이어가 인식 범위에 들어왔을 때 호출되는 함수
## 보스급 생물은 높은 체력과 특수 공격 패턴을 가진 강력한 적입니다
## player: 들어온 플레이어 노드
## entity_node: 이 entity를 가진 씬 노드 (StaticBody3D)
func on_player_enter(player, entity_node):
	print("보스 전투가 시작됩니다!")
	# TODO: 보스 전투 BGM 시작
	# TODO: 현재 HP로 페이즈 확인 (phase_hp_thresholds 사용)
	# TODO: 특수 공격 패턴 활성화 (special_attack_cooldown 체크)
	# TODO: is_immune_to_knockback 적용
	# TODO: 페이즈 전환 시 특수 연출 및 enrage_damage_multiplier 적용
	
	# 부모 클래스의 추적 시작
	super.on_player_enter(player, entity_node)
