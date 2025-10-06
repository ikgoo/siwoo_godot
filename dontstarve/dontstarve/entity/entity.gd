@tool
extends Node3D
@onready var sprite_3d = $Sprite3D
var hp
@onready var death_timer = $death_timer

# 아이템 드롭 설정 (obsticle과 동일한 방식)
@export_group("아이템 드롭 설정")
@export var drop_range_min: float = 0.05  # 최소 드롭 범위
@export var drop_range_max: float = 0.1  # 최대 드롭 범위
@export var arc_height_min: float = 0.05   # 최소 포물선 높이
@export var arc_height_max: float = 0.1   # 최대 포물선 높이
@onready var animation_player = $AnimationPlayer

# 도망가기 관련 변수들
var is_fleeing: bool = false
var flee_direction: Vector3
var flee_speed: float
var flee_target: Node3D = null
var tween: Tween
var flee_update_timer: Timer

# 공격 관련 변수들 (플레이어 F공격과 동일한 방식)
var is_attacking: bool = false          # 현재 공격 중인지 여부
var attack_target: Node3D = null        # 공격 대상 (플레이어)
var attack_tween: Tween                 # 플레이어 추적용 Tween
var last_player_position = Vector3.ZERO # 플레이어의 마지막 위치 추적
var is_target_in_attack_range = false   # 공격 대상이 Area3D 안에 있는지 여부
var is_attack_timer_running = false     # 공격 타이머가 진행 중인지 여부
@onready var attack_timer = $attack_timer # 기존 attack_timer 노드 사용

@export var thing: entity = null:
	set(value):
		thing = value
		if thing:
			if sprite_3d:
				sprite_3d.texture = thing.img
				sprite_3d.hframes = thing.frames
				sprite_3d.vframes = thing.y_frames
			hp = thing.hp
			# 도망가기 속도 설정 (thing의 speed 또는 e_speed 사용)
			flee_speed = float(thing.e_speed) if thing.e_speed > 0 else float(thing.speed)
			
			# 도망가기 업데이트 타이머 생성
			if not flee_update_timer:
				flee_update_timer = Timer.new()
				flee_update_timer.wait_time = 0.5  # 0.5초마다 방향 업데이트 (캐릭터 추적과 균형 맞춤)
				flee_update_timer.timeout.connect(_on_flee_update_timer_timeout)
				add_child(flee_update_timer)
			
			# attack_timer의 wait_time을 entity의 attack_speed로 설정
			if attack_timer:
				attack_timer.wait_time = float(thing.attack_speed)
				attack_timer.one_shot = true

# 플레이어와 완전 동일한 physics_process 로직 추가
func _physics_process(_delta):
	# 공격 중일 때 플레이어 위치 추적 및 Tween 업데이트 (플레이어와 동일)
	if is_attacking and attack_target:
		# 공격 타이머가 이미 실행 중이면 아무것도 하지 않음
		if is_attack_timer_running:
			pass
		# 공격 대상이 범위에 없으면 계속 추적
		elif not is_target_in_attack_range:
			track_player_position()
		# 범위에 있는 경우는 Area3D 시그널에서 처리됨

func take_damage(damage:int):
	hp -= damage
	if hp <= 0:
		sprite_3d.modulate = Color(1.0, 0.0, 0.0, 1.0)
		death_timer.start()



func _on_death_timer_timeout():
	# 죽기 전에 아이템 드롭
	drop_items()
	queue_free()


# Area3D 시그널 함수들 (플레이어의 space_area와 동일한 역할)
func _on_area_3d_area_entered(area):
	var target_object = area.get_parent()
	
	# 공격 대상 플레이어가 범위에 진입한 경우
	if target_object.name == "CharacterBody3D" or target_object.get_script():
		var script_path = target_object.get_script().get_path() if target_object.get_script() else ""
		if script_path.get_file() == "character_body_3d.gd":
			if is_attacking and attack_target == target_object:
				is_target_in_attack_range = true
				
				# 이동 중단 (플레이어 F공격과 동일)
				if attack_tween:
					attack_tween.kill()
				
				# 즉시 공격 타이머 시작 (플레이어 start_attack_timer와 동일)
				start_attack_timer()

func _on_area_3d_area_exited(area):
	var target_object = area.get_parent()
	
	# 공격 대상이 범위를 벗어난 경우
	if target_object.name == "CharacterBody3D" or target_object.get_script():
		var script_path = target_object.get_script().get_path() if target_object.get_script() else ""
		if script_path.get_file() == "character_body_3d.gd":
			if is_attacking and attack_target == target_object:
				is_target_in_attack_range = false

func _on_recognize_area_entered(area):
	# 플레이어가 감지되면 AI 행동 결정
	var target_object = area.get_parent()
	
	# character_body_3d인지 확인 (플레이어)
	if target_object.name == "CharacterBody3D" or target_object.get_script():
		var script_path = target_object.get_script().get_path() if target_object.get_script() else ""
		if script_path.get_file() == "character_body_3d.gd":
			# entity의 attack_type에 따라 행동 결정
			if thing and thing.attack_type == entity.attack_typee.first_attack:
				# 적대적인 몹: 플레이어를 공격 (F키와 완전 동일한 방식)
				start_attack(target_object)
			else:
				# 기본적으로는 도망가기 (기존 로직 유지)
				start_fleeing(target_object)

func _on_recognize_area_exited(area):
	# 플레이어가 멀어지면 AI 행동 중단
	var target_object = area.get_parent()
	
	# 공격 또는 도망가기 중단
	if attack_target == target_object:
		stop_attack()
	elif flee_target == target_object:
		stop_fleeing()

func start_fleeing(target: Node3D):
	if is_fleeing:
		return  # 이미 도망가는 중이면 무시
	
	is_fleeing = true
	flee_target = target
	
	# 도망가기 업데이트 타이머 시작 (지속적으로 방향 업데이트)
	if flee_update_timer:
		flee_update_timer.start()
	
	# 첫 도망 이동 시작
	update_flee_direction_and_move()

func start_flee_movement():
	if not is_fleeing:
		return
	
	# 도망갈 목표 위치 계산 (현재 위치에서 도망 방향으로 이동)
	var flee_distance = 2.5  # 적당한 거리로 안정적인 이동
	var target_position = global_position + flee_direction * flee_distance
	target_position.y = global_position.y  # Y축 고정
	
	# 이동 시간 계산 (거리 / 속도)
	var distance = global_position.distance_to(target_position)
	var move_time = distance / flee_speed if flee_speed > 0 else 0.5
	
	# Tween으로 부드러운 이동
	if tween:
		tween.kill()
	
	tween = create_tween()
	tween.tween_property(self, "global_position", target_position, move_time)

func _on_flee_update_timer_timeout():
	# 타이머가 timeout될 때마다 플레이어 위치를 추적하고 방향 업데이트
	if is_fleeing and flee_target:
		var distance_to_player = global_position.distance_to(flee_target.global_position)
		if distance_to_player < 8.0:  # 8미터 이내면 계속 도망
			update_flee_direction_and_move()
		else:
			stop_fleeing()  # 충분히 멀어지면 도망 중단

func update_flee_direction_and_move():
	if not is_fleeing or not flee_target:
		return
	
	# 현재 플레이어 위치에서 반대 방향 재계산
	var to_player = (flee_target.global_position - global_position).normalized()
	flee_direction = -to_player  # 반대 방향
	flee_direction.y = 0  # Y축 고정 (지면에서만 이동)
	
	# 새로운 방향으로 이동 시작
	start_flee_movement()

func stop_fleeing():
	is_fleeing = false
	flee_target = null
	
	# 타이머 중단
	if flee_update_timer:
		flee_update_timer.stop()
	
	# Tween 중단
	if tween:
		tween.kill()
		tween = null

# 아이템 드롭 시스템 (obsticle과 완전히 동일한 방식)
func drop_items():
	# 새로운 확률적 드롭 시스템 우선 사용
	if thing and not thing.drops.is_empty():
		# 각 entity_drop에 대해 확률적으로 아이템 생성
		for drop_info in thing.drops:
			if drop_info.get_item == null:
				continue
			
			# 먼저 이 아이템이 드롭될지 확률적으로 결정
			if not drop_info.should_drop():
				continue
				
			# min_count와 max_count 사이의 균등한 확률로 개수 결정
			var drop_count = drop_info.get_random_count()
			
			# 드롭할 개수만큼 아이템 생성
			for i in range(drop_count):
				create_item_drop(drop_info.get_item)
	
	# 기존 호환성을 위한 fallback
	elif thing and not thing.drop_item.is_empty():
		for item in thing.drop_item:
			if item == null:
				continue
			create_item_drop(item)

# 개별 아이템을 땅에 드롭하는 함수
func create_item_drop(item: Item):
	# 아이템 복사본 생성
	var dropped_item = item.duplicate()
	dropped_item.count = 1  # 개별 아이템은 1개씩
	
	# 시작 위치 (몹 위치)
	var start_position = global_position
	
	# 목표 위치 계산 (몹 주변 랜덤 위치)
	var target_position = global_position
	target_position.x += randf_range(-drop_range_max, drop_range_max)  # X축 랜덤 오프셋
	target_position.z += randf_range(-drop_range_max, drop_range_max)  # Z축 랜덤 오프셋
	target_position.y = global_position.y        # Y축은 동일하게
	
	# ItemGround 씬 로드 및 생성
	var item_ground_scene = preload("res://item_ground.tscn")
	var item_ground = item_ground_scene.instantiate()
	
	# 아이템 설정
	item_ground.thing = dropped_item
	
	# 메인 씬에 추가
	get_tree().current_scene.add_child(item_ground)
	
	# 포물선 비행 시작 (거리에 따라 자동으로 비행 시간 계산)
	var distance = start_position.distance_to(target_position)
	var flight_time = distance * 0.3 + 0.5  # 거리에 비례한 비행 시간 (최소 0.5초)
	var arc_height = randf_range(arc_height_min, arc_height_max)     # 랜덤 포물선 높이
	item_ground.flying_item(start_position, target_position, flight_time, arc_height)



# ===== 공격 시스템 함수들 (플레이어 F공격과 완전 동일) =====

# 공격 시작 (플레이어의 start_attack과 동일)
func start_attack(target_player: Node3D):
	is_attacking = true
	attack_target = target_player
	last_player_position = target_player.global_position
	
	# 항상 플레이어에게 이동 시작 (Area3D 범위 체크는 별도로)
	move_to_player(target_player)

# 플레이어에게 이동하는 함수 (플레이어의 move_to_enemy와 동일)
func move_to_player(target_player: Node3D):
	# 공격 타이머가 실행 중이면 이동하지 않음
	if is_attack_timer_running:
		return
	
	# 기존 attack_tween이 있으면 중지
	if attack_tween:
		attack_tween.kill()
	
	# 새로운 attack_tween 생성
	attack_tween = create_tween()
	
	# 목표 위치 설정 (플레이어의 현재 위치)
	var player_position = target_player.global_position
	player_position.y = global_position.y  # Y축 고정
	
	# 이동 거리 및 시간 계산 (도망가기와 동일한 속도 사용)
	var distance = global_position.distance_to(player_position)
	var actual_speed = flee_speed if flee_speed > 0 else 2.0
	var move_time = distance / actual_speed
	
	# Tween으로 플레이어에게 이동
	attack_tween.tween_property(self, "global_position", player_position, move_time)

# 플레이어 위치 추적 및 Tween 업데이트 (플레이어의 track_enemy_position과 동일)
func track_player_position():
	if not attack_target or is_attack_timer_running:
		return  # 공격 타이머 실행 중이면 추적 중단
	
	var current_player_position = attack_target.global_position
	
	# 플레이어의 위치가 변경되었는지 확인 (일정 거리 이상 이동했을 때만)
	var position_change = last_player_position.distance_to(current_player_position)
	
	if position_change > 0.01:  # 0.01미터 이상 이동했을 때만 업데이트
		last_player_position = current_player_position
		
		# 기존 Tween 중단하고 새로운 경로로 이동 (공격 타이머 실행 중이 아닐 때만)
		if not is_attack_timer_running:
			move_to_player(attack_target)

# attack_timer 시작 (플레이어의 start_attack_timer와 동일)
func start_attack_timer():
	# 이미 타이머가 실행 중이면 중복 실행 방지
	if is_attack_timer_running:
		return
	animation_player.play(thing.my_animation_attack)
	is_attack_timer_running = true
	
	
	# 이동 중단
	if attack_tween:
		attack_tween.kill()
	
	# attack_timer 시작
	if attack_timer:
		attack_timer.start()

# 공격 중단 (애니메이션 상태 고려)
func stop_attack():
	# 애니메이션이 진행 중이면 완료될 때까지 대기
	if animation_player.is_playing():
		await animation_player.animation_finished
	
	# 애니메이션 완료 후 상태 초기화
	animation_player.play(thing.my_animation_walk)
	is_attacking = false
	attack_target = null
	last_player_position = Vector3.ZERO
	is_target_in_attack_range = false
	is_attack_timer_running = false
	
	# attack_tween 중단
	if attack_tween:
		attack_tween.kill()
		attack_tween = null

# attack_timer 완료 시 호출되는 함수 (애니메이션 완료 대기 로직 추가)
func _on_attack_timer_timeout():
	# 공격 타이머 완료 - 애니메이션이 끝날 때까지 기다림
	is_attack_timer_running = false
	
	if not is_attacking or not attack_target:
		return
	
	# 현재 진행 중인 애니메이션이 끝날 때까지 대기
	if animation_player.is_playing():
		# 애니메이션이 끝날 때까지 대기
		await animation_player.animation_finished
	
	# 애니메이션 완료 후 공격 처리
	execute_attack_after_animation()

# 애니메이션 완료 후 실제 공격을 실행하는 함수
func execute_attack_after_animation():
	# Area3D 내에 공격 대상(플레이어)이 있는지 확인
	if is_target_in_attack_range:
		# 플레이어에게 데미지 처리
		if attack_target.has_method("got_attacked"):
			attack_target.got_attacked(thing.attack_dam)
		
		print("Entity가 플레이어에게 ", thing.attack_dam, " 데미지를 입혔습니다!")
		
		# first_attack 타입이면 공격 후에도 계속 추적
		if thing and thing.attack_type == entity.attack_typee.first_attack:
			# 0.5초 후 다시 추적 시작
			await get_tree().create_timer(0.5).timeout
			if attack_target:  # 플레이어가 여전히 존재하면
				# 다시 추적 시작 (공격 상태는 유지)
				move_to_player(attack_target)
		else:
			# 다른 타입은 공격 완료 후 상태 초기화
			stop_attack()
	else:
		# 공격 범위에 없으면 first_attack은 다시 추적, 다른 타입은 중단
		if thing and thing.attack_type == entity.attack_typee.first_attack:
			# 다시 추적 시작
			move_to_player(attack_target)
		else:
			# 다른 타입은 공격 완료 후 상태 초기화
			stop_attack()
