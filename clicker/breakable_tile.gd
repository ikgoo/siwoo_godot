extends TileMap

## breakable_tile.gd - 캐릭터 근처에서 마우스 방향의 타일 채굴
## Rock과 동일한 차징 시스템 사용

# 캐릭터 참조
var character: CharacterBody2D
var character_area: Area2D = null  # 캐릭터의 채굴 범위 Area2D
var mining_radius: float = 50.0  # Area2D 반지름 (기본값)

# 채굴 중인 타일 정보
var target_tile: Vector2i = Vector2i(-9999, -9999)  # 마우스가 가리키는 타일 좌표
var is_mining: bool = false  # 채굴 중인지
var highlight_sprite: Sprite2D = null  # 하이라이트 표시용 스프라이트

# 좌클릭 연속 채굴
var is_mouse_holding: bool = false  # 좌클릭 꾹 누르고 있는지
var mining_cooldown: float = 0.0  # 채굴 쿨다운 타이머

# 티어별 채굴 간격 (초) - 숫자가 작을수록 빠름
# 기준: 0.15초
# 티어1 = 1/3 속도 → 0.45초
# 티어2 = 2/3 속도 → 0.225초  
# 티어3 = 티어2의 1.8배 속도 → 0.125초
# 티어4 = 티어3의 1.5배 속도 → 0.083초
# 티어5 = 티어4의 1.3배 속도 → 0.064초
const TIER_MINING_INTERVAL: Dictionary = {
	1: 0.45,    # 티어 1: 느림 (1/3 속도)
	2: 0.225,   # 티어 2: 보통 (2/3 속도)
	3: 0.125,   # 티어 3: 빠름 (티어2의 1.8배)
	4: 0.083,   # 티어 4: 매우 빠름 (티어3의 1.5배)
	5: 0.064,   # 티어 5: 초고속 (티어4의 1.3배)
}
const DEFAULT_MINING_INTERVAL: float = 0.45  # 기본값 (티어1)

# ========================================
# 타일 내구도 시스템
# ========================================
# 타일 HP 저장 {Vector2i: {hp: int, max_hp: int, layer: int}}
var tile_hp_data: Dictionary = {}

# 레이어별, 티어별 HP 테이블
# LAYER_TIER_HP[layer][tier] = 필요한 타격 횟수
# Layer 0 (첫 번째): 티어1=3번, 티어2+=1번
# Layer 2 (두 번째): 티어1=8번, 티어2=4번, 티어3=2번
const LAYER_TIER_HP = {
	0: {1: 3, 2: 1, 3: 1, 4: 1, 5: 1},           # Layer 0: 티어1=3번, 그 이상=1번
	2: {1: 8, 2: 4, 3: 2, 4: 1, 5: 1},           # Layer 2: 티어1=8번, 티어2=4번, 티어3=2번
}

# 균열 오버레이 스프라이트들 {Vector2i: Sprite2D}
var crack_sprites: Dictionary = {}

# HP 게이지 스프라이트들 {Vector2i: {bg: Sprite2D, bar: Sprite2D}}
var hp_gauges: Dictionary = {}

# 균열 텍스처 배열 (손상도에 따라 다름)
var crack_textures: Array[ImageTexture] = []

# 설치 모드 (Globals에서 전역 관리)
var build_target_tile: Vector2i = Vector2i(-9999, -9999)  # 설치할 타일 좌표
var build_highlight_sprite: Sprite2D = null  # 설치 하이라이트 스프라이트 (초록색)
var platform_tilemap: TileMap = null  # platform 타일맵 참조

# 횃불 설치 (Globals에서 전역 관리)
var torch_scene: PackedScene = null  # 횃불 씬
var torch_highlight_sprite: Sprite2D = null  # 횃불 하이라이트 스프라이트 (주황색)
var installed_torches: Dictionary = {}  # 설치된 횃불 {Vector2i: torch_instance}

const TILE_SIZE: int = 32  # 타일 크기 (픽셀)

# 플랫폼 타일 설정 (terrain 사용)
const PLATFORM_TERRAIN_SET: int = 0
const PLATFORM_TERRAIN_ID: int = 0  # terrain ID (플랫폼용)

## 채굴 가능한 레이어들 (layer 0, 2)
## 티어 1: layer 0만, 티어 2+: layer 0, 2 둘 다
const MINEABLE_LAYERS: Array[int] = [0, 2]

## 현재 채굴 가능한 레이어에서 타일이 존재하는지 확인하고, 존재하면 레이어 인덱스 반환
## @param tile_pos: 확인할 타일 좌표
## @returns: 타일이 있는 레이어 인덱스 (없으면 -1)
func get_mineable_layer(tile_pos: Vector2i) -> int:
	# 티어에 따라 채굴 가능한 레이어 결정
	# 티어 1: layer 0만
	# 티어 2+: layer 0, 2 둘 다
	var max_layer_count = 1 if Globals.mining_tier == 1 else MINEABLE_LAYERS.size()
	
	for i in range(max_layer_count):
		var layer_idx = MINEABLE_LAYERS[i]
		if get_cell_source_id(layer_idx, tile_pos) != -1:
			return layer_idx
	return -1

## 타일이 존재하는지 확인 (채굴 가능한 모든 레이어 체크)
## @param tile_pos: 확인할 타일 좌표
## @returns: 타일 존재 여부
func tile_exists_in_mineable_layers(tile_pos: Vector2i) -> bool:
	return get_mineable_layer(tile_pos) != -1

func _ready():
	# breakable_tilemaps 그룹에 추가
	add_to_group("breakable_tilemaps")
	
	# 하이라이트 스프라이트 생성
	create_highlight_sprite()
	create_build_highlight_sprite()
	create_torch_highlight_sprite()
	
	# 균열 텍스처 생성
	create_crack_textures()
	
	# platform 타일맵 찾기
	find_platform_tilemap()
	
	# 횃불 씬 로드
	torch_scene = preload("res://torch.tscn")

func _process(_delta):
	# 캐릭터를 아직 찾지 못했으면 찾기 시도
	if not character:
		character = get_tree().root.get_node_or_null("main/character")
		if not character:
			return
		else:
			# 캐릭터의 Area2D와 반지름 가져오기
			character_area = character.get_node_or_null("Area2D")
			if character_area:
				var collision_shape = character_area.get_node_or_null("CollisionShape2D")
				if collision_shape and collision_shape.shape is CircleShape2D:
					mining_radius = collision_shape.shape.radius
	
	# Rock이 근처에 있으면 타일 채굴 비활성화
	var near_rock = is_near_rock()
	if near_rock:
		target_tile = Vector2i(-9999, -9999)
		if highlight_sprite:
			highlight_sprite.visible = false
		return
	
	# 캐릭터에서 마우스 방향으로 raycast를 쏴서 타일 찾기
	var raycast_tile = get_tile_from_raycast()
	
	if raycast_tile != Vector2i(-9999, -9999):
		var prev_target = target_tile
		target_tile = raycast_tile
		
		# 하이라이트 표시
		if highlight_sprite:
			var tile_world_pos = to_global(map_to_local(target_tile))
			highlight_sprite.global_position = tile_world_pos
			highlight_sprite.visible = true
		
	else:
		target_tile = Vector2i(-9999, -9999)
		
		# 하이라이트 숨기기
		if highlight_sprite:
			highlight_sprite.visible = false
	
	# 좌클릭 꾹 누르고 있으면 연속 채굴 (설치 모드가 아닐 때만)
	if not Globals.is_build_mode and is_mouse_holding and target_tile != Vector2i(-9999, -9999):
		mining_cooldown -= _delta
		if mining_cooldown <= 0.0:
			mine_tile(target_tile)
			mining_cooldown = get_current_mining_interval()
	
	# 설치 모드일 때 빈 공간 하이라이트
	if Globals.is_build_mode:
		update_build_mode_highlight()
	else:
		if build_highlight_sprite:
			build_highlight_sprite.visible = false
		build_target_tile = Vector2i(-9999, -9999)
	
	# 횃불 모드일 때 하이라이트
	if Globals.is_torch_mode:
		update_torch_mode_highlight()
	else:
		if torch_highlight_sprite:
			torch_highlight_sprite.visible = false

func _input(event):
	# 2번 키로 설치 모드 토글
	if event is InputEventKey:
		if event.keycode == KEY_2 and event.pressed and not event.echo:
			Globals.is_build_mode = not Globals.is_build_mode
			Globals.is_torch_mode = false  # 횃불 모드 해제
			if Globals.is_build_mode:
				if highlight_sprite:
					highlight_sprite.visible = false
				if torch_highlight_sprite:
					torch_highlight_sprite.visible = false
			else:
				if build_highlight_sprite:
					build_highlight_sprite.visible = false
		
		# 3번 키로 횃불 설치 모드 토글
		if event.keycode == KEY_3 and event.pressed and not event.echo:
			Globals.is_torch_mode = not Globals.is_torch_mode
			Globals.is_build_mode = false  # 플랫폼 모드 해제
			if Globals.is_torch_mode:
				if highlight_sprite:
					highlight_sprite.visible = false
				if build_highlight_sprite:
					build_highlight_sprite.visible = false
			else:
				if torch_highlight_sprite:
					torch_highlight_sprite.visible = false
		
		# B키로 플랫폼 설치 (설치 모드일 때만)
		if event.keycode == KEY_B and event.pressed and not event.echo:
			if Globals.is_build_mode and build_target_tile != Vector2i(-9999, -9999):
				place_platform_tile(build_target_tile)
			# 횃불 모드일 때 횃불 설치
			elif Globals.is_torch_mode and build_target_tile != Vector2i(-9999, -9999):
				place_torch(build_target_tile)
	
	# 좌클릭 눌림/뗌 감지 (설치 모드가 아닐 때만)
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if not Globals.is_build_mode:
				if event.pressed:
					# 좌클릭 눌림 - 즉시 채굴 + 연속 채굴 모드 시작
					is_mouse_holding = true
					mining_cooldown = get_current_mining_interval()  # 첫 클릭 후 잠시 대기
					
					# 타겟 타일이 있으면 즉시 채굴
					if target_tile != Vector2i(-9999, -9999):
						mine_tile(target_tile)
				else:
					# 좌클릭 뗌 - 연속 채굴 모드 종료
					is_mouse_holding = false
					mining_cooldown = 0.0

## 하이라이트 스프라이트 생성
func create_highlight_sprite():
	highlight_sprite = Sprite2D.new()
	
	# 하이라이트 텍스처 생성 (노란색 반투명 사각형)
	var highlight_image = Image.create(TILE_SIZE, TILE_SIZE, false, Image.FORMAT_RGBA8)
	
	# 테두리만 그리기 (2픽셀 두께)
	for x in range(TILE_SIZE):
		for y in range(TILE_SIZE):
			# 테두리 부분만 노란색
			if x < 2 or x >= TILE_SIZE - 2 or y < 2 or y >= TILE_SIZE - 2:
				highlight_image.set_pixel(x, y, Color(1.0, 1.0, 0.0, 0.8))  # 노란색
			else:
				highlight_image.set_pixel(x, y, Color(1.0, 1.0, 0.0, 0.2))  # 반투명 노란색
	
	var highlight_texture = ImageTexture.create_from_image(highlight_image)
	highlight_sprite.texture = highlight_texture
	highlight_sprite.visible = false
	highlight_sprite.z_index = 10  # 타일 위에 표시
	
	add_child(highlight_sprite)

## 설치용 하이라이트 스프라이트 생성 (초록색)
func create_build_highlight_sprite():
	build_highlight_sprite = Sprite2D.new()
	
	# 하이라이트 텍스처 생성 (초록색 반투명 사각형)
	var highlight_image = Image.create(TILE_SIZE, TILE_SIZE, false, Image.FORMAT_RGBA8)
	
	# 테두리만 그리기 (2픽셀 두께)
	for x in range(TILE_SIZE):
		for y in range(TILE_SIZE):
			# 테두리 부분만 초록색
			if x < 2 or x >= TILE_SIZE - 2 or y < 2 or y >= TILE_SIZE - 2:
				highlight_image.set_pixel(x, y, Color(0.0, 1.0, 0.3, 0.8))  # 초록색
			else:
				highlight_image.set_pixel(x, y, Color(0.0, 1.0, 0.3, 0.3))  # 반투명 초록색
	
	var highlight_texture = ImageTexture.create_from_image(highlight_image)
	build_highlight_sprite.texture = highlight_texture
	build_highlight_sprite.visible = false
	build_highlight_sprite.z_index = 10  # 타일 위에 표시
	
	add_child(build_highlight_sprite)

## platform 타일맵 찾기
func find_platform_tilemap():
	var parent = get_parent()  # map_1 또는 map_2
	if parent:
		platform_tilemap = parent.get_node_or_null("platform")

## 현재 티어에 따른 채굴 간격 반환
func get_current_mining_interval() -> float:
	var current_tier = Globals.mining_tier
	if TIER_MINING_INTERVAL.has(current_tier):
		return TIER_MINING_INTERVAL[current_tier]
	# 티어가 5보다 높으면 티어5 값 사용, 없으면 기본값
	elif current_tier > 5:
		return TIER_MINING_INTERVAL.get(5, DEFAULT_MINING_INTERVAL)
	else:
		return DEFAULT_MINING_INTERVAL

## 균열 텍스처 생성 (손상도에 따라 3단계)
func create_crack_textures():
	# 25%, 50%, 75% 손상 단계별 균열 텍스처
	for damage_level in range(3):
		var crack_image = Image.create(TILE_SIZE, TILE_SIZE, true, Image.FORMAT_RGBA8)
		crack_image.fill(Color(0, 0, 0, 0))  # 투명 배경
		
		# 손상 레벨에 따라 균열 강도 증가
		var crack_intensity = (damage_level + 1) * 0.25  # 0.25, 0.5, 0.75
		var crack_color = Color(0.2, 0.15, 0.1, crack_intensity)  # 어두운 갈색 균열
		
		# 균열 패턴 생성 (대각선 + 중앙에서 뻗어나가는 형태)
		var center = Vector2(TILE_SIZE / 2, TILE_SIZE / 2)
		
		# 중앙에서 뻗어나가는 균열 라인들
		var crack_lines = [
			[center, center + Vector2(-8, -8) * (damage_level + 1) * 0.5],
			[center, center + Vector2(10, -6) * (damage_level + 1) * 0.5],
			[center, center + Vector2(-6, 10) * (damage_level + 1) * 0.5],
			[center, center + Vector2(8, 8) * (damage_level + 1) * 0.5],
		]
		
		# 추가 균열 (손상 레벨에 따라)
		if damage_level >= 1:
			crack_lines.append([center + Vector2(-8, 0), center + Vector2(-14, -6)])
			crack_lines.append([center + Vector2(6, 6), center + Vector2(12, 10)])
		if damage_level >= 2:
			crack_lines.append([center + Vector2(0, -8), center + Vector2(8, -14)])
			crack_lines.append([center + Vector2(-6, 8), center + Vector2(-10, 14)])
		
		# 균열 라인 그리기
		for line in crack_lines:
			draw_line_on_image(crack_image, line[0], line[1], crack_color, 2)
		
		var crack_texture = ImageTexture.create_from_image(crack_image)
		crack_textures.append(crack_texture)

## 이미지에 선 그리기 (Bresenham 알고리즘)
func draw_line_on_image(image: Image, start: Vector2, end: Vector2, color: Color, thickness: int = 1):
	var dx = abs(int(end.x) - int(start.x))
	var dy = abs(int(end.y) - int(start.y))
	var sx = 1 if start.x < end.x else -1
	var sy = 1 if start.y < end.y else -1
	var err = dx - dy
	var x = int(start.x)
	var y = int(start.y)
	
	while true:
		# thickness에 따라 주변 픽셀도 채움
		for tx in range(-thickness/2, thickness/2 + 1):
			for ty in range(-thickness/2, thickness/2 + 1):
				var px = x + tx
				var py = y + ty
				if px >= 0 and px < image.get_width() and py >= 0 and py < image.get_height():
					image.set_pixel(px, py, color)
		
		if x == int(end.x) and y == int(end.y):
			break
		var e2 = 2 * err
		if e2 > -dy:
			err -= dy
			x += sx
		if e2 < dx:
			err += dx
			y += sy

## 레이어와 현재 티어에 따른 HP 계산
func calculate_tile_hp(layer: int, tier: int) -> int:
	# LAYER_TIER_HP 테이블에서 HP 가져오기
	if LAYER_TIER_HP.has(layer):
		var tier_hp = LAYER_TIER_HP[layer]
		# 티어가 테이블에 있으면 해당 값, 없으면 가장 높은 티어 값 사용
		if tier_hp.has(tier):
			return tier_hp[tier]
		else:
			# 티어가 5보다 높으면 티어5 값 사용
			return tier_hp.get(5, 1)
	else:
		# 정의되지 않은 레이어는 기본 HP 3
		return 3

## 타일의 HP를 가져옵니다 (없으면 현재 티어 기준으로 초기화)
func get_tile_hp(tile_pos: Vector2i, layer: int) -> Dictionary:
	var key = tile_pos
	
	if not tile_hp_data.has(key):
		# 현재 플레이어 티어에 따른 HP 설정
		var current_tier = Globals.mining_tier
		var max_hp = calculate_tile_hp(layer, current_tier)
		tile_hp_data[key] = {
			"hp": max_hp,
			"max_hp": max_hp,
			"layer": layer,
			"tier_at_init": current_tier  # 초기화 시점의 티어 기록
		}
	
	return tile_hp_data[key]

## 균열 오버레이 생성/업데이트
func update_crack_overlay(tile_pos: Vector2i, hp_ratio: float):
	var world_pos = to_global(map_to_local(tile_pos))
	
	# 손상도 계산 (1.0 = 멀쩡, 0.0 = 파괴 직전)
	var damage_ratio = 1.0 - hp_ratio
	
	# 손상이 없으면 균열 숨기기
	if damage_ratio <= 0.0:
		if crack_sprites.has(tile_pos):
			crack_sprites[tile_pos].queue_free()
			crack_sprites.erase(tile_pos)
		return
	
	# 균열 레벨 결정 (0, 1, 2)
	var crack_level = int(damage_ratio * 3)
	crack_level = clamp(crack_level, 0, 2)
	
	# 균열 스프라이트 생성 또는 업데이트
	if not crack_sprites.has(tile_pos):
		var crack_sprite = Sprite2D.new()
		crack_sprite.z_index = 5  # 타일 위, 하이라이트 아래
		add_child(crack_sprite)
		crack_sprites[tile_pos] = crack_sprite
	
	var crack_sprite = crack_sprites[tile_pos]
	crack_sprite.texture = crack_textures[crack_level]
	crack_sprite.global_position = world_pos

## HP 게이지 생성/업데이트
func update_hp_gauge(tile_pos: Vector2i, hp_ratio: float, show: bool = true):
	var world_pos = to_global(map_to_local(tile_pos))
	
	if not show or hp_ratio >= 1.0:
		# 게이지 숨기기
		if hp_gauges.has(tile_pos):
			hp_gauges[tile_pos]["bg"].queue_free()
			hp_gauges[tile_pos]["bar"].queue_free()
			hp_gauges.erase(tile_pos)
		return
	
	# 게이지 생성 또는 업데이트
	if not hp_gauges.has(tile_pos):
		# 배경 바
		var bg_sprite = Sprite2D.new()
		var bg_image = Image.create(24, 4, false, Image.FORMAT_RGBA8)
		bg_image.fill(Color(0.2, 0.2, 0.2, 0.8))
		bg_sprite.texture = ImageTexture.create_from_image(bg_image)
		bg_sprite.z_index = 15
		add_child(bg_sprite)
		
		# HP 바
		var bar_sprite = Sprite2D.new()
		bar_sprite.z_index = 16
		add_child(bar_sprite)
		
		hp_gauges[tile_pos] = {"bg": bg_sprite, "bar": bar_sprite}
	
	var gauge = hp_gauges[tile_pos]
	gauge["bg"].global_position = world_pos + Vector2(0, -TILE_SIZE / 2 - 4)
	
	# HP 바 업데이트 (hp_ratio에 따라 너비 변경)
	var bar_width = int(22 * hp_ratio)
	if bar_width > 0:
		var bar_image = Image.create(bar_width, 2, false, Image.FORMAT_RGBA8)
		# HP에 따라 색상 변경 (초록 → 노랑 → 빨강)
		var bar_color: Color
		if hp_ratio > 0.6:
			bar_color = Color(0.3, 0.9, 0.3, 1.0)  # 초록
		elif hp_ratio > 0.3:
			bar_color = Color(0.9, 0.9, 0.3, 1.0)  # 노랑
		else:
			bar_color = Color(0.9, 0.3, 0.3, 1.0)  # 빨강
		bar_image.fill(bar_color)
		gauge["bar"].texture = ImageTexture.create_from_image(bar_image)
		gauge["bar"].visible = true
	else:
		gauge["bar"].visible = false
	
	gauge["bar"].global_position = world_pos + Vector2(-11 + bar_width / 2.0, -TILE_SIZE / 2 - 4)

## 타일 흔들림 효과 (피격 시)
func shake_tile(tile_pos: Vector2i):
	# 균열 스프라이트가 있으면 흔들기
	if crack_sprites.has(tile_pos):
		var crack_sprite = crack_sprites[tile_pos]
		var original_pos = crack_sprite.position
		
		# 빠른 흔들림 효과
		var tween = create_tween()
		tween.tween_property(crack_sprite, "position", original_pos + Vector2(2, 0), 0.03)
		tween.tween_property(crack_sprite, "position", original_pos + Vector2(-2, 0), 0.03)
		tween.tween_property(crack_sprite, "position", original_pos + Vector2(0, 2), 0.03)
		tween.tween_property(crack_sprite, "position", original_pos + Vector2(0, -2), 0.03)
		tween.tween_property(crack_sprite, "position", original_pos, 0.03)

## 타일 HP 데이터 정리 (제거된 타일)
func cleanup_tile_data(tile_pos: Vector2i):
	tile_hp_data.erase(tile_pos)
	
	if crack_sprites.has(tile_pos):
		crack_sprites[tile_pos].queue_free()
		crack_sprites.erase(tile_pos)
	
	if hp_gauges.has(tile_pos):
		hp_gauges[tile_pos]["bg"].queue_free()
		hp_gauges[tile_pos]["bar"].queue_free()
		hp_gauges.erase(tile_pos)

## 설치 모드 하이라이트 업데이트
func update_build_mode_highlight():
	if not character or not build_highlight_sprite:
		return
	
	# 마우스 위치를 타일 좌표로 변환
	var mouse_global_pos = get_global_mouse_position()
	var mouse_local_pos = to_local(mouse_global_pos)
	var mouse_tile_pos = local_to_map(mouse_local_pos)
	
	# 캐릭터와의 거리 확인 (Area2D 안에 있는지)
	var tile_world_pos = to_global(map_to_local(mouse_tile_pos))
	var distance = character.global_position.distance_to(tile_world_pos)
	
	if distance > mining_radius:
		# Area2D 밖이면 하이라이트 숨기기
		build_highlight_sprite.visible = false
		build_target_tile = Vector2i(-9999, -9999)
		return
	
	# 해당 위치가 빈 공간인지 확인 (모든 레이어의 breakable_tile, platform 모두 없어야 함)
	var breakable_exists = false
	for i in range(get_layers_count()):
		if get_cell_source_id(i, mouse_tile_pos) != -1:
			breakable_exists = true
			break
	var platform_exists = false
	if platform_tilemap:
		platform_exists = platform_tilemap.get_cell_source_id(0, mouse_tile_pos) != -1
	
	if breakable_exists or platform_exists:
		# 타일이 이미 있으면 하이라이트 숨기기
		build_highlight_sprite.visible = false
		build_target_tile = Vector2i(-9999, -9999)
		return
	
	# 빈 공간이면 초록색 하이라이트 표시
	build_target_tile = mouse_tile_pos
	build_highlight_sprite.global_position = tile_world_pos
	build_highlight_sprite.visible = true

## 플랫폼 타일 설치
func place_platform_tile(tile_pos: Vector2i):
	if not platform_tilemap:
		return
	
	# platform 타일맵이 숨겨져 있으면 보이게 설정
	if not platform_tilemap.visible:
		platform_tilemap.visible = true
	
	# 이미 타일이 있는지 확인 (모든 레이어)
	var breakable_exists = false
	for i in range(get_layers_count()):
		if get_cell_source_id(i, tile_pos) != -1:
			breakable_exists = true
			break
	var platform_exists = platform_tilemap.get_cell_source_id(0, tile_pos) != -1
	
	if breakable_exists or platform_exists:
		return
	
	# 올바른 one-way platform 타일 정보 (Physics Layer 1이 활성화된 타일)
	# source_id: 1, atlas_coords: (6, 0) - Physics Layer 1 활성화됨
	var platform_source_id: int = 1
	var platform_atlas_coords: Vector2i = Vector2i(6, 0)
	
	# 타일 설치 (set_cell 사용)
	platform_tilemap.set_cell(0, tile_pos, platform_source_id, platform_atlas_coords)
	
	# 설치 파티클 효과
	spawn_build_particles(tile_pos)

## 설치 파티클 생성 (초록색)
func spawn_build_particles(tile_pos: Vector2i):
	# 타일의 월드 좌표 계산
	var world_pos = to_global(map_to_local(tile_pos))
	
	# 파티클 생성
	var particles = CPUParticles2D.new()
	particles.emitting = false
	particles.one_shot = true
	particles.amount = 8
	particles.lifetime = 0.4
	particles.explosiveness = 0.9
	particles.direction = Vector2(0, -1)
	particles.spread = 180
	particles.initial_velocity_min = 30
	particles.initial_velocity_max = 60
	particles.gravity = Vector2(0, 100)
	particles.scale_amount_min = 2
	particles.scale_amount_max = 4
	particles.color = Color(0.3, 1.0, 0.5, 0.8)  # 초록색
	particles.global_position = world_pos
	
	get_tree().root.add_child(particles)
	particles.emitting = true
	
	# 파티클이 끝나면 자동 삭제
	await get_tree().create_timer(particles.lifetime).timeout
	if is_instance_valid(particles):
		particles.queue_free()

## 타일을 채굴합니다 (HP 감소 → 0이 되면 제거 + 보상)
func mine_tile(tile_pos: Vector2i):
	# 채굴 가능한 레이어에서 타일 찾기
	var mining_layer = get_mineable_layer(tile_pos)
	if mining_layer == -1:
		return
	
	# 타일 HP 가져오기 (없으면 초기화)
	var hp_data = get_tile_hp(tile_pos, mining_layer)
	
	# 데미지 계산 (기본 1, 추후 업그레이드로 증가 가능)
	var damage = 1
	hp_data["hp"] -= damage
	
	# HP 비율 계산
	var hp_ratio = float(hp_data["hp"]) / float(hp_data["max_hp"])
	
	if hp_data["hp"] <= 0:
		# ========================================
		# 타일 파괴! (HP가 0 이하)
		# ========================================
		
		# HP 데이터 및 오버레이 정리
		cleanup_tile_data(tile_pos)
		
		# 타일 제거 + 주변 타일 terrain 자동 업데이트
		set_cells_terrain_connect(mining_layer, [tile_pos], 0, -1)
		
		# 인접한 횃불들 업데이트 (벽이 사라지면 STAND로 변경)
		update_adjacent_torches(tile_pos)
		
		# 보상 지급 (레이어가 높을수록 더 많은 보상)
		var layer_bonus = mining_layer * 2  # layer 0 = +0, layer 1 = +2, layer 2 = +4
		var base_money = Globals.money_up + Globals.rock_money_bonus + layer_bonus
		var money_gained = int(base_money * Globals.fever_multiplier)
		
		# x3, x2 확률 체크
		var random_roll = randf()
		var is_x3 = random_roll < Globals.x3_chance
		var is_x2 = not is_x3 and random_roll < (Globals.x3_chance + Globals.x2_chance)
		
		if is_x3:
			money_gained *= 3
		elif is_x2:
			money_gained *= 2
		
		Globals.money += money_gained
		
		# 파괴 파티클 효과 (큰 효과)
		spawn_mining_particles(tile_pos)
	else:
		# ========================================
		# 데미지만 입힘 (HP가 남아있음)
		# ========================================
		
		# 균열 오버레이 업데이트
		update_crack_overlay(tile_pos, hp_ratio)
		
		# HP 게이지 표시
		update_hp_gauge(tile_pos, hp_ratio, true)
		
		# 흔들림 효과
		shake_tile(tile_pos)
		
		# 작은 먼지 파티클
		spawn_hit_particles(tile_pos)

## 채굴 파티클 생성 (타일 파괴 시 - 큰 효과)
func spawn_mining_particles(tile_pos: Vector2i):
	# 타일의 월드 좌표 계산
	var world_pos = to_global(map_to_local(tile_pos))
	
	# 파티클 생성
	var particles = CPUParticles2D.new()
	particles.emitting = false
	particles.one_shot = true
	particles.amount = 16  # 파괴 시 더 많은 파티클
	particles.lifetime = 0.7
	particles.explosiveness = 0.95
	particles.direction = Vector2(0, -1)
	particles.spread = 180
	particles.initial_velocity_min = 50
	particles.initial_velocity_max = 100
	particles.gravity = Vector2(0, 250)
	particles.scale_amount_min = 3
	particles.scale_amount_max = 6
	particles.color = Color(0.6, 0.4, 0.2, 0.9)  # 갈색 흙 색상
	particles.global_position = world_pos
	
	get_tree().root.add_child(particles)
	particles.emitting = true
	
	# 파티클이 끝나면 자동 삭제
	await get_tree().create_timer(particles.lifetime).timeout
	if is_instance_valid(particles):
		particles.queue_free()

## 피격 파티클 생성 (데미지만 입었을 때 - 작은 효과)
func spawn_hit_particles(tile_pos: Vector2i):
	# 타일의 월드 좌표 계산
	var world_pos = to_global(map_to_local(tile_pos))
	
	# 작은 먼지 파티클
	var particles = CPUParticles2D.new()
	particles.emitting = false
	particles.one_shot = true
	particles.amount = 6
	particles.lifetime = 0.35
	particles.explosiveness = 0.9
	particles.direction = Vector2(0, -1)
	particles.spread = 120
	particles.initial_velocity_min = 20
	particles.initial_velocity_max = 45
	particles.gravity = Vector2(0, 150)
	particles.scale_amount_min = 1.5
	particles.scale_amount_max = 3
	particles.color = Color(0.55, 0.45, 0.35, 0.7)  # 연한 갈색 먼지
	particles.global_position = world_pos
	
	get_tree().root.add_child(particles)
	particles.emitting = true
	
	# 파티클이 끝나면 자동 삭제
	await get_tree().create_timer(particles.lifetime).timeout
	if is_instance_valid(particles):
		particles.queue_free()

## 캐릭터에서 마우스 방향으로 raycast를 쏴서 타일 찾기
func get_tile_from_raycast() -> Vector2i:
	var mouse_global_pos = get_global_mouse_position()
	var char_global_pos = character.global_position
	
	# 캐릭터에서 마우스 방향 계산
	var direction = (mouse_global_pos - char_global_pos).normalized()
	
	# raycast 거리 (Area2D 반지름)
	var ray_distance = mining_radius
	
	# raycast를 따라 여러 지점을 샘플링 (타일 크기의 절반 간격)
	var step_size = TILE_SIZE / 4.0  # 8픽셀 간격으로 체크
	var steps = int(ray_distance / step_size)
	
	for i in range(1, steps + 1):
		var check_pos = char_global_pos + direction * (i * step_size)
		
		# 월드 좌표를 타일 좌표로 변환
		var local_pos = to_local(check_pos)
		var tile_pos = local_to_map(local_pos)
		
		# 채굴 가능한 레이어에 타일이 존재하는지 확인
		var tile_exists = tile_exists_in_mineable_layers(tile_pos)
		
		if tile_exists:
			# 타일의 겉면이 노출되어 있는지 확인
			var is_exposed = is_tile_exposed(tile_pos)
			
			if is_exposed:
				# Area2D 안에 있는지 체크 (거리가 반지름 이내)
				var tile_world_pos = to_global(map_to_local(tile_pos))
				var distance = char_global_pos.distance_to(tile_world_pos)
				
				if distance <= mining_radius:
					return tile_pos
	
	return Vector2i(-9999, -9999)

## 타일의 겉면이 노출되어 있는지 확인 (상하좌우 중 최소 한 면이 비어있어야 함)
func is_tile_exposed(tile_pos: Vector2i) -> bool:
	# 상하좌우 체크
	var neighbors = [
		Vector2i(0, -1),  # 위
		Vector2i(0, 1),   # 아래
		Vector2i(-1, 0),  # 왼쪽
		Vector2i(1, 0)    # 오른쪽
	]
	
	var exposed_sides = []
	
	for offset in neighbors:
		var neighbor_pos = tile_pos + offset
		var neighbor_exists = tile_exists_in_mineable_layers(neighbor_pos)
		
		# 인접한 칸이 비어있으면 겉면이 노출된 것
		if not neighbor_exists:
			# 방향 문자열 생성
			if offset == Vector2i(0, -1):
				exposed_sides.append("위")
			elif offset == Vector2i(0, 1):
				exposed_sides.append("아래")
			elif offset == Vector2i(-1, 0):
				exposed_sides.append("왼쪽")
			elif offset == Vector2i(1, 0):
				exposed_sides.append("오른쪽")
	
	# 디버그 메시지 (최초 발견 시에만)
	if exposed_sides.size() > 0:
		return true
	else:
		# 모든 면이 막혀있음
		return false

## 캐릭터 근처에 Rock이 있는지 확인
func is_near_rock() -> bool:
	if not character:
		return false
	
	var rocks = get_tree().get_nodes_in_group("rocks")
	for rock in rocks:
		if rock and character.global_position.distance_to(rock.global_position) < 50:
			return true
	return false

## 횃불 하이라이트 스프라이트 생성 (주황색)
func create_torch_highlight_sprite():
	torch_highlight_sprite = Sprite2D.new()
	
	# 하이라이트 텍스처 생성 (주황색 반투명 사각형)
	var highlight_image = Image.create(TILE_SIZE, TILE_SIZE, false, Image.FORMAT_RGBA8)
	
	# 테두리만 그리기 (2픽셀 두께)
	for x in range(TILE_SIZE):
		for y in range(TILE_SIZE):
			if x < 2 or x >= TILE_SIZE - 2 or y < 2 or y >= TILE_SIZE - 2:
				highlight_image.set_pixel(x, y, Color(1.0, 0.6, 0.0, 0.8))  # 주황색
			else:
				highlight_image.set_pixel(x, y, Color(1.0, 0.6, 0.0, 0.3))  # 반투명 주황색
	
	var highlight_texture = ImageTexture.create_from_image(highlight_image)
	torch_highlight_sprite.texture = highlight_texture
	torch_highlight_sprite.visible = false
	torch_highlight_sprite.z_index = 10
	
	add_child(torch_highlight_sprite)

## 횃불 모드 하이라이트 업데이트
func update_torch_mode_highlight():
	if not character or not torch_highlight_sprite:
		return
	
	# 마우스 위치를 타일 좌표로 변환
	var mouse_global_pos = get_global_mouse_position()
	var mouse_local_pos = to_local(mouse_global_pos)
	var mouse_tile_pos = local_to_map(mouse_local_pos)
	
	# 캐릭터와의 거리 확인
	var tile_world_pos = to_global(map_to_local(mouse_tile_pos))
	var distance = character.global_position.distance_to(tile_world_pos)
	
	if distance > mining_radius:
		torch_highlight_sprite.visible = false
		build_target_tile = Vector2i(-9999, -9999)
		return
	
	# 해당 위치가 빈 공간인지 확인 (모든 레이어)
	var breakable_exists = false
	for i in range(get_layers_count()):
		if get_cell_source_id(i, mouse_tile_pos) != -1:
			breakable_exists = true
			break
	var platform_exists = false
	if platform_tilemap:
		platform_exists = platform_tilemap.get_cell_source_id(0, mouse_tile_pos) != -1
	
	if breakable_exists or platform_exists:
		torch_highlight_sprite.visible = false
		build_target_tile = Vector2i(-9999, -9999)
		return
	
	# 빈 공간이면 주황색 하이라이트 표시
	build_target_tile = mouse_tile_pos
	torch_highlight_sprite.global_position = tile_world_pos
	torch_highlight_sprite.visible = true

## 횃불 설치
func place_torch(tile_pos: Vector2i):
	if not torch_scene:
		return
	
	# 이미 횃불이 있는지 확인
	if installed_torches.has(tile_pos):
		return
	
	# 이미 타일이 있는지 확인 (모든 레이어)
	var breakable_exists = false
	for i in range(get_layers_count()):
		if get_cell_source_id(i, tile_pos) != -1:
			breakable_exists = true
			break
	var platform_exists = false
	if platform_tilemap:
		platform_exists = platform_tilemap.get_cell_source_id(0, tile_pos) != -1
	
	if breakable_exists or platform_exists:
		return
	
	# 양옆 타일 확인 (모든 레이어에서 breakable_tile 체크)
	var left_tile_exists = false
	var right_tile_exists = false
	for i in range(get_layers_count()):
		if get_cell_source_id(i, tile_pos + Vector2i(-1, 0)) != -1:
			left_tile_exists = true
		if get_cell_source_id(i, tile_pos + Vector2i(1, 0)) != -1:
			right_tile_exists = true
	
	# 횃불 인스턴스 생성
	var torch_instance = torch_scene.instantiate()
	
	# 타일 위치를 월드 좌표로 변환
	var world_pos = to_global(map_to_local(tile_pos))
	
	# 횃불 타입 결정
	if left_tile_exists:
		# 왼쪽에 타일이 있으면 → WALL_REVERSE (flip_h로 왼쪽을 바라봄)
		torch_instance.torch_type = torch_instance.TorchType.WALL_REVERSE
	elif right_tile_exists:
		# 오른쪽에 타일이 있으면 → WALL
		torch_instance.torch_type = torch_instance.TorchType.WALL
	else:
		# 양옆에 타일이 없으면 → STAND
		torch_instance.torch_type = torch_instance.TorchType.STAND
	
	# 부모 map 노드 (map_1 또는 map_2) 아래의 torch 노드에 추가
	var parent_map = get_parent()  # map_1 또는 map_2
	var torch_container = parent_map.get_node_or_null("torch")
	
	if not torch_container:
		# torch 노드가 없으면 생성
		torch_container = Node2D.new()
		torch_container.name = "torch"
		parent_map.add_child(torch_container)
	
	# 먼저 자식으로 추가한 후에 global_position 설정!
	torch_container.add_child(torch_instance)
	torch_instance.global_position = world_pos
	
	# 설치된 횃불 Dictionary에 저장
	installed_torches[tile_pos] = torch_instance
	
	# 설치 파티클 효과 (주황색)
	spawn_torch_particles(tile_pos)

## 인접한 횃불들의 타입 업데이트 (벽이 사라지면 STAND로 변경)
func update_adjacent_torches(removed_tile_pos: Vector2i):
	# 제거된 타일의 양옆에 횃불이 있는지 확인
	var adjacent_positions = [
		removed_tile_pos + Vector2i(-1, 0),  # 왼쪽
		removed_tile_pos + Vector2i(1, 0)    # 오른쪽
	]
	
	for torch_pos in adjacent_positions:
		if installed_torches.has(torch_pos):
			var torch_instance = installed_torches[torch_pos]
			if not is_instance_valid(torch_instance):
				installed_torches.erase(torch_pos)
				continue
			
			# 횃불 주변의 벽 상태 다시 확인 (모든 레이어 체크)
			var left_tile_exists = false
			var right_tile_exists = false
			for i in range(get_layers_count()):
				if get_cell_source_id(i, torch_pos + Vector2i(-1, 0)) != -1:
					left_tile_exists = true
				if get_cell_source_id(i, torch_pos + Vector2i(1, 0)) != -1:
					right_tile_exists = true
			
			# 새로운 타입 결정
			var new_type
			if left_tile_exists:
				new_type = torch_instance.TorchType.WALL_REVERSE
			elif right_tile_exists:
				new_type = torch_instance.TorchType.WALL
			else:
				new_type = torch_instance.TorchType.STAND
			
			# 타입이 변경되었으면 업데이트
			if torch_instance.torch_type != new_type:
				torch_instance.torch_type = new_type
				
				# 애니메이션 변경
				if torch_instance.animation_player:
					match new_type:
						torch_instance.TorchType.WALL:
							torch_instance.animation_player.play("wall_fire")
						torch_instance.TorchType.WALL_REVERSE:
							torch_instance.animation_player.play("reverse_wall_fire")
						torch_instance.TorchType.STAND:
							torch_instance.animation_player.play("stand_fire")

## 횃불 설치 파티클 생성 (주황색)
func spawn_torch_particles(tile_pos: Vector2i):
	var world_pos = to_global(map_to_local(tile_pos))
	
	var particles = CPUParticles2D.new()
	particles.emitting = false
	particles.one_shot = true
	particles.amount = 10
	particles.lifetime = 0.5
	particles.explosiveness = 0.9
	particles.direction = Vector2(0, -1)
	particles.spread = 180
	particles.initial_velocity_min = 30
	particles.initial_velocity_max = 60
	particles.gravity = Vector2(0, 80)
	particles.scale_amount_min = 2
	particles.scale_amount_max = 4
	particles.color = Color(1.0, 0.6, 0.2, 0.9)  # 주황색
	particles.global_position = world_pos
	
	get_tree().root.add_child(particles)
	particles.emitting = true
	
	await get_tree().create_timer(particles.lifetime).timeout
	if is_instance_valid(particles):
		particles.queue_free()
