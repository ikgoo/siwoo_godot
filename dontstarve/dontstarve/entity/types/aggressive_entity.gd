extends entity
class_name aggressive_entity

## 공격적인 생물의 기본 클래스
## 플레이어를 발견하면 추격하고 공격합니다

## 공격 관련 스탯
@export var damage : int = 10 ## 공격 데미지
@export var att_reload : float = 2.0
@export var att_cool : float = 2.0 ## 공격 쿨타임 (초)
@export var aggro_range : float = 10.0 ## 어그로 범위 (플레이어 감지 거리)
@export var chase_speed_multiplier : float = 1.2 ## 추격 시 속도 배율
@export var move_n_attack : bool
## 추적 관련 변수
var is_chasing : bool = false
var chase_target : Node3D = null
var attack_cooldown_timer : float = 0.0
var last_known_position : Vector3 = Vector3.ZERO  # 마지막으로 본 플레이어 위치
var moving_to_last_position : bool = false  # 마지막 위치로 이동 중인지

# 플레이어가 인식 범위에 들어왔을 때 호출되는 함수
# 공격적인 생물은 플레이어를 발견하면 즉시 추격을 시작합니다
# player: 들어온 플레이어 노드
# entity_node: 이 entity를 가진 씬 노드 (StaticBody3D)
func on_player_enter(player, entity_node):
	print("[aggressive_entity] 플레이어 발견! 추적 시작 - 데미지: ", damage)
	start_chasing(player, entity_node)


# 플레이어 추적을 시작하는 함수
# target: 추적할 대상 (플레이어)
# entity_node: 이 entity를 가진 씬 노드 (StaticBody3D)
func start_chasing(target: Node3D, entity_node: Node3D) -> void:
	is_chasing = true
	chase_target = target
	print("[aggressive_entity] 추적 시작: ", target.name)


# 플레이어 추적을 중지하는 함수
func stop_chasing() -> void:
	is_chasing = false
	chase_target = null
	print("[aggressive_entity] 추적 중지")


# 매 프레임 추적 로직을 처리하는 함수
# entity_node의 _process에서 호출되어야 합니다
# delta: 프레임 간 시간 간격
# entity_node: 이 entity를 가진 씬 노드 (StaticBody3D)
func process_chasing(delta: float, entity_node: Node3D) -> void:
	# 공격 쿨타임 감소
	if attack_cooldown_timer > 0:
		attack_cooldown_timer -= delta
	
	# 마지막 위치로 이동 중인 경우
	if moving_to_last_position:
		var distance_to_last = entity_node.global_position.distance_to(last_known_position)
		
		# 마지막 위치에 도착했으면 이동 중지
		if distance_to_last < 0.5:
			print("[aggressive_entity] 마지막 위치에 도착 - 대기")
			moving_to_last_position = false
			return
		
		# 마지막 위치로 이동
		var direction = (last_known_position - entity_node.global_position).normalized()
		var chase_speed = speed * chase_speed_multiplier
		entity_node.global_position += direction * chase_speed * delta
		return
	
	# 추적 중이고 타겟이 있으면
	if is_chasing and chase_target:
		# 타겟까지의 거리 계산
		var distance = entity_node.global_position.distance_to(chase_target.global_position)
		
		# aggro_range를 벗어나면 추적 중지
		if distance > aggro_range:
			stop_chasing()
			return
		
		# attack_area 반지름 가져오기 (안전 거리 계산용)
		var safe_distance = 0.3  # 기본값
		if entity_node.has_node("attack_area"):
			var attack_area = entity_node.get_node("attack_area")
			if attack_area.get_child_count() > 0:
				var shape = attack_area.get_child(0).shape
				if shape is SphereShape3D:
					safe_distance = shape.radius + 0.1  # 반지름 + 여유
		
		# 공격 타이머가 실행 중인지 체크
		var is_attacking = false
		if "is_attack_timer_running" in entity_node:
			is_attacking = entity_node.is_attack_timer_running
		
		# 이동 조건 체크
		# 1. 안전 거리보다 멀리 있어야 함
		# 2. move_n_attack이 true이거나, 공격 중이 아니어야 함
		var can_move = distance > safe_distance and (move_n_attack or not is_attacking)
		
		if can_move:
			var direction = (chase_target.global_position - entity_node.global_position).normalized()
			var chase_speed = speed * chase_speed_multiplier
			entity_node.global_position += direction * chase_speed * delta
		
		# 공격 범위 내에 있고 쿨타임이 끝났으면 공격
		if distance < 0.01 and attack_cooldown_timer <= 0:
			attack_player(chase_target)


# 플레이어를 공격하는 함수
# player: 공격할 플레이어 노드
func attack_player(player: Node3D) -> void:
	print("[aggressive_entity] 플레이어 공격! 데미지: ", damage)
	
	# 플레이어에게 데미지 입히기
	if player.has_method("take_damage"):
		player.take_damage(damage)

	# 공격 쿨타임 설정
	attack_cooldown_timer = att_cool

func on_player_exit(player,me):
	is_chasing = false
	moving_to_last_position = false

## 마지막으로 본 플레이어 위치를 설정하는 함수
## entity.gd에서 호출됩니다
func set_last_known_position(position: Vector3):
	last_known_position = position
	moving_to_last_position = true
	print("[aggressive_entity] 마지막 위치 설정: ", position)

func bhaver():
	pass
