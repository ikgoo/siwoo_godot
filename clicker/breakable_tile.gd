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
const MINING_INTERVAL: float = 0.15  # 연속 채굴 간격 (초)

# 설치 모드
var is_build_mode: bool = false  # 설치 모드 활성화 여부
var build_target_tile: Vector2i = Vector2i(-9999, -9999)  # 설치할 타일 좌표
var build_highlight_sprite: Sprite2D = null  # 설치 하이라이트 스프라이트 (초록색)
var platform_tilemap: TileMap = null  # platform 타일맵 참조

const MINING_LAYER: int = 0  # 채굴 가능한 레이어 인덱스
const TILE_SIZE: int = 32  # 타일 크기 (픽셀)

# 플랫폼 타일 설정 (terrain 사용)
const PLATFORM_TERRAIN_SET: int = 0
const PLATFORM_TERRAIN_ID: int = 0  # terrain ID (플랫폼용)

func _ready():
	# breakable_tilemaps 그룹에 추가
	add_to_group("breakable_tilemaps")
	
	# 하이라이트 스프라이트 생성
	create_highlight_sprite()
	create_build_highlight_sprite()
	
	# platform 타일맵 찾기
	find_platform_tilemap()
	
	print("💎 [", name, "] breakable_tile 초기화 완료!")
	print("  - 경로: ", get_path())
	print("  - visible: ", visible)
	print("  - 채굴 가능한 타일 개수: ", get_used_cells(MINING_LAYER).size())
	
	# 첫 번째 타일 위치 출력
	var used_cells = get_used_cells(MINING_LAYER)
	if used_cells.size() > 0:
		print("  - 첫 번째 타일 좌표: ", used_cells[0])
		print("  - 첫 번째 타일 월드 위치: ", to_global(map_to_local(used_cells[0])))

func _process(_delta):
	# 캐릭터를 아직 찾지 못했으면 찾기 시도
	if not character:
		character = get_tree().root.get_node_or_null("main/character")
		if not character:
			return
		else:
			print("✅ [", name, "] 캐릭터 발견: ", character.get_path())
			# 캐릭터의 Area2D와 반지름 가져오기
			character_area = character.get_node_or_null("Area2D")
			if character_area:
				var collision_shape = character_area.get_node_or_null("CollisionShape2D")
				if collision_shape and collision_shape.shape is CircleShape2D:
					mining_radius = collision_shape.shape.radius
					print("  - 채굴 Area2D 반지름: ", mining_radius)
	
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
		
		# 새로운 타일을 타겟팅할 때 디버그 (1초마다)
		if prev_target != target_tile and Engine.get_frames_drawn() % 60 == 0:
			var distance = character.global_position.distance_to(to_global(map_to_local(target_tile)))
			
			# 노출된 면 확인
			var neighbors = [
				Vector2i(0, -1),  # 위
				Vector2i(0, 1),   # 아래
				Vector2i(-1, 0),  # 왼쪽
				Vector2i(1, 0)    # 오른쪽
			]
			var exposed_sides = []
			for offset in neighbors:
				var neighbor_pos = target_tile + offset
				var neighbor_exists = get_cell_source_id(MINING_LAYER, neighbor_pos) != -1
				if not neighbor_exists:
					if offset == Vector2i(0, -1):
						exposed_sides.append("위")
					elif offset == Vector2i(0, 1):
						exposed_sides.append("아래")
					elif offset == Vector2i(-1, 0):
						exposed_sides.append("왼쪽")
					elif offset == Vector2i(1, 0):
						exposed_sides.append("오른쪽")
			
			print("🎯 [", name, "] 타일 타겟팅: ", target_tile, " (거리: ", int(distance), ")")
			print("  - 노출된 면: ", exposed_sides)
	else:
		target_tile = Vector2i(-9999, -9999)
		
		# 하이라이트 숨기기
		if highlight_sprite:
			highlight_sprite.visible = false
	
	# 좌클릭 꾹 누르고 있으면 연속 채굴 (설치 모드가 아닐 때만)
	if not is_build_mode and is_mouse_holding and target_tile != Vector2i(-9999, -9999):
		mining_cooldown -= _delta
		if mining_cooldown <= 0.0:
			mine_tile(target_tile)
			mining_cooldown = MINING_INTERVAL
	
	# 설치 모드일 때 빈 공간 하이라이트
	if is_build_mode:
		update_build_mode_highlight()
	else:
		if build_highlight_sprite:
			build_highlight_sprite.visible = false
		build_target_tile = Vector2i(-9999, -9999)

func _input(event):
	# 2번 키로 설치 모드 토글
	if event is InputEventKey:
		if event.keycode == KEY_2 and event.pressed and not event.echo:
			is_build_mode = not is_build_mode
			if is_build_mode:
				print("🔧 [", name, "] 설치 모드 활성화!")
				# 채굴 하이라이트 숨기기
				if highlight_sprite:
					highlight_sprite.visible = false
			else:
				print("⛏️ [", name, "] 채굴 모드로 복귀!")
				# 설치 하이라이트 숨기기
				if build_highlight_sprite:
					build_highlight_sprite.visible = false
		
		# B키로 플랫폼 설치 (설치 모드일 때만)
		if event.keycode == KEY_B and event.pressed and not event.echo:
			if is_build_mode and build_target_tile != Vector2i(-9999, -9999):
				place_platform_tile(build_target_tile)
	
	# 좌클릭 눌림/뗌 감지 (설치 모드가 아닐 때만)
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if not is_build_mode:
				if event.pressed:
					# 좌클릭 눌림 - 즉시 채굴 + 연속 채굴 모드 시작
					is_mouse_holding = true
					mining_cooldown = MINING_INTERVAL  # 첫 클릭 후 잠시 대기
					
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
	print("✨ [", name, "] 채굴 하이라이트 스프라이트 생성 완료!")

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
	print("✨ [", name, "] 설치 하이라이트 스프라이트 생성 완료!")

## platform 타일맵 찾기
func find_platform_tilemap():
	var parent = get_parent()  # map_1 또는 map_2
	if parent:
		platform_tilemap = parent.get_node_or_null("platform")
		if platform_tilemap:
			print("✅ [", name, "] platform 타일맵 발견: ", platform_tilemap.get_path())

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
	
	# 해당 위치가 빈 공간인지 확인 (breakable_tile, platform 모두 없어야 함)
	var breakable_exists = get_cell_source_id(MINING_LAYER, mouse_tile_pos) != -1
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
		print("❌ [", name, "] platform 타일맵이 없습니다!")
		return
	
	# platform 타일맵이 숨겨져 있으면 보이게 설정
	if not platform_tilemap.visible:
		platform_tilemap.visible = true
		print("👁️ [", name, "] platform 타일맵 visible = true로 설정!")
	
	# 이미 타일이 있는지 확인
	var breakable_exists = get_cell_source_id(MINING_LAYER, tile_pos) != -1
	var platform_exists = platform_tilemap.get_cell_source_id(0, tile_pos) != -1
	
	if breakable_exists or platform_exists:
		print("❌ [", name, "] 해당 위치에 이미 타일이 있습니다!")
		return
	
	# 올바른 one-way platform 타일 정보 (Physics Layer 1이 활성화된 타일)
	# source_id: 1, atlas_coords: (6, 0) - Physics Layer 1 활성화됨
	var platform_source_id: int = 1
	var platform_atlas_coords: Vector2i = Vector2i(6, 0)
	
	# 타일 설치 (set_cell 사용)
	platform_tilemap.set_cell(0, tile_pos, platform_source_id, platform_atlas_coords)
	
	# 설치 확인
	var check_id = platform_tilemap.get_cell_source_id(0, tile_pos)
	if check_id != -1:
		print("🔧 [", name, "] 플랫폼 타일 설치 완료!")
		print("  - 좌표: ", tile_pos)
		print("  - source_id: ", platform_source_id)
		print("  - atlas_coords: ", platform_atlas_coords)
	else:
		print("❌ [", name, "] 플랫폼 타일 설치 실패!")
	
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

## 타일을 채굴합니다 (제거 + 보상)
func mine_tile(tile_pos: Vector2i):
	# 타일이 존재하는지 확인
	if get_cell_source_id(MINING_LAYER, tile_pos) == -1:
		return
	
	# 타일 제거 + 주변 타일 terrain 자동 업데이트
	# set_cells_terrain_connect(레이어, [좌표들], terrain_set, terrain_id)
	# terrain_id를 -1로 설정하면 해당 좌표의 타일이 제거되고 주변 타일들이 자동으로 업데이트됨
	set_cells_terrain_connect(MINING_LAYER, [tile_pos], 0, -1)
	
	# 보상 지급 (Rock과 동일한 시스템)
	var money_gained = int(Globals.money_up * Globals.fever_multiplier)
	
	# x3, x2 확률 체크
	var random_roll = randf()
	var is_x3 = random_roll < Globals.x3_chance
	var is_x2 = not is_x3 and random_roll < (Globals.x3_chance + Globals.x2_chance)
	
	if is_x3:
		money_gained *= 3
	elif is_x2:
		money_gained *= 2
	
	Globals.money += money_gained
	
	# 메시지 출력
	if is_x3:
		print("🌟 타일 채굴 잭팟! +💎", money_gained, " (x3), 현재 돈: 💎", Globals.money)
	elif is_x2:
		print("💥 타일 채굴 크리티컬! +💎", money_gained, " (x2), 현재 돈: 💎", Globals.money)
	elif Globals.is_fever_active:
		print("🔥 타일 채굴 피버! +💎", money_gained, " (", Globals.fever_multiplier, "배), 현재 돈: 💎", Globals.money)
	else:
		print("💎 타일 채굴! +💎", money_gained, ", 현재 돈: 💎", Globals.money)
	
	# 파티클 효과 생성 (타일 위치에)
	spawn_mining_particles(tile_pos)

## 채굴 파티클 생성 (타일 위치에)
func spawn_mining_particles(tile_pos: Vector2i):
	# 타일의 월드 좌표 계산
	var world_pos = to_global(map_to_local(tile_pos))
	
	# 파티클 생성
	var particles = CPUParticles2D.new()
	particles.emitting = false
	particles.one_shot = true
	particles.amount = 12
	particles.lifetime = 0.6
	particles.explosiveness = 0.9
	particles.direction = Vector2(0, -1)
	particles.spread = 180
	particles.initial_velocity_min = 40
	particles.initial_velocity_max = 80
	particles.gravity = Vector2(0, 200)
	particles.scale_amount_min = 3
	particles.scale_amount_max = 5
	particles.color = Color(0.6, 0.4, 0.2, 0.8)  # 갈색 흙 색상
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
	
	# 디버그 (1초마다)
	var should_debug = Engine.get_frames_drawn() % 60 == 0
	
	if should_debug:
		print("🔍 [", name, "] Raycast 검색 중...")
		print("  - 캐릭터 위치: ", char_global_pos)
		print("  - 마우스 위치: ", mouse_global_pos)
		print("  - 방향: ", direction)
		print("  - 검색 스텝: ", steps)
	
	for i in range(1, steps + 1):
		var check_pos = char_global_pos + direction * (i * step_size)
		
		# 월드 좌표를 타일 좌표로 변환
		var local_pos = to_local(check_pos)
		var tile_pos = local_to_map(local_pos)
		
		# 타일이 존재하는지 확인
		var tile_exists = get_cell_source_id(MINING_LAYER, tile_pos) != -1
		
		if tile_exists:
			# 타일의 겉면이 노출되어 있는지 확인
			var is_exposed = is_tile_exposed(tile_pos)
			
			if should_debug:
				print("  ✓ 타일 발견: ", tile_pos, " (겉면 노출: ", is_exposed, ")")
			
			if is_exposed:
				# Area2D 안에 있는지 체크 (거리가 반지름 이내)
				var tile_world_pos = to_global(map_to_local(tile_pos))
				var distance = char_global_pos.distance_to(tile_world_pos)
				
				if distance <= mining_radius:
					if should_debug:
						print("  ✅ Area2D 안에 있는 채굴 가능한 타일 발견!")
					return tile_pos
				elif should_debug:
					print("  ❌ Area2D 밖: ", int(distance), " > ", int(mining_radius))
	
	if should_debug:
		print("  ❌ 채굴 가능한 타일 없음")
	
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
		var neighbor_exists = get_cell_source_id(MINING_LAYER, neighbor_pos) != -1
		
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
