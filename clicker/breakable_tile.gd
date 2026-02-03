extends TileMap

## ========================================
## 파괴 가능한 타일 시스템
## ========================================
## 레이어별 티어 체크:
## - layer_0~3: 해당 레이어 + 1 티어 필요
## - layer_4 (instant_break): 티어 무시, 한방 파괴
## ========================================

# 특수 레이어 인덱스 (한방 파괴)
const INSTANT_BREAK_LAYER: int = 4

# 캐릭터 참조
var character: CharacterBody2D = null

# 현재 하이라이트된 타일 정보
var highlighted_tile: Vector2i = Vector2i(-9999, -9999)
var highlighted_layer: int = -1

# 채굴 범위 (캐릭터로부터의 거리, 픽셀)
@export var mining_range: float = 40.0

# 하이라이트용 Sprite2D
var highlight_sprite: Sprite2D = null
var highlight_pulse_time: float = 0.0  # 펄스 애니메이션용

# 체력바 UI
var hp_bar_bg: ColorRect = null
var hp_bar_fill: ColorRect = null

# 타일별 남은 클릭 횟수 (HP)
# key: "layer_x_y" 형식, value: 남은 클릭 횟수
var tile_hp: Dictionary = {}

# 먼지 파티클 텍스처
var dust_texture: Texture2D = null

# 사운드 (선택적)
@onready var break_sound: AudioStreamPlayer = $break_sound if has_node("break_sound") else null

func _ready():
	# breakable_tiles 그룹에 추가 (캐릭터가 찾을 수 있도록)
	add_to_group("breakable_tiles")
	print("✅ breakable_tile이 breakable_tiles 그룹에 추가됨: ", name)
	
	# 캐릭터 찾기
	await get_tree().process_frame
	character = Globals.player
	
	# TileSet 확인
	if tile_set:
		print("✅ TileSet 연결됨, 타일 크기: ", tile_set.tile_size)
	else:
		print("❌ TileSet이 연결되지 않음!")
	
	# 하이라이트 스프라이트 생성
	create_highlight_sprite()
	
	# 먼지 텍스처 로드
	if ResourceLoader.exists("res://CONCEPT/asset/mine_clicker32-dust.png"):
		dust_texture = load("res://CONCEPT/asset/mine_clicker32-dust.png")

func _process(delta):
	if not character:
		character = Globals.player
		return
	
	# 캐릭터 근처의 타일 찾기 및 하이라이트
	update_highlighted_tile()
	
	# 하이라이트 펄스 애니메이션 (Sprite2D)
	if highlight_sprite and highlight_sprite.visible:
		highlight_pulse_time += delta * 4.0
		var pulse = (sin(highlight_pulse_time) + 1.0) / 2.0  # 0.0 ~ 1.0
		var alpha = 0.4 + pulse * 0.3  # 0.4 ~ 0.7
		highlight_sprite.modulate.a = alpha

# 마우스 클릭 입력은 비활성화 (raycast 방식 사용)
# func _input(event: InputEvent):
# 	if event is InputEventMouseButton:
# 		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
# 			try_break_tile_at_mouse()

## ========================================
## 캐릭터 근처 가장 가까운 타일 찾기 (raycast 방식 대체)
## ========================================

## 특정 월드 좌표에 타일이 있는지 확인합니다 (횃불/플랫폼 설치 체크용).
## @param world_pos: 월드 좌표
## @returns: 타일이 있으면 true, 없으면 false
func has_tile_at_position(world_pos: Vector2) -> bool:
	var local_pos = to_local(world_pos)
	var tile_pos = local_to_map(local_pos)
	
	# 모든 레이어에서 타일 확인
	for layer_idx in range(get_layers_count()):
		var source_id = get_cell_source_id(layer_idx, tile_pos)
		if source_id != -1:
			# 타일 발견!
			return true
	
	# 타일 없음
	return false

## 타일이 채굴 가능한지 확인합니다 (상하좌우 중 최소 한 면이 노출되어 있어야 함).
## @param tile_pos: 타일 좌표
## @param layer_idx: 레이어 인덱스
## @returns: 채굴 가능하면 true, 완전히 막혀있으면 false
func is_tile_exposed(tile_pos: Vector2i, layer_idx: int) -> bool:
	# 상하좌우 4방향만 체크 (대각선은 무시)
	var neighbors = [
		Vector2i(0, -1),  # 위
		Vector2i(-1, 0),  # 왼쪽
		Vector2i(1, 0),   # 오른쪽
		Vector2i(0, 1)    # 아래
	]
	
	# 최소 한 방향이라도 비어있으면 채굴 가능
	for offset in neighbors:
		var neighbor_pos = tile_pos + offset
		var source_id = get_cell_source_id(layer_idx, neighbor_pos)
		if source_id == -1:
			# 빈 공간 발견! 채굴 가능
			return true
	
	# 상하좌우가 모두 막혀있음 - 채굴 불가
	return false

## 마우스 방향으로 raycast해서 가장 가까운 타일을 찾습니다.
## @returns: { "tile_pos": Vector2i, "layer": int, "world_pos": Vector2 } 또는 null
func get_nearest_breakable_tile() -> Variant:
	if not character:
		return null
	
	# TileSet이 없으면 검색 불가
	if not tile_set:
		return null
	
	var char_pos = character.global_position
	var mouse_pos = get_global_mouse_position()
	
	# 캐릭터 → 마우스 방향 계산
	var direction = (mouse_pos - char_pos).normalized()
	if direction.length() < 0.01:
		direction = Vector2.RIGHT  # 방향이 없으면 오른쪽
	
	# raycast 방식: 캐릭터에서 마우스 방향으로 타일들을 검사
	var tile_size_val = tile_set.tile_size.x if tile_set.tile_size.x > 0 else 16
	var step_size = tile_size_val * 0.5  # 반 타일씩 이동하며 검사
	var max_steps = int(mining_range / step_size) + 1
	
	# 캐릭터 위치에서 마우스 방향으로 raycast
	for step in range(max_steps):
		var check_pos = char_pos + direction * (step * step_size)
		var distance_from_char = char_pos.distance_to(check_pos)
		
		# 채굴 범위 초과하면 중단
		if distance_from_char > mining_range:
			break
		
		# 해당 위치의 타일 좌표
		var tile_pos = local_to_map(to_local(check_pos))
		
		# 모든 레이어에서 타일 찾기 (위에서부터)
		for layer_idx in range(get_layers_count() - 1, -1, -1):
			var source_id = get_cell_source_id(layer_idx, tile_pos)
			if source_id != -1:
				# 타일 발견!
				var tile_world_pos = to_global(map_to_local(tile_pos))
				var tile_distance = char_pos.distance_to(tile_world_pos)
				
				# 채굴 범위 내에 있는지 최종 확인
				if tile_distance <= mining_range:
					# 타일이 노출되어 있는지 확인 (완전히 막혀있으면 채굴 불가)
					if not is_tile_exposed(tile_pos, layer_idx):
						break  # 이 타일은 채굴 불가, 다음 step으로
					
					return {
						"tile_pos": tile_pos,
						"layer": layer_idx,
						"world_pos": tile_world_pos,
						"distance": tile_distance
					}
				break  # 이 타일 좌표는 범위 밖이므로 다음 step으로
	
	# 타일을 찾지 못함
	return null

## 캐릭터가 근처에 파괴 가능한 타일이 있는지 확인합니다.
func has_nearby_breakable_tile() -> bool:
	var nearest = get_nearest_breakable_tile()
	if nearest:
		# 디버그: 타일 감지됨
		# print("🎯 타일 감지: ", nearest["tile_pos"], " layer: ", nearest["layer"], " dist: ", nearest["distance"])
		pass
	return nearest != null

## 특정 위치 근처에 파괴 가능한 타일이 있는지 확인합니다 (요정용).
## @param position: 확인할 위치 (월드 좌표)
## @returns: 범위 내 타일이 있으면 true
func has_nearby_breakable_tile_at_position(position: Vector2) -> bool:
	# TileSet이 없으면 검색 불가
	if not tile_set:
		return false
	
	# 해당 위치 주변의 타일 확인
	var local_pos = to_local(position)
	var tile_pos = local_to_map(local_pos)
	
	# 주변 3x3 범위 검사
	for dx in range(-1, 2):
		for dy in range(-1, 2):
			var check_pos = tile_pos + Vector2i(dx, dy)
			
			# 모든 레이어에서 타일 찾기
			for layer_idx in range(get_layers_count()):
				var source_id = get_cell_source_id(layer_idx, check_pos)
				if source_id != -1:
					# 타일 발견
					var tile_world_pos = to_global(map_to_local(check_pos))
					var distance = position.distance_to(tile_world_pos)
					
					# mining_range 내에 있으면 true
					if distance <= mining_range:
						return true
	
	return false

## 캐릭터 근처의 가장 가까운 타일을 채굴합니다 (character.gd에서 호출).
## 클릭할 때마다 HP가 줄어들고, 0이 되면 타일 파괴
## @returns: 채굴 성공 여부
func mine_nearest_tile() -> bool:
	var nearest = get_nearest_breakable_tile()
	if nearest == null:
		return false
	
	var tile_pos = nearest["tile_pos"]
	var layer_idx = nearest["layer"]
	var tile_world_pos = nearest["world_pos"]
	
	# 타일이 실제로 존재하는지 다시 확인
	var source_id = get_cell_source_id(layer_idx, tile_pos)
	if source_id == -1:
		return false
	
	# 타일 HP 키 생성
	var hp_key = "%d_%d_%d" % [layer_idx, tile_pos.x, tile_pos.y]
	
	# 타일 HP가 없으면 초기화
	if not tile_hp.has(hp_key):
		var max_hp = get_required_clicks(layer_idx)
		tile_hp[hp_key] = max_hp
	
	# HP 감소
	tile_hp[hp_key] -= 1
	var remaining_hp = tile_hp[hp_key]
	
	# 채굴 이펙트 (타격)
	spawn_hit_particles(tile_world_pos)
	
	# HP가 0 이하면 타일 파괴
	if remaining_hp <= 0:
		tile_hp.erase(hp_key)  # HP 데이터 삭제
		break_tile(tile_pos, layer_idx)
		return true
	else:
		return true

## 타격 파티클을 생성합니다 (타일 파괴 전 타격 이펙트)
func spawn_hit_particles(world_pos: Vector2):
	var particles = CPUParticles2D.new()
	particles.emitting = false
	particles.one_shot = true
	particles.amount = 4
	particles.lifetime = 0.3
	particles.explosiveness = 0.9
	particles.direction = Vector2(0, -1)
	particles.spread = 60
	particles.initial_velocity_min = 20
	particles.initial_velocity_max = 40
	particles.gravity = Vector2(0, 100)
	particles.scale_amount_min = 1
	particles.scale_amount_max = 2
	particles.color = Color(0.8, 0.7, 0.5, 0.7)  # 연한 흙색
	particles.global_position = world_pos
	
	get_tree().current_scene.add_child(particles)
	particles.emitting = true
	
	# 파티클이 끝나면 자동 삭제
	await get_tree().create_timer(particles.lifetime + 0.1).timeout
	if is_instance_valid(particles):
		particles.queue_free()

## ========================================
## 타일 파괴 가능 여부 체크
## ========================================

## 특정 레이어의 타일을 파괴할 수 있는지 확인합니다.
## 모든 타일은 항상 파괴 가능 (티어는 속도/횟수에만 영향)
## @param layer_index: 타일 레이어 인덱스
## @returns: 항상 true (모든 타일 파괴 가능)
func can_break_tile(_layer_index: int) -> bool:
	return true  # 모든 타일 파괴 가능

## 특정 레이어의 타일에 필요한 클릭 횟수를 반환합니다.
## 티어가 높을수록 필요 횟수 감소
## @param layer_index: 타일 레이어 인덱스
## @returns: 필요한 클릭 횟수
func get_required_clicks(layer_index: int) -> int:
	# layer 4 (instant_break)는 항상 1번
	if layer_index == INSTANT_BREAK_LAYER:
		return 1
	
	# 기본 클릭 횟수 (레이어가 깊을수록 더 많은 클릭 필요)
	var base_clicks = (layer_index + 1) * 2  # layer_0: 2, layer_1: 4, layer_2: 6, layer_3: 8
	
	# 티어에 따른 감소 (티어 1개당 1클릭 감소, 최소 1)
	var reduction = Globals.mining_tier - 1
	var final_clicks = max(1, base_clicks - reduction)
	
	return final_clicks

## ========================================
## 타일 파괴 처리
## ========================================

## 마우스 위치의 타일을 파괴 시도합니다.
func try_break_tile_at_mouse():
	if not character:
		return
	
	# 마우스 위치를 타일 좌표로 변환
	var mouse_pos = get_global_mouse_position()
	var local_pos = to_local(mouse_pos)
	var tile_pos = local_to_map(local_pos)
	
	# 캐릭터와의 거리 체크
	var tile_world_pos = to_global(map_to_local(tile_pos))
	if character.global_position.distance_to(tile_world_pos) > mining_range:
		return  # 너무 멀리 있음
	
	# 모든 레이어에서 타일 찾기 (위에서부터)
	for layer_idx in range(get_layers_count() - 1, -1, -1):
		var source_id = get_cell_source_id(layer_idx, tile_pos)
		if source_id != -1:
			# 타일 발견 - 파괴 (모든 타일은 항상 파괴 가능)
			break_tile(tile_pos, layer_idx)
			return

## 특정 위치의 타일을 파괴합니다.
## @param tile_pos: 타일 좌표
## @param layer_idx: 레이어 인덱스
func break_tile(tile_pos: Vector2i, layer_idx: int):
	# 타일 월드 좌표 계산 (파티클/이펙트용)
	var tile_world_pos = to_global(map_to_local(tile_pos))
	
	# 제거하기 전에 타일의 terrain 정보 가져오기
	var tile_data = get_cell_tile_data(layer_idx, tile_pos)
	var terrain_set = -1
	var terrain = -1
	
	if tile_data:
		terrain_set = tile_data.terrain_set
		terrain = tile_data.terrain
	
	# 타일 제거 + 주변 terrain 자동 업데이트
	# terrain = -1로 설정하면 타일이 제거되면서 주변 terrain이 자동으로 업데이트됨
	if terrain_set >= 0:
		# terrain 정보가 있으면 terrain 기반 제거 (자동 주변 업데이트)
		set_cells_terrain_connect(layer_idx, [tile_pos], terrain_set, -1, true)
	else:
		# terrain 정보가 없으면 일반 제거
		set_cell(layer_idx, tile_pos, -1)
	
	# 제거 후 확인 (디버깅용)
	var source_id_after = get_cell_source_id(layer_idx, tile_pos)
	if source_id_after != -1:
		print("⚠️ 경고: 타일이 제거되지 않았습니다! pos=", tile_pos, " layer=", layer_idx)
	
	# 보상 지급
	var is_instant = (layer_idx == INSTANT_BREAK_LAYER)
	give_mining_reward(tile_world_pos, is_instant)
	
	# 파티클 효과
	spawn_break_particles(tile_world_pos)
	
	# 사운드 재생
	if break_sound:
		break_sound.play()
	
	# 위에 있는 플랫폼 타일 업데이트 (지지대 → 공중용으로 변경)
	_update_platform_above(tile_world_pos)

## 블록 파괴 후 위에 있는 플랫폼 타일을 업데이트합니다.
## @param world_pos: 파괴된 블록의 월드 좌표
func _update_platform_above(world_pos: Vector2) -> void:
	# 여러 경로를 시도하여 tile_map 노드 찾기
	var tile_map_node = null
	
	# 1. 절대 경로 시도
	tile_map_node = get_node_or_null("/root/main/tilemaps")
	
	# 2. TileMap 이름으로 시도
	if not tile_map_node:
		tile_map_node = get_tree().current_scene.get_node_or_null("TileMap")
	
	# 3. tile_map 이름으로 시도
	if not tile_map_node:
		tile_map_node = get_tree().current_scene.get_node_or_null("tile_map")
	
	# 4. 그룹에서 찾기
	if not tile_map_node:
		tile_map_node = get_tree().get_first_node_in_group("tile_map_manager")
	
	# 5. 부모 노드에서 찾기
	if not tile_map_node:
		var parent = get_parent()
		while parent and not tile_map_node:
			if parent.has_method("update_platform_above"):
				tile_map_node = parent
				break
			parent = parent.get_parent()
	
	if tile_map_node:
		# 플랫폼 타일 업데이트
		if tile_map_node.has_method("update_platform_above"):
			tile_map_node.update_platform_above(world_pos)
			print("🔄 플랫폼 업데이트 요청: ", world_pos)
		
		# inside_cave terrain 업데이트 (인접한 동굴 타일 지형 변경)
		if tile_map_node.has_method("update_inside_cave_terrain_around"):
			tile_map_node.update_inside_cave_terrain_around(world_pos)
	else:
		print("⚠️ tile_map 노드를 찾을 수 없음 - 플랫폼 업데이트 실패")

## [더 이상 사용 안 함] 제거된 타일 주변의 terrain 연결을 업데이트합니다.
## set_cells_terrain_connect()가 자동으로 처리하므로 이 함수는 더 이상 필요 없습니다.
# func update_terrain_around(removed_pos: Vector2i, layer_idx: int):
# 	if not tile_set:
# 		return
# 	
# 	# 주변 8방향 + 자기 자신 위치의 타일들
# 	var neighbors = [
# 		Vector2i(-1, -1), Vector2i(0, -1), Vector2i(1, -1),
# 		Vector2i(-1, 0),                   Vector2i(1, 0),
# 		Vector2i(-1, 1),  Vector2i(0, 1),  Vector2i(1, 1)
# 	]
# 	
# 	# 주변 타일들 중 terrain을 사용하는 타일들 수집
# 	var tiles_to_update: Array[Vector2i] = []
# 	
# 	for offset in neighbors:
# 		var neighbor_pos = removed_pos + offset
# 		var source_id = get_cell_source_id(layer_idx, neighbor_pos)
# 		if source_id != -1:
# 			# 타일이 있으면 업데이트 대상에 추가
# 			tiles_to_update.append(neighbor_pos)
# 	
# 	# terrain 연결 업데이트
# 	if tiles_to_update.size() > 0:
# 		# 첫 번째 타일에서 terrain 정보 가져오기
# 		var first_tile = tiles_to_update[0]
# 		var tile_data = get_cell_tile_data(layer_idx, first_tile)
# 		if tile_data:
# 			var terrain_set = tile_data.terrain_set
# 			var terrain = tile_data.terrain
# 			if terrain_set >= 0 and terrain >= 0:
# 				# terrain 연결로 주변 타일들 업데이트
# 				set_cells_terrain_connect(layer_idx, tiles_to_update, terrain_set, terrain, false)

## ========================================
## 보상 시스템
## ========================================

## 채굴 보상을 지급합니다.
## @param world_pos: 타일 월드 좌표 (텍스트 표시용)
## @param is_instant: 한방 파괴 여부
func give_mining_reward(world_pos: Vector2, is_instant: bool):
	# 기본 보상 계산
	var base_reward = Globals.money_up * Globals.rock_money_bonus
	
	# 피버 배율 적용
	var reward = int(base_reward * Globals.fever_multiplier)
	
	# x3, x2 확률 체크
	var random_roll = randf()
	var is_x3 = random_roll < Globals.x3_chance
	var is_x2 = not is_x3 and random_roll < (Globals.x3_chance + Globals.x2_chance)
	
	if is_x3:
		reward *= 3
	elif is_x2:
		reward *= 2
	
	# 돈 추가
	Globals.money += reward
	
	# 떠오르는 텍스트 표시
	var text = "+💎" + str(reward)
	var color = Color(1.0, 0.9, 0.3)  # 기본 금색
	
	if is_x3:
		text += "!!"
		color = Color(0.3, 0.6, 1.0)  # 잭팟 파란색
	elif is_x2:
		text += "!"
		color = Color(1.0, 0.3, 0.8)  # 크리티컬 핑크
	elif is_instant:
		color = Color(0.3, 1.0, 1.0)  # 한방 파괴 시안색
	
	spawn_floating_text(world_pos, text, color)

## ========================================
## 하이라이트 시스템 (Sprite2D 방식)
## ========================================

## 하이라이트용 스프라이트를 생성합니다.
func create_highlight_sprite():
	highlight_sprite = Sprite2D.new()
	highlight_sprite.name = "HighlightSprite"
	highlight_sprite.z_index = 100  # 타일 위에 표시
	highlight_sprite.visible = false
	
	# 16x16 노란색 테두리 텍스처 생성
	var size = 16
	var border = 2
	var image = Image.create(size, size, false, Image.FORMAT_RGBA8)
	image.fill(Color(0, 0, 0, 0))  # 투명 배경
	
	# 테두리만 그리기 (노란색)
	var highlight_color = Color(1.0, 1.0, 0.3, 0.8)  # 노란색
	for x in range(size):
		for y in range(size):
			# 테두리 영역인지 확인
			if x < border or x >= size - border or y < border or y >= size - border:
				image.set_pixel(x, y, highlight_color)
	
	var texture = ImageTexture.create_from_image(image)
	highlight_sprite.texture = texture
	
	# 체력바 배경 생성
	hp_bar_bg = ColorRect.new()
	hp_bar_bg.size = Vector2(16, 3)
	hp_bar_bg.position = Vector2(-8, -12)  # 타일 위에 표시
	hp_bar_bg.color = Color(0.2, 0.2, 0.2, 0.8)
	hp_bar_bg.visible = false
	highlight_sprite.add_child(hp_bar_bg)
	
	# 체력바 채움 생성
	hp_bar_fill = ColorRect.new()
	hp_bar_fill.size = Vector2(16, 3)
	hp_bar_fill.position = Vector2(0, 0)
	hp_bar_fill.color = Color(0.2, 1.0, 0.2, 1.0)  # 녹색
	hp_bar_bg.add_child(hp_bar_fill)
	
	# 씬에 추가 (TileMap의 부모에)
	get_parent().add_child.call_deferred(highlight_sprite)
	print("✅ 하이라이트 스프라이트 + 체력바 생성 완료 (16x16)")

## 캐릭터 근처의 가장 가까운 파괴 가능한 타일을 찾아 하이라이트합니다.
func update_highlighted_tile():
	if not character:
		hide_highlight()
		return
	
	# 가장 가까운 타일 찾기
	var nearest = get_nearest_breakable_tile()
	
	if nearest == null:
		# 범위 내 타일 없음 - 하이라이트 해제
		highlighted_tile = Vector2i(-9999, -9999)
		highlighted_layer = -1
		hide_highlight()
		return
	
	# 하이라이트 업데이트
	highlighted_tile = nearest["tile_pos"]
	highlighted_layer = nearest["layer"]
	
	# Sprite2D로 하이라이트 표시
	show_highlight(nearest["world_pos"])

## 하이라이트를 표시합니다 (Sprite2D 방식).
func show_highlight(world_pos: Vector2):
	if highlight_sprite:
		highlight_sprite.global_position = world_pos
		highlight_sprite.visible = true
		
		# 타일 HP 키
		var tile_key = "%d_%d_%d" % [highlighted_layer, highlighted_tile.x, highlighted_tile.y]
		var max_hp = get_required_clicks(highlighted_layer)
		var current_hp = tile_hp.get(tile_key, max_hp)
		
		# 이미 타격한 타일이면 주황색 + 체력바 표시
		if tile_hp.has(tile_key):
			highlight_sprite.modulate = Color(1.0, 0.6, 0.2, 0.7)  # 주황색
			# 체력바 표시
			if hp_bar_bg:
				hp_bar_bg.visible = true
				var hp_ratio = float(current_hp) / float(max_hp)
				hp_bar_fill.size.x = 16.0 * hp_ratio
				# HP 비율에 따른 색상 (녹색 → 빨간색)
				hp_bar_fill.color = Color(1.0 - hp_ratio, hp_ratio, 0.2, 1.0)
		else:
			highlight_sprite.modulate = Color(1.0, 1.0, 0.3, 0.7)  # 노란색
			if hp_bar_bg:
				hp_bar_bg.visible = false  # 새 타일은 체력바 숨김

## 하이라이트를 숨깁니다.
func hide_highlight():
	if highlight_sprite:
		highlight_sprite.visible = false
	if hp_bar_bg:
		hp_bar_bg.visible = false

## ========================================
## 시각 효과
## ========================================

## 떠오르는 텍스트를 생성합니다.
## @param world_pos: 월드 좌표
## @param text: 표시할 텍스트
## @param color: 텍스트 색상
func spawn_floating_text(world_pos: Vector2, text: String, color: Color = Color.WHITE):
	var floating_text_script = load("res://floating_text.gd")
	if floating_text_script:
		# 현재 씬의 루트에 상대 좌표로 생성
		var scene_root = get_tree().current_scene
		if scene_root:
			var relative_pos = world_pos - scene_root.global_position if scene_root is Node2D else world_pos
			floating_text_script.create(scene_root, relative_pos, text, color)

## 파괴 파티클을 생성합니다.
## @param world_pos: 월드 좌표
func spawn_break_particles(world_pos: Vector2):
	var particles = CPUParticles2D.new()
	particles.emitting = false
	particles.one_shot = true
	particles.amount = 8
	particles.lifetime = 0.5
	particles.explosiveness = 0.9
	particles.direction = Vector2(0, -1)
	particles.spread = 90
	particles.initial_velocity_min = 40
	particles.initial_velocity_max = 80
	particles.gravity = Vector2(0, 200)
	particles.scale_amount_min = 2
	particles.scale_amount_max = 4
	particles.color = Color(0.6, 0.5, 0.4, 0.9)  # 흙/돌 색상
	particles.global_position = world_pos
	
	get_tree().current_scene.add_child(particles)
	particles.emitting = true
	
	# 파티클이 끝나면 자동 삭제
	await get_tree().create_timer(particles.lifetime + 0.1).timeout
	if is_instance_valid(particles):
		particles.queue_free()

## 먼지 스프라이트 파티클을 생성합니다 (dust_texture 사용).
## @param world_pos: 월드 좌표
## @param amount: 파티클 개수
func spawn_dust_particles(world_pos: Vector2, amount: int = 6):
	if not dust_texture:
		return
	
	for i in range(amount):
		var dust_sprite = Sprite2D.new()
		
		# 아틀라스 텍스처 설정
		var atlas_tex = AtlasTexture.new()
		atlas_tex.atlas = dust_texture
		atlas_tex.region = Rect2(0, 0, 16, 16)
		dust_sprite.texture = atlas_tex
		
		# 크기 및 필터 설정
		var scale_val = randf_range(0.3, 0.6)
		dust_sprite.scale = Vector2(scale_val, scale_val)
		dust_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		dust_sprite.global_position = world_pos
		
		get_tree().current_scene.add_child(dust_sprite)
		
		# 애니메이션
		_animate_dust(dust_sprite, atlas_tex)

## 먼지 파티클 애니메이션 (중력 효과).
func _animate_dust(dust_sprite: Sprite2D, atlas_tex: AtlasTexture):
	var angle = randf_range(-150, -30) * PI / 180.0
	var speed = randf_range(30, 60)
	var velocity = Vector2(cos(angle), sin(angle)) * speed
	var gravity = 120.0
	var lifetime = randf_range(0.4, 0.7)
	var elapsed = 0.0
	var rotation_speed = randf_range(-4.0, 4.0)
	var switched_sprite = false
	var switch_progress = randf_range(0.3, 0.5)
	
	while elapsed < lifetime and is_instance_valid(dust_sprite):
		var delta = get_process_delta_time()
		elapsed += delta
		velocity.y += gravity * delta
		dust_sprite.position += velocity * delta
		dust_sprite.rotation += rotation_speed * delta
		
		var progress = elapsed / lifetime
		if not switched_sprite and progress > switch_progress:
			atlas_tex.region = Rect2(16, 0, 16, 16)
			switched_sprite = true
		
		if progress > 0.5:
			dust_sprite.modulate.a = 1.0 - (progress - 0.5) * 2.0
		
		await get_tree().process_frame
	
	if is_instance_valid(dust_sprite):
		dust_sprite.queue_free()
