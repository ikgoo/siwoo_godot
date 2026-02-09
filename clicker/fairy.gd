extends CharacterBody2D
class_name Fairy

## /** 플레이어를 따라다니며 채굴을 돕는 요정 캐릭터 (테라리아 펫 스타일)
##  * 중력 영향을 받으며 걷기/점프로 플레이어 뒤를 따라다닙니다.
##  * 너무 멀어지면 벽을 무시하고 부드럽게 lerp로 날아옵니다.
##  */

# ========================================
# Export 설정
# ========================================
@export var player: CharacterBody2D  # 플레이어 참조

# ========================================
# 이동 설정 (테라리아 펫 스타일)
# ========================================
@export var move_speed: float = 80.0          # 걷기 속도 (캐릭터보다 살짝 빠름)
@export var jump_velocity: float = -180.0     # 점프 힘 (캐릭터와 동일)
@export var gravity_scale: float = 0.7        # 중력 배율 (캐릭터와 동일)
@export var follow_offset_x: float = 20.0     # 플레이어 뒤에 서려는 X 거리
@export var warp_distance: float = 150.0      # 이 거리 이상이면 워프 시작
@export var idle_threshold: float = 8.0       # 이 거리 이내면 걷기 멈춤
@export var warp_lerp_speed: float = 3.0      # 워프 시 lerp 속도 (높을수록 빠름)
@export var warp_arrive_distance: float = 15.0 # 워프 도착 판정 거리

# ========================================
# 노드 참조
# ========================================
@onready var anim_player: AnimationPlayer = $AnimationPlayer
@onready var fairy_light: PointLight2D = $FairyLight

# ========================================
# 내부 변수
# ========================================
var time_elapsed: float = 0.0
var current_animation: String = ""  # 현재 재생 중인 애니메이션
var was_on_floor: bool = true       # 이전 프레임 바닥 상태 (착지 감지용)

# 워프 상태 (멀어졌을 때 벽을 뚫고 부드럽게 이동)
var is_warping: bool = false
var original_collision_mask: int = 0  # 워프 전 충돌 마스크 백업

# 벽에 막힌 시간 추적 (일정 시간 이상 막히면 워프)
var stuck_timer: float = 0.0
var stuck_warp_time: float = 2.0  # 2초 이상 막히면 워프

# ========================================
# 채굴 관련 변수
# ========================================
var is_mining: bool = false
var mining_cooldown: float = 0.0
var mining_cooldown_duration: float = 0.3
var is_playing_act: bool = false  # act 애니메이션 재생 중

# 근처 돌 감지 (플레이어 기준)
var current_nearby_rock: Node2D = null
var current_nearby_tilemap: TileMap = null

# 플레이어가 실제로 채굴 중인지 (charge > 0 + 돌 근처)
var is_player_mining: bool = false
var mining_rock_target_x: float = 0.0  # 채굴 시 요정이 서 있을 고정 X 좌표
@export var rock_stick_offset: float = 15.0  # 돌 중심에서 요정까지의 거리

# 채굴 키 (J키 = all_mining_keys[1])
var fairy_mining_key: int = KEY_J

# 키 입력 상태 추적 (연타 방지)
var was_j_key_pressed: bool = false

# 곡괭이 보유 여부 (SpriteFrames 애니메이션 전환용)
var has_pickaxe: bool = true

func _ready():
	# 플레이어가 없으면 Globals에서 가져오기
	if not player:
		player = Globals.player
	
	# fairy 그룹에 추가
	add_to_group("fairy")
	
	# 플레이어와 충돌하지 않도록 예외 추가
	if player:
		add_collision_exception_with(player)
		# 초기 위치: 플레이어 옆
		global_position = player.global_position + Vector2(-follow_offset_x, 0)
	
	# 곡괭이 모드에 맞게 SpriteFrames 애니메이션 설정
	_apply_pickaxe_mode()
	
	# 이전에 획득한 요정 아이템 효과 복원
	_restore_fairy_items()

## /** 곡괭이 보유 모드를 전환합니다.
##  * true → "default" (곡괭이 들고 있는 스프라이트)
##  * false → "pickaxe_less" (곡괭이 없는 스프라이트)
##  * @param value bool 곡괭이 보유 여부
##  * @returns void
##  */
func set_pickaxe_mode(value: bool) -> void:
	has_pickaxe = value
	_apply_pickaxe_mode()

## /** 현재 곡괭이 모드에 맞게 AnimatedSprite2D 애니메이션을 적용합니다.
##  * @returns void
##  */
func _apply_pickaxe_mode() -> void:
	var sprite = get_node_or_null("AnimatedSprite2D")
	if not sprite:
		return
	var target_anim = "default" if has_pickaxe else "pickaxe_less"
	if sprite.sprite_frames and sprite.sprite_frames.has_animation(target_anim):
		sprite.animation = target_anim

func _physics_process(delta: float) -> void:
	time_elapsed += delta
	
	if not player:
		return
	
	var distance_to_player = global_position.distance_to(player.global_position)
	
	if is_warping:
		# 워프 중: 벽을 무시하고 lerp로 부드럽게 이동
		warp_towards_player(delta)
	else:
		# 일반 모드: 너무 멀면 워프 시작
		if distance_to_player > warp_distance:
			start_warp()
		else:
			# 걷기 + 점프
			move_towards_player(delta)
	
	# 플레이어 채굴 상태 확인 (F키로 실제 채굴 시작했을 때만)
	update_player_mining_state()
	
	# 스프라이트 방향 + 애니메이션 업데이트
	update_sprite_direction()
	update_animation()
	
	# 채굴 관련
	check_nearby_rocks()
	if Globals.is_tutorial_completed:
		handle_mining_input()
	if is_mining:
		update_mining_cooldown(delta)

# ========================================
# 이동 로직 (테라리아 펫 스타일)
# ========================================

## /** 워프 시작 (멀어졌거나 막혔을 때)
##  * 충돌을 끄고 lerp로 부드럽게 플레이어에게 날아갑니다.
##  * @returns void
##  */
func start_warp():
	is_warping = true
	velocity = Vector2.ZERO
	stuck_timer = 0.0
	# 충돌 마스크 백업 후 끄기 (벽을 뚫고 이동)
	original_collision_mask = collision_mask
	collision_mask = 0

## /** 워프 중 이동 (벽 무시, lerp로 부드럽게)
##  * 안전한 착지 위치를 찾아 lerp로 이동합니다.
##  * @param delta float 델타 타임
##  * @returns void
##  */
func warp_towards_player(delta: float):
	# 안전한 착지 위치 계산 (벽 안이면 자동 보정)
	var target_pos = find_safe_warp_target()
	
	# lerp로 부드럽게 이동
	global_position = global_position.lerp(target_pos, delta * warp_lerp_speed)
	
	# 도착 판정: 목표 근처에 도달하면 워프 종료
	if global_position.distance_to(target_pos) < warp_arrive_distance:
		end_warp()

## /** 워프 종료 (충돌 복구, 일반 이동으로 전환)
##  * 충돌 마스크 복구 전에 현재 위치가 벽 안인지 최종 검증합니다.
##  * @returns void
##  */
func end_warp():
	is_warping = false
	velocity = Vector2.ZERO
	
	# 충돌 마스크 복구 전에 벽 안인지 최종 검증
	if is_position_in_wall(global_position):
		global_position = find_safe_warp_target()
	
	# 충돌 마스크 복구
	collision_mask = original_collision_mask

## /** 안전한 워프 착지 위치를 찾습니다.
##  * 1순위: 플레이어 뒤쪽 (기본 오프셋)
##  * 2순위: 플레이어 반대쪽 (벽이 한쪽에만 있을 때)
##  * 3순위: 플레이어 바로 위 (좁은 공간일 때)
##  * 최후수단: 플레이어 정확한 위치 (플레이어가 서 있으므로 항상 안전)
##  * @returns Vector2 안전한 착지 위치
##  */
func find_safe_warp_target() -> Vector2:
	var facing = get_player_facing()
	
	# 1순위: 플레이어 뒤쪽 (기본 위치)
	var behind_pos = player.global_position + Vector2(-follow_offset_x * facing, 0)
	if not is_position_in_wall(behind_pos):
		return behind_pos
	
	# 2순위: 플레이어 반대편 (앞쪽)
	var front_pos = player.global_position + Vector2(follow_offset_x * facing, 0)
	if not is_position_in_wall(front_pos):
		return front_pos
	
	# 3순위: 플레이어 바로 위
	var above_pos = player.global_position + Vector2(0, -20)
	if not is_position_in_wall(above_pos):
		return above_pos
	
	# 최후수단: 플레이어 위치 그대로 (플레이어가 서 있으니 안전)
	return player.global_position

## /** 특정 위치가 벽 안인지 확인합니다.
##  * 요정의 충돌 셰이프를 해당 위치에 놓고, 지형과 겹치는지 검사합니다.
##  * @param pos Vector2 확인할 위치
##  * @returns bool 벽 안이면 true
##  */
func is_position_in_wall(pos: Vector2) -> bool:
	var space_state = get_world_2d().direct_space_state
	var col_shape = get_node_or_null("CollisionShape2D")
	if not space_state or not col_shape or not col_shape.shape:
		return false
	
	var query = PhysicsShapeQueryParameters2D.new()
	query.shape = col_shape.shape
	# 요정의 스케일과 충돌 셰이프 오프셋을 반영
	query.transform = Transform2D(0, pos + col_shape.position * scale)
	query.collision_mask = original_collision_mask
	query.exclude = [get_rid()]
	
	var results = space_state.intersect_shape(query)
	return results.size() > 0

## /** 플레이어를 향해 걷기/점프 이동 (테라리아 펫처럼)
##  * 1단계: 중력 적용 (바닥에 서 있기)
##  * 2단계: X축으로 플레이어 뒤를 향해 걷기
##  * 3단계: 필요하면 점프 (플레이어가 위에 있거나 벽에 막혔을 때)
##  * @param delta float 델타 타임
##  * @returns void
##  */
func move_towards_player(delta: float) -> void:
	# --- 1단계: 중력 적용 ---
	if not is_on_floor():
		velocity.y += get_gravity().y * gravity_scale * delta
	else:
		# 바닥에 닿으면 Y 속도 리셋
		if velocity.y > 0:
			velocity.y = 0
	
	# --- 2단계: 목표 위치 계산 ---
	var facing = get_player_facing()
	var target_x: float
	if is_player_mining:
		# 채굴 중: 돌 옆 고정 위치로 이동
		target_x = mining_rock_target_x
	else:
		# 일반: 플레이어 뒤쪽에 서기
		target_x = player.global_position.x - follow_offset_x * facing
	var diff_x = target_x - global_position.x
	var diff_y = player.global_position.y - global_position.y
	
	# --- 3단계: X축 이동 ---
	if abs(diff_x) > idle_threshold:
		# 목표를 향해 걷기
		velocity.x = sign(diff_x) * move_speed
	else:
		# 목표 근처면 부드럽게 감속 (미끄러지지 않게)
		velocity.x = move_toward(velocity.x, 0, move_speed * delta * 10.0)
	
	# --- 4단계: 점프 판정 (바닥에 있을 때만) ---
	# 벽에 부딪혔을 때만 점프 (블록 올라가기)
	# 플레이어가 위에 있다고 무작정 점프하지 않음 → 못 따라가면 워프로 해결
	if is_on_floor() and is_on_wall() and abs(diff_x) > idle_threshold:
		velocity.y = jump_velocity
	
	# --- 5단계: 벽에 오래 막히면 워프 ---
	if is_on_wall() and abs(diff_x) > idle_threshold:
		stuck_timer += delta
		if stuck_timer > stuck_warp_time:
			start_warp()
			return
	else:
		stuck_timer = 0.0
	
	move_and_slide()

## /** 플레이어가 바라보는 방향을 반환
##  * character.gd의 facing_direction 변수를 참조합니다.
##  * @returns float 1.0(오른쪽) 또는 -1.0(왼쪽)
##  */
func get_player_facing() -> float:
	# character.gd의 facing_direction 변수 사용
	if "facing_direction" in player:
		return float(player.facing_direction)
	# fallback: sprite flip 확인
	var player_sprite = player.get_node_or_null("sprite")
	if player_sprite and player_sprite.flip_h:
		return -1.0
	return 1.0

## /** 이동 방향에 따라 스프라이트 좌우 반전
##  * act 애니메이션 재생 중에는 방향을 고정하여 뒤돌았다 앞보는 현상을 방지합니다.
##  * @returns void
##  */
func update_sprite_direction():
	var sprite = get_node_or_null("AnimatedSprite2D")
	if not sprite:
		return
	
	# act 애니메이션 재생 중에는 방향을 변경하지 않음 (뒤돌기 방지)
	if is_playing_act:
		return
	
	if is_warping:
		# 워프 중: 플레이어 방향을 바라봄
		var diff = player.global_position.x - global_position.x
		if diff < -0.5:
			sprite.flip_h = true
		elif diff > 0.5:
			sprite.flip_h = false
	else:
		# 일반 이동: 이동 방향 (자연스럽게 걸어가는 방향)
		if velocity.x < -0.5:
			sprite.flip_h = true
		elif velocity.x > 0.5:
			sprite.flip_h = false

# ========================================
# 애니메이션 로직
# ========================================

## /** 현재 상태에 맞는 애니메이션을 재생합니다.
##  * 바닥 + 이동 → walk, 바닥 + 정지 → idle,
##  * 공중 → jump, 방금 착지 → jump_end
##  * @returns void
##  */
func update_animation():
	# act 재생 중이면 끝날 때까지 대기 → 끝나면 idle로
	if is_playing_act:
		if anim_player and anim_player.is_playing():
			return
		# act 끝남 → idle 전환
		is_playing_act = false
		current_animation = ""  # 리셋해서 다음 play_anim이 작동하게
	
	if is_warping:
		# 워프 중: jump 애니메이션 (날아가는 느낌)
		play_anim("jump")
		was_on_floor = false
		return
	
	var on_floor = is_on_floor()
	
	# 착지 순간 감지: 공중 → 바닥
	if on_floor and not was_on_floor:
		play_anim("jump_end")
		was_on_floor = on_floor
		return
	
	was_on_floor = on_floor
	
	# jump_end 재생 중이면 끝날 때까지 대기
	if current_animation == "jump_end" and anim_player and anim_player.is_playing():
		return
	
	if on_floor:
		# 바닥: 이동 중이면 walk, 아니면 idle
		if abs(velocity.x) > 0.5:
			play_anim("walk")
		else:
			play_anim("idle")
	else:
		# 공중: jump
		play_anim("jump")

## /** 애니메이션을 재생합니다 (중복 재생 방지)
##  * @param anim_name String 재생할 애니메이션 이름
##  * @returns void
##  */
func play_anim(anim_name: String):
	if current_animation == anim_name:
		return
	if anim_player and anim_player.has_animation(anim_name):
		current_animation = anim_name
		anim_player.play(anim_name)

# ========================================
# 채굴 로직
# ========================================

## /** 카메라가 돌에 고정되었는지 확인합니다.
##  * 카메라가 돌에 고정되면 요정이 돌의 반대편으로 이동합니다.
##  * @returns void
##  */
func update_player_mining_state():
	is_player_mining = false
	
	if not player:
		return
	
	# 플레이어 근처 돌의 카메라 고정 상태 확인
	if "current_nearby_rock" in player and player.current_nearby_rock:
		var rock = player.current_nearby_rock
		var is_camera_locked_to_rock = false
		
		# 돌의 카메라 고정 상태 확인
		if rock.has_method("is_camera_locked_to_this"):
			is_camera_locked_to_rock = rock.is_camera_locked_to_this()
		elif "is_camera_locked" in rock:
			is_camera_locked_to_rock = rock.is_camera_locked
		
		if is_camera_locked_to_rock:
			is_player_mining = true
			# 플레이어가 돌의 왼쪽에 있으면 → 요정은 돌의 오른쪽 (반대편)
			var player_side = sign(player.global_position.x - rock.global_position.x)
			if player_side == 0:
				player_side = 1.0  # 같은 위치면 기본 오른쪽
			mining_rock_target_x = rock.global_position.x - player_side * rock_stick_offset

## /** 플레이어 근처에 있는 돌이나 타일맵을 확인합니다 (요정 J키 채굴용)
##  * @returns void
##  */
func check_nearby_rocks():
	current_nearby_rock = null
	current_nearby_tilemap = null
	
	if not player:
		return
	
	var check_pos = player.global_position
	
	# 1. 일반 돌 (rocks 그룹) 확인 - 플레이어 기준
	var rocks = get_tree().get_nodes_in_group("rocks")
	for rock in rocks:
		if rock and check_pos.distance_to(rock.global_position) < 50:
			current_nearby_rock = rock
			return
	
	# 2. 파괴 가능한 타일맵 (breakable_tiles 그룹) 확인 - 플레이어 기준
	var tilemaps = get_tree().get_nodes_in_group("breakable_tiles")
	for tilemap in tilemaps:
		if tilemap and tilemap.has_method("has_nearby_breakable_tile"):
			var has_tile = tilemap.has_nearby_breakable_tile_at_position(check_pos)
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

## /** 채굴 시작 (act 애니메이션 재생)
##  * 채굴 시작 시 돌 방향을 바라보도록 스프라이트 방향을 고정합니다.
##  * 실제 차징 게이지 증가는 character.gd에서 J키 입력으로 처리하므로
##  * 요정은 시각적 피드백(act 애니메이션)만 담당합니다.
##  * @returns void
##  */
func start_mining():
	is_mining = true
	mining_cooldown = 0.0
	
	# 돌 방향을 바라보도록 스프라이트 방향 설정 (act 중 고정됨)
	var sprite = get_node_or_null("AnimatedSprite2D")
	if sprite and current_nearby_rock:
		var rock_diff = current_nearby_rock.global_position.x - global_position.x
		if rock_diff < 0:
			sprite.flip_h = true
		else:
			sprite.flip_h = false
	
	# act 애니메이션 재생 (1회) — 시각적 피드백만 담당
	# (차징 게이지 증가는 character.gd에서 J키 입력으로 이미 처리됨)
	is_playing_act = true
	play_anim("act")

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

# ========================================
# 요정 아이템 효과
# ========================================

## /** 요정 빛을 활성화한다 (횃불의 2/3 밝기)
##  * FairyLight(PointLight2D) 노드를 visible로 전환
##  * @returns void
##  */
func enable_fairy_light() -> void:
	if fairy_light:
		fairy_light.visible = true

## /** 이전에 획득한 요정 아이템 효과를 복원한다
##  * 게임 시작 시 Globals.collected_fairy_items를 확인하여
##  * 이미 획득한 아이템의 효과를 다시 적용합니다
##  * @returns void
##  */
func _restore_fairy_items() -> void:
	# 곡괭이 아이템 복원
	if "fairy_pickaxe" in Globals.collected_fairy_items:
		set_pickaxe_mode(true)
	
	# 빛 아이템 복원
	if "fairy_light" in Globals.collected_fairy_items:
		enable_fairy_light()
