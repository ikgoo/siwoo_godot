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
@export var follow_distance: float = 10.0  # 캐릭터로부터 10칸 뒤

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
var mining_animation_time: float = 0.0
var mining_animation_duration: float = 0.3

# 근처 돌 감지
var current_nearby_rock: Node2D = null
var current_nearby_tilemap: TileMap = null

# 채굴 키 (J키 = all_mining_keys[1])
var fairy_mining_key: int = KEY_J

# ========================================
# 노드 참조
# ========================================
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D

func _ready():
	# 플레이어가 없으면 Globals에서 가져오기
	if not player:
		player = Globals.player
	
	# 애니메이션 설정
	_setup_animations()
	
	# fairy 그룹에 추가
	add_to_group("fairy")
	
	# 초기 위치를 경로에 추가
	if player:
		path_points.append(player.global_position)
		path_distances.append(0.0)
		global_position = player.global_position
	
	# 기본 애니메이션 재생
	if animated_sprite:
		animated_sprite.play("idle")

func _physics_process(delta: float) -> void:
	time_elapsed += delta
	
	# 1. 플레이어 팔로우
	update_follow(delta)
	
	# 2. 근처 돌 체크
	check_nearby_rocks()
	
	# 3. J키 입력 감지 (튜토리얼 완료 후에만)
	if Globals.is_tutorial_completed:
		handle_mining_input()
	
	# 4. 채굴 애니메이션 업데이트
	if is_mining:
		update_mining_animation(delta)

## /** 플레이어 팔로우 로직 (거리 기반 추적)
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
	
	# 4. 타겟 위치로 이동
	var direction = global_position.direction_to(target_position)
	var distance = global_position.distance_to(target_position)
	
	if distance > 0.5:
		velocity = direction * max_speed
	else:
		velocity = Vector2.ZERO
	
	move_and_slide()
	
	# 5. 둥둥 효과 (AnimatedSprite에만 적용)
	if animated_sprite:
		var bob_offset = sin(time_elapsed * bob_frequency) * bob_amplitude
		animated_sprite.position.y = bob_offset
	
	# 6. 부드러운 방향 전환
	if animated_sprite:
		if velocity.x < -1.0:
			animated_sprite.flip_h = true
		elif velocity.x > 1.0:
			animated_sprite.flip_h = false
	
	# 7. 이동 애니메이션
	if animated_sprite and not is_mining:
		if velocity.length() > 5.0:
			if animated_sprite.animation != "walk":
				animated_sprite.play("walk")
		else:
			if animated_sprite.animation != "idle":
				animated_sprite.play("idle")
	
	# 8. 오래된 경로 정리 (100개 이상이면 앞쪽 제거)
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
	# J키가 눌렸는지 확인
	if Input.is_key_pressed(fairy_mining_key):
		# 근처에 돌이 있으면 채굴 시작
		if (current_nearby_rock or current_nearby_tilemap) and not is_mining:
			start_mining()

## /** 채굴 시작
##  * @returns void
##  */
func start_mining():
	is_mining = true
	mining_animation_time = 0.0
	
	# 채굴 애니메이션 재생
	if animated_sprite:
		animated_sprite.play("mine")
	
	# 실제 채굴 실행
	if current_nearby_rock and current_nearby_rock.has_method("mine_from_player"):
		current_nearby_rock.mine_from_player()
	elif current_nearby_tilemap and current_nearby_tilemap.has_method("mine_nearest_tile"):
		current_nearby_tilemap.mine_nearest_tile()

## /** 채굴 애니메이션 업데이트
##  * @param delta float 델타 타임
##  * @returns void
##  */
func update_mining_animation(delta: float):
	mining_animation_time += delta
	
	# 애니메이션 완료
	if mining_animation_time >= mining_animation_duration:
		is_mining = false
		mining_animation_time = 0.0
		
		# 기본 애니메이션으로 복귀
		if animated_sprite:
			animated_sprite.play("idle")

## /** 애니메이션 프레임 설정
##  * mine_clicker-helper.png 스프라이트 시트를 사용하여 애니메이션 생성
##  * @returns void
##  */
func _setup_animations():
	if not animated_sprite:
		return
	
	# SpriteFrames 생성
	var sprite_frames = SpriteFrames.new()
	
	# 스프라이트 시트 로드
	var texture = load("res://CONCEPT/asset/helper/mine_clicker-helper.png") as Texture2D
	if not texture:
		print("❌ [Fairy] 스프라이트 시트를 찾을 수 없음!")
		return
	
	# 프레임 크기 (이미지를 보니 6x4 = 24프레임, 각 프레임 16x16으로 추정)
	var frame_width = 16
	var frame_height = 16
	var columns = 6
	
	# === idle 애니메이션 (1행: 0~5번 프레임) ===
	sprite_frames.add_animation("idle")
	sprite_frames.set_animation_loop("idle", true)
	sprite_frames.set_animation_speed("idle", 8.0)
	
	for i in range(6):
		var atlas = AtlasTexture.new()
		atlas.atlas = texture
		atlas.region = Rect2(i * frame_width, 0 * frame_height, frame_width, frame_height)
		sprite_frames.add_frame("idle", atlas)
	
	# === walk 애니메이션 (2행: 6~11번 프레임) ===
	sprite_frames.add_animation("walk")
	sprite_frames.set_animation_loop("walk", true)
	sprite_frames.set_animation_speed("walk", 10.0)
	
	for i in range(6):
		var atlas = AtlasTexture.new()
		atlas.atlas = texture
		atlas.region = Rect2(i * frame_width, 1 * frame_height, frame_width, frame_height)
		sprite_frames.add_frame("walk", atlas)
	
	# === mine 애니메이션 (3행: 12~17번 프레임) ===
	sprite_frames.add_animation("mine")
	sprite_frames.set_animation_loop("mine", false)
	sprite_frames.set_animation_speed("mine", 12.0)
	
	for i in range(6):
		var atlas = AtlasTexture.new()
		atlas.atlas = texture
		atlas.region = Rect2(i * frame_width, 2 * frame_height, frame_width, frame_height)
		sprite_frames.add_frame("mine", atlas)
	
	# AnimatedSprite2D에 적용
	animated_sprite.sprite_frames = sprite_frames
	print("✅ [Fairy] 애니메이션 설정 완료!")
