extends CharacterBody3D

@onready var sprite_3d = $Sprite3D

@onready var collision_shape_3d = $Area3D/CollisionShape3D
@onready var att_cool = $att_cool
@onready var reloading = $reloading
@onready var character_scan = $charater_scan  # 플레이어 감지용 raycast

# 물리 충돌 관련 변수
var knockback_velocity: Vector3 = Vector3.ZERO  # 튕겨나가는 속도
var friction: float = 8.0  # 마찰력 (속도 감소율)
@onready var animation_player = $AnimationPlayer
# 아이템 드롭 설정
@export_group("아이템 드롭 설정")
@export var drop_range_min: float = 0.5  # 최소 드롭 범위
@export var drop_range_max: float = 2.0  # 최대 드롭 범위
@export var arc_height_min: float = 2.0   # 최소 포물선 높이
@export var arc_height_max: float = 4.0   # 최대 포물선 높이
# attack_area 관련 변수
var attack_area_node: Area3D = null  # attack_area 노드 참조
var knockback_strength_per_step: float = 0.1  # 한 스텝당 밀어내는 거리
var max_knockback_iterations: int = 100  # 무한루프 방지용 최대 반복 횟수

# 공격 관련 변수
var is_attack_timer_running: bool = false  # 공격 타이머 실행 중인지 여부
var is_reloading: bool = false  # 공격 후 휴식 중인지 여부
var player_in_attack_range: Node3D = null  # attack_area 안에 있는 플레이어

# 플레이어 추적 관련 변수
var player_in_recognition_area: Node3D = null  # 인식 범위 안에 있는 플레이어
var last_seen_player_position: Vector3 = Vector3.ZERO  # 마지막으로 본 플레이어 위치
var has_seen_player: bool = false  # 플레이어를 본 적이 있는지

@export var thing : entity:
	set(value):
		thing = value
		if thing:
			# 씬이 준비되기 전에 호출될 수 있으므로 체크
			if sprite_3d:
				apply_thing_properties()
			if collision_shape_3d:
				collision_shape_3d.shape.radius = thing.recog
		else:
			print("[entity] thing이 null로 설정됨")

# thing의 속성들을 Sprite3D에 적용하는 함수
# entity 리소스의 이미지, 프레임, 스케일 등을 설정합니다
func apply_thing_properties():
	# entity의 이미지를 Sprite3D에 적용
	if thing.img:
		sprite_3d.texture = thing.img
		print("[entity DEBUG] 텍스처 설정: ", thing.img.get_size(), " | region_enabled: ", sprite_3d.region_enabled)
	
	# img_xy를 사용해서 프레임 설정
	# x = 가로 프레임 개수, y = 세로 프레임 개수
	if thing.img_xy.x > 0:
		sprite_3d.hframes = thing.img_xy.x
	
	if thing.img_xy.y > 0:
		sprite_3d.vframes = thing.img_xy.y
	
	# 스케일 적용 (옵션)
	if thing.scale:
		scale = Vector3(thing.scale.x, thing.scale.y, thing.scale.z)
	
	# CollisionShape 크기 업데이트 (thing.pixel_s 값 전달)
	if sprite_3d.has_method("update_collision_shape_size"):
		sprite_3d.update_collision_shape_size(thing.pixel_s)
		print("[entity DEBUG] CollisionShape 업데이트 완료 (pixel_s: ", thing.pixel_s, ")")

# 씬이 준비되면 호출되는 함수
# Area3D 시그널을 연결하고 thing 속성을 적용합니다
func _ready():
	# StaticBody3D의 마우스 입력을 비활성화 (Area3D만 마우스 이벤트 받도록)
	input_ray_pickable = false
	
	# attack_area 노드 참조 저장
	attack_area_node = get_node_or_null("attack_area")
	if not attack_area_node:
		print("[Entity] 경고: attack_area 노드를 찾을 수 없습니다!")
	
	# att_cool 타이머 설정 (공격속도)
	if att_cool and thing:
		# aggressive_entity인 경우 att_cool 값 설정
		if thing is aggressive_entity:
			var aggro_entity = thing as aggressive_entity
			att_cool.wait_time = aggro_entity.att_cool
			att_cool.one_shot = true
			att_cool.timeout.connect(_on_att_cool_timeout)
			print("[Entity] 공격 타이머 설정: ", aggro_entity.att_cool, "초")
	
	# reloading 타이머 설정 (공격 후 휴식 시간)
	if reloading and thing:
		# aggressive_entity인 경우 att_reload 값 설정
		if thing is aggressive_entity:
			var aggro_entity = thing as aggressive_entity
			reloading.wait_time = aggro_entity.att_reload
			reloading.one_shot = true
			reloading.timeout.connect(_on_reloading_timeout)
			print("[Entity] 휴식 타이머 설정: ", aggro_entity.att_reload, "초")

	# thing이 있으면 속성 적용 (setter에서 호출되지 않았을 경우를 대비)
	if thing and sprite_3d:
		apply_thing_properties()


# 매 프레임 호출 - entity 타입별 로직 처리
func _physics_process(delta: float) -> void:
	# thing이 없으면 리턴
	if not thing:
		return
	
	# attack_area 안에 플레이어가 있는지 체크
	# 플레이어와 겹쳐있으면 이동하지 않음
	var is_overlapping_player = check_and_push_player_out()
	
	# 플레이어와 충돌 체크 및 각도 기반 튕김 처리
	handle_player_collision(delta)
	
	# 넉백 속도를 마찰력으로 감소
	if knockback_velocity.length() > 0.1:
		knockback_velocity = knockback_velocity.lerp(Vector3.ZERO, friction * delta)
		velocity = knockback_velocity
		move_and_slide()
	else:
		knockback_velocity = Vector3.ZERO
		velocity = Vector3.ZERO
	
	# 플레이어와 겹쳐있으면 추적 로직 실행 안 함
	if is_overlapping_player:
		return
	
	# 인식 범위 안에 플레이어가 있으면 지속적으로 raycast 체크
	if player_in_recognition_area and is_instance_valid(player_in_recognition_area):
		check_player_visibility_continuously()
	
	# aggressive_entity인 경우 추적 로직 처리
	if thing is aggressive_entity:
		var aggro_entity = thing as aggressive_entity
		# process_chasing 함수가 있는지 확인 후 호출
		if aggro_entity.has_method("process_chasing"):
			aggro_entity.process_chasing(delta, self)


func handle_player_collision(delta: float) -> void:
	# 충돌 감지를 위해 move_and_slide 호출
	var collision_count = get_slide_collision_count()
	
	for i in collision_count:
		var collision = get_slide_collision(i)
		var collider = collision.get_collider()
		
		# 충돌한 오브젝트가 플레이어인지 확인
		# 플레이어는 CharacterBody3D이며 collision_mask에 layer 6(entity)을 포함
		# 플레이어 감지는 groups로 확인하는 것이 더 안전
		if collider and collider.is_in_group("player"):
			# 충돌 지점의 법선 벡터 (collision normal)
			var collision_normal = collision.get_normal()
			
			# 플레이어에서 entity로의 방향 벡터
			var push_direction = (global_position - collider.global_position).normalized()
			push_direction.y = 0  # 수평 방향만 사용
			
			# 충돌 각도 계산 (0~180도)
			# dot product를 사용: -1(정면 충돌) ~ 1(측면 충돌)
			var collision_angle_factor = push_direction.dot(collision_normal)
			
			# 각도에 따른 튕김 강도 계산
			# 정면 충돌(-1): 강하게 튕김
			# 측면 충돌(0): 중간 정도 튕김
			# 비스듬한 충돌(1): 약하게 튕김
			var knockback_strength = lerp(5.0, 2.0, (collision_angle_factor + 1.0) / 2.0)
			
			# 반사 벡터 계산 (물리학의 반사 공식 사용)
			# reflect = direction - 2 * (direction · normal) * normal
			var reflect_direction = push_direction - 2 * push_direction.dot(collision_normal) * collision_normal
			reflect_direction.y = 0  # 수평으로만
			reflect_direction = reflect_direction.normalized()
			
			# 최종 넉백 속도 적용
			knockback_velocity = reflect_direction * knockback_strength
			
			print("[Entity] 플레이어 충돌! 각도 계수: %.2f, 튕김 강도: %.2f" % [collision_angle_factor, knockback_strength])
			break


# Area에 물체가 들어왔을 때 호출되는 함수
# area: 들어온 Area3D (플레이어의 space_area 또는 다른 entity)
func _on_area_3d_area_entered(area):
	print("[Entity DEBUG] area 진입 감지 - collision_layer: ", area.collision_layer)
	
	# collision layer 10번(추격용)인지 체크
	# 1 << 9 = 512 = layer 10
	if not area.collision_layer & (1 << 9):
		print("[Entity DEBUG] layer 10이 아님, 무시")
		return
	
	# thing이 없으면 리턴
	if not thing:
		print("[Entity DEBUG] thing이 없음")
		return
	
	# area의 부모(플레이어)를 찾아서 전달
	var player = area.get_parent()
	if not player:
		print("[Entity DEBUG] 플레이어를 찾을 수 없음")
		return
	
	print("[Entity DEBUG] 플레이어 발견! 인식 범위에 진입")
	
	# 플레이어를 인식 범위 변수에 저장 (지속적인 raycast 체크를 위해)
	player_in_recognition_area = player
	
	# 초기 raycast 체크
	check_player_visibility_continuously()

# main.gd에서 호출하는 픽셀 퍼펙트 체크 함수
# main.gd의 raycast 충돌 지점을 직접 사용하여 픽셀 퍼펙트를 실행
# detected_area: main.gd의 raycast가 감지한 Area3D 객체
# collision_point: main.gd의 raycast 충돌 지점 (월드 좌표)
# 반환값: 픽셀 퍼펙트 성공 시 true, 실패 시 false
func check_pixel_perfect_from_main(detected_area: Area3D, collision_point: Vector3) -> bool:
	if not sprite_3d:
		return false
	
	# sprite의 Area3D 가져오기 (entity는 "body"라는 이름 사용)
	var sprite_area_3d = sprite_3d.get_node_or_null("body")
	if not sprite_area_3d:
		return false
	
	# 감지된 Area가 내 Area가 아니면 false (다른 entity의 Area)
	if detected_area != sprite_area_3d:
		return false
	
	# sprite의 픽셀 퍼펙트 체크 함수 호출 (충돌 지점 전달)
	var pixel_check = sprite_3d.check_pixel_perfect_at_point(collision_point)
	
	if pixel_check:
		# 성공: 빨간색으로 표시
		if sprite_3d.has_method("set_red_highlight"):
			sprite_3d.set_red_highlight()
		return true
	else:
		# 실패: 원래 색상으로 복원
		if sprite_3d.has_method("update_hover_effect"):
			sprite_3d.is_hovered = false
			sprite_3d.update_hover_effect()
		return false

# 색상을 원래대로 복원하는 함수
func reset_color():
	if sprite_3d and sprite_3d.has_method("update_hover_effect"):
		sprite_3d.is_hovered = false
		sprite_3d.update_hover_effect()

# 마우스 클릭 처리 함수
# _camera: 클릭한 카메라 (사용하지 않음)
# event: 입력 이벤트
# _event_position: 클릭 위치 (사용하지 않음)
# _normal: 충돌 표면의 법선 벡터 (사용하지 않음)
# _shape_idx: 충돌한 shape 인덱스 (사용하지 않음)
func _on_input_event(_camera: Node, event: InputEvent, _event_position: Vector3, _normal: Vector3, _shape_idx: int):
	# 마우스 클릭 이벤트인지 확인
	if event is InputEventMouseButton:
		# 왼쪽 클릭이고 눌렀을 때 (released가 아님)
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			# UI 위에서 클릭했는지 확인
			var viewport = get_viewport()
			var control_under_mouse = viewport.gui_get_hovered_control()
			if control_under_mouse:
				# UI 위에서 클릭하면 이벤트를 통과시킴 (인벤토리 등)
				return
			
			# Shift 키가 눌려있으면 이동 (이벤트 통과시킴)
			if Input.is_key_pressed(KEY_SHIFT):
				return  # 이벤트를 통과시켜서 main.gd에서 처리하도록 함
			
			# entity 클릭 처리
			if thing:
				var hp_text = str(thing.hp) if "hp" in thing else "unknown"
				print("Entity 클릭: HP ", hp_text)
				
				# 플레이어에게 entity 설명 표시
				var player = get_tree().get_first_node_in_group("player")
				if player and player.has_method("show_description_text"):
					# entity 이름과 설명을 함께 표시
					var display_text = thing.entity_name
					if thing.description != "":
						display_text += "\n" + thing.description
					player.show_description_text(display_text, 3.0)
					print("[Entity] 설명 표시: ", display_text)
				
				get_viewport().set_input_as_handled()


func _on_area_3d_area_exited(area):
	# collision layer 10번(추격용)인지 체크
	# 1 << 9 = 512 = layer 10
	if not area.collision_layer & (1 << 9):
		return
	
	# thing이 없으면 리턴
	if not thing:
		return
	
	# area의 부모(플레이어)를 찾아서 전달
	var player = area.get_parent()
	if not player:
		return
	
	# 인식 범위 변수 초기화
	player_in_recognition_area = null
	has_seen_player = false
	last_seen_player_position = Vector3.ZERO
	
	print("[Entity] 플레이어가 인식 범위를 벗어남")
	
	# thing의 on_player_exit 함수 호출
	# 플레이어가 entity의 인식 범위를 벗어났을 때 처리
	thing.on_player_exit(player, self)



func check_and_push_player_out() -> bool:
	# attack_area가 없으면 리턴
	if not attack_area_node:
		return false
	
	# attack_area와 겹치는 모든 area 가져오기
	var overlapping_areas = attack_area_node.get_overlapping_areas()
	
	if overlapping_areas.size() > 0:
		print("[Entity DEBUG] 겹치는 area 개수: ", overlapping_areas.size())
	
	for area in overlapping_areas:
		print("[Entity DEBUG] area collision_layer: ", area.collision_layer, " | 이름: ", area.name)
		
		# collision layer 10번(player body_area)인지 체크
		# 1 << 9 = 512 = layer 10
		if not area.collision_layer & (1 << 9):
			continue
		
		# area의 부모(플레이어) 찾기
		var player = area.get_parent()
		if not player or not player.is_in_group("player"):
			continue
		
		print("[Entity DEBUG] 플레이어 발견! 밀어내기 시작")
		# entity를 밀어내기
		push_entity_out_of_player(player, area)
		return true  # 플레이어와 겹쳐있음
	
	return false  # 플레이어와 겹치지 않음


func push_entity_out_of_player(player: Node3D, player_body_area: Area3D) -> void:
	# 플레이어가 유효한지 체크
	if not is_instance_valid(player):
		return
	
	# 플레이어에서 entity로의 방향 계산
	var push_direction = (global_position - player.global_position).normalized()
	push_direction.y = 0  # 수평 방향만 사용
	
	# attack_area와 body_area의 반지름 가져오기
	var attack_shape = attack_area_node.get_child(0).shape as SphereShape3D
	var body_shape = player_body_area.get_child(0).shape as SphereShape3D
	
	if not attack_shape or not body_shape:
		print("[Entity] 경고: Shape를 찾을 수 없음")
		return
	
	var attack_radius = attack_shape.radius
	var body_radius = body_shape.radius
	var required_distance = attack_radius + body_radius
	
	# 현재 거리 계산
	var current_distance = global_position.distance_to(player.global_position)
	
	# 필요한 만큼 밀어냄
	if current_distance < required_distance:
		var push_amount = required_distance - current_distance + 0.01  # 약간 여유
		global_position += push_direction * push_amount
		print("[Entity] entity를 밀어냄 (거리: %.2f)" % push_amount)


# attack_area에 플레이어가 들어왔을 때 호출 (공격 시작)
func _on_attack_area_area_entered(area):
	# collision layer 8번(player body_area)인지 체크
	# 1 << 7 = 128 = layer 8
	if not area.collision_layer & (1 << 7):
		return
	
	# thing이 aggressive_entity가 아니면 공격 안 함
	if not thing or not thing is aggressive_entity:
		return
	
	# area의 부모(플레이어) 찾기
	var player = area.get_parent()
	if not player or not player.is_in_group("player"):
		return
	
	# 플레이어 저장
	player_in_attack_range = player
	
	# 타이머가 실행 중이 아니고 휴식 중이 아니면 시작
	if not is_attack_timer_running and not is_reloading and att_cool:
		is_attack_timer_running = true
		animation_player.stop()
		att_cool.start()
		animation_player.play("attack")
		print("[Entity] 공격 타이머 시작")
	elif is_reloading:
		print("[Entity] 플레이어 진입했지만 휴식 중이라 공격 안 함 (남은 시간: ", reloading.time_left, "초)")


# attack_area에서 플레이어가 나갔을 때 호출 (공격 중지)
func _on_attack_area_area_exited(area):
	# collision layer 8번(player body_area)인지 체크
	# 1 << 7 = 128 = layer 8
	if not area.collision_layer & (1 << 7):
		return
	
	# 플레이어 추적 중지
	player_in_attack_range = null
	print("[Entity] 플레이어가 공격 범위를 벗어남 (휴식 타이머는 계속 진행)")


# 공격 타이머 종료 시 호출
func _on_att_cool_timeout():
	is_attack_timer_running = false
	
	# attack_area 안에 layer 8(player body_area)이 있는지 체크
	if not attack_area_node:
		return
	
	var overlapping_areas = attack_area_node.get_overlapping_areas()
	
	for area in overlapping_areas:
		# collision layer 8번(player body_area)인지 체크
		# 1 << 7 = 128 = layer 8
		if not area.collision_layer & (1 << 7):
			continue
		
		# area의 부모(플레이어) 찾기
		var player = area.get_parent()
		if not player or not player.is_in_group("player"):
			continue
		
		# 플레이어와 entity 사이에 장애물이 있는지 raycast로 체크
		if not can_see_player(player):
			print("[Entity] 플레이어와 사이에 장애물이 있어 공격 불가")
			break
		
		# 플레이어에게 공격
		if player.has_method("got_attack"):
			var aggro_entity = thing as aggressive_entity
			player.got_attack(aggro_entity.damage)
			print("[Entity] 플레이어 공격! 데미지: ", aggro_entity.damage)
		
		# 공격 후 휴식 타이머 시작
		if player_in_attack_range and reloading:
			is_reloading = true
			reloading.start()
			print("[Entity] 휴식 타이머 시작 (", reloading.wait_time, "초)")
		
		break  # 한 명만 공격


## 휴식 타이머 종료 시 호출되는 함수
## 휴식이 끝나면 다시 공격 가능 상태로 전환
func _on_reloading_timeout():
	is_reloading = false
	print("[Entity] 휴식 종료 - 다시 공격 가능")
	
	# 플레이어가 여전히 attack_area 안에 있으면 다시 공격 시작
	if player_in_attack_range and not is_attack_timer_running and att_cool:
		# 플레이어와 entity 사이에 장애물이 있는지 raycast로 체크
		if not can_see_player(player_in_attack_range):
			print("[Entity] 플레이어와 사이에 장애물이 있어 공격 불가")
			return
		
		is_attack_timer_running = true
		animation_player.stop()
		att_cool.start()
		animation_player.play("attack")
		print("[Entity] 다음 공격 타이머 시작")


## 인식 범위 안의 플레이어를 지속적으로 체크하는 함수
## 매 프레임 호출되어 플레이어 가시성을 확인하고 추적 상태를 업데이트
func check_player_visibility_continuously():
	if not player_in_recognition_area or not is_instance_valid(player_in_recognition_area):
		return
	
	# raycast로 플레이어를 볼 수 있는지 체크
	var can_see = can_see_player(player_in_recognition_area)
	
	if can_see:
		# 플레이어를 볼 수 있음
		if not has_seen_player:
			# 처음 플레이어를 발견했을 때
			print("[Entity] 플레이어 발견! on_player_enter 호출")
			has_seen_player = true
			
			# thing의 on_player_enter 함수 호출
			if thing:
				thing.on_player_enter(player_in_recognition_area, self)
		
		# 마지막으로 본 위치 업데이트
		last_seen_player_position = player_in_recognition_area.global_position
	else:
		# 플레이어를 볼 수 없음 (장애물에 가려짐)
		if has_seen_player:
			# 이전에 플레이어를 봤었다면, 마지막 위치로 이동하도록 설정
			print("[Entity] 플레이어가 장애물에 가려짐 - 마지막 위치로 이동: ", last_seen_player_position)
			
			# aggressive_entity인 경우 마지막 위치를 target으로 설정
			if thing is aggressive_entity:
				var aggro_entity = thing as aggressive_entity
				if aggro_entity.has_method("set_last_known_position"):
					aggro_entity.set_last_known_position(last_seen_player_position)


## 플레이어를 볼 수 있는지 raycast로 체크하는 함수
## player: 체크할 플레이어 노드
## 반환값: 장애물이 없으면 true, 장애물이 있으면 false
func can_see_player(player: Node3D) -> bool:
	if not character_scan or not player:
		return true
	
	# character_scan을 플레이어 방향으로 향하게 함
	var direction = (player.global_position - global_position).normalized()
	var distance = global_position.distance_to(player.global_position)
	
	# character_scan의 target_position을 로컬 좌표로 변환
	var local_direction = global_transform.basis.inverse() * direction
	character_scan.target_position = local_direction * distance
	
	# raycast 강제 업데이트
	character_scan.force_raycast_update()
	
	print("[Entity DEBUG] raycast 시작 - 거리: %.2f" % distance)
	
	# 여러 충돌을 체크하기 위해 반복
	var max_iterations = 10
	var iteration = 0
	var current_offset = 0.0
	
	while iteration < max_iterations:
		iteration += 1
		
		# raycast가 충돌했는지 체크
		if character_scan.is_colliding():
			var collider = character_scan.get_collider()
			var collision_point = character_scan.get_collision_point()
			var collision_distance = global_position.distance_to(collision_point)
			
			# 충돌한 오브젝트 확인
			if collider.is_in_group("player"):
				# 플레이어와 충돌 - 성공
				print("[Entity] raycast 반복 %d: 플레이어 감지 성공" % iteration)
				return true
			elif collider.is_in_group("obsticle"):
				# 장애물과 충돌 - 실패
				print("[Entity] raycast 반복 %d: obsticle 감지 (%s) - 플레이어 가림" % [iteration, collider.name])
				return false
			else:
				# 다른 오브젝트 - 충돌 지점을 지나서 다시 체크
				print("[Entity] raycast 반복 %d: 다른 오브젝트 (%s) - 계속 진행" % [iteration, collider.name])
				
				# 충돌 지점보다 약간 더 먼 곳부터 다시 raycast
				current_offset = collision_distance + 0.05
				
				# 남은 거리가 충분한지 확인
				if current_offset >= distance:
					print("[Entity] raycast 종료 - 플레이어까지 도달")
					return true
				
				# raycast를 충돌 지점 너머부터 시작하도록 조정
				# (Godot의 RayCast3D는 시작 위치를 변경할 수 없으므로 exclude 사용)
				character_scan.add_exception(collider)
				character_scan.force_raycast_update()
		else:
			# 충돌하지 않았으면 플레이어까지 직선 경로
			print("[Entity] raycast 반복 %d: 충돌 없음 - 플레이어 보임" % iteration)
			
			# exception 초기화
			character_scan.clear_exceptions()
			return true
	
	# exception 초기화
	character_scan.clear_exceptions()
	
	# 최대 반복 횟수 도달
	print("[Entity] raycast 반복 종료 (반복: %d) - 플레이어 보임" % iteration)
	return true


func set_hp():
	if thing.hp <= 0:
		drop_items()
		queue_free()
		
# 아이템 드롭 시스템
func drop_items():
	if not thing or thing.dead_tem.is_empty():
		return
	
	
	# 각 obsticle_get에 대해 확률적으로 아이템 생성
	for drop_info in thing.dead_tem:
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

# 개별 아이템을 땅에 드롭하는 함수
func create_item_drop(item: Item):
	# 아이템 복사본 생성
	var dropped_item = item.duplicate()
	dropped_item.count = 1  # 개별 아이템은 1개씩
	
	# 시작 위치 (obsticle 위치)
	var start_position = global_position
	
	# 목표 위치 계산 (장애물 주변 랜덤 위치)
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
