extends CharacterBody2D
class_name Fairy

## /** 플레이어를 따라다니며 채굴을 돕는 요정 캐릭터
##  * pet.gd의 팔로우 로직을 기반으로 하며, J키(2번 키)로 채굴을 수행합니다.
##  */
		
# ========================================
# Export 설정
# ========================================
@export var player: CharacterBody2D  # 플레이어 참조

# ========================================
# 팔로우 설정 (거리 기반 추적)
# ========================================
@export var max_speed: float = 60.0
@export var bob_amplitude: float = 2.0
@export var bob_frequency: float = 2.5
@export var flip_speed: float = 14.0
@export var follow_distance: float = 20.0  # 캐릭터로부터 20칸 뒤
@export var stay_on_ground: bool = true  # 땅에 붙어서 이동

# ========================================
# 내부 변수
# ========================================
var time_elapsed: float = 0.0
var current_visual_scale_x: float = 1.0

# 거리 기반 추적을 위한 경로 기록
var path_points: Array[Vector2] = []  # 플레이어의 이동 경로
var path_distances: Array[float] = []  # 각 포인트까지의 누적 거리
var total_path_distance: float = 0.0  # 전체 경로 길이

# ========================================
# 채굴 관련 변수
# ========================================
var is_mining: bool = false
var mining_cooldown: float = 0.0
var mining_cooldown_duration: float = 0.3

# 근처 돌 감지
var current_nearby_rock: Node2D = null
var current_nearby_tilemap: TileMap = null

# 채굴 키 (J키 = all_mining_keys[1])
var fairy_mining_key: int = KEY_J

# 키 입력 상태 추적 (연타 방지)
var was_j_key_pressed: bool = false

func _ready():
	# 플레이어가 없으면 Globals에서 가져오기
	if not player:
		player = Globals.player
	
	# fairy 그룹에 추가
	add_to_group("fairy")
	
	# 초기 위치를 경로에 추가
	if player:
		path_points.append(player.global_position)
		path_distances.append(0.0)
		global_position = player.global_position

func _physics_process(delta: float) -> void:
	time_elapsed += delta
	
	# 1. 플레이어 팔로우
	update_follow(delta)
	
	# 2. 근처 돌 체크
	check_nearby_rocks()
	
	# 3. J키 입력 감지 (튜토리얼 완료 후에만)
	if Globals.is_tutorial_completed:
		handle_mining_input()
	
	# 4. 채굴 쿨다운 업데이트
	if is_mining:
		update_mining_cooldown(delta)

## /** 플레이어 팔로우 로직 (거리 기반 추적 - 트레일처럼)
##  * 플레이어가 간 경로를 기록하고, follow_distance만큼 뒤를 따라갑니다
##  * @param delta float 델타 타임
##  * @returns void
##  */
func update_follow(delta: float) -> void:
	if not player:
		return
	
	# 1. 플레이어의 현재 위치를 경로에 추가
	var player_pos = player.global_position
	
	# 마지막 포인트와 충분히 멀어졌을 때만 추가 (0.5칸 이상)
	if path_points.is_empty() or path_points[-1].distance_to(player_pos) > 0.5:
		var distance_to_add = 0.0
		if not path_points.is_empty():
			distance_to_add = path_points[-1].distance_to(player_pos)
		
		path_points.append(player_pos)
		total_path_distance += distance_to_add
		path_distances.append(total_path_distance)
	
	# 2. follow_distance만큼 뒤의 위치 계산
	var target_distance = total_path_distance - follow_distance
	if target_distance < 0:
		target_distance = 0
	
	# 3. 해당 거리에 해당하는 위치 찾기
	var target_position = _get_position_at_distance(target_distance)
	
	# 4. 땅에 붙어서 이동 (X축만 따라가고 Y축은 중력 적용)
	if stay_on_ground:
		# 중력 적용
		if not is_on_floor():
			velocity.y += get_gravity().y * get_physics_process_delta_time()
		else:
			velocity.y = 0
		
		# X축 이동만 처리
		var direction_x = sign(target_position.x - global_position.x)
		var distance_x = abs(target_position.x - global_position.x)
		
		if distance_x > 0.5:
			velocity.x = direction_x * max_speed
		else:
			velocity.x = 0
		
		move_and_slide()
	else:
		# 공중 이동 (기존 방식)
		var direction = global_position.direction_to(target_position)
		var distance = global_position.distance_to(target_position)
		
		if distance > 0.5:
			velocity = direction * max_speed
		else:
			velocity = Vector2.ZERO
		
		move_and_slide()
	
	# 5. 오래된 경로 정리 (100개 이상이면 앞쪽 제거)
	while path_points.size() > 100:
		path_points.pop_front()
		var removed_distance = path_distances.pop_front()
		# 나머지 거리들을 조정
		for i in range(path_distances.size()):
			path_distances[i] -= removed_distance
		total_path_distance -= removed_distance

## /** 특정 거리에 해당하는 경로상의 위치를 반환합니다
##  * @param distance float 찾을 거리
##  * @returns Vector2 해당 거리의 위치
##  */
func _get_position_at_distance(distance: float) -> Vector2:
	if path_points.is_empty():
		return global_position
	
	if distance <= 0:
		return path_points[0]
	
	# 이진 탐색으로 거리에 해당하는 구간 찾기
	for i in range(path_distances.size() - 1):
		if path_distances[i] <= distance and distance <= path_distances[i + 1]:
			# 두 포인트 사이를 보간
			var t = (distance - path_distances[i]) / (path_distances[i + 1] - path_distances[i])
			return path_points[i].lerp(path_points[i + 1], t)
	
	# 마지막 포인트 반환
	return path_points[-1]

## /** 근처에 있는 돌이나 타일맵을 확인합니다 (character.gd의 check_nearby_rocks 참고)
##  * @returns void
##  */
func check_nearby_rocks():
	var rocks = get_tree().get_nodes_in_group("rocks")
	current_nearby_rock = null
	current_nearby_tilemap = null
	
	# 1. 일반 돌 (rocks 그룹) 확인
	for rock in rocks:
		if rock and global_position.distance_to(rock.global_position) < 50:
			current_nearby_rock = rock
			return
	
	# 2. 파괴 가능한 타일맵 (breakable_tiles 그룹) 확인
	var tilemaps = get_tree().get_nodes_in_group("breakable_tiles")
	for tilemap in tilemaps:
		if tilemap and tilemap.has_method("has_nearby_breakable_tile"):
			# 요정의 위치 기준으로 체크
			var has_tile = tilemap.has_nearby_breakable_tile_at_position(global_position)
			if has_tile:
				current_nearby_tilemap = tilemap
				return

## /** J키 입력을 감지하고 채굴을 실행합니다
##  * @returns void
##  */
func handle_mining_input():
	# J키 상태 확인
	var is_j_key_pressed = Input.is_key_pressed(fairy_mining_key)
	var is_j_key_just_pressed = is_j_key_pressed and not was_j_key_pressed
	
	# 이전 프레임의 키 상태 저장
	was_j_key_pressed = is_j_key_pressed
	
	# J키를 처음 눌렀을 때만 채굴 시작 (연타 방지)
	if is_j_key_just_pressed:
		# 근처에 돌이 있으면 채굴 시작
		if (current_nearby_rock or current_nearby_tilemap) and not is_mining:
			start_mining()

## /** 채굴 시작 (플레이어의 차징 게이지에 기여)
##  * @returns void
##  */
func start_mining():
	is_mining = true
	mining_cooldown = 0.0
	
	# 플레이어의 차징 게이지에 기여
	if player and player.has_method("add_charge"):
		player.add_charge()
		print("✨ [Fairy] 차징 게이지 기여!")

## /** 채굴 쿨다운 업데이트
##  * @param delta float 델타 타임
##  * @returns void
##  */
func update_mining_cooldown(delta: float):
	mining_cooldown += delta
	
	# 쿨다운 완료
	if mining_cooldown >= mining_cooldown_duration:
		is_mining = false
		mining_cooldown = 0.0
