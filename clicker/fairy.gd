extends CharacterBody2D
class_name Fairy

## /** 플레이어를 따라다니며 채굴을 돕는 요정 캐릭터
##  * pet.gd의 팔로우 로직을 기반으로 하며, J키(2번 키)로 채굴을 수행합니다.
##  */

# ========================================
# Export 설정
# ========================================
@export var player: CharacterBody2D  # 플레이어 참조
@export var idle_sprite: Texture2D  # 대기 스프라이트
@export var mining_sprite: Texture2D  # 광질 스프라이트

# ========================================
# 팔로우 설정 (pet.gd와 동일)
# ========================================
@export var max_speed: float = 60.0
@export var steering_force: float = 1.5
@export var arrive_radius: float = 40.0
@export var stop_radius: float = 9.0
@export var bob_amplitude: float = 2.0
@export var bob_frequency: float = 2.5
@export var flip_speed: float = 14.0
@export var follow_distance: float = 45.0

# ========================================
# 내부 변수
# ========================================
var time_elapsed: float = 0.0
var current_visual_scale_x: float = 1.0

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
@onready var sprite: Sprite2D = $Sprite2D
@onready var follow_point: Marker2D = null

func _ready():
	# 플레이어가 없으면 Globals에서 가져오기
	if not player:
		player = Globals.player
	
	# FollowPoint 찾기
	if player and player.has_node("Sprite2D/FollowPoint"):
		follow_point = player.get_node("Sprite2D/FollowPoint")
	
	# 스프라이트 초기 설정
	if idle_sprite and sprite:
		sprite.texture = idle_sprite
	
	# fairy 그룹에 추가
	add_to_group("fairy")

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

## /** 플레이어 팔로우 로직 (pet.gd 기반)
##  * @param delta float 델타 타임
##  * @returns void
##  */
func update_follow(delta: float) -> void:
	if not follow_point:
		return
	
	# 타겟 위치 계산
	var target = follow_point.global_position
	var distance = global_position.distance_to(target)
	
	# 스티어링 기반 이동
	var desired_velocity = Vector2.ZERO
	
	if distance > stop_radius:
		var direction = global_position.direction_to(target)
		var speed_factor = clamp(distance / arrive_radius, 0.0, 1.0)
		desired_velocity = direction * max_speed * speed_factor
	
	var steering = (desired_velocity - velocity) * steering_force * delta
	velocity += steering
	
	move_and_slide()
	
	# 둥둥 효과 (Sprite에만 적용)
	if sprite:
		var bob_offset = sin(time_elapsed * bob_frequency) * bob_amplitude
		sprite.position.y = bob_offset
	
	# 부드러운 방향 전환
	var target_scale_x = 1.0 if velocity.x >= 0 else -1.0
	
	# 움직임이 있을 때만 방향 전환
	if abs(velocity.x) > 5.0:
		current_visual_scale_x = lerp(current_visual_scale_x, target_scale_x, flip_speed * delta)
	
	if sprite:
		sprite.scale.x = current_visual_scale_x

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
	
	# 스프라이트 변경
	if mining_sprite and sprite:
		sprite.texture = mining_sprite
	
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
		
		# 스프라이트 복구
		if idle_sprite and sprite:
			sprite.texture = idle_sprite
